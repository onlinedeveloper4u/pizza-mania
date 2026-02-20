<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { settings } from '$lib/stores/settings';
    import { createClient } from '$lib/supabase/client';
    import type { OrderWithItems, OrderStatus } from '$lib/types';
    import { ORDER_STATUS_LABELS, ORDER_TYPE_LABELS, ORDER_STATUS_FLOW } from '$lib/constants';
    import { formatPrice, timeAgo, cn } from '$lib/utils';

    let orders = $state<OrderWithItems[]>([]);
    let filter = $state('active');
    let loading = $state(true);

    const supabase = createClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;

    onMount(() => {
        fetchOrders();
        channel = supabase
            .channel('admin-orders')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => fetchOrders())
            .subscribe();
    });

    onDestroy(() => { if (channel) supabase.removeChannel(channel); });

    async function fetchOrders() {
        loading = true;
        let query = supabase.from('orders').select('*, order_items(*)').order('created_at', { ascending: false }).limit(50);
        if (filter === 'active') query = query.in('status', ['new', 'confirmed', 'preparing', 'ready', 'out_for_delivery']);
        else if (filter !== 'all') query = query.eq('status', filter);
        const { data } = await query;
        orders = (data || []) as OrderWithItems[];
        loading = false;
    }

    // Re-fetch when filter changes
    $effect(() => { filter; fetchOrders(); });

    async function updateStatus(orderId: string, newStatus: OrderStatus) {
        const previous = [...orders];
        orders = orders.map(o => o.id === orderId ? { ...o, status: newStatus } : o);
        try {
            const res = await fetch(`/api/orders/${orderId}/status`, {
                method: 'PATCH', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: newStatus }),
            });
            if (!res.ok) throw new Error((await res.json()).error || 'Failed');
        } catch (err) {
            orders = previous;
            const { toast } = await import('svelte-sonner');
            toast.error(err instanceof Error ? err.message : 'Failed to update status');
        }
    }

    function getNextStatus(order: OrderWithItems): OrderStatus | null {
        const flow = ORDER_STATUS_FLOW[order.order_type] || [];
        const idx = flow.indexOf(order.status as OrderStatus);
        return idx >= 0 && idx < flow.length - 1 ? flow[idx + 1] : null;
    }

    const filters = [
        { key: 'active', label: 'Active' },
        { key: 'new', label: 'New' },
        { key: 'confirmed', label: 'Confirmed' },
        { key: 'preparing', label: 'Preparing' },
        { key: 'ready', label: 'Ready' },
        { key: 'all', label: 'All Orders' },
    ];
</script>

<svelte:head><title>Orders — {$settings?.restaurant_name || 'Pizza Mania'} Admin</title></svelte:head>

