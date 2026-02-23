<script lang="ts">
    import { page } from "$app/stores";
    import { ShoppingCart, UtensilsCrossed, Ticket } from "lucide-svelte";
    import { cart } from "$lib/stores/cart";
    import { cn } from "$lib/utils";
    import { settings } from "$lib/stores/settings";

    let scrolled = $state(false);

    let currentPath = $derived($page.url.pathname);
    let currentItemCount: number = $state(0);
    let currentIsDineIn: boolean = $state(false);
    let currentTableNumber: string | null = $state(null);

    cart.itemCount.subscribe((v) => (currentItemCount = v));
    cart.isDineIn.subscribe((v) => (currentIsDineIn = v));
    cart.subscribe((s) => (currentTableNumber = s.tableNumber));

    let isHome = $derived(currentPath === "/");

    function handleScroll() {
        scrolled = window.scrollY > 20;
    }
</script>

<svelte:window onscroll={handleScroll} />

<header
    class={cn(
        "header",
        scrolled && "header-scrolled",
        isHome && !scrolled && "header-transparent",
    )}
>
    <div class="header-inner">
        <!-- Left: Logo -->
        <div class="header-left">
            <a href="/" class="logo">
                {#if $settings?.logo_url}
                    <img
                        src={$settings.logo_url}
                        alt={$settings?.restaurant_name || "Pizza Mania"}
                        class="logo-img"
                    />
                {:else}
                    <span class="logo-text"
                        >{$settings?.restaurant_name || "Pizza Mania"}</span
                    >
                {/if}
            </a>
        </div>

        <!-- Right: Cart + Menu Toggle -->
        <div class="header-right">
            <a href="/offers" class="nav-btn" aria-label="Offers">
                <Ticket size={20} />
            </a>
            <a href="/cart" class="cart-btn">
                <ShoppingCart size={20} />
                {#if currentItemCount > 0}
                    <span class="cart-badge">{currentItemCount}</span>
                {/if}
            </a>
        </div>
    </div>
</header>

{#if currentIsDineIn}
    <div class="dine-in-banner">
        <UtensilsCrossed size={14} />
        Table #{currentTableNumber} — Dine-in
    </div>
{/if}

<style>
    .header {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        height: var(--header-height);
        z-index: var(--z-sticky);
        transition: all var(--transition-base);
    }

    .header-transparent {
        background: transparent;
        border-bottom: none;
    }

    .header-scrolled {
        background: rgba(15, 15, 26, 0.95);
        backdrop-filter: blur(20px);
        -webkit-backdrop-filter: blur(20px);
        border-bottom: 1px solid var(--color-border);
    }

    .header-inner {
        display: flex;
        align-items: center;
        justify-content: space-between;
        height: 100%;
        max-width: var(--container-xl);
        margin: 0 auto;
        padding: 0 var(--space-4);
    }

    .header-left {
        display: flex;
        align-items: center;
        gap: var(--space-2);
    }

    .header-right {
        display: flex;
        align-items: center;
        gap: var(--space-2);
    }

    .back-btn {
        width: 36px;
        height: 36px;
        border-radius: var(--radius-full);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-text-primary);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        transition: all var(--transition-fast);
        -webkit-tap-highlight-color: transparent;
    }

    .back-btn:hover {
        background: var(--color-bg-glass-hover);
        border-color: var(--color-border-hover);
    }

    .logo {
        display: flex;
        align-items: center;
        text-decoration: none;
    }

    .logo-img {
        height: 44px;
        width: auto;
        object-fit: contain;
        mix-blend-mode: lighten;
    }

    .nav-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        color: var(--color-text-primary);
        text-decoration: none;
        transition: all var(--transition-fast);
        -webkit-tap-highlight-color: transparent;
    }

    .nav-btn:hover {
        background: var(--color-bg-glass);
        color: var(--color-accent);
    }

    .cart-btn {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        color: var(--color-text-primary);
        text-decoration: none;
        transition: all var(--transition-fast);
        -webkit-tap-highlight-color: transparent;
    }

    .cart-btn:hover {
        background: var(--color-bg-glass);
    }

    .cart-badge {
        position: absolute;
        top: 2px;
        right: 2px;
        background: var(--color-primary);
        color: white;
        font-size: 10px;
        font-weight: var(--weight-bold);
        min-width: 18px;
        height: 18px;
        border-radius: var(--radius-full);
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0 4px;
    }

    .dine-in-banner {
        position: fixed;
        top: var(--header-height);
        left: 0;
        right: 0;
        background: linear-gradient(135deg, var(--color-accent), #e85d2c);
        color: white;
        text-align: center;
        padding: var(--space-2) var(--space-4);
        font-size: var(--text-xs);
        font-weight: var(--weight-semibold);
        z-index: var(--z-sticky);
        display: flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-2);
    }

    .nav-link {
        padding: var(--space-2) var(--space-4);
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        border-radius: var(--radius-md);
        transition: all var(--transition-fast);
        text-decoration: none;
    }

    .nav-link:hover {
        color: var(--color-text-primary);
        background: var(--color-bg-glass);
    }

    .nav-link-active {
        color: var(--color-primary) !important;
        background: rgba(230, 57, 70, 0.08) !important;
    }
</style>
