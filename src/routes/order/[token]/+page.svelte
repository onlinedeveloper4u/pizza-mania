<script lang="ts">
    import { onMount, onDestroy } from "svelte";
    import { page } from "$app/stores";
    import {
        Package,
        Clock,
        CheckCircle,
        ChefHat,
        Truck,
        Search,
        XCircle,
        UtensilsCrossed,
        Loader2,
    } from "lucide-svelte";
    import { createClient } from "$lib/supabase/client";
    import { settings } from "$lib/stores/settings";
    import { cart } from "$lib/stores/cart";
    import type { OrderWithItems, OrderStatus } from "$lib/types";
    import { ORDER_STATUS_LABELS } from "$lib/constants";
    import { formatPrice, formatDateTime, timeAgo } from "$lib/utils";
    import { t } from "$lib/stores/language";

    let token = $derived($page.params.token);
    let order: OrderWithItems | null = $state(null);
    let loading = $state(true);
    let error = $state(false);
    let subscription: any = null;

    // Cancellation state
    let showCancelModal = $state(false);
    let cancelling = $state(false);
    let cancelError = $state("");

    const cancellableStatuses: OrderStatus[] = ["new", "confirmed"];
    let canCancel = $derived(
        order !== null &&
            cancellableStatuses.includes(order.status as OrderStatus),
    );

    const statusFlow: OrderStatus[] = [
        "new",
        "confirmed",
        "preparing",
        "ready",
    ];
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
        new: "var(--color-info)",
        confirmed: "var(--color-amber)",
        preparing: "var(--color-accent)",
        ready: "var(--color-success)",
        out_for_delivery: "var(--color-gold)",
        delivered: "var(--color-success)",
        picked_up: "var(--color-success)",
        served: "var(--color-success)",
        cancelled: "var(--color-danger)",
    };

    onMount(async () => {
        // Clear cart if returning from successful payment
        const paymentStatus = $page.url.searchParams.get("payment");
        if (paymentStatus === "success") {
            cart.clearCart();
        }

        const supabase = createClient();
        const { data, error: fetchError } = await supabase
            .from("orders")
            .select("*, order_items(*)")
            .eq("tracking_token", token)
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
                .on(
                    "postgres_changes",
                    {
                        event: "UPDATE",
                        schema: "public",
                        table: "orders",
                        filter: `id=eq.${order.id}`,
                    },
                    (payload: any) => {
                        if (order) {
                            order = { ...order, ...payload.new };
                        }
                    },
                )
                .subscribe();
        }
    });

    onDestroy(() => {
        subscription?.unsubscribe();
    });

    function getStatusIndex(status: string): number {
        return statusFlow.indexOf(status as OrderStatus);
    }

    async function cancelOrder() {
        if (!order) return;
        cancelling = true;
        cancelError = "";
        try {
            const res = await fetch("/api/orders/cancel", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ tracking_token: order.tracking_token }),
            });
            const data = await res.json();
            if (!res.ok) {
                cancelError = data.error || $t("order.token.cancel.error");
                return;
            }
            showCancelModal = false;
            const { toast } = await import("svelte-sonner");
            toast.success($t("order.token.cancel.success"));
            if (data.refunded) {
                toast.info($t("order.token.cancel.refunded"));
            }
            // Optimistically update UI (realtime will also sync)
            order = { ...order, status: "cancelled" };
        } catch {
            cancelError = $t("order.token.cancel.error");
        } finally {
            cancelling = false;
        }
    }
</script>

<svelte:head>
    <title>Track Order — {$settings?.restaurant_name || "Pizza Mania"}</title>
</svelte:head>

