<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import { settings } from '$lib/stores/settings';
    import { Truck, Store, Clock, ChefHat, CreditCard, Banknote, ArrowRight, ArrowLeft } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import type { OrderWithItems, OrderStatus } from '$lib/types';
    import { ORDER_STATUS_LABELS, ORDER_TYPE_LABELS, ORDER_STATUS_FLOW } from '$lib/constants';
    import { timeAgo, cn } from '$lib/utils';
    import { toast } from 'svelte-sonner';

    let orders = $state<OrderWithItems[]>([]);
    let soundEnabled = $state(true);
    const supabase = createClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let interval: ReturnType<typeof setInterval> | null = null;

    onMount(() => {
        fetchOrders();
        interval = setInterval(fetchOrders, 10000);

        channel = supabase
            .channel('kitchen-orders')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, (payload: { eventType: string }) => {
                fetchOrders();
                if (payload.eventType === 'INSERT' && soundEnabled) {
                    playNotificationSound();
                    toast('🔔 New order received!');
                }
            })
            .subscribe();
    });

    onDestroy(() => {
        if (channel) supabase.removeChannel(channel);
        if (interval) clearInterval(interval);
    });

    async function fetchOrders() {
        const { data } = await supabase
            .from('orders')
            .select('*, order_items(*)')
            .in('status', ['new', 'confirmed', 'preparing', 'ready'])
            .order('created_at', { ascending: true });
        orders = (data || []) as OrderWithItems[];
    }

    function playNotificationSound() {
        try {
            const ctx = new AudioContext();
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.frequency.value = 800;
            gain.gain.value = 0.3;
            osc.start();
            setTimeout(() => { osc.frequency.value = 1000; setTimeout(() => { osc.stop(); ctx.close(); }, 200); }, 200);
        } catch { /* audio not supported */ }
    }

    async function updateStatus(orderId: string, newStatus: OrderStatus) {
        const previous = [...orders];
        orders = orders.map(o => o.id === orderId ? { ...o, status: newStatus } : o);
        try {
            const res = await fetch(`/api/orders/${orderId}/status`, {
                method: 'PATCH', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: newStatus }),
            });
            if (!res.ok) throw new Error((await res.json()).error || 'Failed');
            toast.success(`Order moved to ${ORDER_STATUS_LABELS[newStatus]}`);
            fetchOrders();
        } catch (err) {
            orders = previous;
            toast.error(err instanceof Error ? err.message : 'Failed to update status');
        }
    }

    const columns: { status: OrderStatus; label: string; color: string; bgColor: string }[] = [
        { status: 'new', label: 'New Orders', color: 'var(--color-warning)', bgColor: 'rgba(255,177,0,0.15)' },
        { status: 'confirmed', label: 'Confirmed', color: 'var(--color-info)', bgColor: 'rgba(59,130,246,0.15)' },
        { status: 'preparing', label: 'Preparing', color: 'var(--color-accent)', bgColor: 'rgba(255,107,53,0.15)' },
        { status: 'ready', label: 'Ready', color: 'var(--color-success)', bgColor: 'rgba(42,157,143,0.15)' },
    ];

    function getColumnOrders(status: OrderStatus): OrderWithItems[] { return orders.filter(o => o.status === status); }

    function getNextKitchenStatus(order: OrderWithItems): OrderStatus | null {
        const flow = ORDER_STATUS_FLOW[order.order_type] || [];
        const idx = flow.indexOf(order.status as OrderStatus);
        return idx >= 0 && idx < flow.length - 1 ? flow[idx + 1] : null;
    }

    function getPrevKitchenStatus(order: OrderWithItems): OrderStatus | null {
        const flow = ORDER_STATUS_FLOW[order.order_type] || [];
        const idx = flow.indexOf(order.status as OrderStatus);
        return idx > 0 ? flow[idx - 1] : null;
    }
</script>

