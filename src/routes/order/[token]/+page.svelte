<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { page } from '$app/stores';
    import { Package, Clock, CheckCircle, ChefHat, Truck, Search, XCircle, UtensilsCrossed, Loader2 } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import type { OrderWithItems, OrderStatus } from '$lib/types';
    import { ORDER_STATUS_LABELS } from '$lib/constants';
    import { formatPrice, formatDateTime, timeAgo } from '$lib/utils';

    let token = $derived($page.params.token);
    let order: OrderWithItems | null = $state(null);
    let loading = $state(true);
    let error = $state(false);
    let subscription: any = null;

    const statusFlow: OrderStatus[] = ['new', 'confirmed', 'preparing', 'ready'];
    const statusIcons: Record<string, any> = {
        new: Package,
        confirmed: CheckCircle,
        preparing: ChefHat,
        ready: UtensilsCrossed,
        out_for_delivery: Truck,
        delivered: CheckCircle,
        picked_up: CheckCircle,
        served: CheckCircle,
        cancelled: XCircle,
    };

    const statusColors: Record<string, string> = {
        new: 'var(--color-info)',
        confirmed: 'var(--color-amber)',
        preparing: 'var(--color-accent)',
        ready: 'var(--color-success)',
        out_for_delivery: 'var(--color-gold)',
        delivered: 'var(--color-success)',
        picked_up: 'var(--color-success)',
        served: 'var(--color-success)',
        cancelled: 'var(--color-danger)',
    };

    onMount(async () => {
        const supabase = createClient();
        const { data, error: fetchError } = await supabase
            .from('orders')
            .select('*, order_items(*)')
            .eq('tracking_token', token)
            .single();

        if (fetchError || !data) {
            error = true;
        } else {
            order = data as OrderWithItems;
        }
        loading = false;

        // Subscribe to realtime updates
        if (order) {
            subscription = supabase
                .channel(`order-${order.id}`)
                .on('postgres_changes', {
                    event: 'UPDATE',
                    schema: 'public',
                    table: 'orders',
                    filter: `id=eq.${order.id}`,
                }, (payload: any) => {
                    if (order) {
                        order = { ...order, ...payload.new };
                    }
                })
                .subscribe();
        }
    });

    onDestroy(() => {
        subscription?.unsubscribe();
    });

    function getStatusIndex(status: string): number {
        return statusFlow.indexOf(status as OrderStatus);
    }
</script>

<svelte:head>
    <title>Track Order — Pizza Mania</title>
</svelte:head>

