import { createServerClient } from '@supabase/ssr';
import { env } from '$env/dynamic/public';
import type { Cookies } from '@sveltejs/kit';

export function createClient(cookies: Cookies) {
    return createServerClient(env.PUBLIC_SUPABASE_URL!, env.PUBLIC_SUPABASE_ANON_KEY!, {
        cookies: {
            getAll() {
                return cookies.getAll();
            },
            setAll(cookiesToSet) {
                cookiesToSet.forEach(({ name, value, options }) => {
                    cookies.set(name, value, { ...options, path: '/' });
                });
            },
        },
    });
}
