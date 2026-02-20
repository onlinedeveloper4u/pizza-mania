<script lang="ts">
    import { goto } from '$app/navigation';
    import { Truck, Store, Clock, Ticket, Search } from 'lucide-svelte';
    import { cart } from '$lib/stores/cart';
    import type { OrderType } from '$lib/types';
    import LocationModal from '$lib/components/LocationModal.svelte';

    let showLocationModal = $state(false);

    function selectOrderType(type: OrderType) {
        if (type === 'delivery') {
            showLocationModal = true;
            return;
        }
        cart.setOrderType(type);
        goto('/menu');
    }

    function handleLocationConfirm(data: any) {
        // Here we could store the address in the cart or a separate store
        cart.setOrderType('delivery');
        goto('/menu');
    }
</script>

<svelte:head>
    <title>Pizza Mania — Order Now</title>
</svelte:head>

<div class="home">
    <div class="home-bg"></div>

    <div class="home-content">
        <!-- Logo -->
        <div class="home-logo">
            <img src="/logo.png" alt="Pizza Mania" class="home-logo-img" />
        </div>

        <p class="home-tagline">How would you like your order?</p>

        <!-- Order Type Cards -->
        <div class="order-cards">
            <button class="order-card delivery-card" onclick={() => selectOrderType('delivery')}>
                <div class="order-card-icon delivery-icon">
                    <Truck size={32} />
                </div>
                <div class="order-card-info">
                    <h2>Delivery</h2>
                    <p>We'll bring it to your door</p>
                </div>
                <div class="order-card-meta">
                    <Clock size={14} />
                    <span>30–45 min</span>
                </div>
            </button>

            <button class="order-card pickup-card" onclick={() => selectOrderType('pickup')}>
                <div class="order-card-icon pickup-icon">
                    <Store size={32} />
                </div>
                <div class="order-card-info">
                    <h2>Pickup</h2>
                    <p>Ready for you at the counter</p>
                </div>
                <div class="order-card-meta">
                    <Clock size={14} />
                    <span>15–20 min</span>
                </div>
            </button>
        </div>

        <!-- Home Actions -->
        <div class="home-actions">
            <a href="/offers" class="action-link offers">
                <Ticket size={18} />
                <span>View Special Offers</span>
            </a>
            <a href="/order" class="action-link track">
                <Search size={18} />
                <span>Track Order</span>
            </a>
        </div>

        <!-- Info badges -->
        <div class="home-badges">
            <div class="badge">
                <span>Pizza • Pasta • Breakfast</span>
            </div>
        </div>

        <p class="dine-in-hint">
            Dining in? Scan the <strong>QR code</strong> at your table
        </p>
    </div>

    <LocationModal 
        bind:show={showLocationModal} 
        onConfirm={handleLocationConfirm}
    />
</div>

