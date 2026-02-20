import { createClient } from '@supabase/supabase-js';
import { env as public_env } from '$env/dynamic/public';
import { env as private_env } from '$env/dynamic/private';

// Service role client — bypasses RLS. Only use in API routes / server actions.
export function createAdminClient() {
    return createClient(public_env.PUBLIC_SUPABASE_URL!, private_env.SUPABASE_SERVICE_ROLE_KEY!, {
        auth: {
            autoRefreshToken: false,
            persistSession: false,
        },
    });
}