<div class="tracking-page">
    {#if loading}
        <div class="centered">
            <Loader2 size={48} class="animate-spin" color="var(--color-primary)" />
            <p>Loading order details...</p>
        </div>
    {:else if error || !order}
        <div class="centered">
            <Search size={64} color="var(--color-text-muted)" />
            <h2>Order Not Found</h2>
            <p>We couldn't find an order with this tracking token.</p>
            <a href="/" class="btn btn-primary">Go Home</a>
        </div>
    {:else}
        <div class="tracking-header">
            <h1>Order {order.tracking_token}</h1>
            <p>Placed {formatDateTime(order.created_at)} · {timeAgo(order.created_at)}</p>
        </div>

        <!-- Status Progress -->
        <div class="status-card glass">
            <div class="status-current">
                <div class="status-icon" style="background: {statusColors[order.status]}20; color: {statusColors[order.status]};">
                    {#if statusIcons[order.status]}
                        <svelte:component this={statusIcons[order.status]} size={32} />
                    {/if}
                </div>
                <div>
                    <div class="status-label">{ORDER_STATUS_LABELS[order.status] || order.status}</div>
                    <div class="status-sub">
                        {#if order.status === 'cancelled'}
                            This order has been cancelled
                        {:else if order.estimated_minutes}
                            Estimated: ~{order.estimated_minutes} minutes
                        {:else}
                            We're working on your order
                        {/if}
                    </div>
                </div>
            </div>

            {#if order.status !== 'cancelled'}
                <div class="status-steps">
                    {#each statusFlow as step, i}
                        {@const currentIndex = getStatusIndex(order.status)}
                        {@const isComplete = i <= currentIndex}
                        {@const isCurrent = i === currentIndex}
                        <div class="status-step" class:complete={isComplete} class:current={isCurrent}>
                            <div class="step-dot" style={isComplete ? `background: ${statusColors[step]}` : ''}></div>
                            {#if i < statusFlow.length - 1}
                                <div class="step-line" class:complete={i < currentIndex}></div>
                            {/if}
                            <div class="step-label">{ORDER_STATUS_LABELS[step]}</div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>

        <!-- Order Details -->
        <div class="details-grid">
            <div class="detail-card glass">
                <h3>Order Details</h3>
                <div class="detail-row">
                    <span>Order Type</span>
                    <span class="badge badge-{order.order_type}">{order.order_type.replace('_', ' ')}</span>
                </div>
                <div class="detail-row">
                    <span>Payment</span>
                    <span>{order.payment_method === 'online' ? 'Online' : 'At Counter'} — {order.payment_status}</span>
                </div>
                {#if order.delivery_address}
                    <div class="detail-row">
                        <span>Delivery to</span>
                        <span>{order.delivery_address}</span>
                    </div>
                {/if}
            </div>

            <div class="detail-card glass">
                <h3>Items</h3>
                {#each order.order_items as item}
                    <div class="detail-row">
                        <span>{item.quantity}× {item.item_name}</span>
                        <span>{formatPrice(item.item_price * item.quantity)}</span>
                    </div>
                {/each}
                <div class="detail-total">
                    <span>Total</span>
                    <span>{formatPrice(order.total)}</span>
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .tracking-page {
        padding: calc(var(--header-height) + var(--space-8)) 0 var(--space-16);
        min-height: 100vh;
        max-width: var(--container-lg);
        margin: 0 auto;
        padding-left: var(--space-6);
        padding-right: var(--space-6);
    }

    .centered {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-4);
        padding: var(--space-20) 0;
        text-align: center;
    }

    .centered h2 { font-size: var(--text-2xl); font-weight: var(--weight-bold); }
    .centered p { color: var(--color-text-secondary); }

    .tracking-header { margin-bottom: var(--space-8); }
    .tracking-header h1 {
        font-family: var(--font-display);
        font-size: var(--text-3xl);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-2);
    }
    .tracking-header p { color: var(--color-text-secondary); }

    .status-card {
        padding: var(--space-8);
        margin-bottom: var(--space-8);
    }

    .status-current {
        display: flex;
        align-items: center;
        gap: var(--space-5);
        margin-bottom: var(--space-8);
    }

    .status-icon {
        width: 64px;
        height: 64px;
        border-radius: var(--radius-xl);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .status-label {
        font-size: var(--text-2xl);
        font-weight: var(--weight-bold);
    }

    .status-sub {
        color: var(--color-text-secondary);
        font-size: var(--text-sm);
    }

    .status-steps {
        display: flex;
        gap: 0;
        align-items: flex-start;
    }

    .status-step {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        position: relative;
    }

    .step-dot {
        width: 16px;
        height: 16px;
        border-radius: var(--radius-full);
        background: var(--color-bg-tertiary);
        border: 2px solid var(--color-border);
        z-index: 1;
    }

    .status-step.complete .step-dot { border-color: transparent; }
    .status-step.current .step-dot { box-shadow: 0 0 0 4px rgba(230, 57, 70, 0.3); }

    .step-line {
        position: absolute;
        top: 8px;
        left: 50%;
        width: 100%;
        height: 2px;
        background: var(--color-border);
    }

    .step-line.complete { background: var(--color-success); }

    .step-label {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        margin-top: var(--space-2);
        text-align: center;
    }

    .details-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: var(--space-6);
    }

    .detail-card { padding: var(--space-6); }

    .detail-card h3 {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-5);
    }

    .detail-row {
        display: flex;
        justify-content: space-between;
        padding: var(--space-2) 0;
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        border-bottom: 1px solid var(--color-border);
    }

    .detail-total {
        display: flex;
        justify-content: space-between;
        padding: var(--space-3) 0;
        margin-top: var(--space-2);
        font-weight: var(--weight-bold);
        font-size: var(--text-lg);
    }

    @media (max-width: 768px) {
        .details-grid { grid-template-columns: 1fr; }
        .status-steps { gap: var(--space-1); }
    }
</style>
