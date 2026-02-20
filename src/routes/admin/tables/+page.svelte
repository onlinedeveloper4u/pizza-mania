<script lang="ts">
    import { onMount } from 'svelte';
    import { Plus, Edit2, Trash2, QrCode, ToggleLeft, ToggleRight, Download } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import type { Table } from '$lib/types';
    import { toast } from 'svelte-sonner';

    let tables = $state<Table[]>([]);
    let loading = $state(true);
    let showModal = $state(false);
    let showQrModal = $state<Table | null>(null);
    let editingTable = $state<Table | null>(null);
    let form = $state({ table_number: '', seats: '4' });
    const supabase = createClient();

    onMount(() => { fetchTables(); });

    async function fetchTables() {
        loading = true;
        const { data } = await supabase.from('tables').select('*').order('table_number');
        tables = data || [];
        loading = false;
    }

    function openModal(table?: Table) {
        if (table) { editingTable = table; form = { table_number: table.table_number, seats: table.seats.toString() }; }
        else { editingTable = null; form = { table_number: '', seats: '4' }; }
        showModal = true;
    }

    async function saveForm() {
        if (!form.table_number.trim()) { toast.error('Table number required'); return; }
        const seats = parseInt(form.seats) || 4;
        if (editingTable) {
            await supabase.from('tables').update({ table_number: form.table_number, seats }).eq('id', editingTable.id);
            toast.success('Table updated');
        } else {
            await supabase.from('tables').insert({ table_number: form.table_number, seats, is_active: true });
            toast.success('Table created');
        }
        showModal = false;
        fetchTables();
    }

    async function deleteTable(id: string) {
        if (!confirm('Delete this table?')) return;
        await supabase.from('tables').delete().eq('id', id);
        toast.success('Table deleted');
        fetchTables();
    }

    async function toggleActive(table: Table) {
        await supabase.from('tables').update({ is_active: !table.is_active }).eq('id', table.id);
        fetchTables();
    }

    function getTableQrUrl(table: Table): string {
        const appUrl = typeof window !== 'undefined' ? window.location.origin : '';
        return `${appUrl}/table/${table.id}`;
    }
</script>

<svelte:head><title>Tables — Pizza Mania Admin</title></svelte:head>

