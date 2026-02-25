<script lang="ts">
    import { Plus, Trash2, ChevronDown, ChevronUp } from 'lucide-svelte';
    import { cn } from '$lib/utils';

    let { options = $bindable([]) } = $props<{ options: any[] }>();

    function addGroup() {
        options = [...options, {
            name: '',
            type: 'single',
            required: true,
            choices: [{ name: '', price_addition: 0 }]
        }];
    }

    function removeGroup(index: number) {
        options = options.filter((_, i) => i !== index);
    }

    function addChoice(groupIndex: number) {
        options[groupIndex].choices = [...options[groupIndex].choices, { name: '', price_addition: 0 }];
    }

    function removeChoice(groupIndex: number, choiceIndex: number) {
        options[groupIndex].choices = options[groupIndex].choices.filter((_: any, i: number) => i !== choiceIndex);
    }

    function moveGroup(index: number, direction: 'up' | 'down') {
        const newIndex = direction === 'up' ? index - 1 : index + 1;
        if (newIndex < 0 || newIndex >= options.length) return;
        const newOptions = [...options];
        [newOptions[index], newOptions[newIndex]] = [newOptions[newIndex], newOptions[index]];
        options = newOptions;
    }
</script>

<div class="options-editor">
    <div class="section-header">
        <h4>Customization Options</h4>
        <button type="button" class="btn btn-ghost btn-sm" onclick={addGroup}>
            <Plus size={14} /> Add Group
        </button>
    </div>

    {#if options.length === 0}
        <div class="empty-state">
            No customization options defined (e.g. sizes, toppings)
        </div>
    {:else}
        <div class="groups-list">
            {#each options as group, gIdx}
                <div class="group-card">
                    <div class="group-header">
                        <div class="group-controls">
                            <button type="button" class="btn btn-ghost btn-xs" onclick={() => moveGroup(gIdx, 'up')} disabled={gIdx === 0}>
                                <ChevronUp size={14} />
                            </button>
                            <button type="button" class="btn btn-ghost btn-xs" onclick={() => moveGroup(gIdx, 'down')} disabled={gIdx === options.length - 1}>
                                <ChevronDown size={14} />
                            </button>
                        </div>
                        <div class="group-main-fields">
                            <input 
                                class="input input-sm" 
                                placeholder="Group Name (e.g. Choose Size)" 
                                bind:value={group.name} 
                            />
                            <select class="input input-sm" bind:value={group.type}>
                                <option value="single">Single Choice</option>
                                <option value="multiple">Multiple Choice</option>
                            </select>
                            <label class="checkbox-label">
                                <input type="checkbox" bind:checked={group.required} />
                                <span>Required</span>
                            </label>
                        </div>
                        <button type="button" class="btn btn-ghost btn-sm text-danger" onclick={() => removeGroup(gIdx)}>
                            <Trash2 size={14} />
                        </button>
                    </div>

                    <div class="choices-list">
                        {#each group.choices as choice, cIdx}
                            <div class="choice-row">
                                <input 
                                    class="input input-sm" 
                                    placeholder="Choice Name" 
                                    bind:value={choice.name} 
                                />
                                <div class="price-input">
                                    <span>+€</span>
                                    <input 
                                        type="number" 
                                        step="0.01" 
                                        class="input input-sm" 
                                        placeholder="0.00" 
                                        bind:value={choice.price_addition} 
                                    />
                                </div>
                                <button type="button" class="btn btn-ghost btn-xs text-danger" onclick={() => removeChoice(gIdx, cIdx)} disabled={group.choices.length <= 1}>
                                    <Trash2 size={24} />
                                </button>
                            </div>
                        {/each}
                        <button type="button" class="btn btn-ghost btn-xs" style="margin-top:var(--space-1)" onclick={() => addChoice(gIdx)}>
                            <Plus size={12} /> Add Choice
                        </button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .options-editor { margin-top: var(--space-4); border-top: 1px solid var(--color-border); padding-top: var(--space-4); }
    .section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: var(--space-3); }
    .section-header h4 { font-size: var(--text-sm); font-weight: var(--weight-bold); color: var(--color-text-secondary); text-transform: uppercase; }
    
    .empty-state { font-size: var(--text-xs); color: var(--color-text-muted); text-align: center; padding: var(--space-4); background: var(--color-bg-tertiary); border-radius: var(--radius-lg); border: 1px dashed var(--color-border); }

    .groups-list { display: flex; flex-direction: column; gap: var(--space-4); }
    .group-card { background: var(--color-bg-tertiary); border: 1px solid var(--color-border); border-radius: var(--radius-lg); padding: var(--space-3); }
    
    .group-header { display: flex; align-items: center; gap: var(--space-2); margin-bottom: var(--space-3); }
    .group-controls { display: flex; flex-direction: column; gap: 0; }
    .group-main-fields { flex: 1; display: flex; align-items: center; gap: var(--space-3); flex-direction: row; }

    @media (max-width: 768px) {
        .group-main-fields {
            flex-direction: column;
            align-items: stretch; /* optional — makes fields full width */
        }
    }
    
    .checkbox-label { display: flex; align-items: center; gap: var(--space-2); font-size: 11px; color: var(--color-text-secondary); cursor: pointer; white-space: nowrap; }
    
    .choices-list { border-left: 2px solid var(--color-border); margin-left: var(--space-4); padding-left: var(--space-4); display: flex; flex-direction: column; gap: var(--space-2); }
    .choice-row { display: flex; align-items: center; gap: var(--space-2); }
    .price-input { display: flex; align-items: center; gap: 4px; font-size: 11px; color: var(--color-text-muted); }
    
    .text-danger { color: var(--color-danger) !important; }
    
    input.input-sm, select.input-sm { height: 32px; font-size: 13px; padding: 0 var(--space-2); }
</style>
