<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { ShoppingBag, Clock, AlertTriangle, DollarSign, ArrowLeft } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import type { Order, OrderWithItems, OrderStatus } from '$lib/types';
    import { ORDER_STATUS_LABELS, ORDER_TYPE_LABELS, ORDER_STATUS_FLOW } from '$lib/constants';
    import { formatPrice, timeAgo, cn } from '$lib/utils';
    import { settings } from '$lib/stores/settings';

    let stats = $state({ totalOrders: 0, activeOrders: 0, revenue: 0, avgPrepTime: 30 });
    let recentOrders = $state<OrderWithItems[]>([]);
    let loading = $state(true);

    const supabase = createClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;

    onMount(() => {
        fetchDashboardData();
        channel = supabase
            .channel('dashboard-orders')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => fetchDashboardData())
            .subscribe();
    });

    onDestroy(() => { if (channel) supabase.removeChannel(channel); });

    async function fetchDashboardData() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const [ordersRes, activeRes] = await Promise.all([
            supabase.from('orders').select('*, order_items(*)').gte('created_at', today.toISOString()).order('created_at', { ascending: false }).limit(20),
            supabase.from('orders').select('id, status, total, created_at').in('status', ['new', 'confirmed', 'preparing', 'ready', 'out_for_delivery']),
        ]);

        const todayOrders = ordersRes.data || [];
        const activeOrders = activeRes.data || [];

        const totalRevenue = todayOrders
            .filter((o: Order) => o.payment_status === 'paid' || ['delivered', 'picked_up', 'served'].includes(o.status))
            .reduce((sum: number, o: Order) => sum + o.total, 0);

        stats = { totalOrders: todayOrders.length, activeOrders: activeOrders.length, revenue: totalRevenue, avgPrepTime: 30 };
        recentOrders = todayOrders as OrderWithItems[];
        loading = false;
    }

    async function updateStatus(orderId: string, newStatus: OrderStatus) {
        const previous = [...recentOrders];
        recentOrders = recentOrders.map(o => o.id === orderId ? { ...o, status: newStatus } : o);

        try {
            const res = await fetch(`/api/orders/${orderId}/status`, {
                method: 'PATCH', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: newStatus }),
            });
            if (!res.ok) { const d = await res.json(); throw new Error(d.error || 'Failed'); }
            fetchDashboardData();
            const { toast } = await import('svelte-sonner');
            toast.success(`Order moved to ${ORDER_STATUS_LABELS[newStatus]}`);
        } catch (err) {
            recentOrders = previous;
            const { toast } = await import('svelte-sonner');
            toast.error(err instanceof Error ? err.message : 'Failed to update status');
        }
    }

    function getNextStatus(order: Order): OrderStatus | null {
        const flow = ORDER_STATUS_FLOW[order.order_type] || [];
        const idx = flow.indexOf(order.status as OrderStatus);
        return idx >= 0 && idx < flow.length - 1 ? flow[idx + 1] : null;
    }

    function getPrevStatus(order: Order): OrderStatus | null {
        const flow = ORDER_STATUS_FLOW[order.order_type] || [];
        const idx = flow.indexOf(order.status as OrderStatus);
        return idx > 0 ? flow[idx - 1] : null;
    }
</script>

<svelte:head><title>Dashboard — {$settings?.restaurant_name || 'Pizza Mania'} Admin</title></svelte:head>