<div>
    <div class="admin-topbar">
        <h1>Table Management</h1>
        <button class="btn btn-primary" onclick={() => openModal()}>
            <Plus size={16} /> Add Table
        </button>
    </div>

    <div class="tables-grid">
        {#each tables as table}
            <div class="table-card" style="opacity:{table.is_active ? 1 : 0.5}">
                <div class="table-card-number">#{table.table_number}</div>
                <div class="table-card-seats">{table.seats} seats</div>
                <div class="table-card-actions">
                    <button class="btn btn-outline btn-sm" onclick={() => openModal(table)}>
                        <Edit2 size={12} />
                    </button>
                    <button class="btn btn-outline btn-sm" onclick={() => (showQrModal = table)}>
                        <QrCode size={12} />
                    </button>
                    <button class="btn btn-ghost btn-sm" onclick={() => toggleActive(table)}>
                        {#if table.is_active}
                            <ToggleRight size={16} color="var(--color-success)" />
                        {:else}
                            <ToggleLeft size={16} />
                        {/if}
                    </button>
                    <button class="btn btn-ghost btn-sm" style="color:var(--color-danger)" onclick={() => deleteTable(table.id)}>
                        <Trash2 size={12} />
                    </button>
                </div>
            </div>
        {/each}
    </div>
</div>

<!-- Add/Edit Modal -->
{#if showModal}
    <div class="modal" role="dialog" tabindex="-1" onclick={() => (showModal = false)} onkeydown={(e) => e.key === 'Escape' && (showModal = false)}>
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <div class="modal-box" role="document" onclick={(e) => e.stopPropagation()}>
            <h2>{editingTable ? 'Edit Table' : 'Add Table'}</h2>
            <div class="field">
                <label class="label" for="tbl-num">Table Number *</label>
                <input id="tbl-num" class="input" bind:value={form.table_number} />
            </div>
            <div class="field">
                <label class="label" for="tbl-seats">Seats</label>
                <input id="tbl-seats" class="input" type="number" bind:value={form.seats} />
            </div>
            <div class="modal-actions">
                <button class="btn btn-outline" onclick={() => (showModal = false)}>Cancel</button>
                <button class="btn btn-primary" onclick={saveForm}>{editingTable ? 'Update' : 'Create'}</button>
            </div>
        </div>
    </div>
{/if}

<!-- QR Code Modal -->
{#if showQrModal}
    <div class="modal" role="dialog" tabindex="-1" onclick={() => (showQrModal = null)} onkeydown={(e) => e.key === 'Escape' && (showQrModal = null)}>
        <!-- svelte-ignore a11y_click_events_have_key_events -->
        <div class="modal-box" role="document" onclick={(e) => e.stopPropagation()} style="text-align:center">
            <h2>QR Code — Table #{showQrModal.table_number}</h2>
            <p style="color:var(--color-text-secondary);font-size:var(--text-sm);margin-bottom:var(--space-4)">
                Customers scan this to access the dine-in menu.
            </p>
            <div class="qr-wrapper">
                <img
                    src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(getTableQrUrl(showQrModal))}`}
                    alt={`QR Code for Table ${showQrModal.table_number}`}
                    width="200" height="200"
                />
            </div>
            <p style="font-size:var(--text-xs);color:var(--color-text-muted);margin-top:var(--space-2);word-break:break-all">
                {getTableQrUrl(showQrModal)}
            </p>
            <div class="modal-actions" style="justify-content:center">
                <a
                    class="btn btn-primary"
                    href={`https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=${encodeURIComponent(getTableQrUrl(showQrModal))}&format=png`}
                    download={`table-${showQrModal.table_number}-qr.png`}
                    target="_blank"
                >
                    <Download size={16} /> Download QR
                </a>
                <button class="btn btn-outline" onclick={() => (showQrModal = null)}>Close</button>
            </div>
        </div>
    </div>
{/if}

<style>
    .admin-topbar { display:flex; align-items:center; justify-content:space-between; margin-bottom:var(--space-8); }
    .admin-topbar h1 { font-family:var(--font-display); font-size:var(--text-3xl); font-weight:var(--weight-bold); }

    .tables-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(250px,1fr)); gap:var(--space-4); }
    .table-card { background:var(--color-bg-glass); border:1px solid var(--color-border); border-radius:var(--radius-xl); padding:var(--space-6); text-align:center; transition:all var(--transition-fast); }
    .table-card:hover { border-color:var(--color-border-hover); }
    .table-card-number { font-size:var(--text-3xl); font-weight:var(--weight-extrabold); margin-bottom:var(--space-2); }
    .table-card-seats { font-size:var(--text-sm); color:var(--color-text-secondary); margin-bottom:var(--space-4); }
    .table-card-actions { display:flex; gap:var(--space-2); justify-content:center; }

    .modal { position:fixed; inset:0; background:var(--color-bg-overlay); z-index:var(--z-modal); display:flex; align-items:center; justify-content:center; padding:var(--space-6); animation:fadeIn var(--transition-fast); }
    .modal-box { background:var(--color-bg-secondary); border:1px solid var(--color-border); border-radius:var(--radius-2xl); max-width:560px; width:100%; max-height:90vh; overflow-y:auto; padding:var(--space-6); animation:scaleIn var(--transition-spring); }
    .modal-box h2 { font-size:var(--text-xl); font-weight:var(--weight-semibold); margin-bottom:var(--space-6); }
    .modal-actions { display:flex; gap:var(--space-3); justify-content:flex-end; margin-top:var(--space-6); }

    .qr-wrapper { padding:var(--space-4); background:white; border-radius:var(--radius-lg); display:inline-block; margin:var(--space-4) 0; }

    @media (max-width:768px) { .tables-grid { grid-template-columns:1fr; } }
</style>
