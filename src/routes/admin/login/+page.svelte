<script lang="ts">
    import { goto } from '$app/navigation';
    import { createClient } from '$lib/supabase/client';
    import { APP_NAME } from '$lib/constants';
    import { Loader2, LogIn } from 'lucide-svelte';

    let email = $state('');
    let password = $state('');
    let loading = $state(false);
    let error = $state('');

    async function handleLogin(e: Event) {
        e.preventDefault();
        error = '';
        loading = true;

        try {
            const supabase = createClient();
            const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password });

            if (authError) { error = authError.message; loading = false; return; }

            const { data: profile, error: profileError } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', data.user.id)
                .single();

            if (profileError || !profile) {
                error = 'You do not have staff access.';
                await supabase.auth.signOut();
                loading = false;
                return;
            }

            if (profile.role === 'chef') {
                goto('/admin/kitchen');
            } else {
                goto('/admin/dashboard');
            }
        } catch {
            error = 'Something went wrong. Please try again.';
            loading = false;
        }
    }
</script>

<svelte:head>
    <title>Staff Login — {APP_NAME}</title>
</svelte:head>

<div class="admin-login">
    <div class="login-card">
        <div class="login-logo">
            <img src="/logo.png" alt="{APP_NAME}" class="login-logo-img" />
        </div>
        <p class="login-subtitle">Staff Dashboard Login</p>

        {#if error}
            <div class="login-error">{error}</div>
        {/if}

        <form onsubmit={handleLogin}>
            <div class="field">
                <label class="label" for="login-email">Email</label>
                <input
                    id="login-email"
                    type="email"
                    class="input"
                    placeholder="your@email.com"
                    bind:value={email}
                    required
                />
            </div>
            <div class="field">
                <label class="label" for="login-password">Password</label>
                <input
                    id="login-password"
                    type="password"
                    class="input"
                    placeholder="••••••••"
                    bind:value={password}
                    required
                />
            </div>
            <button type="submit" class="btn btn-primary btn-lg login-btn" disabled={loading}>
                {#if loading}
                    <Loader2 size={18} class="animate-spin" /> Signing in...
                {:else}
                    <LogIn size={18} /> Sign In
                {/if}
            </button>
        </form>
    </div>
</div>

<style>
    .admin-login {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: var(--space-6);
        background:
            radial-gradient(ellipse at 50% 30%, rgba(230, 57, 70, 0.08) 0%, transparent 50%),
            var(--color-bg-primary);
    }

    .login-card {
        width: 100%;
        max-width: 420px;
        background: var(--color-bg-glass);
        backdrop-filter: blur(20px);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        padding: var(--space-10);
        animation: scaleIn var(--transition-spring);
    }

    .login-logo {
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: var(--space-8);
    }

    .login-logo-img {
        height: 100px;
        width: auto;
        object-fit: contain;
        mix-blend-mode: lighten;
    }

    .login-subtitle {
        text-align: center;
        color: var(--color-text-secondary);
        font-size: var(--text-sm);
        margin-bottom: var(--space-8);
    }

    .login-btn {
        width: 100%;
        margin-top: var(--space-6);
    }

    .login-error {
        padding: var(--space-3) var(--space-4);
        background: rgba(230, 57, 70, 0.1);
        border: 1px solid rgba(230, 57, 70, 0.2);
        border-radius: var(--radius-md);
        color: var(--color-danger);
        font-size: var(--text-sm);
        margin-bottom: var(--space-4);
    }
</style>