<style>
    .home {
        position: relative;
        min-height: 100dvh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: var(--space-6);
        overflow-y: auto;
    }

    .home-bg {
        position: absolute;
        inset: 0;
        z-index: -1;
        background:
            radial-gradient(ellipse at 50% 30%, rgba(230, 57, 70, 0.12) 0%, transparent 60%),
            radial-gradient(ellipse at 50% 80%, rgba(255, 107, 53, 0.08) 0%, transparent 50%),
            linear-gradient(180deg, var(--color-bg-primary) 0%, var(--color-bg-secondary) 100%);
    }

    .home-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        text-align: center;
        width: 100%;
        max-width: 440px;
        animation: fadeInUp 0.5s ease-out;
    }

    .home-logo {
        margin-bottom: var(--space-6);
    }

    .home-logo-img {
        height: 100px;
        width: auto;
        object-fit: contain;
        mix-blend-mode: lighten;
    }

    .home-tagline {
        font-size: var(--text-xl);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        margin-bottom: var(--space-8);
    }

    /* Order Cards */
    .order-cards {
        display: flex;
        flex-direction: column;
        gap: var(--space-4);
        width: 100%;
        margin-bottom: var(--space-8);
    }

    .order-card {
        display: flex;
        align-items: center;
        gap: var(--space-4);
        padding: var(--space-5) var(--space-6);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        cursor: pointer;
        transition: all var(--transition-base);
        text-align: left;
        width: 100%;
        color: var(--color-text-primary);
        -webkit-tap-highlight-color: transparent;
    }

    .order-card:hover {
        border-color: var(--color-border-hover);
        transform: translateY(-2px);
        box-shadow: var(--shadow-lg);
    }

    .order-card:active {
        transform: scale(0.98);
        box-shadow: none;
    }

    .order-card-icon {
        width: 56px;
        height: 56px;
        border-radius: var(--radius-xl);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .delivery-icon {
        background: rgba(59, 130, 246, 0.12);
        color: var(--color-info);
    }

    .delivery-card:hover {
        border-color: rgba(59, 130, 246, 0.4);
        background: rgba(59, 130, 246, 0.06);
    }

    .pickup-icon {
        background: rgba(42, 157, 143, 0.12);
        color: var(--color-success);
    }

    .pickup-card:hover {
        border-color: rgba(42, 157, 143, 0.4);
        background: rgba(42, 157, 143, 0.06);
    }

    .order-card-info {
        flex: 1;
    }

    .order-card-info h2 {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
        margin-bottom: 2px;
    }

    .order-card-info p {
        font-size: var(--text-sm);
        color: var(--color-text-muted);
    }

    .order-card-meta {
        display: flex;
        align-items: center;
        gap: var(--space-1);
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        background: var(--color-bg-glass);
        padding: var(--space-1) var(--space-3);
        border-radius: var(--radius-full);
        white-space: nowrap;
    }

    .home-actions {
        display: flex;
        flex-direction: column;
        gap: var(--space-3);
        width: 100%;
        margin-bottom: var(--space-8);
    }

    .action-link {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-2);
        font-weight: var(--weight-medium);
        font-size: var(--text-sm);
        text-decoration: none;
        padding: var(--space-3) var(--space-5);
        border-radius: var(--radius-full);
        transition: all var(--transition-fast);
        width: 100%;
    }

    .action-link.offers {
        color: var(--color-accent);
        background: rgba(230, 57, 70, 0.1);
    }

    .action-link.offers:hover {
        background: rgba(230, 57, 70, 0.2);
        transform: translateY(-1px);
    }

    .action-link.track {
        color: var(--color-text-secondary);
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
    }

    .action-link.track:hover {
        background: var(--color-bg-hover);
        border-color: var(--color-border-hover);
        transform: translateY(-1px);
    }

    /* Badges */
    .home-badges {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        margin-bottom: var(--space-6);
    }

    .badge {
        display: flex;
        align-items: center;
        gap: var(--space-1);
        font-size: var(--text-xs);
        color: var(--color-text-muted);
    }

    .badge-dot {
        width: 4px;
        height: 4px;
        border-radius: 50%;
        background: var(--color-text-muted);
    }

    .dine-in-hint {
        font-size: var(--text-sm);
        color: var(--color-text-muted);
        opacity: 0.7;
    }

    .dine-in-hint strong {
        color: var(--color-text-secondary);
    }

    @media (min-width: 769px) {
        .home-logo-img {
            height: 120px;
        }

        .order-cards {
            flex-direction: row;
        }

        .order-card {
            flex-direction: column;
            text-align: center;
            padding: var(--space-8) var(--space-6);
        }

        .order-card-info h2 {
            font-size: var(--text-xl);
        }

        .order-card-meta {
            margin-top: var(--space-2);
        }

        .home-content {
            max-width: 600px;
        }

        .home-actions {
            flex-direction: row;
            justify-content: center;
        }

        .action-link {
            width: auto;
            min-width: 200px;
        }
    }
</style>
