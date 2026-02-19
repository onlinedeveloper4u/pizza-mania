<script lang="ts">
    import { page } from '$app/stores';
    import { goto } from '$app/navigation';
    import { onMount } from 'svelte';
    import { createClient } from '$lib/supabase/client';
    import { APP_NAME } from '$lib/constants';
    import { cn } from '$lib/utils';
    import type { Profile } from '$lib/types';
    import { LayoutDashboard, ShoppingBag, BookOpen, Grid3x3, ChefHat, LogOut, Loader2, Ticket } from 'lucide-svelte';
    
    let { children } = $props();

    let profile = $state<Profile | null>(null);
    let loading = $state(true);
    let currentPath = $derived($page.url.pathname);
    let isLoginPage = $derived(currentPath === '/admin/login');

    async function checkAuth() {
        if (isLoginPage) { loading = false; return; }
        
        if (!profile) loading = true;

        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) { goto('/admin/login'); return; }

        const { data: profileData } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();

        if (!profileData) { goto('/admin/login'); return; }
        profile = profileData;
        loading = false;

        // Role-based Redirect Protection
        if (profile.role === 'chef' && !currentPath.startsWith('/admin/kitchen')) {
            goto('/admin/kitchen');
        }
    }

    $effect(() => {
        if (!isLoginPage) {
            checkAuth();
        }
    });

    async function handleLogout() {
        profile = null; // Clear state immediately
        const supabase = createClient();
        await supabase.auth.signOut();
        goto('/admin/login', { replaceState: true });
    }

    let isManager = $derived(profile?.role === 'manager');

    const managerLinks = [
        { href: '/admin/dashboard', label: 'Dashboard', icon: LayoutDashboard },
        { href: '/admin/orders', label: 'Orders', icon: ShoppingBag },
        { href: '/admin/menu', label: 'Menu', icon: BookOpen },
        { href: '/admin/offers', label: 'Offers', icon: Ticket },
        { href: '/admin/tables', label: 'Tables', icon: Grid3x3 },
    ];

    const chefLinks = [
        { href: '/admin/kitchen', label: 'Kitchen', icon: ChefHat },
    ];

    let navLinks = $derived(isManager ? managerLinks : chefLinks);
</script>

{#if isLoginPage}
    {@render children()}
{:else if loading}
    <div class="admin-loading">
        <Loader2 size={48} class="animate-spin" color="var(--color-primary)" />
    </div>
{:else}
    <div class="admin-layout">
        <aside class="sidebar">
            <div class="sidebar-header">
                <div class="sidebar-logo">
                    <img src="/logo.png" alt="{APP_NAME}" class="sidebar-logo-img" />
                </div>
            </div>

            <nav class="sidebar-nav">
                {#each navLinks as link}
                    <a
                        href={link.href}
                        class={cn('sidebar-link', currentPath === link.href && 'sidebar-link-active')}
                    >
                        <link.icon size={18} />
                        {link.label}
                    </a>
                {/each}
            </nav>

            <div class="sidebar-footer">
                <div class="sidebar-user">
                    <div class="sidebar-avatar">
                        {profile?.full_name?.charAt(0).toUpperCase() || '?'}
                    </div>
                    <div class="sidebar-user-info">
                        <div class="sidebar-user-name">{profile?.full_name}</div>
                        <div class="sidebar-user-role">{profile?.role}</div>
                    </div>
                </div>
                <button
                    class="sidebar-link"
                    onclick={handleLogout}
                    style="width:100%;cursor:pointer"
                >
                    <LogOut size={18} />
                    Sign Out
                </button>
            </div>
        </aside>

        <main class="admin-main">
            {@render children()}
        </main>
    </div>
{/if}

<style>
    .admin-loading {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .admin-layout {
        display: flex;
        min-height: 100vh;
    }

    .sidebar {
        width: var(--sidebar-width, 260px);
        background: var(--color-bg-secondary);
        border-right: 1px solid var(--color-border);
        position: fixed;
        top: 0; left: 0; bottom: 0;
        display: flex;
        flex-direction: column;
        z-index: var(--z-sticky);
    }

    .sidebar-header {
        padding: var(--space-6);
        border-bottom: 1px solid var(--color-border);
    }

    .sidebar-logo {
        display: flex;
        align-items: center;
    }

    .sidebar-logo-img {
        height: 60px;
        width: auto;
        object-fit: contain;
        mix-blend-mode: lighten;
    }

    .sidebar-nav {
        flex: 1;
        padding: var(--space-4) var(--space-3);
        display: flex;
        flex-direction: column;
        gap: var(--space-1);
    }

    :global(.sidebar-link) {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        padding: var(--space-3) var(--space-4);
        border-radius: var(--radius-lg);
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        transition: all var(--transition-fast);
        text-decoration: none;
        background: none;
        border: none;
    }

    :global(.sidebar-link:hover) {
        color: var(--color-text-primary);
        background: var(--color-bg-glass);
    }

    :global(.sidebar-link-active) {
        color: var(--color-primary) !important;
        background: rgba(230, 57, 70, 0.08) !important;
    }

    .sidebar-footer {
        padding: var(--space-4) var(--space-3);
        border-top: 1px solid var(--color-border);
    }

    .sidebar-user {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        padding: var(--space-3) var(--space-4);
    }

    .sidebar-user-info {
        flex: 1;
        min-width: 0;
    }

    .sidebar-user-name {
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .sidebar-user-role {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        text-transform: capitalize;
    }

    .sidebar-avatar {
        width: 36px; height: 36px;
        border-radius: var(--radius-full);
        background: linear-gradient(135deg, var(--color-primary), var(--color-accent));
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: var(--text-sm);
        font-weight: var(--weight-bold);
        color: white;
        flex-shrink: 0;
    }

    .admin-main {
        flex: 1;
        margin-left: var(--sidebar-width, 260px);
        padding: var(--space-8);
    }

    @media (max-width: 1024px) {
        .sidebar { display: none; }
        .admin-main { margin-left: 0; }
    }
</style>