<svelte:head><title>Kitchen Display — {$settings?.restaurant_name || 'Pizza Mania'}</title></svelte:head>

<div>
    <div class="admin-topbar">
        <h1>
            <ChefHat size={28} style="display:inline-block;vertical-align:middle;margin-right:8px" />
            Kitchen Display
        </h1>
        <button class="btn btn-outline btn-sm" onclick={() => (soundEnabled = !soundEnabled)}>
            {#if soundEnabled}
                <Volume2 size={16} /> Sound On
            {:else}
                <VolumeX size={16} /> Sound Off
            {/if}
        </button>
    </div>

    <div class="kitchen-board">
        {#each columns as col}
            {@const colOrders = getColumnOrders(col.status)}
            <div class="kitchen-column">
                <div class="kitchen-column-header" style="background:{col.bgColor};color:{col.color}">
                    {col.label}
                    <span class="kitchen-column-count">{colOrders.length}</span>
                </div>

                {#each colOrders as order}
                    {@const nextStatus = getNextKitchenStatus(order)}
                    <div class="kitchen-ticket">
                        <div class="kitchen-ticket-header">
                            <div style="display:flex;align-items:center;gap:var(--space-2)">
                                {#if order.order_type === 'delivery'}
                                    <Truck size={16} color="var(--color-info)" />
                                {:else if order.order_type === 'pickup'}
                                    <Store size={16} color="var(--color-success)" />
                                {:else}
                                    <ChefHat size={16} color="var(--color-accent)" />
                                {/if}
                                <span class="kitchen-ticket-order">{order.tracking_token}</span>
                            </div>
                            <span class="kitchen-ticket-time">
                                <Clock size={12} style="display:inline;margin-right:4px" />
                                {timeAgo(order.created_at)}
                            </span>
                        </div>

                        {#if order.scheduled_time}
                            <div style="margin-top:var(--space-2);margin-bottom:var(--space-2);background:rgba(255,177,0,0.15);color:var(--color-warning);padding:4px 8px;border-radius:var(--radius-sm);font-weight:var(--weight-bold);font-size:var(--text-xs);display:flex;align-items:center;gap:4px;">
                                <Clock size={12} strokeWidth={2.5} />
                                SCHEDULED: {new Date(order.scheduled_time).toLocaleString('en-GB', { weekday: 'short', hour: '2-digit', minute: '2-digit' })}
                            </div>
                        {/if}

                        <div class="kitchen-ticket-items">
                            {#each order.order_items || [] as item}
                                <div class="kitchen-ticket-item">
                                    <span class="kitchen-ticket-qty">{item.quantity}×</span>
                                    <div>
                                        <div>{item.item_name}</div>
                                        {#if item.notes}
                                            <div class="kitchen-ticket-note">⚠ {item.notes}</div>
                                        {/if}
                                        {#if item.selected_options && Object.keys(item.selected_options).length > 0}
                                            <div class="kitchen-options-list">
                                                {#each Object.entries(item.selected_options) as [k, v]}
                                                    <div class="kitchen-option">
                                                        <span class="opt-label">{k}:</span> 
                                                        <span class="opt-val">{Array.isArray(v) ? v.join(', ') : v}</span>
                                                    </div>
                                                {/each}
                                            </div>
                                        {/if}
                                    </div>
                                </div>
                            {/each}
                        </div>

                        {#if order.special_instructions}
                            <div style="padding:var(--space-2) var(--space-3);background:rgba(255,177,0,0.1);border-radius:var(--radius-md);font-size:var(--text-xs);color:var(--color-warning);margin-bottom:var(--space-3)">
                                📝 {order.special_instructions}
                            </div>
                        {/if}

                        <div class="kitchen-ticket-footer">
                            <div style="display:flex;align-items:center;gap:var(--space-2)">
                                <span class={cn('badge', 'badge-info', 'kitchen-ticket-type')}>
                                    {ORDER_TYPE_LABELS[order.order_type]}
                                </span>
                                {#if order.payment_status === 'paid'}
                                    <span class="badge badge-success" title="Paid Online"><CreditCard size={12} /></span>
                                {:else}
                                    <span class="badge badge-warning" title="Pay at Counter"><Banknote size={12} /></span>
                                {/if}
                            </div>
                            <svelte:fragment>
                                {@const prev = getPrevKitchenStatus(order)}
                                <div style="display:flex; gap: 4px;">
                                    {#if prev}
                                        <button class="btn btn-ghost btn-sm" style="padding:4px" onclick={() => updateStatus(order.id, prev)} title="Move Back to {ORDER_STATUS_LABELS[prev]}">
                                            <ArrowLeft size={16} />
                                        </button>
                                    {/if}
                                    {#if nextStatus}
                                        <button class="btn btn-primary btn-sm" onclick={() => updateStatus(order.id, nextStatus)}>
                                            {ORDER_STATUS_LABELS[nextStatus]} <ArrowRight size={14} />
                                        </button>
                                    {/if}
                                </div>
                            </svelte:fragment>
                        </div>
                    </div>
                {:else}
                    <div style="text-align:center;padding:var(--space-8);color:var(--color-text-muted);font-size:var(--text-sm)">
                        No orders
                    </div>
                {/each}
            </div>
        {/each}
    </div>
</div>

<style>
    .admin-topbar { display:flex; align-items:center; justify-content:space-between; margin-bottom:var(--space-8); }
    .admin-topbar h1 { font-family:var(--font-display); font-size:var(--text-3xl); font-weight:var(--weight-bold); }

    .kitchen-board { display:grid; grid-template-columns:repeat(4,1fr); gap:var(--space-6); align-items:start; }

    .kitchen-column { min-height:300px; }

    .kitchen-column-header { display:flex; align-items:center; gap:var(--space-2); padding:var(--space-3) var(--space-4); border-radius:var(--radius-lg); margin-bottom:var(--space-4); font-size:var(--text-sm); font-weight:var(--weight-semibold); }
    .kitchen-column-count { background:rgba(255,255,255,0.1); padding:2px 8px; border-radius:var(--radius-full); font-size:var(--text-xs); margin-left:auto; }

    .kitchen-ticket { background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); padding:var(--space-4); margin-bottom:var(--space-3); transition:all var(--transition-fast); }
    .kitchen-ticket:hover { border-color:var(--color-border-hover); }
    .kitchen-ticket-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:var(--space-3); }
    .kitchen-ticket-order { font-weight:var(--weight-bold); font-size:var(--text-sm); }
    .kitchen-ticket-time { font-size:var(--text-xs); color:var(--color-text-muted); }
    .kitchen-ticket-items { margin-bottom:var(--space-3); }
    .kitchen-ticket-item { display:flex; align-items:flex-start; gap:var(--space-2); padding:var(--space-1) 0; font-size:var(--text-sm); }
    .kitchen-ticket-qty { font-weight:var(--weight-bold); color:var(--color-primary); min-width:24px; }
    .kitchen-ticket-note { font-size:var(--text-xs); color:var(--color-warning); font-style:italic; margin-top:var(--space-1); }
    .kitchen-ticket-footer { display:flex; align-items:center; justify-content:space-between; padding-top:var(--space-3); border-top:1px solid var(--color-border); }
    :global(.kitchen-ticket-type) { font-size:var(--text-xs); }

    .kitchen-options-list { margin-top:var(--space-1); font-size:var(--text-xs); color:var(--color-text-secondary); }
    .kitchen-option { display:block; padding-left:var(--space-2); border-left:2px solid var(--color-border); margin-bottom:2px; }
    .opt-label { font-weight:var(--weight-medium); color:var(--color-text-muted); }
    .opt-val { font-weight:var(--weight-semibold); }
    
    @media (max-width:1024px) { .kitchen-board { grid-template-columns:1fr; } }
</style>
