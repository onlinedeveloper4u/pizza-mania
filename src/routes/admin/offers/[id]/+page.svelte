<script lang="ts">
    import { onMount } from 'svelte';
    import { page } from '$app/stores';
    import { goto } from '$app/navigation';
    import { createClient } from '$lib/supabase/client';
    import { ArrowLeft, Save, Plus, Trash2, GripVertical } from 'lucide-svelte';
    import { toast } from 'svelte-sonner';

    const supabase = createClient();
    const dealId = $page.params.id;
    const isNew = dealId === 'new';

    // State
    let loading = $state(true);
    let saving = $state(false);
    let categories = $state<any[]>([]);
    
    // Form Data
    let deal = $state({
        title: '',
        description: '',
        price: 0,
        original_price: null as number | null,
        type: 'delivery', // 'delivery' | 'takeaway' | 'both'
        validity: '',
        image_url: '',
        is_active: true,
        sort_order: 0,
        steps: [] as any[]
    });

    onMount(async () => {
        await Promise.all([fetchCategories(), isNew ? null : fetchDeal()]);
        loading = false;
    });

    async function fetchCategories() {
        const { data } = await supabase.from('categories').select('*').order('sort_order');
        categories = data || [];
    }

    async function fetchDeal() {
        const { data, error } = await supabase.from('deals').select('*').eq('id', dealId).single();
        if (error) {
            toast.error('Deal not found');
            goto('/admin/offers');
        } else {
            deal = data;
             // Ensure steps is array
            if (!Array.isArray(deal.steps)) deal.steps = [];
        }
    }

    // Step Builder Logic
    function addStep() {
        deal.steps = [
            ...deal.steps,
            {
                id: `step_${Date.now()}`,
                title: 'Choose Item',
                category: categories[0]?.name || '', // Default to first category name matching
                required: true
            }
        ];
    }

    function removeStep(index: number) {
        deal.steps = deal.steps.filter((_, i) => i !== index);
    }
    
    function moveStep(index: number, direction: 'up' | 'down') {
        if (direction === 'up' && index > 0) {
            const temp = deal.steps[index];
            deal.steps[index] = deal.steps[index - 1];
            deal.steps[index - 1] = temp;
        } else if (direction === 'down' && index < deal.steps.length - 1) {
            const temp = deal.steps[index];
            deal.steps[index] = deal.steps[index + 1];
            deal.steps[index + 1] = temp;
        }
        // Trigger reactivity
        deal.steps = [...deal.steps];
    }

    async function saveDeal() {
        if (!deal.title) { toast.error('Title is required'); return; }
        
        saving = true;
        
        const payload = { ...deal };
        
        // Auto-generate description from contents if empty? 
        // Or just let user fill it. User fills it.

        let error;
        if (isNew) {
            const { error: err } = await supabase.from('deals').insert(payload);
            error = err;
        } else {
            const { error: err } = await supabase.from('deals').update(payload).eq('id', dealId);
            error = err;
        }

        saving = false;

        if (error) {
            console.error(error);
            toast.error('Failed to save deal');
        } else {
            toast.success('Deal saved successfully');
            goto('/admin/offers');
        }
    }
</script>

<svelte:head><title>{isNew ? 'New Deal' : 'Edit Deal'} — Pizza Mania Admin</title></svelte:head>

