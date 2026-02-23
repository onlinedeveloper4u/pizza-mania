<script lang="ts">
    import {
        UtensilsCrossed,
        Minus,
        Plus,
        Trash2,
        ShoppingBag,
        ArrowRight,
    } from "lucide-svelte";
    import { settings } from "$lib/stores/settings";
    import { cart } from "$lib/stores/cart";
    import { formatPrice } from "$lib/utils";
    import { DELIVERY_FEE } from "$lib/constants";

    let items: typeof $state.snapshot extends never ? never : any[] = $state(
        [],
    );
    let currentItemCount = $state(0);
    let currentSubtotal = $state(0);
    let currentIsDineIn = $state(false);
    let orderType: string | null = $state(null);

    cart.subscribe((s) => {
        items = s.items;
        orderType = s.orderType;
    });
    cart.itemCount.subscribe((v) => (currentItemCount = v));
    cart.subtotal.subscribe((v) => (currentSubtotal = v));
    cart.isDineIn.subscribe((v) => (currentIsDineIn = v));

    let deliveryFee = $derived(orderType === "delivery" ? DELIVERY_FEE : 0);
    let total = $derived(currentSubtotal + deliveryFee);
</script>

<svelte:head>
    <title>Cart — {$settings?.restaurant_name || "Pizza Mania"}</title>
</svelte:head>

