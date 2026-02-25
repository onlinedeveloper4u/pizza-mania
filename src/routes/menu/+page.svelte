<script lang="ts">
    import { onMount } from "svelte";
    import {
        Plus,
        Minus,
        X,
        UtensilsCrossed,
        ShoppingCart,
        Search,
        Check,
    } from "lucide-svelte";
    import { settings } from "$lib/stores/settings";
    import { createClient } from "$lib/supabase/client";
    import { cart } from "$lib/stores/cart";
    import type { Category, MenuItem, MenuItemOption } from "$lib/types";
    import { formatPrice, cn, calculateItemPrice } from "$lib/utils";
    import { toast } from "svelte-sonner";

    let categories: Category[] = $state([]);
    let menuItems: MenuItem[] = $state([]);
    let deals: any[] = $state([]);
    let activeCategory: string | null = $state(null);
    let searchQuery = $state("");
    let selectedItem: MenuItem | null = $state(null);
    let loading = $state(true);

    // Modal state
    let quantity = $state(1);
    let selectedOptions: Record<string, string | string[]> = $state({});
    let notes = $state("");

    let currentItemCount = $state(0);
    let currentIsDineIn = $state(false);
    cart.itemCount.subscribe((v) => (currentItemCount = v));
    cart.isDineIn.subscribe((v) => (currentIsDineIn = v));

    let layout: "grid" | "list" = $state("grid");

    // Filtered items
    let filteredItems = $derived.by(() => {
        let items = menuItems;
        if (activeCategory) {
            items = items.filter((item) => item.category_id === activeCategory);
        }
        if (searchQuery.trim()) {
            const q = searchQuery.toLowerCase();
            items = items.filter(
                (item) =>
                    item.name.toLowerCase().includes(q) ||
                    (item.description &&
                        item.description.toLowerCase().includes(q)),
            );
        }
        return items;
    });

    // Modal price
    let modalPrice = $derived(
        selectedItem
            ? calculateItemPrice(
                  selectedItem.price,
                  selectedOptions,
                  selectedItem.options,
              )
            : 0,
    );

    onMount(async () => {
        const supabase = createClient();
        const [catRes, itemRes, dealsRes] = await Promise.all([
            supabase
                .from("categories")
                .select("*")
                .eq("is_active", true)
                .order("sort_order"),
            supabase
                .from("menu_items")
                .select("*")
                .eq("is_available", true)
                .order("name"),
            supabase
                .from("deals")
                .select("*")
                .eq("is_active", true)
                .order("sort_order", { ascending: true }),
        ]);
        if (catRes.data) categories = catRes.data;
        if (itemRes.data) menuItems = itemRes.data;
        if (dealsRes.data) deals = dealsRes.data;
        if (catRes.data && catRes.data.length > 0)
            activeCategory = catRes.data[0].id;
        loading = false;
    });

    function openItemModal(item: MenuItem) {
        selectedItem = item;
        quantity = 1;
        selectedOptions = {};
        notes = "";
    }

    function handleOptionChange(option: MenuItemOption, choiceName: string) {
        if (option.type === "single") {
            selectedOptions = { ...selectedOptions, [option.name]: choiceName };
        } else {
            const current = (selectedOptions[option.name] as string[]) || [];
            if (current.includes(choiceName)) {
                selectedOptions = {
                    ...selectedOptions,
                    [option.name]: current.filter((c) => c !== choiceName),
                };
            } else {
                selectedOptions = {
                    ...selectedOptions,
                    [option.name]: [...current, choiceName],
                };
            }
        }
    }

    function isChoiceSelected(optionName: string, choiceName: string): boolean {
        const sel = selectedOptions[optionName];
        if (!sel) return false;
        if (Array.isArray(sel)) return sel.includes(choiceName);
        return sel === choiceName;
    }

    function handleAddToCart() {
        if (!selectedItem) return;
        const options = selectedItem.options || [];
        for (const opt of options) {
            if (opt.required && !selectedOptions[opt.name]) {
                toast.error(`Please select ${opt.name}`);
                return;
            }
        }
        cart.addItem(selectedItem, quantity, selectedOptions, notes);
        toast.success(`${selectedItem.name} added to cart!`);
        selectedItem = null;
    }

    function ingredientWithEmoji(name: string): string {
        const map: Record<string, string> = {
            // Sauces
            "sauce tomate": "🍅",
            "tomato sauce": "🍅",
            "crème fraîche": "🥛",
            "creme fraiche": "🥛",
            crème: "🥛",
            cream: "🥛",
            "sauce blanche": "🥛",
            "white sauce": "🥛",
            "sauce barbecue": "🍖",
            "bbq sauce": "🍖",
            pesto: "🌿",
            "huile d'olive": "🫒",
            "olive oil": "🫒",
            "sauce curry": "🍛",
            "curry sauce": "🍛",
            "base tomate": "🍅",
            "sauce bolognaise": "🍝",
            bolognese: "🍝",

            // Cheeses
            mozzarella: "🧀",
            chèvre: "🐐",
            "goat cheese": "🐐",
            "fromage de chèvre": "🐐",
            gorgonzola: "🫕",
            emmental: "🧀",
            parmesan: "🧀",
            parmigiano: "🧀",
            ricotta: "🥛",
            burrata: "🤍",
            cheddar: "🧀",
            fromage: "🧀",
            cheese: "🧀",
            "quatre fromages": "🧀",
            "4 fromages": "🧀",
            raclette: "🫕",
            roquefort: "🔵",
            mascarpone: "🍰",
            feta: "🧊",
            brie: "🧀",
            comté: "🧀",

            // Meats
            jambon: "🥩",
            ham: "🥩",
            pepperoni: "🔴",
            salami: "🔴",
            chorizo: "🌶️",
            merguez: "🌭",
            lardons: "🥓",
            bacon: "🥓",
            poulet: "🍗",
            chicken: "🍗",
            dinde: "🦃",
            turkey: "🦃",
            boeuf: "🥩",
            beef: "🥩",
            "viande hachée": "🥩",
            "ground beef": "🥩",
            steak: "🥩",
            kebab: "🥙",
            döner: "🥙",
            saucisse: "🌭",
            sausage: "🌭",
            prosciutto: "🇮🇹",
            coppa: "🇮🇹",
            speck: "🇮🇹",
            pancetta: "🥓",
            nduja: "🌶️",

            // Seafood
            thon: "🐟",
            tuna: "🐟",
            saumon: "🍣",
            salmon: "🍣",
            anchois: "🐟",
            anchovies: "🐟",
            crevettes: "🦐",
            shrimp: "🦐",
            "fruits de mer": "🦞",
            seafood: "🦞",
            moules: "🦪",
            mussels: "🦪",
            calamars: "🦑",
            calamari: "🦑",

            // Vegetables
            champignons: "🍄",
            mushrooms: "🍄",
            oignons: "🧅",
            onions: "🧅",
            "oignons rouges": "🧅",
            "red onions": "🧅",
            poivrons: "🫑",
            peppers: "🫑",
            poivron: "🫑",
            pepper: "🫑",
            olives: "🫒",
            olive: "🫒",
            "olives noires": "🫒",
            "black olives": "🫒",
            "olives vertes": "🫒",
            tomates: "🍅",
            tomatoes: "🍅",
            "tomates fraîches": "🍅",
            "tomates cerises": "🍅",
            "cherry tomatoes": "🍅",
            épinards: "🥬",
            spinach: "🥬",
            roquette: "🥬",
            arugula: "🥬",
            salade: "🥗",
            lettuce: "🥗",
            maïs: "🌽",
            corn: "🌽",
            artichaut: "🌻",
            artichoke: "🌻",
            aubergine: "🍆",
            eggplant: "🍆",
            courgette: "🥒",
            zucchini: "🥒",
            brocoli: "🥦",
            broccoli: "🥦",
            "pommes de terre": "🥔",
            potatoes: "🥔",
            ail: "🧄",
            garlic: "🧄",
            câpres: "🟢",
            capers: "🟢",
            jalapeño: "🌶️",
            jalapeno: "🌶️",
            piment: "🌶️",
            chili: "🌶️",
            avocat: "🥑",
            avocado: "🥑",
            cornichons: "🥒",
            pickles: "🥒",

            // Fruits
            ananas: "🍍",
            pineapple: "🍍",
            figues: "🪻",
            figs: "🪻",
            noix: "🥜",
            walnuts: "🥜",
            noisettes: "🌰",
            hazelnuts: "🌰",

            // Herbs & Spices
            basilic: "🌿",
            basil: "🌿",
            origan: "🌿",
            oregano: "🌿",
            persil: "🌿",
            parsley: "🌿",
            herbes: "🌿",
            herbs: "🌿",
            truffe: "🖤",
            truffle: "🖤",
            "huile truffe": "🖤",
            "truffle oil": "🖤",

            // Eggs & Others
            oeuf: "🥚",
            egg: "🥚",
            œuf: "🥚",
            miel: "🍯",
            honey: "🍯",
            nutella: "🍫",
            chocolat: "🍫",
            chocolate: "🍫",
            sucre: "🍬",
            sugar: "🍬",

            // Condiments
            ketchup: "🟥",
            mayonnaise: "🥫",
            mayo: "🥫",
            moutarde: "🟡",
            mustard: "🟡",
            "vinaigre balsamique": "🍶",
            balsamic: "🍶",

            // Bread/Dough
            pain: "🍞",
            bread: "🍞",
            focaccia: "🫓",
            pâte: "🫓",
            dough: "🫓",

            // Frites / Sides
            frites: "🍟",
            fries: "🍟",
            "pommes frites": "🍟",
        };

        const key = name.toLowerCase().trim();

        // Exact match
        if (map[key]) return `${map[key]} ${name.trim()}`;

        // Partial / keyword match
        for (const [ingredient, emoji] of Object.entries(map)) {
            if (key.includes(ingredient) || ingredient.includes(key)) {
                return `${emoji} ${name.trim()}`;
            }
        }

        // Default
        return `🍽️ ${name.trim()}`;
    }

    let currentOrderType = $state<"delivery" | "pickup" | "dine_in" | null>(
        null,
    );
    cart.subscribe((s) => (currentOrderType = s.orderType));

    // Body Scroll Lock for Modal
    $effect(() => {
        if (selectedItem) {
            const originalStyle = window.getComputedStyle(
                document.body,
            ).overflow;
            document.body.style.overflow = "hidden";
            return () => {
                document.body.style.overflow = originalStyle;
            };
        }
    });

    let applicableDeals = $derived(
        deals.filter((d) => {
            if (!currentOrderType)
                return d.type === "both" || d.type === "delivery"; // Default
            if (d.type === "both") return true;
            if (currentOrderType === "delivery" && d.type === "delivery")
                return true;
            if (currentOrderType === "pickup" && d.type === "takeaway")
                return true;
            return false;
        }),
    );
