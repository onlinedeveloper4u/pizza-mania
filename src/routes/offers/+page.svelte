<script lang="ts">
    import { onMount } from 'svelte';
    import { ShoppingCart, Clock, Info, Check, MapPin, Phone, Mail, ArrowRight, Loader2 } from 'lucide-svelte';
    import { cn } from '$lib/utils';
    import { cart } from '$lib/stores/cart';
    import { goto } from '$app/navigation';
    import { createClient } from '$lib/supabase/client';
    import { settings } from '$lib/stores/settings';
    import { APP_NAME } from '$lib/constants';
    import { toast } from 'svelte-sonner';

    // Type definition to avoid simple generic confusion in runoff
    type TabType = 'delivery' | 'takeaway';
    let activeTab = $state('delivery' as TabType);
    
    let email = $state('');
    let submitting = $state(false);

    // Data State
    let offers: any[] = $state([]);
    let loading = $state(true);
    let error: string | null = $state(null);

    const supabase = createClient();

    onMount(async () => {
        await fetchDeals();
    });

    async function fetchDeals() {
        try {
            loading = true;
            const { data, error: err } = await supabase
                .from('deals')
                .select('*')
                .eq('is_active', true)
                .order('sort_order', { ascending: true });
            
            if (err) throw err;

            // Transform data if needed for UI (e.g. description to array)
            offers = (data || []).map(d => ({
                ...d,
                contents: d.description ? d.description.split(',').map((s: string) => s.trim()) : []
            }));
        } catch (e) {
            console.error('Error fetching deals:', e);
            error = 'Failed to load offers. Please try again later.';
        } finally {
            loading = false;
        }
    }

    let displayedOffers = $derived(offers.filter(o => o.type === activeTab || o.type === 'both'));

    function handleOrderNow(offer: any) {
        cart.setOrderType(activeTab === 'takeaway' ? 'pickup' : 'delivery');
        goto(`/offers/${offer.id}?type=${activeTab}`);
    }

    async function handleSubscribe() {
        if (!email || !email.includes('@')) {
            toast.error('Please enter a valid email address');
            return;
        }

        try {
            submitting = true;
            const res = await fetch('/api/newsletter', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email })
            });

            const data = await res.json();

            if (!res.ok) {
                toast.error(data.error || 'Subscription failed');
                return;
            }

            toast.success(data.message || 'Subscribed successfully!');
            email = '';
        } catch (err) {
            console.error('Newsletter error:', err);
            toast.error('Something went wrong. Please try again later.');
        } finally {
            submitting = false;
        }
    }
</script>

<svelte:head>
    <title>Offers — {$settings?.restaurant_name || APP_NAME}</title>
</svelte:head>