<div class="editor-page">
    <header class="editor-header">
        <div class="header-left">
            <a href="/admin/offers" class="btn btn-ghost btn-sm">
                <ArrowLeft size={16} /> Back
            </a>
            <h1>{isNew ? 'Create New Deal' : 'Edit Deal'}</h1>
        </div>
        <button class="btn btn-primary" onclick={saveDeal} disabled={saving}>
            <Save size={16} /> {saving ? 'Saving...' : 'Save Deal'}
        </button>
    </header>

    {#if loading}
        <div class="loading">Loading...</div>
    {:else}
        <div class="editor-grid">
            <!-- Main Details -->
            <div class="card form-section">
                <h2>Basic Details</h2>
                
                <div class="field">
                    <label class="label">Deal Title</label>
                    <input class="input" bind:value={deal.title} placeholder="e.g. Family Feast" />
                </div>

                <div class="grid-2">
                    <div class="field">
                        <label class="label">Price (€)</label>
                        <input class="input" type="number" step="0.01" bind:value={deal.price} />
                    </div>
                    <div class="field">
                        <label class="label">Original/Regular Price (€)</label>
                        <input class="input" type="number" step="0.01" bind:value={deal.original_price} placeholder="Optional" />
                    </div>
                </div>

                <div class="field">
                    <label class="label">Description (Contents)</label>
                    <textarea class="input" rows="2" bind:value={deal.description} placeholder="e.g. 2 Large Pizzas, 1 Drink..."></textarea>
                    <span class="help">This text is displayed on the card to list contents.</span>
                </div>

                <div class="grid-2">
                    <div class="field">
                        <label class="label">Validity Text</label>
                        <input class="input" bind:value={deal.validity} placeholder="e.g. Mon-Fri only" />
                    </div>
                    <div class="field">
                        <label class="label">Order Type</label>
                        <select class="input" bind:value={deal.type}>
                            <option value="delivery">Delivery Only</option>
                            <option value="takeaway">Pickup/Takeaway Only</option>
                            <option value="both">Both (Delivery & Pickup)</option>
                        </select>
                    </div>
                </div>
                
                 <div class="field">
                    <label class="label">Image URL</label>
                    <input class="input" bind:value={deal.image_url} placeholder="/images/..." />
                </div>

                 <div class="field row-field">
                    <input type="checkbox" bind:checked={deal.is_active} id="active" />
                    <label for="active">Active (Visible on website)</label>
                </div>
            </div>

            <!-- Step Builder -->
            <div class="card step-builder">
                <div class="builder-header">
                    <div>
                        <h2>Deal Builder Configuration</h2>
                        <p class="text-muted">Define the steps user takes to customize this deal.</p>
                    </div>
                    <button class="btn btn-outline btn-sm" onclick={addStep}>
                        <Plus size={14} /> Add Step
                    </button>
                </div>

                <div class="steps-list">
                    {#each deal.steps as step, i}
                        <div class="step-card">
                            <div class="step-handle">
                                <span class="step-num">{i + 1}</span>
                                <div class="step-controls">
                                     <button class="btn-icon" onclick={() => moveStep(i, 'up')} disabled={i === 0}>↑</button>
                                     <button class="btn-icon" onclick={() => moveStep(i, 'down')} disabled={i === deal.steps.length - 1}>↓</button>
                                </div>
                            </div>
                            
                            <div class="step-content">
                                <div class="field">
                                    <label class="label-sm">Step Title</label>
                                    <input class="input input-sm" bind:value={step.title} placeholder="e.g. Choose Pizza" />
                                </div>
                                
                                <div class="field">
                                    <label class="label-sm">Linked Category</label>
                                    <select class="input input-sm" bind:value={step.category}>
                                        <option value="">Select Category...</option>
                                        {#each categories as cat}
                                            <option value={cat.name}>{cat.name}</option>
                                            <!-- Note: Storing Name because existing logic uses Name matching. Ideally ID. -->
                                            <!-- But DealModal regex matches name. Let's start with Name. -->
                                        {/each}
                                    </select>
                                </div>

                                <div class="field checkbox-field">
                                    <label class="label-sm">
                                        <input type="checkbox" bind:checked={step.required} /> Required?
                                    </label>
                                </div>
                            </div>

                            <button class="btn btn-ghost text-danger" onclick={() => removeStep(i)}>
                                <Trash2 size={16} />
                            </button>
                        </div>
                    {:else}
                         <div class="empty-steps">
                            No steps defined. Click "Add Step" to configure the wizard.
                         </div>
                    {/each}
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .editor-page { max-width: 1000px; margin: 0 auto; }
    .editor-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-8); }
    .header-left { display: flex; flex-direction: column; gap: var(--space-2); }
    .header-left h1 { font-family: var(--font-display); font-size: var(--text-2xl); font-weight: var(--weight-bold); }
    
    .editor-grid { display: grid; gap: var(--space-6); }
    .card { background: var(--color-bg-glass); border: 1px solid var(--color-border); border-radius: var(--radius-xl); padding: var(--space-6); }
    .card h2 { font-size: var(--text-lg); font-weight: var(--weight-semibold); margin-bottom: var(--space-4); padding-bottom: var(--space-2); border-bottom: 1px solid var(--color-border); }

    .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: var(--space-4); }

    .help { font-size: var(--text-xs); color: var(--color-text-muted); margin-top: 4px; display: block; }
    .text-muted { font-size: var(--text-sm); color: var(--color-text-muted); }

    .row-field { display: flex; align-items: center; gap: var(--space-3); }

    /* Step Builder */
    .builder-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--space-4); }
    
    .steps-list { display: flex; flex-direction: column; gap: var(--space-3); }
    
    .step-card { 
        display: flex; gap: var(--space-4); 
        background: var(--color-bg-tertiary); 
        padding: var(--space-3); 
        border-radius: var(--radius-lg); 
        align-items: flex-start;
        border: 1px solid transparent;
    }
    .step-card:hover { border-color: var(--color-border-hover); }

    .step-handle { display: flex; flex-direction: column; align-items: center; gap: var(--space-2); width: 30px; }
    .step-num { font-weight: bold; color: var(--color-text-muted); }
    
    .step-content { flex: 1; display: grid; grid-template-columns: 2fr 2fr 1fr; gap: var(--space-3); }
    
    .label-sm { font-size: 11px; color: var(--color-text-secondary); display: block; margin-bottom: 2px; }
    .input-sm { font-size: 13px; padding: 6px 10px; }

    .btn-icon { background: none; border: none; font-size: 12px; cursor: pointer; color: var(--color-text-muted); padding: 2px; }
    .btn-icon:hover { color: var(--color-text-primary); }
    .btn-icon:disabled { opacity: 0.3; cursor: default; }

    .checkbox-field { display: flex; align-items: center; height: 100%; padding-top: 14px; }
    
    .empty-steps { text-align: center; padding: var(--space-8); color: var(--color-text-muted); border: 1px dashed var(--color-border); border-radius: var(--radius-lg); }

    @media (max-width: 768px) {
        .step-content { grid-template-columns: 1fr; }
        .grid-2 { grid-template-columns: 1fr; }
    }
</style>