<div class="cart-page">
    {#if currentItemCount === 0}
        <div class="empty-cart">
            <ShoppingBag size={64} color="var(--color-text-muted)" />
            <h2>Your cart is empty</h2>
            <p>Looks like you haven't added any items yet.</p>
            <a href="/menu" class="btn btn-primary btn-lg">Browse Menu</a>
        </div>
    {:else}
        <div class="cart-header">
            <h1>Your Cart</h1>
            <p>
                {currentItemCount} item{currentItemCount > 1 ? "s" : ""} in your
                cart
            </p>
        </div>

        <div class="cart-layout">
            <!-- Items -->
            <div>
                {#each items as item (item.id)}
                    <div class="cart-item">
                        {#if item.menuItem.image_url}
                            <img
                                src={item.menuItem.image_url}
                                alt={item.menuItem.name}
                                class="cart-item-image"
                            />
                        {:else}
                            <div class="cart-item-image-placeholder">
                                <UtensilsCrossed
                                    size={24}
                                    color="rgba(255,255,255,0.1)"
                                />
                            </div>
                        {/if}
                        <div class="cart-item-info">
                            <div class="cart-item-name">
                                {item.menuItem.name}
                            </div>
                            {#if Object.keys(item.selectedOptions).length > 0}
                                <div class="cart-item-options">
                                    {#each Object.entries(item.selectedOptions) as [key, val]}
                                        <span
                                            >{key}: {Array.isArray(val)
                                                ? val.join(", ")
                                                : val} ·
                                        </span>
                                    {/each}
                                </div>
                            {/if}
                            {#if item.notes}
                                <div class="cart-item-notes">
                                    Note: {item.notes}
                                </div>
                            {/if}
                            <div class="cart-item-actions">
                                <span class="cart-item-price"
                                    >{formatPrice(
                                        item.unitPrice * item.quantity,
                                    )}</span
                                >
                                <div class="cart-item-qty">
                                    <button
                                        class="qty-btn"
                                        onclick={() =>
                                            cart.updateQuantity(
                                                item.id,
                                                item.quantity - 1,
                                            )}
                                    >
                                        <Minus size={14} />
                                    </button>
                                    <span class="qty-value"
                                        >{item.quantity}</span
                                    >
                                    <button
                                        class="qty-btn"
                                        onclick={() =>
                                            cart.updateQuantity(
                                                item.id,
                                                item.quantity + 1,
                                            )}
                                    >
                                        <Plus size={14} />
                                    </button>
                                    <button
                                        class="remove-btn"
                                        onclick={() => cart.removeItem(item.id)}
                                        aria-label="Remove item"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Order Summary -->
            <div class="order-summary">
                <h2>Order Summary</h2>
                <div class="summary-row">
                    <span>Subtotal</span>
                    <span>{formatPrice(currentSubtotal)}</span>
                </div>
                {#if orderType === "delivery"}
                    <div class="summary-row">
                        <span>Delivery Fee</span>
                        <span>{formatPrice(deliveryFee)}</span>
                    </div>
                {/if}
                <div class="summary-total">
                    <span>Total</span>
                    <span>{formatPrice(total)}</span>
                </div>
                <a href="/checkout" class="btn btn-primary btn-lg checkout-btn">
                    Proceed to Checkout
                    <ArrowRight size={18} />
                </a>
                <a href="/menu" class="btn btn-ghost continue-shopping-btn">
                    Continue Shopping
                </a>
            </div>
        </div>
    {/if}
</div>

<style>
    .cart-page {
        padding: calc(var(--header-height) + var(--space-8)) 0 var(--space-16);
        min-height: 100vh;
        max-width: var(--container-xl);
        margin: 0 auto;
        padding-left: var(--space-6);
        padding-right: var(--space-6);
    }

    .empty-cart {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-4);
        padding: var(--space-20) 0;
        text-align: center;
    }

    .empty-cart h2 {
        font-size: var(--text-2xl);
        font-weight: var(--weight-bold);
    }

    .empty-cart p {
        color: var(--color-text-secondary);
    }

    .cart-header {
        margin-bottom: var(--space-8);
    }

    .cart-header h1 {
        font-family: var(--font-display);
        font-size: var(--text-4xl);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-2);
    }

    .cart-header p {
        color: var(--color-text-secondary);
    }

    .cart-layout {
        display: grid;
        grid-template-columns: 1fr 360px;
        gap: var(--space-8);
        align-items: start;
    }

    .cart-item {
        display: flex;
        gap: var(--space-4);
        padding: var(--space-5);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        margin-bottom: var(--space-4);
    }

    .cart-item-image {
        width: 100px;
        height: 80px;
        object-fit: contain;
        background: rgba(255, 255, 255, 0.05);
        border-radius: var(--radius-lg);
        flex-shrink: 0;
    }

    .cart-item-image-placeholder {
        width: 100px;
        height: 80px;
        background: var(--color-bg-tertiary);
        border-radius: var(--radius-lg);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .cart-item-info {
        flex: 1;
    }

    .cart-item-name {
        font-weight: var(--weight-semibold);
        margin-bottom: var(--space-1);
    }

    .cart-item-options {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        margin-bottom: var(--space-1);
    }

    .cart-item-notes {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        font-style: italic;
        margin-bottom: var(--space-2);
    }

    .cart-item-actions {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-top: var(--space-2);
    }

    .cart-item-price {
        font-weight: var(--weight-bold);
        color: var(--color-primary);
    }

    .cart-item-qty {
        display: flex;
        align-items: center;
        gap: var(--space-2);
    }

    .qty-btn {
        width: 28px;
        height: 28px;
        border-radius: var(--radius-full);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-text-primary);
        transition: all var(--transition-fast);
    }

    .qty-btn:hover {
        border-color: var(--color-primary);
        background: rgba(230, 57, 70, 0.08);
    }

    .qty-value {
        font-weight: var(--weight-semibold);
        min-width: 24px;
        text-align: center;
    }

    .remove-btn {
        width: 28px;
        height: 28px;
        border-radius: var(--radius-full);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-text-muted);
        transition: all var(--transition-fast);
        margin-left: var(--space-2);
    }

    .remove-btn:hover {
        color: var(--color-danger);
    }

    .order-summary {
        position: sticky;
        top: calc(var(--header-height) + var(--space-4));
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        padding: var(--space-6);
    }

    .order-summary h2 {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-5);
    }

    .summary-row {
        display: flex;
        justify-content: space-between;
        padding: var(--space-2) 0;
        color: var(--color-text-secondary);
        font-size: var(--text-sm);
    }

    .summary-total {
        display: flex;
        justify-content: space-between;
        padding: var(--space-4) 0;
        border-top: 1px solid var(--color-border);
        margin-top: var(--space-2);
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
    }

    .checkout-btn {
        width: 100%;
        margin-top: var(--space-5);
    }

    .continue-shopping-btn {
        width: 100%;
        margin-top: var(--space-3);
        justify-content: center;
    }

    @media (max-width: 768px) {
        .cart-header h1 {
            font-size: var(--text-2xl);
        }

        .cart-layout {
            grid-template-columns: 1fr;
        }

        .cart-item {
            padding: var(--space-4);
        }

        .cart-item-image,
        .cart-item-image-placeholder {
            width: 80px;
            height: 64px;
        }

        .qty-btn {
            width: 36px;
            height: 36px;
        }

        .remove-btn {
            width: 36px;
            height: 36px;
        }

        .order-summary {
            position: static;
            border-radius: var(--radius-xl);
            padding: var(--space-4);
            margin-top: var(--space-4);
        }

        .summary-total {
            margin-top: var(--space-2);
            padding: var(--space-4) 0;
            border-top: 1px solid var(--color-border);
            font-size: var(--text-xl);
        }
    }
</style>
