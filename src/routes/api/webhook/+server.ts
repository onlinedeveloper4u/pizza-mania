import { json, text } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { stripe } from '$lib/stripe.server';
import { createAdminClient } from '$lib/supabase/admin';
import { STRIPE_WEBHOOK_SECRET } from '$env/static/private';

export const POST: RequestHandler = async ({ request }) => {
    const body = await request.text();
    const sig = request.headers.get('stripe-signature');

    if (!sig) {
        return json({ error: 'Missing signature' }, { status: 400 });
    }

    try {
        const event = stripe.webhooks.constructEvent(body, sig, STRIPE_WEBHOOK_SECRET);

        if (event.type === 'checkout.session.completed') {
            const session = event.data.object;
            const orderId = session.metadata?.order_id;

            if (orderId) {
                const supabase = createAdminClient();

                // Update payment status
                await supabase
                    .from('orders')
                    .update({ payment_status: 'paid' })
                    .eq('id', orderId);

                console.log(`Payment completed for order ${orderId}`);
            }
        }

        return json({ received: true });
    } catch (err) {
        console.error('Webhook error:', err);
        return json({ error: 'Webhook failed' }, { status: 400 });
    }
};