<div>
    <div class="admin-topbar"><h1>Orders</h1></div>

    <div class="filters">
        {#each filters as f}
            <button
                class={cn('filter-btn', filter === f.key && 'filter-btn-active')}
                onclick={() => (filter = f.key)}
            >{f.label}</button>
        {/each}
    </div>

    <div class="orders-table">
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>Token</th><th>Type</th><th>Customer</th><th>Items</th><th>Total</th><th>Payment</th><th>Status</th><th>Time</th><th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {#each orders as order}
                        {@const nextStatus = getNextStatus(order)}
                        <tr>
                            <td style="font-weight:var(--weight-semibold)">{order.tracking_token}</td>
                            <td><span class="badge badge-info">{ORDER_TYPE_LABELS[order.order_type]}</span></td>
                            <td>
                                <div>{order.customer_name || '—'}</div>
                                <div style="font-size:var(--text-xs);color:var(--color-text-muted)">{order.customer_phone}</div>
                            </td>
                            <td>
                                {#each order.order_items || [] as it}
                                    <div style="margin-bottom:4px">
                                        <div style="font-size:var(--text-xs);color:var(--color-text-secondary);font-weight:var(--weight-medium)">
                                            {it.quantity}× {it.item_name}
                                        </div>
                                        {#if it.selected_options && Object.keys(it.selected_options).length > 0}
                                            <div style="font-size:11px;color:var(--color-text-muted);padding-left:8px;border-left:2px solid var(--color-border)">
                                                {#each Object.entries(it.selected_options) as [k, v]}
                                                    <div>{k}: {Array.isArray(v) ? v.join(', ') : v}</div>
                                                {/each}
                                            </div>
                                        {/if}
                                    </div>
                                {/each}
                            </td>
                            <td style="font-weight:var(--weight-semibold)">{formatPrice(order.total)}</td>
                            <td>
                                <span class={cn('badge', order.payment_status === 'paid' ? 'badge-success' : 'badge-warning')}>
                                    {order.payment_status}
                                </span>
                            </td>
                            <td>
                                <span class={cn('badge', order.status === 'new' ? 'badge-warning' : ['delivered','picked_up','served'].includes(order.status) ? 'badge-success' : order.status === 'cancelled' ? 'badge-danger' : 'badge-info')}>
                                    {ORDER_STATUS_LABELS[order.status]}
                                </span>
                            </td>
                            <td style="font-size:var(--text-xs);color:var(--color-text-muted)">{timeAgo(order.created_at)}</td>
                            <td>
                                <div class="order-actions">
                                    {#if nextStatus}
                                        <button class="btn btn-primary btn-sm" onclick={() => updateStatus(order.id, nextStatus)}>
                                            → {ORDER_STATUS_LABELS[nextStatus]}
                                        </button>
                                    {/if}
                                    {#if order.status === 'new'}
                                        <button class="btn btn-ghost btn-sm" style="color:var(--color-danger)" onclick={() => updateStatus(order.id, 'cancelled')}>
                                            Cancel
                                        </button>
                                    {/if}
                                </div>
                            </td>
                        </tr>
                    {:else}
                        <tr>
                            <td colspan="9" style="text-align:center;padding:var(--space-10);color:var(--color-text-muted)">
                                {loading ? 'Loading...' : 'No orders found'}
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    </div>
</div>

<style>
    .admin-topbar { display:flex; align-items:center; justify-content:space-between; margin-bottom:var(--space-8); }
    .admin-topbar h1 { font-family:var(--font-display); font-size:var(--text-3xl); font-weight:var(--weight-bold); }

    .filters { display:flex; gap:var(--space-3); margin-bottom:var(--space-6); flex-wrap:wrap; }
    .filter-btn { padding:var(--space-2) var(--space-4); font-size:var(--text-xs); font-weight:var(--weight-medium); border-radius:var(--radius-full); border:1px solid var(--color-border); background:transparent; color:var(--color-text-secondary); transition:all var(--transition-fast); cursor:pointer; }
    .filter-btn:hover { border-color:var(--color-border-hover); color:var(--color-text-primary); }
    .filter-btn-active { border-color:var(--color-primary); background:rgba(230,57,70,0.08); color:var(--color-primary); }

    .orders-table { width:100%; background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); overflow:hidden; }
    .table-wrapper { overflow-x:auto; }
    .table-wrapper table { width:100%; border-collapse:collapse; }
    .table-wrapper th { padding:var(--space-3) var(--space-4); font-size:var(--text-xs); font-weight:var(--weight-semibold); color:var(--color-text-muted); text-transform:uppercase; letter-spacing:0.05em; text-align:left; border-bottom:1px solid var(--color-border); }
    .table-wrapper td { padding:var(--space-3) var(--space-4); font-size:var(--text-sm); border-bottom:1px solid var(--color-border); }
    .table-wrapper tr:last-child td { border-bottom:none; }
    .table-wrapper tr:hover td { background:var(--color-bg-glass); }
    .order-actions { display:flex; gap:var(--space-2); }
</style>
