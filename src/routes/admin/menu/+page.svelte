<script lang="ts">
    import { onMount } from 'svelte';
    import { settings } from '$lib/stores/settings';
    import { Plus, Edit2, Trash2, UtensilsCrossed, Pen } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import type { Category, MenuItem } from '$lib/types';
    import { formatPrice, cn } from '$lib/utils';
    import { toast } from 'svelte-sonner';

    import ImageUpload from '$lib/components/ImageUpload.svelte';
    import MenuOptionsEditor from '$lib/components/MenuOptionsEditor.svelte';

    let categories = $state<Category[]>([]);
    let menuItems = $state<MenuItem[]>([]);
    let selectedCategory = $state<string | null>(null);
    let loading = $state(true);
    const supabase = createClient();

    // Modal state
    let showItemModal = $state(false);
    let showCategoryModal = $state(false);
    let editingItem = $state<MenuItem | null>(null);
    let editingCategory = $state<Category | null>(null);

    // Forms
    let itemForm = $state({ name: '', description: '', price: '', category_id: '', is_available: true, is_featured: false, sort_order: 0, image_url: '', options: [] as any[] });
    let categoryForm = $state({ name: '', description: '', sort_order: 0 });

    // Body Scroll Lock
    $effect(() => {
        if (showItemModal || showCategoryModal) {
            const originalStyle = window.getComputedStyle(document.body).overflow;
            document.body.style.overflow = 'hidden';
            return () => {
                document.body.style.overflow = originalStyle;
            };
        }
    });

    onMount(() => { fetchData(); });

    async function fetchData() {
        loading = true;
        const [catRes, itemRes] = await Promise.all([
            supabase.from('categories').select('*').order('sort_order'),
            supabase.from('menu_items').select('*').order('sort_order'),
        ]);
        if (catRes.data) { categories = catRes.data; if (!selectedCategory && catRes.data.length > 0) selectedCategory = catRes.data[0].id; }
        if (itemRes.data) menuItems = itemRes.data;
        loading = false;
    }

    let filteredItems = $derived(selectedCategory ? menuItems.filter(i => i.category_id === selectedCategory) : menuItems);

    // Category CRUD
    function openCategoryModal(cat?: Category) {
        if (cat) { editingCategory = cat; categoryForm = { name: cat.name, description: cat.description || '', sort_order: cat.sort_order }; }
        else { editingCategory = null; categoryForm = { name: '', description: '', sort_order: categories.length }; }
        showCategoryModal = true;
    }

    async function saveCategoryForm() {
        if (!categoryForm.name.trim()) { toast.error('Name is required'); return; }
        if (editingCategory) {
            await supabase.from('categories').update({ name: categoryForm.name, description: categoryForm.description || null, sort_order: categoryForm.sort_order }).eq('id', editingCategory.id);
            toast.success('Category updated');
        } else {
            await supabase.from('categories').insert({ name: categoryForm.name, description: categoryForm.description || null, sort_order: categoryForm.sort_order, is_active: true });
            toast.success('Category created');
        }
        showCategoryModal = false;
        fetchData();
    }

    async function deleteCategory(id: string) {
        if (!confirm('Delete this category? Items will become uncategorized.')) return;
        await supabase.from('categories').delete().eq('id', id);
        toast.success('Category deleted');
        fetchData();
    }

    // Item CRUD
    function openItemModal(item?: MenuItem) {
        if (item) {
            editingItem = item;
            itemForm = { name: item.name, description: item.description || '', price: item.price.toString(), category_id: item.category_id, is_available: item.is_available, is_featured: item.is_featured, sort_order: item.sort_order, image_url: item.image_url || '', options: item.options || [] };
        } else {
            editingItem = null;
            itemForm = { name: '', description: '', price: '', category_id: selectedCategory || '', is_available: true, is_featured: false, sort_order: filteredItems.length, image_url: '', options: [] };
        }
        showItemModal = true;
    }

    async function saveItemForm() {
        if (!itemForm.name.trim()) { toast.error('Name is required'); return; }
        if (!itemForm.price || parseFloat(itemForm.price) <= 0) { toast.error('Valid price required'); return; }
        if (!itemForm.category_id) { toast.error('Category is required'); return; }

        const data = { 
            name: itemForm.name, 
            description: itemForm.description || null, 
            price: parseFloat(itemForm.price), 
            category_id: itemForm.category_id, 
            is_available: itemForm.is_available, 
            is_featured: itemForm.is_featured, 
            sort_order: itemForm.sort_order, 
            image_url: itemForm.image_url || null,
            options: itemForm.options 
        };

        if (editingItem) { await supabase.from('menu_items').update(data).eq('id', editingItem.id); toast.success('Item updated'); }
        else { await supabase.from('menu_items').insert(data); toast.success('Item created'); }
        showItemModal = false;
        fetchData();
    }

    async function deleteItem(id: string) {
        if (!confirm('Delete this menu item?')) return;
        await supabase.from('menu_items').delete().eq('id', id);
        toast.success('Item deleted');
        fetchData();
    }

    async function toggleAvailability(item: MenuItem) {
        await supabase.from('menu_items').update({ is_available: !item.is_available }).eq('id', item.id);
        fetchData();
    }
