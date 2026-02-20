import { createBrowserClient } from '@supabase/ssr';
import { env } from '$env/dynamic/public';

let client: ReturnType<typeof createBrowserClient> | null = null;

export function createClient() {
    if (client) return client;
    client = createBrowserClient(env.PUBLIC_SUPABASE_URL!, env.PUBLIC_SUPABASE_ANON_KEY!);
    return client;
}
