<script lang="ts">
    import { X, Check, ChevronRight, ChevronLeft, ShoppingBag } from 'lucide-svelte';
    import { fade, fly, scale } from 'svelte/transition';
    import { cart } from '$lib/stores/cart';
    import { formatPrice } from '$lib/utils';
    import { toast } from 'svelte-sonner';
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { createClient } from '$lib/supabase/client';

    const supabase = createClient();

    let { deal, onclose, orderType } = $props<{ deal: any, onclose: () => void, orderType: string }>();
    
    // State
    let step = $state(0);
    let selections: Record<string, any> = $state({});
    let loading = $state(true);
    let menuItems: any[] = $state([]);
    
    // Configuration for the deal steps
    let steps: any[] = $state([]);

    // Body Scroll Lock
    $effect(() => {
        const originalStyle = window.getComputedStyle(document.body).overflow;
        document.body.style.overflow = 'hidden';
        return () => {
            document.body.style.overflow = originalStyle;
        };
    });

    onMount(async () => {
        await fetchMenu();
        configureSteps();
        loading = false;
    });

    async function fetchMenu() {
        try {
            const [catRes, itemRes] = await Promise.all([
                supabase.from('categories').select('*').eq('is_active', true).order('sort_order'),
                supabase.from('menu_items').select('*').eq('is_available', true).order('sort_order'),
            ]);

            if (catRes.error) console.error('Error fetching categories:', catRes.error);
            if (itemRes.error) console.error('Error fetching items:', itemRes.error);

            if (catRes.data && itemRes.data) {
                // Map items to categories manually to ensure data integrity
                menuItems = itemRes.data.map((item: any) => {
                    const category = catRes.data.find((c: any) => c.id === item.category_id);
                    return { ...item, category };
                });
                console.log('Loaded menu items with categories:', menuItems.length);
                console.log('Categories:', catRes.data.map(c => c.name));
            }
        } catch (e) {
            console.error('Fetch error:', e);
        }
    }

    function configureSteps() {
        if (deal.steps && Array.isArray(deal.steps) && deal.steps.length > 0) {
            steps = deal.steps;
        } else {
            console.warn('Deal has no configuration steps:', deal);
            steps = [];
        }
    }

    function getItemsForStep(stepIndex: number) {
        if (!steps[stepIndex]) return [];
        const categoryName = steps[stepIndex].category;
        return menuItems.filter(i => i.category?.name.includes(categoryName) || i.category?.name === categoryName);
    }

    function selectItem(stepId: string, item: any) {
        selections[stepId] = item;
        // Auto-advance
        if (step < steps.length - 1) {
            setTimeout(() => {
                if(step < steps.length - 1) step++;
            }, 300);
        }
    }

    function prevStep() {
        if (step > 0) step--;
    }

    function nextStep() {
        if (step < steps.length - 1) step++;
    }

    function addToCart() {
        const options: Record<string, string> = {
            'Valid for': orderType === 'delivery' ? 'Home Delivery' : 'Self Pickup'
        };
        
        steps.forEach(s => {
            if (selections[s.id]) {
                options[s.title] = selections[s.id].name;
            }
        });

        const cartItem = {
            id: `deal-${deal.id}-${Date.now()}`,
            name: deal.title,
            description: deal.contents.join(', '),
            price: deal.price,
            category_id: 'deals',
            image_url: deal.image,
            is_available: true,
            options: [],
            created_at: new Date().toISOString()
        };

        cart.addItem(cartItem, 1, options, 'Special Deal Bundle');
        
        toast.success(`${deal.title} added to cart!`);
        if (onclose) onclose();
        goto('/cart');
    }

    // Reactivity
    let currentProgress = $derived(steps.length > 0 ? ((step + 1) / steps.length) * 100 : 0);
    let isStepComplete = $derived(steps[step] && !!selections[steps[step].id]);
    let isAllComplete = $derived(steps.length > 0 && steps.every(s => selections[s.id]));

</script>

