import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient as createServerClient } from '$lib/supabase/server';
import { createAdminClient } from '$lib/supabase/admin';
import type { OrderStatus, OrderWithItems } from '$lib/types';
import { sendOrderStatusEmail } from '$lib/server/email';
import { stripe } from '$lib/stripe.server';

export const PATCH: RequestHandler = async ({ request, params, cookies, url }) => {
    const { id } = params;

    try {
        const supabase = createServerClient(cookies);
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Check if user is staff (manager/chef)
        const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        if (!profile || !['manager', 'chef'].includes(profile.role)) {
            return json({ error: 'Forbidden' }, { status: 403 });
        }

        const { status: newStatus } = await request.json();

        if (!newStatus) {
            return json({ error: 'Status is required' }, { status: 400 });
        }

        const adminSupabase = createAdminClient();

        // 0. Fetch full previous order to detect transitions
        const { data: oldOrder } = await adminSupabase
            .from('orders')
            .select('*')
            .eq('id', id)
            .single();

        const previousStatus = oldOrder?.status;

        const isTerminalStatus = ['delivered', 'picked_up', 'served'].includes(newStatus);
        const updateData: Record<string, unknown> = { status: newStatus as OrderStatus };
        if (isTerminalStatus) {
            updateData.payment_status = 'paid';
        }

        // If cancelling an online-paid order → issue Stripe refund
        if (
            newStatus === 'cancelled' &&
            oldOrder?.payment_method === 'online' &&
            oldOrder?.payment_status === 'paid' &&
            oldOrder?.stripe_session_id
        ) {
            try {
                const stripeSession = await stripe.checkout.sessions.retrieve(oldOrder.stripe_session_id);
                if (stripeSession.payment_intent) {
                    await stripe.refunds.create({
                        payment_intent: stripeSession.payment_intent as string,
                    });
                    updateData.payment_status = 'refunded';
                    console.log(`Refund issued for order ${id} (Stripe session: ${oldOrder.stripe_session_id})`);
                }
            } catch (refundError) {
                console.error('Stripe refund error:', refundError);
                // Don't block the status update — log the error but continue
            }
        }

        // 1. Update the order
        const { data: order, error: updateError } = await adminSupabase
            .from('orders')
            .update(updateData)
            .eq('id', id)
            .select('*, order_items(*)')
            .single();

        if (updateError) {
            throw updateError;
        }

        // 2. Add to status history
        await adminSupabase.from('order_status_history').insert({
            order_id: id,
            status: newStatus as OrderStatus,
            changed_by: user.id,
        });

        // 3. Send email update (Smart logic inside function)
        if (order.customer_email) {
            sendOrderStatusEmail(order as OrderWithItems, order.customer_email, url.origin, previousStatus).catch(console.error);
        }

        return json({ success: true, status: order.status });
    } catch (error) {
        console.error('Status update API error:', error);
        return json({ error: 'Internal server error' }, { status: 500 });
    }
};
