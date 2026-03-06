import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createAdminClient } from '$lib/supabase/admin';
import { stripe } from '$lib/stripe.server';
import { sendOrderStatusEmail } from '$lib/server/email';
import type { OrderWithItems } from '$lib/types';

// Statuses that are still cancellable by the user
const CANCELLABLE_STATUSES = ['new', 'confirmed'];

export const POST: RequestHandler = async ({ request, url }) => {
    try {
        const { tracking_token } = await request.json();

        if (!tracking_token) {
            return json({ error: 'Tracking token is required' }, { status: 400 });
        }

        const adminSupabase = createAdminClient();

        // Fetch the order by tracking token
        const { data: order, error: fetchError } = await adminSupabase
            .from('orders')
            .select('*, order_items(*)')
            .eq('tracking_token', tracking_token)
            .single();

        if (fetchError || !order) {
            return json({ error: 'Order not found' }, { status: 404 });
        }

        // Check if cancellation is allowed based on current status
        if (!CANCELLABLE_STATUSES.includes(order.status)) {
            return json(
                {
                    error:
                        order.status === 'cancelled'
                            ? 'This order is already cancelled.'
                            : 'This order cannot be cancelled — it is already being prepared.',
                },
                { status: 422 }
            );
        }

        const updateData: Record<string, unknown> = { status: 'cancelled' };
        let refunded = false;

        // Issue Stripe refund if the customer paid online
        if (
            order.payment_method === 'online' &&
            order.payment_status === 'paid' &&
            order.stripe_session_id
        ) {
            try {
                const stripeSession = await stripe.checkout.sessions.retrieve(
                    order.stripe_session_id
                );
                if (stripeSession.payment_intent) {
                    await stripe.refunds.create({
                        payment_intent: stripeSession.payment_intent as string,
                    });
                    updateData.payment_status = 'refunded';
                    refunded = true;
                    console.log(
                        `Refund issued for order ${order.id} (Stripe session: ${order.stripe_session_id})`
                    );
                }
            } catch (refundError) {
                console.error('Stripe refund error:', refundError);
                // Don't block cancellation — log the error but continue
            }
        }

        // Update order status
        const { error: updateError } = await adminSupabase
            .from('orders')
            .update(updateData)
            .eq('id', order.id);

        if (updateError) {
            throw updateError;
        }

        // Log status change to history
        await adminSupabase.from('order_status_history').insert({
            order_id: order.id,
            status: 'cancelled',
            changed_by: null, // user-initiated
        });

        // Send cancellation email to customer
        if (order.customer_email) {
            const fullOrder: OrderWithItems = { ...order, status: 'cancelled' };
            sendOrderStatusEmail(fullOrder as OrderWithItems, order.customer_email, url.origin, order.status).catch(
                console.error
            );
        }

        return json({ success: true, refunded });
    } catch (error) {
        console.error('Cancel order API error:', error);
        return json({ error: 'Internal server error' }, { status: 500 });
    }
};