</script>

<svelte:head>
    <title>Menu — {$settings?.restaurant_name || "Pizza Mania"}</title>
</svelte:head>

<div class={cn("menu-page", currentIsDineIn && "menu-page-dinein")}>
    {#if loading}
        <div class="menu-grid">
            {#each Array(6) as _}
                <div class="menu-card">
                    <div class="skeleton" style="aspect-ratio: 16/10;"></div>
                    <div class="menu-card-body">
                        <div
                            class="skeleton"
                            style="height: 18px; width: 60%; margin-bottom: 8px;"
                        ></div>
                        <div
                            class="skeleton"
                            style="height: 14px; width: 100%; margin-bottom: 12px;"
                        ></div>
                        <div
                            class="skeleton"
                            style="height: 22px; width: 30%;"
                        ></div>
                    </div>
                </div>
            {/each}
        </div>
    {:else}
        <!-- Search & Layout Toggle -->
        <div class="menu-controls">
            <div class="search-wrapper">
                <Search size={18} color="var(--color-text-muted)" />
                <input
                    type="text"
                    class="search-input"
                    placeholder="Search dishes..."
                    bind:value={searchQuery}
                    oninput={() => {
                        if (searchQuery.trim()) activeCategory = null;
                    }}
                />
            </div>
            <div class="layout-toggle">
                <button
                    class={cn("toggle-btn", layout === "grid" && "active")}
                    onclick={() => (layout = "grid")}
                    aria-label="Grid View"
                >
                    <div class="grid-icon"></div>
                </button>
                <button
                    class={cn("toggle-btn", layout === "list" && "active")}
                    onclick={() => (layout = "list")}
                    aria-label="List View"
                >
                    <div class="list-icon"></div>
                </button>
            </div>
        </div>

        <!-- Category Pills -->
        <div class="category-pills">
            <div class="category-pills-inner">
                {#each categories as cat}
                    <button
                        class={cn(
                            "pill",
                            activeCategory === cat.id && "pill-active",
                        )}
                        onclick={() => {
                            activeCategory = cat.id;
                            searchQuery = "";
                        }}
                    >
                        {cat.name}
                    </button>
                {/each}
            </div>
        </div>

        <!-- Menu Grid/List -->
        {#if filteredItems.length === 0}
            <div class="empty-state">
                <Search size={40} />
                <h3>No items found</h3>
                <p>Try a different search or category</p>
            </div>
        {:else}
            <div
                class={cn(
                    "menu-items-container",
                    layout === "grid" ? "menu-grid" : "menu-list",
                )}
            >
                {#each filteredItems as item}
                    <div
                        class="menu-card"
                        role="button"
                        tabindex="0"
                        onclick={() => openItemModal(item)}
                        onkeydown={(e) =>
                            e.key === "Enter" && openItemModal(item)}
                    >
                        {#if item.image_url}
                            <img
                                src={item.image_url}
                                alt={item.name}
                                class="menu-card-image"
                            />
                        {:else}
                            <div class="menu-card-image-placeholder">
                                <UtensilsCrossed
                                    size={layout === "list" ? 24 : 32}
                                    color="rgba(255,255,255,0.1)"
                                />
                            </div>
                        {/if}
                        <div class="menu-card-body">
                            <div class="menu-card-name">{item.name}</div>
                            {#if item.description}
                                <div
                                    class="menu-card-desc"
                                    class:list-desc={layout === "list"}
                                >
                                    {item.description}
                                </div>
                            {/if}
                            <div class="menu-card-footer">
                                <div class="menu-card-price">
                                    {formatPrice(item.price)}
                                </div>
                                <button
                                    class="add-btn"
                                    onclick={(e) => {
                                        e.stopPropagation();
                                        openItemModal(item);
                                    }}
                                    aria-label="Add {item.name}"
                                >
                                    <Plus size={18} />
                                </button>
                            </div>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}

        <!-- Floating Cart Button -->
        {#if currentItemCount > 0}
            <div class="floating-cart">
                <a
                    href="/cart"
                    class="btn btn-primary btn-lg floating-cart-btn"
                >
                    <ShoppingCart size={18} />
                    View Cart ({currentItemCount})
                </a>
            </div>
        {/if}
    {/if}

    <!-- Item Detail Modal (Bottom Sheet on mobile) -->
    {#if selectedItem}
        <div
            class="modal-overlay"
            role="button"
            tabindex="-1"
            onclick={() => (selectedItem = null)}
            onkeydown={(e) => e.key === "Escape" && (selectedItem = null)}
        >
            <div
                class="modal-content glass"
                role="dialog"
                tabindex="-1"
                onclick={(e) => e.stopPropagation()}
                onkeydown={() => {}}
            >
                <header class="modal-header">
                    <div class="sheet-handle"></div>
                    <button
                        class="close-btn"
                        onclick={() => (selectedItem = null)}
                        aria-label="Close"
                    >
                        <X size={24} />
                    </button>
                    {#if selectedItem.image_url}
                        <img
                            src={selectedItem.image_url}
                            alt={selectedItem.name}
                            class="modal-image"
                        />
                    {:else}
                        <div class="modal-image-placeholder">
                            <UtensilsCrossed
                                size={48}
                                color="rgba(255,255,255,0.1)"
                            />
                        </div>
                    {/if}
                </header>

                <div class="modal-body">
                    <h2 class="modal-title">{selectedItem.name}</h2>
                    <!-- {#if selectedItem.description}
                        <div class="modal-desc">{selectedItem.description}</div>
                    {/if} -->
                    {#if selectedItem.description}
                        <ul class="modal-desc">
                            {#each selectedItem.description.split(",") as ingredient}
                                <li>{ingredientWithEmoji(ingredient)}</li>
                            {/each}
                        </ul>
                    {/if}
                    <div class="modal-price">{formatPrice(modalPrice)}</div>

                    <div class="modal-sections-divider"></div>

                    <!-- Quantity & Instructions -->
                    <div class="modal-section">
                        <div class="quantity-row">
                            <span class="label" style="margin-bottom: 0;"
                                >Quantity</span
                            >
                            <div class="quantity-controls">
                                <button
                                    class="quantity-btn"
                                    onclick={() =>
                                        (quantity = Math.max(1, quantity - 1))}
                                >
                                    <Minus size={16} />
                                </button>
                                <span class="quantity-value">{quantity}</span>
                                <button
                                    class="quantity-btn"
                                    onclick={() => quantity++}
                                >
                                    <Plus size={16} />
                                </button>
                            </div>
                        </div>

                        <div class="notes-field">
                            <label class="label" for="special-notes"
                                >Special Instructions</label
                            >
                            <textarea
                                id="special-notes"
                                class="input"
                                placeholder="Any special requests?"
                                bind:value={notes}
                                rows="2"
                            ></textarea>
                        </div>
                    </div>

                    <div class="modal-sections-divider"></div>

                    <!-- Options (Size, etc. - Moved to top of body) -->
                    {#if selectedItem.options}
                        <div class="modal-section">
                            {#each selectedItem.options as option}
                                <div class="option-group">
                                    <div class="option-group-title">
                                        <span>{option.name}</span>
                                        {#if option.required}
                                            <span class="option-required"
                                                >Required</span
                                            >
                                        {/if}
                                    </div>
                                    {#each option.choices as choice}
                                        <div
                                            class={cn(
                                                "option-choice",
                                                isChoiceSelected(
                                                    option.name,
                                                    choice.name,
                                                ) && "option-choice-selected",
                                            )}
                                            role="button"
                                            tabindex="0"
                                            onclick={() =>
                                                handleOptionChange(
                                                    option,
                                                    choice.name,
                                                )}
                                            onkeydown={(e) =>
                                                e.key === "Enter" &&
                                                handleOptionChange(
                                                    option,
                                                    choice.name,
                                                )}
                                        >
                                            <span class="option-choice-name">
                                                {#if isChoiceSelected(option.name, choice.name)}
                                                    <Check
                                                        size={14}
                                                        color="var(--color-primary)"
                                                    />
                                                {/if}
                                                {choice.name}
                                            </span>
                                            {#if choice.price_addition > 0}
                                                <span
                                                    class="option-choice-price"
                                                    >+{formatPrice(
                                                        choice.price_addition,
                                                    )}</span
                                                >
                                            {/if}
                                        </div>
                                    {/each}
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>

                <footer class="modal-footer">
                    <button
                        class="btn btn-primary btn-lg add-to-cart-btn"
                        onclick={handleAddToCart}
                    >
                        Add to Cart — {formatPrice(modalPrice * quantity)}
                    </button>
                </footer>
            </div>
        </div>
    {/if}
</div>

<style>
    .menu-page {
        padding: calc(var(--header-height) + var(--space-4)) 0 var(--space-24);
        min-height: 100vh;
    }

    .menu-page-dinein {
        padding-top: calc(var(--header-height) + 32px + var(--space-4));
    }

    /* Controls & Layout Toggle */
    .menu-controls {
        display: flex;
        align-items: center;
        gap: var(--space-4);
        padding: 0 var(--space-4) var(--space-3);
    }

    .menu-controls .search-wrapper {
        flex: 1;
    }

    .layout-toggle {
        display: flex;
        background: var(--color-bg-tertiary);
        padding: 2px;
        border-radius: var(--radius-lg);
        border: 1px solid var(--color-border);
    }

    .toggle-btn {
        width: 36px;
        height: 36px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: var(--radius-md);
        color: var(--color-text-muted);
        transition: all var(--transition-fast);
        background: transparent;
    }

    .toggle-btn.active {
        background: var(--color-bg-secondary);
        color: var(--color-primary);
        box-shadow: var(--shadow-sm);
    }

    .grid-icon {
        width: 14px;
        height: 14px;
        border: 2px solid currentColor;
        display: grid;
        grid-template-columns: 1fr 1fr;
        grid-template-rows: 1fr 1fr;
        gap: 2px;
    }
    .grid-icon::before,
    .grid-icon::after {
        content: "";
        background: currentColor;
    }

    .list-icon {
        width: 14px;
        height: 14px;
        border-top: 2px solid currentColor;
        border-bottom: 2px solid currentColor;
        position: relative;
    }
    .list-icon::before {
        content: "";
        position: absolute;
        left: 0;
        right: 0;
        top: 50%;
        height: 2px;
        background: currentColor;
        transform: translateY(-50%);
    }

    /* Search */
    .search-bar {
        padding: 0 var(--space-4) var(--space-3);
    }

    .search-wrapper {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-full);
        padding: 0 var(--space-4);
        transition: all var(--transition-fast);
    }

    .search-wrapper:focus-within {
        border-color: var(--color-primary);
        box-shadow: 0 0 0 3px rgba(230, 57, 70, 0.15);
    }

    .search-input {
        flex: 1;
        background: none;
        border: none;
        outline: none;
        color: var(--color-text-primary);
        font-size: var(--text-sm);
        padding: var(--space-3) 0;
        min-height: 44px;
    }

    .search-input::placeholder {
        color: var(--color-text-muted);
    }

    /* Category Pills */
    .category-pills {
        position: sticky;
        top: var(--header-height);
        z-index: var(--z-sticky);
        background: rgba(0, 0, 0, 0.85);
        backdrop-filter: blur(20px);
        -webkit-backdrop-filter: blur(20px);
        padding: var(--space-2) 0;
    }

    .category-pills-inner {
        display: flex;
        gap: var(--space-2);
        padding: 0 var(--space-4);
        overflow-x: auto;
        scrollbar-width: none;
    }

    .category-pills-inner::-webkit-scrollbar {
        display: none;
    }

    .pill {
        flex-shrink: 0;
        padding: var(--space-2) var(--space-4);
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-full);
        cursor: pointer;
        transition: all var(--transition-fast);
        white-space: nowrap;
        -webkit-tap-highlight-color: transparent;
    }

    .pill:hover {
        color: var(--color-text-primary);
        border-color: var(--color-border-hover);
    }

    .pill-active {
        color: white !important;
        background: var(--color-primary) !important;
        border-color: var(--color-primary) !important;
    }

    /* Menu Grid & List */
    .menu-items-container {
        flex: 1;
        padding: var(--space-4);
        padding-bottom: 120px;
        position: relative;
    }

    .deals-section {
        margin-bottom: var(--space-8);
    }

    .deals-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: var(--space-4);
    }

    .deals-badge {
        font-size: var(--text-xs);
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.1em;
        padding: 4px 10px;
        background: rgba(230, 57, 70, 0.1);
        color: var(--color-primary);
        border: 1px solid rgba(230, 57, 70, 0.2);
        border-radius: var(--radius-full);
    }

    .deal-card {
        border-color: rgba(230, 57, 70, 0.3) !important;
        background: linear-gradient(
            135deg,
            rgba(230, 57, 70, 0.05),
            rgba(0, 0, 0, 0.2)
        ) !important;
    }

    .deal-img-bg {
        background: linear-gradient(
            135deg,
            var(--color-bg-secondary),
            var(--color-primary-dark)
        );
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .deal-badge {
        background: var(--color-primary);
        color: white;
        font-weight: 900;
        font-size: 14px;
        padding: 6px 14px;
        border-radius: var(--radius-sm);
        transform: rotate(-5deg);
        box-shadow: var(--shadow-md);
        letter-spacing: 0.05em;
        text-transform: uppercase;
    }

    .deal-add-btn {
        background: var(--color-primary) !important;
        border-color: var(--color-primary) !important;
    }

    .section-divider {
        height: 1px;
        background: var(--color-border);
        margin: var(--space-8) 0 var(--space-4);
    }
    .menu-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
        gap: var(--space-3);
    }

    .menu-list {
        display: flex;
        flex-direction: column;
        gap: var(--space-3);
        max-width: 800px;
        margin: 0 auto;
    }

    .menu-grid .menu-card {
        max-width: none;
        justify-self: stretch;
        width: 100%;
    }

    .menu-grid .menu-card-body {
        padding: var(--space-3);
    }

    .menu-grid .menu-card-name {
        font-size: var(--text-sm);
        margin-bottom: 0px;
    }

    .menu-grid .menu-card-desc {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
        font-size: var(--text-xs);
        color: var(--color-text-secondary);
        margin-bottom: var(--space-2);
        line-height: var(--leading-tight);
    }

    .menu-grid .menu-card-price {
        font-size: var(--text-base);
    }

    .menu-grid .add-btn {
        width: 32px;
        height: 32px;
    }

    @media (min-width: 769px) {
        .menu-grid {
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: var(--space-6);
        }
        .menu-grid .menu-card-name {
            font-size: var(--text-base);
            margin-bottom: var(--space-1);
        }
        .menu-grid .menu-card-desc {
            display: -webkit-box;
        }
        .menu-grid .menu-card-price {
            font-size: var(--text-lg);
        }
    }

    .menu-card {
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        overflow: hidden;
        transition: all var(--transition-base);
        cursor: pointer;
        -webkit-tap-highlight-color: transparent;
        display: flex;
        flex-direction: column;
    }

    .menu-list .menu-card {
        flex-direction: row;
        align-items: center;
        height: 100px;
    }

    .menu-card:hover {
        border-color: var(--color-border-hover);
        box-shadow: var(--shadow-lg);
    }

    .menu-card:active {
        transform: scale(0.98);
    }

    .menu-card-image {
        width: 100%;
        aspect-ratio: 16/10;
        object-fit: contain;
        background: white;
    }

    .menu-list .menu-card-image {
        width: 100px;
        height: 100%;
        aspect-ratio: 1/1;
    }

    .menu-card-image-placeholder {
        width: 100%;
        aspect-ratio: 16/10;
        background: linear-gradient(
            135deg,
            var(--color-bg-tertiary),
            var(--color-bg-secondary)
        );
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .menu-list .menu-card-image-placeholder {
        width: 100px;
        height: 100%;
        aspect-ratio: 1/1;
    }

    .menu-card-body {
        padding: var(--space-4);
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .menu-list .menu-card-body {
        padding: var(--space-3) var(--space-4);
        justify-content: center;
    }

    .menu-card-name {
        font-size: var(--text-base);
        font-weight: var(--weight-semibold);
        margin-bottom: var(--space-1);
    }

    .menu-card-desc {
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        line-height: var(--leading-relaxed);
        margin-bottom: var(--space-3);
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    .menu-list .menu-card-desc {
        display: -webkit-box;
        -webkit-line-clamp: 1;
        margin-bottom: var(--space-2);
        font-size: var(--text-xs);
    }

    .menu-card-footer {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-top: auto;
    }

    .menu-list .menu-card-footer {
        margin-top: 0;
    }

    .menu-card-price {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
        color: var(--color-gold);
    }

    .menu-list .menu-card-price {
        font-size: var(--text-base);
    }

    .add-btn {
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        background: linear-gradient(
            135deg,
            var(--color-primary),
            var(--color-primary-dark)
        );
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all var(--transition-base);
        box-shadow: var(--shadow-sm), var(--shadow-glow-primary);
        -webkit-tap-highlight-color: transparent;
    }

    .menu-list .add-btn {
        width: 32px;
        height: 32px;
    }

    .add-btn:active {
        transform: scale(0.9);
    }

    /* Modal — Bottom Sheet */
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: var(--color-bg-overlay);
        backdrop-filter: blur(8px);
        z-index: 1000;
        display: flex;
        align-items: flex-end; /* Bottom sheet align */
        justify-content: center;
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
        border-radius: 22px 22px 0 0;
        overflow: hidden;
        display: flex;
        flex-direction: column;
        border: none;
    }

    @media (min-width: 768px) {
        .modal-content {
            max-width: 480px;
            height: auto;
            max-height: 90vh;
            border-radius: var(--radius-2xl);
            border: 1px solid var(--color-border);
            box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.7);
        }
    }

    /* Header */
    .modal-header {
        position: relative;
        flex-shrink: 0;
        background: var(--color-bg-secondary);
        z-index: 2;
        border-top-left-radius: inherit;
        border-top-right-radius: inherit;
        overflow: hidden;
    }

    .modal-header h2 {
        display: none;
    }

    .sheet-handle {
        position: absolute;
        top: var(--space-3);
        left: 50%;
        transform: translateX(-50%);
        width: 40px;
        height: 4px;
        background: var(--color-text-muted);
        border-radius: var(--radius-full);
        opacity: 0.5;
        z-index: 3;
    }

    .close-btn {
        position: absolute;
        top: var(--space-4);
        right: var(--space-4);
        width: 36px;
        height: 36px;
        border-radius: var(--radius-full);
        background: rgba(0, 0, 0, 0.5);
        backdrop-filter: blur(10px);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 3;
        transition: all var(--transition-fast);
        border: 1px solid rgba(255, 255, 255, 0.1);
    }

    .close-btn:hover {
        background: var(--color-primary);
        transform: rotate(90deg);
        border-color: transparent;
    }

    .modal-image {
        width: 100%;
        aspect-ratio: 16/9;
        object-fit: contain;
        background: white;
    }

    .modal-image-placeholder {
        width: 100%;
        aspect-ratio: 16/9;
        background: linear-gradient(
            135deg,
            var(--color-bg-tertiary),
            var(--color-bg-primary)
        );
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .modal-body {
        padding: var(--space-5);
        overflow-y: auto;
        flex: 1;
        scrollbar-width: none;
    }

    .modal-body::-webkit-scrollbar {
        display: none;
    }

    .modal-section {
        margin-bottom: var(--space-6);
    }

    .modal-sections-divider {
        height: 1px;
        background: var(--color-border);
        margin: var(--space-4) 0;
        opacity: 0.5;
    }

    .modal-title {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: 800;
        color: var(--color-text-primary);
        margin-bottom: var(--space-2);
    }

    .modal-desc {
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        line-height: var(--leading-relaxed);
        margin-bottom: var(--space-2);
    }

    .modal-price {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
        color: var(--color-gold);
        margin-bottom: var(--space-2);
    }

    /* Footer */
    .modal-footer {
        padding: var(--space-4) var(--space-5)
            calc(var(--space-4) + env(safe-area-inset-bottom, 0));
        background: var(--color-bg-secondary);
        border-top: 1px solid var(--color-border);
        flex-shrink: 0;
        z-index: 2;
    }

    .option-group {
        margin-bottom: var(--space-5);
    }

    .option-group-title {
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        margin-bottom: var(--space-3);
        display: flex;
        justify-content: space-between;
    }

    .option-required {
        font-size: var(--text-xs);
        color: var(--color-primary);
    }

    .option-choice {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--space-3) var(--space-4);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-lg);
        margin-bottom: var(--space-2);
        cursor: pointer;
        min-height: 48px;
        transition: all var(--transition-fast);
        -webkit-tap-highlight-color: transparent;
    }

    .option-choice:hover {
        border-color: var(--color-border-hover);
        background: var(--color-bg-glass);
    }

    .option-choice-selected {
        border-color: var(--color-primary) !important;
        background: rgba(230, 57, 70, 0.08) !important;
    }

    .option-choice-name {
        font-size: var(--text-sm);
        display: flex;
        align-items: center;
        gap: var(--space-2);
    }

    .option-choice-price {
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
    }

    .quantity-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: var(--space-4);
    }

    .quantity-controls {
        display: flex;
        align-items: center;
        gap: var(--space-3);
    }

    .quantity-btn {
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-text-primary);
        transition: all var(--transition-fast);
        -webkit-tap-highlight-color: transparent;
    }

    .quantity-btn:active {
        border-color: var(--color-primary);
        background: rgba(230, 57, 70, 0.08);
    }

    .quantity-value {
        font-size: var(--text-lg);
        font-weight: var(--weight-semibold);
        min-width: 32px;
        text-align: center;
    }

    .notes-field {
        margin-bottom: var(--space-2);
    }

    .add-to-cart-btn {
        width: 100%;
    }

    .empty-state {
        text-align: center;
        padding: var(--space-16);
        color: var(--color-text-muted);
    }

    .empty-state :global(svg) {
        margin-bottom: var(--space-4);
        opacity: 0.3;
    }

    .empty-state h3 {
        font-size: var(--text-lg);
        margin-bottom: var(--space-2);
    }

    /* Floating Cart */
    .floating-cart {
        position: fixed;
        bottom: var(--space-4);
        left: var(--space-4);
        right: var(--space-4);
        z-index: var(--z-sticky);
        animation: fadeInUp 0.3s ease-out;
    }

    .floating-cart-btn {
        width: 100%;
    }

    /* Desktop */
    @media (min-width: 769px) {
        .menu-page {
            max-width: var(--container-xl);
            margin: 0 auto;
        }

        .menu-controls {
            padding: 0 var(--space-6) var(--space-4);
        }

        .category-pills-inner {
            padding: 0 var(--space-6);
        }

        .menu-items-container {
            padding: var(--space-4) var(--space-6);
        }

        .menu-grid {
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: var(--space-6);
        }

        .menu-card:hover {
            transform: translateY(-4px);
        }

        .add-btn:hover {
            transform: scale(1.1);
        }

        .modal-overlay {
            align-items: center;
            justify-content: center;
            padding: var(--space-6);
        }

        .modal-sheet {
            max-width: 560px;
            border-radius: var(--radius-2xl);
            animation: scaleIn var(--transition-spring);
            height: 80vh;
        }

        .modal-header-sticky {
            border-top-left-radius: var(--radius-2xl);
            border-top-right-radius: var(--radius-2xl);
        }

        .sheet-handle {
            display: none;
        }

        .floating-cart {
            left: auto;
            right: var(--space-6);
            bottom: var(--space-6);
            max-width: 240px;
        }
    }
</style>