<div class="offers-page">
    <!-- 1. Header Section -->
    <header class="offers-header">
        <div class="container header-content">
            <div class="store-info">
                <h1>{$settings?.restaurant_name || APP_NAME}</h1>
                <p class="city-badge"><MapPin size={14} /> {$settings?.address || 'Flavor Hub'}</p>
            </div>
            <a href="/" class="back-link">Back to Home</a>
        </div>
    </header>

    <main class="container main-content">
        <!-- 2. Offer Categories (Tabs) -->
        <div class="tabs-container">
            <div class="tabs">
                <button 
                    class={cn('tab-btn', activeTab === 'delivery' && 'active')}
                    onclick={() => activeTab = 'delivery'}
                >
                    Delivery Deals
                </button>
                <button 
                    class={cn('tab-btn', activeTab === 'takeaway' && 'active')}
                    onclick={() => activeTab = 'takeaway'}
                >
                    Takeaway Specials
                </button>
            </div>
        </div>

        <!-- 3. Offer Cards -->
        {#if loading}
            <div style="display:flex;justify-content:center;padding:var(--space-12)">
                <Loader2 size={48} class="animate-spin text-accent" />
            </div>
        {:else if error}
            <div style="text-align:center;padding:var(--space-12);color:var(--color-danger)">
                <p>{error}</p>
                <button class="btn btn-outline btn-sm" onclick={fetchDeals} style="margin-top:1rem">Try Again</button>
            </div>
        {:else if displayedOffers.length === 0}
            <div style="text-align:center;padding:var(--space-12);color:var(--color-text-muted)">
                <p>No offers available for this category right now.</p>
            </div>
        {/if}

        <div class="offers-grid animate-fadeInUp">
            {#each displayedOffers as offer (offer.id)}
                <div class="offer-card glass">
                    <div class="offer-header">
                        <div class="offer-title-row">
                            <h3 class="offer-title">{offer.title}</h3>
                            <div class="offer-price">
                                <span class="currency">€</span>{offer.price.toFixed(2)}
                            </div>
                        </div>
                        {#if offer.original_price}
                            <div class="original-price">Usually €{offer.original_price.toFixed(2)}</div>
                        {/if}
                    </div>
                    
                    <div class="offer-body">
                        <ul class="offer-contents">
                            {#each offer.contents as item}
                                <li><Check size={16} class="text-accent" /> {item}</li>
                            {/each}
                        </ul>
                        
                        <div class="offer-meta">
                            {#if offer.validity}
                                <div class="validity">
                                    <Clock size={14} /> {offer.validity}
                                </div>
                            {/if}
                            <div class="conditions">
                                <Info size={14} /> {offer.type === 'both' ? 'Delivery & Takeaway' : (offer.type === 'delivery' ? 'Delivery Only' : 'Takeaway Only')}
                            </div>
                        </div>
                    </div>

                    <div class="offer-footer">
                        <button class="btn btn-primary btn-lg full-width" onclick={() => handleOrderNow(offer)}>
                            Order Now <ArrowRight size={18} />
                        </button>
                    </div>
                </div>
            {/each}
        </div>
    </main>

    <!-- 4. Newsletter Section -->
    <section class="newsletter-section">
        <div class="container container-sm">
            <div class="newsletter-content glass">
                <h2>Unlock Exclusive Deals!</h2>
                <p>Receive our best promotions in advance.</p>
                <div class="newsletter-form">
                    <div class="input-group">
                        <Mail size={20} class="input-icon" />
                        <input 
                            type="email" 
                            class="input newsletter-input" 
                            placeholder="Your email address" 
                            bind:value={email} 
                        />
                    </div>
                    <button class="btn btn-accent" onclick={handleSubscribe}>
                        Subscribe
                    </button>
                </div>
            </div>
        </div>
    </section>

    <!-- 5. Footer Section -->
    <footer class="offers-footer">
        <div class="container footer-content">
            <div class="footer-links">
                <a href="/terms">Terms & Conditions</a>
                <a href="/privacy">Privacy Policy</a>
            </div>
            <div class="footer-contact">
                <div class="contact-item"><Phone size={14} /> {$settings?.phone || ''}</div>
                <div class="contact-item"><MapPin size={14} /> {$settings?.address || ''}</div>
            </div>
            <div class="copyright">
                &copy; {new Date().getFullYear()} {$settings?.restaurant_name || APP_NAME}
            </div>
        </div>
    </footer>

    <!-- Deal Builder Modal -->
</div>

<style>
    .offers-page {
        min-height: 100vh;
        background: var(--color-bg-primary);
        display: flex;
        flex-direction: column;
    }

    /* Header */
    .offers-header {
        background: rgba(0,0,0,0.8);
        backdrop-filter: blur(10px);
        border-bottom: 1px solid var(--color-border);
        padding: var(--space-4) 0;
        position: sticky;
        top: 0;
        z-index: var(--z-sticky);
    }

    .header-content {
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .store-info h1 {
        font-family: var(--font-display);
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
        margin: 0;
        line-height: 1.2;
    }

    .text-accent { color: var(--color-accent); }
    .text-success { color: var(--color-success); }

    .city-badge {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        font-size: var(--text-xs);
        color: var(--color-text-secondary);
        margin-top: 2px;
    }

    .back-link {
        font-size: var(--text-sm);
        color: var(--color-text-muted);
        text-decoration: underline;
    }

    /* Main Content */
    .main-content {
        flex: 1;
        padding-top: var(--space-8);
        padding-bottom: var(--space-12);
    }

    /* Tabs */
    .tabs-container {
        display: flex;
        justify-content: center;
        margin-bottom: var(--space-8);
    }

    .tabs {
        background: var(--color-bg-tertiary);
        padding: 4px;
        border-radius: var(--radius-full);
        display: inline-flex;
        gap: 4px;
    }

    .tab-btn {
        padding: 8px 20px;
        border-radius: var(--radius-full);
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        transition: all var(--transition-base);
    }

    .tab-btn.active {
        background: var(--color-primary);
        color: white;
        box-shadow: var(--shadow-sm);
    }

    /* Offers Grid */
    .offers-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: var(--space-6);
    }

    /* Offer Card */
    .offer-card {
        display: flex;
        flex-direction: column;
        overflow: hidden;
        transition: transform var(--transition-base);
        background: linear-gradient(135deg, rgba(255,255,255,0.03) 0%, rgba(255,255,255,0.01) 100%);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
    }

    .offer-card:hover {
        transform: translateY(-4px);
        border-color: var(--color-border-hover);
        background: linear-gradient(135deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0.02) 100%);
    }

    .offer-header {
        padding: var(--space-5);
        border-bottom: 1px solid var(--color-border);
        background: rgba(0,0,0,0.2);
    }
    
    .offer-title-row {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: var(--space-2);
    }

    .offer-title {
        font-family: var(--font-display);
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
        margin: 0;
        color: white;
        line-height: 1.2;
    }

    .offer-price {
        display: flex;
        align-items: baseline;
        gap: 2px;
        color: var(--color-accent);
        font-weight: var(--weight-bold);
        font-size: var(--text-2xl);
        white-space: nowrap;
    }

    .currency { font-size: var(--text-lg); }

    .original-price {
        font-size: var(--text-sm);
        color: var(--color-text-muted);
        text-decoration: line-through;
        margin-top: 4px;
        text-align: right;
    }

    .offer-body {
        padding: var(--space-5);
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: var(--space-4);
    }

    .offer-contents {
        display: flex;
        flex-direction: column;
        gap: var(--space-2);
    }

    .offer-contents li {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
    }

    .offer-meta {
        margin-top: auto;
        padding-top: var(--space-4);
        border-top: 1px dashed var(--color-border);
        display: flex;
        flex-direction: column;
        gap: var(--space-2);
        font-size: var(--text-xs);
        color: var(--color-text-muted);
    }

    .validity, .conditions {
        display: flex;
        align-items: center;
        gap: var(--space-2);
    }

    .offer-footer {
        padding: var(--space-4);
        border-top: 1px solid var(--color-border);
        background: rgba(0,0,0,0.2);
    }

    .full-width { width: 100%; justify-content: space-between; }

    /* Newsletter */
    .newsletter-section {
        padding: var(--space-12) 0;
        background: linear-gradient(to top, rgba(0,0,0,0.5), transparent);
        border-top: 1px solid var(--color-border);
    }

    .newsletter-content {
        padding: var(--space-8);
        text-align: center;
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        background: linear-gradient(135deg, rgba(255, 107, 53, 0.1), rgba(0,0,0,0.4));
    }

    .newsletter-content h2 {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-2);
        color: var(--color-text-primary);
    }

    .newsletter-content p {
        color: var(--color-text-secondary);
        margin-bottom: var(--space-6);
    }

    .newsletter-form {
        display: flex;
        gap: var(--space-3);
        max-width: 400px;
        margin: 0 auto;
    }

    .input-group {
        position: relative;
        flex: 1;
    }

    .input-icon {
        position: absolute;
        left: 12px;
        top: 50%;
        transform: translateY(-50%);
        color: var(--color-text-muted);
        pointer-events: none;
    }

    .newsletter-input {
        padding-left: 40px;
    }

    /* Footer */
    .offers-footer {
        background: var(--color-bg-secondary);
        border-top: 1px solid var(--color-border);
        padding: var(--space-8) 0;
        margin-top: auto;
    }

    .footer-content {
        display: flex;
        flex-direction: column;
        gap: var(--space-6);
        text-align: center;
        font-size: var(--text-sm);
        color: var(--color-text-muted);
    }

    .footer-links {
        display: flex;
        justify-content: center;
        gap: var(--space-6);
    }

    .footer-links a:hover { color: var(--color-primary); }

    .footer-contact {
        display: flex;
        flex-direction: column;
        gap: var(--space-2);
        align-items: center;
    }

    .contact-item {
        display: flex;
        align-items: center;
        gap: var(--space-2);
    }

    /* Mobile Improvements */
    @media (max-width: 768px) {
        .offers-grid {
            grid-template-columns: 1fr;
        }

        .newsletter-form {
            flex-direction: column;
        }
        
        .tab-btn {
            padding: 8px 16px;
            font-size: var(--text-xs);
        }

        .offer-price {
            font-size: var(--text-xl);
        }

        .store-info h1 {
            font-size: var(--text-lg);
        }
    }
</style>
