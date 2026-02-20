import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createAdminClient } from '$lib/supabase/admin';
import { sendNewsletterWelcomeEmail } from '$lib/server/email';

export const POST: RequestHandler = async ({ request, url }) => {
    try {
        const { email } = await request.json();

        if (!email || !email.includes('@')) {
            return json({ error: 'Valid email is required' }, { status: 400 });
        }

        const normalizedEmail = email.toLowerCase().trim();
        const supabase = createAdminClient();

        // Check if subscriber already exists
        const { data: existing } = await supabase
            .from('newsletter_subscribers')
            .select('id')
            .eq('email', normalizedEmail)
            .single();

        if (existing) {
            return json({ error: 'This email is already subscribed!' }, { status: 400 });
        }

        // Insert new subscriber
        const { error } = await supabase
            .from('newsletter_subscribers')
            .insert({ email: normalizedEmail });

        if (error) {
            console.error('Newsletter error:', error);
            return json({ error: 'Failed to subscribe. Please try again later.' }, { status: 500 });
        }

        // Send welcome email asynchronously
        sendNewsletterWelcomeEmail(normalizedEmail, url.origin).catch(err => {
            console.error('Failed to send welcome email:', err);
        });

        return json({ success: true, message: 'Welcome to the family! Check your email.' });
    } catch (error) {
        console.error('Newsletter API error:', error);
        return json({ error: 'An unexpected error occurred' }, { status: 500 });
    }
};