</script>

<svelte:head><title>Menu Management — {$settings?.restaurant_name || 'Pizza Mania'} Admin</title></svelte:head>

<div class="admin-page-container">
    <div class="admin-topbar">
        <h1>Menu Management</h1>
        <button class="btn btn-primary" onclick={() => openItemModal()}>
            <Plus size={16} /> Add Item
        </button>
    </div>

    <div class="menu-mgmt-grid">
        <!-- Categories sidebar -> Topbar -->
        <div class="category-list">
            <div class="category-list-header">
                <h3>Categories</h3>
                <button class="btn btn-ghost btn-sm" onclick={() => openCategoryModal()}>
                    <Plus size={14} /> Add Category
                </button>
            </div>
            <div class="category-items-scroll">
            {#each categories as cat}
                <div
                    class={cn('category-list-item', selectedCategory === cat.id && 'category-list-item-active')}
                    role="button"
                    tabindex="0"
                    onclick={() => (selectedCategory = cat.id)}
                    onkeydown={(e) => e.key === 'Enter' && (selectedCategory = cat.id)}
                >
                    <span>{cat.name}</span>
                    <div style="display:flex;gap:var(--space-1)">
                        <button class="btn btn-ghost btn-sm" style="padding:4px" onclick={(e) => { e.stopPropagation(); openCategoryModal(cat); }}>
                            <Edit2 size={12} />
                        </button>
                        <button class="btn btn-ghost btn-sm" style="padding:4px;color:var(--color-danger)" onclick={(e) => { e.stopPropagation(); deleteCategory(cat.id); }}>
                            <Trash2 size={12} />
                        </button>
                    </div>
                </div>
            {/each}
            </div>
        </div>

        <!-- Menu Items -->
        <div class="menu-items-list">
            {#each filteredItems as item}
                <div class="menu-item-card" style="opacity:{item.is_available ? 1 : 0.5}">
                    {#if item.image_url}
                        <img src={item.image_url} alt={item.name} class="menu-item-card-img" />
                    {:else}
                        <div class="menu-item-card-placeholder">
                            <UtensilsCrossed size={28} color="rgba(255,255,255,0.1)" />
                        </div>
                    {/if}
                    <div class="menu-item-card-name">{item.name}</div>
                    <div class="menu-item-card-price">{formatPrice(item.price)}</div>
                    <div class="menu-item-card-actions">
                        <button class="btn btn-outline btn-sm" onclick={() => openItemModal(item)}>
                            <Pen size={16} /> Edit
                        </button>
                        <button class="btn btn-ghost btn-sm" onclick={() => toggleAvailability(item)}>
                            {item.is_available ? 'Hide' : 'Show'}
                        </button>
                        <button class="btn btn-ghost btn-sm" style="color:var(--color-danger)" onclick={() => deleteItem(item.id)}>
                            <Trash2 size={12} />
                        </button>
                    </div>
                </div>
            {:else}
                <div style="grid-column:1/-1;text-align:center;padding:var(--space-10);color:var(--color-text-muted)">
                    No items in this category
                </div>
            {/each}
        </div>
    </div>
</div>

<!-- Category Modal -->
{#if showCategoryModal}
    <div class="modal" role="dialog" onclick={() => (showCategoryModal = false)} onkeydown={(e) => e.key === 'Escape' && (showCategoryModal = false)}>
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <div class="modal-box" onclick={(e) => e.stopPropagation()}>
            <h2>{editingCategory ? 'Edit Category' : 'Add Category'}</h2>
            <div class="field">
                <label class="label" for="cat-name">Name *</label>
                <input id="cat-name" class="input" bind:value={categoryForm.name} />
            </div>
            <div class="field">
                <label class="label" for="cat-desc">Description</label>
                <input id="cat-desc" class="input" bind:value={categoryForm.description} />
            </div>
            <div class="field">
                <label class="label" for="cat-sort">Sort Order</label>
                <input id="cat-sort" class="input" type="number" bind:value={categoryForm.sort_order} />
            </div>
            <div class="modal-actions">
                <button class="btn btn-outline" onclick={() => (showCategoryModal = false)}>Cancel</button>
                <button class="btn btn-primary" onclick={saveCategoryForm}>{editingCategory ? 'Update' : 'Create'}</button>
            </div>
        </div>
    </div>
{/if}

<!-- Item Modal -->
{#if showItemModal}
    <div class="modal" role="dialog" onclick={() => (showItemModal = false)} onkeydown={(e) => e.key === 'Escape' && (showItemModal = false)}>
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <div class="modal-box" onclick={(e) => e.stopPropagation()}>
            <h2>{editingItem ? 'Edit Item' : 'Add Item'}</h2>
            
            <ImageUpload bind:value={itemForm.image_url} label="Menu Item Image" path="menu-items" />

            <div class="field">
                <label class="label" for="item-name">Name *</label>
                <input id="item-name" class="input" bind:value={itemForm.name} />
            </div>
            <div class="field">
                <label class="label" for="item-desc">Description</label>
                <textarea id="item-desc" class="input" rows="2" bind:value={itemForm.description}></textarea>
            </div>
            <div class="field">
                <label class="label" for="item-price">Price (€) *</label>
                <input id="item-price" class="input" type="number" step="0.01" bind:value={itemForm.price} />
            </div>
            <div class="field">
                <label class="label" for="item-cat">Category *</label>
                <select id="item-cat" class="input" bind:value={itemForm.category_id}>
                    <option value="">Select category</option>
                    {#each categories as cat}
                        <option value={cat.id}>{cat.name}</option>
                    {/each}
                </select>
            </div>
            <div style="display:flex;gap:var(--space-6);margin-top:var(--space-4)">
                <label style="display:flex;align-items:center;gap:var(--space-2);cursor:pointer">
                    <input type="checkbox" bind:checked={itemForm.is_available} /> Available
                </label>
                <label style="display:flex;align-items:center;gap:var(--space-2);cursor:pointer">
                    <input type="checkbox" bind:checked={itemForm.is_featured} /> Featured
                </label>
            </div>

            <MenuOptionsEditor bind:options={itemForm.options} />

            <div class="modal-actions">
                <button class="btn btn-outline" onclick={() => (showItemModal = false)}>Cancel</button>
                <button class="btn btn-primary" onclick={saveItemForm}>{editingItem ? 'Update' : 'Create'}</button>
            </div>
        </div>
    </div>
{/if}

<style>
    .admin-page-container {
        width: 100%;
        max-width: 100%;
        overflow-x: hidden;
    }

    .admin-topbar { display:flex; align-items:center; justify-content:space-between; margin-bottom:var(--space-8); }
    .admin-topbar h1 { font-family:var(--font-display); font-size:var(--text-3xl); font-weight:var(--weight-bold); }

    .menu-mgmt-grid { display:flex; flex-direction:column; gap:var(--space-6); min-width: 0; }

    .category-list { background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); overflow:hidden; min-width: 0; }
    .category-list-header { display:flex; align-items:center; justify-content:space-between; padding:var(--space-3) var(--space-4); border-bottom:1px solid var(--color-border); }
    .category-list-header h3 { font-size:var(--text-md); font-weight:var(--weight-semibold); }
    
    .category-items-scroll { display:flex; flex-wrap:nowrap; overflow-x:auto; padding:var(--space-4); gap:var(--space-3); scrollbar-width:thin; width:100%; box-sizing:border-box; }
    .category-items-scroll::-webkit-scrollbar { height:6px; }
    .category-items-scroll::-webkit-scrollbar-track { background:transparent; }
    .category-items-scroll::-webkit-scrollbar-thumb { background:var(--color-border); border-radius:3px; }
    
    .category-list-item { display:flex; align-items:center; gap:var(--space-3); padding:var(--space-2) var(--space-4); border:1px solid var(--color-border); border-radius:var(--radius-full); cursor:pointer; transition:all var(--transition-fast); white-space:nowrap; flex-shrink:0; }
    .category-list-item:hover { background:var(--color-bg-glass); border-color:var(--color-border-hover); }
    .category-list-item-active { background:rgba(230,57,70,0.08) !important; color:var(--color-primary); border-color:var(--color-primary); }

    .menu-items-list { display:grid; grid-template-columns:repeat(auto-fill,minmax(210px,1fr)); gap:var(--space-4); min-width: 0; }
    .menu-item-card { background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); padding:var(--space-4); transition:all var(--transition-fast); display:flex; flex-direction:column; }
    .menu-item-card:hover { border-color:var(--color-border-hover); }
    .menu-item-card-img { width:100%; aspect-ratio:16/9; border-radius:var(--radius-md); object-fit:contain; margin-bottom:var(--space-3); background:white; }
    .menu-item-card-placeholder { width:100%; aspect-ratio:16/9; border-radius:var(--radius-md); background:var(--color-bg-tertiary); display:flex; align-items:center; justify-content:center; margin-bottom:var(--space-3); }
    .menu-item-card-name { font-weight:var(--weight-semibold); margin-bottom:var(--space-1); }
    .menu-item-card-price { color:var(--color-primary); font-weight:var(--weight-bold); margin-bottom:var(--space-3); }
    .menu-item-card-actions { display:flex; gap:var(--space-2); }

    .modal { position:fixed; inset:0; background:var(--color-bg-overlay); z-index:var(--z-modal); display:flex; align-items:center; justify-content:center; padding:var(--space-6); animation:fadeIn var(--transition-fast); }
    .modal-box { background:var(--color-bg-secondary); border:1px solid var(--color-border); border-radius:var(--radius-2xl); max-width:560px; width:100%; max-height:90vh; overflow-y:auto; padding:var(--space-6); animation:scaleIn var(--transition-spring); }
    .modal-box h2 { font-size:var(--text-xl); font-weight:var(--weight-semibold); margin-bottom:var(--space-6); }
    .modal-actions { display:flex; gap:var(--space-3); justify-content:flex-end; margin-top:var(--space-6); }

    @media (max-width:1024px) { 
        .menu-items-list { grid-template-columns:1fr; }
    }
</style>