<div class="tracking-page">
    {#if loading}
        <div class="centered">
            <Loader2
                size={48}
                class="animate-spin"
                color="var(--color-primary)"
            />
            <p>{$t("order.token.loading")}</p>
        </div>
    {:else if error || !order}
        <div class="centered">
            <Search size={64} color="var(--color-text-muted)" />
            <h2>{$t("order.token.not_found")}</h2>
            <p>{$t("order.token.not_found.desc")}</p>
            <a href="/" class="btn btn-primary">{$t("order.token.go_home")}</a>
        </div>
    {:else}
        <div class="tracking-header">
            <h1>Order {order.tracking_token}</h1>
            <p>
                {$t("order.token.placed")}
                {formatDateTime(order.created_at)} · {timeAgo(order.created_at)}
            </p>
        </div>

        <!-- Status Progress -->
        <div class="status-card glass">
            <div class="status-current">
                <div
                    class="status-icon"
                    style="background: {statusColors[
                        order.status
                    ]}20; color: {statusColors[order.status]};"
                >
                    {#if statusIcons[order.status]}
                        <svelte:component
                            this={statusIcons[order.status]}
                            size={32}
                        />
                    {/if}
                </div>
                <div>
                    <div class="status-label">
                        {ORDER_STATUS_LABELS[order.status] || order.status}
                    </div>
                    <div class="status-sub">
                        {#if order.status === "cancelled"}
                            {$t("order.token.cancelled")}
                        {:else if order.scheduled_time}
                            <span
                                style="color:var(--color-warning);font-weight:var(--weight-bold);"
                            >
                                {$t("order.token.scheduled")}
                                {new Date(order.scheduled_time).toLocaleString(
                                    "fr-FR",
                                    {
                                        weekday: "short",
                                        hour: "2-digit",
                                        minute: "2-digit",
                                    },
                                )}
                            </span>
                        {:else if order.estimated_minutes}
                            {$t("order.token.estimated").replace(
                                "{n}",
                                String(order.estimated_minutes),
                            )}
                        {:else}
                            {$t("order.token.in_progress")}
                        {/if}
                    </div>
                </div>
            </div>

            {#if order.status !== "cancelled"}
                <div class="status-steps">
                    {#each statusFlow as step, i}
                        {@const currentIndex = getStatusIndex(order.status)}
                        {@const isComplete = i <= currentIndex}
                        {@const isCurrent = i === currentIndex}
                        <div
                            class="status-step"
                            class:complete={isComplete}
                            class:current={isCurrent}
                        >
                            <div
                                class="step-dot"
                                style={isComplete
                                    ? `background: ${statusColors[step]}`
                                    : ""}
                            ></div>
                            {#if i < statusFlow.length - 1}
                                <div
                                    class="step-line"
                                    class:complete={i < currentIndex}
                                ></div>
                            {/if}
                            <div class="step-label">
                                {ORDER_STATUS_LABELS[step]}
                            </div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>

        <!-- Order Details -->
        <div class="details-grid">
            <div class="detail-card glass">
                <h3>{$t("order.token.details")}</h3>
                <div class="detail-row">
                    <span>{$t("order.token.order_type")}</span>
                    <span class="badge badge-{order.order_type}"
                        >{order.order_type.replace("_", " ")}</span
                    >
                </div>
                <div class="detail-row">
                    <span>{$t("order.token.payment")}</span>
                    <span
                        >{order.payment_method === "online"
                            ? $t("order.token.payment.online")
                            : $t("order.token.payment.counter")} — {order.payment_status}</span
                    >
                </div>
                {#if order.delivery_address}
                    <div class="detail-row">
                        <span>{$t("order.token.delivery_to")}</span>
                        <span>{order.delivery_address}</span>
                    </div>
                {/if}
            </div>

            <div class="detail-card glass">
                <h3>{$t("order.token.items")}</h3>
                {#each order.order_items as item}
                    <div class="detail-row">
                        <span>{item.quantity}× {item.item_name}</span>
                        <span
                            >{formatPrice(
                                item.item_price * item.quantity,
                            )}</span
                        >
                    </div>
                {/each}
                <div class="detail-total">
                    <span>{$t("order.token.total")}</span>
                    <span>{formatPrice(order.total)}</span>
                </div>
            </div>
        </div>
        <!-- Cancel Order Button -->
        {#if order.status !== "cancelled" && cancellableStatuses.includes(order.status as OrderStatus)}
            <div class="cancel-section">
                <button
                    class="btn btn-danger-outline"
                    onclick={() => {
                        showCancelModal = true;
                        cancelError = "";
                    }}
                >
                    {$t("order.token.cancel")}
                </button>
            </div>
        {/if}
    {/if}
</div>

<!-- Cancel Confirmation Modal -->
{#if showCancelModal}
    <div class="modal-overlay" role="dialog" aria-modal="true">
        <div class="modal-card glass">
            <h3>{$t("order.token.cancel.confirm.title")}</h3>
            <p>{$t("order.token.cancel.confirm.desc")}</p>
            {#if order?.payment_method === "online" && order?.payment_status === "paid"}
                <p class="refund-notice">
                    {$t("order.token.cancel.confirm.refund")}
                </p>
            {/if}
            {#if cancelError}
                <p class="cancel-error">{cancelError}</p>
            {/if}
            <div class="modal-actions">
                <button
                    class="btn btn-outline"
                    onclick={() => (showCancelModal = false)}
                    disabled={cancelling}
                >
                    {$t("order.token.cancel.confirm.no")}
                </button>
                <button
                    class="btn btn-danger"
                    onclick={cancelOrder}
                    disabled={cancelling}
                >
                    {cancelling
                        ? $t("order.token.cancel.cancelling")
                        : $t("order.token.cancel.confirm.yes")}
                </button>
            </div>
        </div>
    </div>
{/if}

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

    .centered h2 {
        font-size: var(--text-2xl);
        font-weight: var(--weight-bold);
    }
    .centered p {
        color: var(--color-text-secondary);
    }

    .tracking-header {
        margin-bottom: var(--space-8);
    }
    .tracking-header h1 {
        font-family: var(--font-display);
        font-size: var(--text-3xl);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-2);
    }
    .tracking-header p {
        color: var(--color-text-secondary);
    }

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

    .status-step.complete .step-dot {
        border-color: transparent;
    }
    .status-step.current .step-dot {
        box-shadow: 0 0 0 4px rgba(230, 57, 70, 0.3);
    }

    .step-line {
        position: absolute;
        top: 8px;
        left: 50%;
        width: 100%;
        height: 2px;
        background: var(--color-border);
    }

    .step-line.complete {
        background: var(--color-success);
    }

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

    .detail-card {
        padding: var(--space-6);
    }

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
        .details-grid {
            grid-template-columns: 1fr;
        }
        .status-steps {
            gap: var(--space-1);
        }
    }

    /* ── Cancel Order ───────────────────────────────────── */
    .cancel-section {
        margin-top: var(--space-8);
        display: flex;
        justify-content: center;
    }

    .btn-danger-outline {
        padding: var(--space-3) var(--space-6);
        border: 1.5px solid var(--color-danger);
        color: var(--color-danger);
        background: transparent;
        border-radius: var(--radius-full);
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        cursor: pointer;
        transition:
            background var(--transition-fast),
            color var(--transition-fast);
    }
    .btn-danger-outline:hover {
        background: rgba(230, 57, 70, 0.08);
    }

    .btn-danger {
        padding: var(--space-3) var(--space-6);
        background: var(--color-danger);
        color: #fff;
        border: none;
        border-radius: var(--radius-full);
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        cursor: pointer;
        transition: opacity var(--transition-fast);
    }
    .btn-danger:disabled,
    .btn-danger-outline:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }
    .btn-danger:hover:not(:disabled) {
        opacity: 0.88;
    }

    /* ── Modal ──────────────────────────────────────────── */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.6);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 9999;
        padding: var(--space-6);
        backdrop-filter: blur(4px);
    }

    .modal-card {
        max-width: 420px;
        width: 100%;
        padding: var(--space-8);
        border-radius: var(--radius-2xl);
        border: 1px solid var(--color-border);
    }

    .modal-card h3 {
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-3);
    }

    .modal-card p {
        color: var(--color-text-secondary);
        font-size: var(--text-sm);
        margin-bottom: var(--space-3);
    }

    .refund-notice {
        background: rgba(59, 130, 246, 0.1);
        color: var(--color-info);
        border-radius: var(--radius-md);
        padding: var(--space-3) var(--space-4);
        font-size: var(--text-sm) !important;
        font-weight: var(--weight-medium);
    }

    .cancel-error {
        color: var(--color-danger) !important;
        font-size: var(--text-sm) !important;
    }

    .modal-actions {
        display: flex;
        gap: var(--space-3);
        justify-content: flex-end;
        margin-top: var(--space-6);
    }
</style>
