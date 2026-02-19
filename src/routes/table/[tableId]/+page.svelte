<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';
    import { UtensilsCrossed, AlertCircle, Loader2 } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import { cart } from '$lib/stores/cart';
    import type { Table } from '$lib/types';

    let tableId = $derived($page.params.tableId);
    let table: Table | null = $state(null);
    let loading = $state(true);
    let error = $state(false);

    onMount(async () => {
        const supabase = createClient();
        const { data, error: err } = await supabase
            .from('tables')
            .select('*')
            .eq('id', tableId)
            .eq('is_active', true)
            .single();

        if (err || !data) {
            error = true;
        } else {
            table = data;
            cart.setTable(data.id, data.table_number);
        }
        loading = false;
    });

    // Auto-redirect to menu after 3 seconds
    $effect(() => {
        if (table) {
            const timer = setTimeout(() => goto('/menu'), 3000);
            return () => clearTimeout(timer);
        }
    });
</script>

<svelte:head>
    <title>Table — Pizza Mania</title>
</svelte:head>

{#if loading}
    <div class="centered">
        <Loader2 size={48} class="animate-spin" color="var(--color-primary)" />
        <p>Setting up your table...</p>
    </div>
{:else if error}
    <div class="centered">
        <AlertCircle size={64} color="var(--color-danger)" />
        <h1>Table Not Found</h1>
        <p>This table doesn't exist or is not active. Please ask a staff member for assistance.</p>
        <button class="btn btn-primary" onclick={() => goto('/')}>Go Home</button>
    </div>
{:else}
    <div class="centered">
        <div class="table-icon">
            <UtensilsCrossed size={48} color="white" />
        </div>
        <h1>Welcome!</h1>
        <p class="seated-text">You're seated at</p>
        <div class="table-badge">Table #{table?.table_number}</div>
        <p class="redirect-text">Redirecting to menu...</p>
        <button class="btn btn-primary btn-lg" onclick={() => goto('/menu')} style="margin-top: var(--space-4);">
            <UtensilsCrossed size={18} />
            Browse Menu Now
        </button>
    </div>
{/if}

<style>
    .centered {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-direction: column;
        gap: var(--space-6);
        padding: var(--space-6);
        padding-top: var(--header-height);
        text-align: center;
    }

    .centered h1 {
        font-family: var(--font-display);
        font-size: var(--text-3xl);
        font-weight: var(--weight-bold);
    }

    .centered p { color: var(--color-text-secondary); max-width: 400px; }

    .table-icon {
        width: 96px;
        height: 96px;
        border-radius: var(--radius-2xl);
        background: linear-gradient(135deg, var(--color-accent), #e85d2c);
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: var(--shadow-glow-accent);
        animation: bounceIn 0.5s ease-out;
    }

    .seated-text {
        font-size: var(--text-xl);
    }

    .table-badge {
        padding: var(--space-4) var(--space-8);
        background: rgba(255, 107, 53, 0.1);
        border: 2px solid rgba(255, 107, 53, 0.3);
        border-radius: var(--radius-2xl);
        font-size: var(--text-4xl);
        font-weight: var(--weight-extrabold);
        color: var(--color-accent);
    }

    .redirect-text {
        color: var(--color-text-muted);
        font-size: var(--text-sm);
        animation: pulse 2s infinite;
    }
</style>
