import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient as createServerClient } from '$lib/supabase/server';
import { createAdminClient } from '$lib/supabase/admin';
import type { OrderStatus } from '$lib/types';

export const PATCH: RequestHandler = async ({ request, params, cookies }) => {
    const { id } = params;

    try {
        const supabase = createServerClient(cookies);
        const { data: { session } } = await supabase.auth.getSession();

        if (!session) {
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Check if user is staff (manager/chef)
        const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();

        if (!profile || !['manager', 'chef'].includes(profile.role)) {
            return json({ error: 'Forbidden' }, { status: 403 });
        }

        const { status } = await request.json();

        if (!status) {
            return json({ error: 'Status is required' }, { status: 400 });
        }

        const adminSupabase = createAdminClient();

        const isTerminalStatus = ['delivered', 'picked_up', 'served'].includes(status);
        const updateData: Record<string, unknown> = { status: status as OrderStatus };
        if (isTerminalStatus) {
            updateData.payment_status = 'paid';
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
            status: status as OrderStatus,
            changed_by: session.user.id,
        });



        return json({ success: true, status: order.status });
    } catch (error) {
        console.error('Status update API error:', error);
        return json({ error: 'Internal server error' }, { status: 500 });
    }
};
