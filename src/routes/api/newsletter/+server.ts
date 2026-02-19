import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createAdminClient } from '$lib/supabase/admin';

export const POST: RequestHandler = async ({ request }) => {
    try {
        const { email } = await request.json();

        if (!email || !email.includes('@')) {
            return json({ error: 'Valid email is required' }, { status: 400 });
        }

        const supabase = createAdminClient();

        // Check if subscriber already exists
        const { data: existing } = await supabase
            .from('newsletter_subscribers')
            .select('id')
            .eq('email', email)
            .single();

        if (existing) {
            return json({ error: 'This email is already subscribed!' }, { status: 400 });
        }

        // Insert new subscriber
        const { error } = await supabase
            .from('newsletter_subscribers')
            .insert({ email });

        if (error) {
            console.error('Newsletter error:', error);
            return json({ error: 'Failed to subscribe. Please try again later.' }, { status: 500 });
        }

        return json({ success: true });
    } catch (error) {
        console.error('Newsletter API error:', error);
        return json({ error: 'An unexpected error occurred' }, { status: 500 });
    }
};