<!-- Modal Overlay -->
<div class="modal-overlay" transition:fade onclick={() => onclose && onclose()}>
    <!-- Modal Content -->
    <div 
        class="modal-content" 
        transition:fly={{ y: 100, duration: 300 }} 
        onclick={(e) => e.stopPropagation()}
    >
        
        <!-- Header -->
        <div class="modal-header">
            <button class="close-btn" onclick={() => onclose && onclose()}>
                <X size={24} />
            </button>
            <div class="header-text">
                <h3>{deal.title}</h3>
                <p class="price">€{formatPrice(deal.price)}</p>
            </div>
            <!-- Progress Bar -->
            <div class="progress-container">
                <div class="progress-fill" style="width: {currentProgress}%"></div>
            </div>
        </div>

        <!-- Body -->
        <div class="modal-body">
            {#if loading}
                <div class="loading-state">
                    <div class="spinner"></div>
                    <p>Loading tasty choices...</p>
                </div>
            {:else if steps.length === 0}
                 <div class="error-state">
                    <p>Configuration error for this deal.</p>
                </div>
            {:else}
                <div class="step-container">
                    <div class="step-header">
                        <span class="step-badge">{step + 1} of {steps.length}</span>
                        <h4>{steps[step].title}</h4>
                    </div>

                    <div class="items-grid">
                        {#each getItemsForStep(step) as item (item.id)}
                            <button 
                                class="item-card {selections[steps[step].id]?.id === item.id ? 'selected' : ''}"
                                onclick={() => selectItem(steps[step].id, item)}
                            >
                                <div class="item-info">
                                    <span class="item-name">{item.name}</span>
                                    {#if item.description}
                                        <span class="item-desc">{item.description}</span>
                                    {/if}
                                </div>
                                {#if selections[steps[step].id]?.id === item.id}
                                    <div class="check-icon" transition:scale>
                                        <Check size={16} />
                                    </div>
                                {/if}
                            </button>
                        {/each}
                    </div>
                </div>
            {/if}
        </div>

        <!-- Footer -->
        <div class="modal-footer">
            {#if step > 0}
                <button class="btn btn-outline" onclick={prevStep}>
                    <ChevronLeft size={18} /> Back
                </button>
            {:else}
                <div></div> <!-- Spacer -->
            {/if}

            {#if step < steps.length - 1}
                <button class="btn btn-primary" onclick={nextStep} disabled={!isStepComplete}>
                    Next <ChevronRight size={18} />
                </button>
            {:else}
                <button class="btn btn-accent" onclick={addToCart} disabled={!isAllComplete}>
                    Add to Cart <ShoppingBag size={18} />
                </button>
            {/if}
        </div>

    </div>
</div>

<style>
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.85);
        backdrop-filter: blur(8px);
        z-index: var(--z-modal);
        display: flex;
        justify-content: center;
        align-items: center; 
    }

    @media (min-width: 768px) {
        .modal-overlay {
            padding: var(--space-4);
        }
    }

    .modal-content {
        background: var(--color-bg-secondary);
        width: 100%;
        height: 100%;
        max-height: 100%;
        border-radius: 0;
        display: flex;
        flex-direction: column;
        border: none;
        box-shadow: none;
        overflow: hidden;
    }

    @media (min-width: 768px) {
        .modal-content {
            max-width: 1000px;
            height: 85vh;
            border-radius: var(--radius-2xl);
            border: 1px solid var(--color-border);
            box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.7);
        }
    }

    /* Header */
    .modal-header {
        padding: var(--space-4);
        border-bottom: 1px solid var(--color-border);
        position: relative;
        text-align: center;
        background: var(--color-bg-secondary);
        z-index: 10;
    }

    .header-text h3 {
        font-family: var(--font-display);
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
        margin-bottom: 4px;
    }

    .price {
        color: var(--color-accent);
        font-weight: var(--weight-bold);
    }

    .close-btn {
        position: absolute;
        top: var(--space-4);
        right: var(--space-4);
        padding: var(--space-2);
        color: var(--color-text-muted);
        background: rgba(255,255,255,0.05);
        border-radius: var(--radius-full);
    }

    .progress-container {
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        height: 4px;
        background: var(--color-bg-tertiary);
    }

    .progress-fill {
        height: 100%;
        background: var(--color-primary);
        transition: width 0.3s ease;
    }

    /* Body */
    .modal-body {
        flex: 1;
        overflow-y: auto;
        padding: var(--space-4);
        background: var(--color-bg-primary);
    }

    .loading-state, .error-state {
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: var(--color-text-muted);
        gap: var(--space-4);
    }

    .step-header {
        margin-bottom: var(--space-4);
        display: flex;
        flex-direction: column;
        gap: var(--space-2);
    }

    .step-badge {
        align-self: flex-start;
        background: var(--color-bg-tertiary);
        padding: 4px 10px;
        border-radius: var(--radius-full);
        font-size: var(--text-xs);
        color: var(--color-text-secondary);
        text-transform: uppercase;
        font-weight: var(--weight-bold);
        letter-spacing: 0.05em;
    }

    .step-header h4 {
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
    }

    .items-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: var(--space-3);
        padding-bottom: var(--space-8);
    }

    .item-card {
        text-align: left;
        padding: var(--space-4);
        border-radius: var(--radius-lg);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        display: flex;
        justify-content: space-between;
        align-items: center;
        transition: all 0.2s ease;
        width: 100%;
    }

    .item-card:hover {
        background: var(--color-bg-glass-hover);
        border-color: var(--color-border-hover);
    }

    .item-card.selected {
        border-color: var(--color-primary);
        background: rgba(230, 57, 70, 0.08);
        box-shadow: 0 0 0 1px var(--color-primary);
    }

    .item-info {
        display: flex;
        flex-direction: column;
        gap: 2px;
    }

    .item-name { font-weight: var(--weight-medium); font-size: var(--text-base); }
    .item-desc { font-size: var(--text-xs); color: var(--color-text-muted); }

    .check-icon {
        color: var(--color-primary);
        background: white;
        border-radius: 50%;
        padding: 2px;
        display: flex;
        box-shadow: var(--shadow-sm);
    }

    /* Footer */
    .modal-footer {
        padding: var(--space-4);
        border-top: 1px solid var(--color-border);
        display: flex;
        justify-content: space-between;
        align-items: center;
        background: var(--color-bg-secondary);
        /* Safe area for iPhone home bar */
        padding-bottom: max(var(--space-4), env(safe-area-inset-bottom));
    }

    .spinner {
        width: 32px;
        height: 32px;
        border: 3px solid rgba(255,255,255,0.1);
        border-radius: 50%;
        border-top-color: var(--color-primary);
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        to { transform: rotate(360deg); }
    }

    /* Desktop Adjustments */
    @media (min-width: 768px) {
        .modal-overlay {
            align-items: center;
            padding: var(--space-4);
        }

        .modal-content {
            height: 600px; /* Fixed reasonable height on Desktop */
            max-height: 90vh;
            border-radius: var(--radius-2xl);
            box-shadow: var(--shadow-2xl);
        }
        
        .items-grid {
            grid-template-columns: 1fr 1fr; /* Two columns on larger screens */
        }
    }
</style>