<div>
    <div class="admin-topbar">
        <h1>Dashboard</h1>
        <span style="font-size:var(--text-sm);color:var(--color-text-muted)">
            Today, {new Date().toLocaleDateString('en-GB', { weekday: 'long', month: 'long', day: 'numeric' })}
        </span>
    </div>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-header">
                <span class="stat-label">Total Orders</span>
                <div class="stat-icon" style="background:rgba(59,130,246,0.1)"><ShoppingBag size={18} color="var(--color-info)" /></div>
            </div>
            <div class="stat-value">{stats.totalOrders}</div>
        </div>
        <div class="stat-card">
            <div class="stat-header">
                <span class="stat-label">Active Orders</span>
                <div class="stat-icon" style="background:rgba(255,107,53,0.1)"><AlertTriangle size={18} color="var(--color-accent)" /></div>
            </div>
            <div class="stat-value">{stats.activeOrders}</div>
        </div>
        <div class="stat-card">
            <div class="stat-header">
                <span class="stat-label">Revenue Today</span>
                <div class="stat-icon" style="background:rgba(42,157,143,0.1)"><DollarSign size={18} color="var(--color-success)" /></div>
            </div>
            <div class="stat-value">{formatPrice(stats.revenue)}</div>
        </div>
        <div class="stat-card">
            <div class="stat-header">
                <span class="stat-label">Avg Prep Time</span>
                <div class="stat-icon" style="background:rgba(168,85,247,0.1)"><Clock size={18} color="#a855f7" /></div>
            </div>
            <div class="stat-value">{stats.avgPrepTime}m</div>
        </div>
    </div>

    <div class="orders-table">
        <div class="orders-table-header">
            <h2>Recent Orders</h2>
            <a href="/admin/orders" class="btn btn-outline btn-sm">View All</a>
        </div>
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr>
                        <th>Order</th><th>Type</th><th>Customer</th><th>Items</th><th>Total</th><th>Status</th><th>Scheduled</th><th>Time</th><th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {#each recentOrders as order}
                        {@const nextStatus = getNextStatus(order)}
                        <tr>
                            <td style="font-weight:var(--weight-semibold)">{order.tracking_token}</td>
                            <td><span class="badge badge-info">{ORDER_TYPE_LABELS[order.order_type]}</span></td>
                            <td>{order.customer_name || '—'}</td>
                            <td>
                                <div style="font-size:var(--text-xs);color:var(--color-text-secondary)">
                                    {#each (order.order_items || []).slice(0, 3) as item}
                                        <div>{item.quantity}× {item.item_name}</div>
                                    {/each}
                                    {#if (order.order_items || []).length > 3}
                                        <div style="color:var(--color-text-muted)">+{(order.order_items?.length || 0) - 3} more...</div>
                                    {/if}
                                </div>
                            </td>
                            <td style="font-weight:var(--weight-semibold)">{formatPrice(order.total)}</td>
                            <td>
                                <span class={cn('badge', order.status === 'new' ? 'badge-warning' : ['delivered','picked_up','served'].includes(order.status) ? 'badge-success' : order.status === 'cancelled' ? 'badge-danger' : 'badge-info')}>
                                    {ORDER_STATUS_LABELS[order.status]}
                                </span>
                            </td>
                            <td>
                                {#if order.scheduled_time}
                                    <span class="badge badge-warning" style="font-size: 11px;">
                                        {new Date(order.scheduled_time).toLocaleString('en-GB', { weekday: 'short', hour: '2-digit', minute: '2-digit' })}
                                    </span>
                                {:else}
                                    <span style="color:var(--color-text-muted);font-size:var(--text-xs)">ASAP</span>
                                {/if}
                            </td>
                            <td style="color:var(--color-text-muted);font-size:var(--text-xs)">{timeAgo(order.created_at)}</td>
                            <td>
                                    {@const next = getNextStatus(order)}
                                    {@const prev = getPrevStatus(order)}
                                    
                                    <div class="order-actions">
                                        {#if prev}
                                            <button class="btn btn-ghost btn-sm" style="padding:4px" onclick={() => updateStatus(order.id, prev)} title="Move Back to {ORDER_STATUS_LABELS[prev]}">
                                                <ArrowLeft size={16} />
                                            </button>
                                        {/if}

                                        {#if next}
                                            <button class="btn btn-primary btn-sm" onclick={() => updateStatus(order.id, next)}>
                                                {ORDER_STATUS_LABELS[next]}
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
                            <td colspan="8" style="text-align:center;padding:var(--space-10);color:var(--color-text-muted)">
                                {loading ? 'Loading...' : 'No orders today yet'}
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

    .stats-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:var(--space-4); margin-bottom:var(--space-8); }
    .stat-card { background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); padding:var(--space-5); transition:all var(--transition-fast); }
    .stat-card:hover { border-color:var(--color-border-hover); }
    .stat-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:var(--space-3); }
    .stat-label { font-size:var(--text-xs); font-weight:var(--weight-medium); color:var(--color-text-muted); text-transform:uppercase; letter-spacing:0.05em; }
    .stat-icon { width:36px; height:36px; border-radius:var(--radius-md); display:flex; align-items:center; justify-content:center; }
    .stat-value { font-size:var(--text-2xl); font-weight:var(--weight-bold); }

    .orders-table { width:100%; background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); overflow:hidden; }
    .orders-table-header { display:flex; align-items:center; justify-content:space-between; padding:var(--space-5); border-bottom:1px solid var(--color-border); }
    .orders-table-header h2 { font-size:var(--text-lg); font-weight:var(--weight-semibold); }
    .table-wrapper { overflow-x:auto; -webkit-overflow-scrolling: touch; }
    .table-wrapper table { width:100%; border-collapse:collapse; min-width: 800px; }
    .table-wrapper th { padding:var(--space-3) var(--space-4); font-size:var(--text-xs); font-weight:var(--weight-semibold); color:var(--color-text-muted); text-transform:uppercase; letter-spacing:0.05em; text-align:left; border-bottom:1px solid var(--color-border); }
    .table-wrapper td { padding:var(--space-3) var(--space-4); font-size:var(--text-sm); border-bottom:1px solid var(--color-border); }
    .table-wrapper tr:last-child td { border-bottom:none; }
    .table-wrapper tr:hover td { background:var(--color-bg-glass); }
    .order-actions { display:flex; gap:var(--space-2); }

    @media (max-width: 1024px) {
        .stats-grid { grid-template-columns: repeat(2, 1fr); }
    }

    @media (max-width: 768px) {
        .admin-topbar { flex-direction: column; align-items: flex-start; gap: var(--space-2); margin-bottom: var(--space-6); }
        .admin-topbar h1 { font-size: var(--text-2xl); }
        
        .stats-grid { grid-template-columns: 1fr; gap: var(--space-3); }
        .stat-card { padding: var(--space-4); }
        .stat-value { font-size: var(--text-2xl); }

        .orders-table-header { padding: var(--space-4); }
        .orders-table-header h2 { font-size: var(--text-base); }
    }

    @media (max-width: 480px) {
        .admin-main { padding: var(--space-4); }
        .table-wrapper th, .table-wrapper td { padding: var(--space-3); font-size: 13px; }
        .order-actions .btn { padding: 6px 10px; font-size: 11px; }
    }
</style>
