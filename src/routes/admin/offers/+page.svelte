<script lang="ts">
    import { onMount } from "svelte";
    import { settings } from "$lib/stores/settings";
    import { Plus, Edit2, Trash2, Ticket } from "lucide-svelte";
    import { createClient } from "$lib/supabase/client";
    import { formatPrice } from "$lib/utils";
    import { toast } from "svelte-sonner";
    import { goto } from "$app/navigation";

    let deals: any[] = $state([]);
    let loading = $state(true);
    const supabase = createClient();

    onMount(() => {
        fetchData();
    });

    async function fetchData() {
        loading = true;
        const { data, error } = await supabase
            .from("deals")
            .select("*")
            .order("sort_order");

        if (error) {
            console.error(error);
            toast.error("Failed to load deals");
        } else {
            deals = data || [];
        }
        loading = false;
    }

    async function toggleActive(deal: any) {
        const { error } = await supabase
            .from("deals")
            .update({ is_active: !deal.is_active })
            .eq("id", deal.id);

        if (error) toast.error("Update failed");
        else fetchData();
    }

    async function deleteDeal(id: string) {
        if (!confirm("Are you sure you want to delete this deal?")) return;
        const { error } = await supabase.from("deals").delete().eq("id", id);
        if (error) toast.error("Delete failed");
        else {
            toast.success("Deal deleted");
            fetchData();
        }
    }
</script>

<svelte:head
    ><title
        >Offers Management — {$settings?.restaurant_name || "Pizza Mania"} Admin</title
    ></svelte:head
>

<div>
    <div class="admin-topbar">
        <h1>Offers & Deals</h1>
        <a href="/admin/offers/new" class="btn btn-primary">
            <Plus size={16} /> Add New Deal
        </a>
    </div>

    {#if loading}
        <div class="loading-state">Loading deals...</div>
    {:else if deals.length === 0}
        <div class="empty-state">
            <Ticket size={48} color="var(--color-text-muted)" />
            <p>No active deals found. Create one to boost sales!</p>
            <a href="/admin/offers/new" class="btn btn-outline"
                >Create First Deal</a
            >
        </div>
    {:else}
        <div class="deals-grid">
            {#each deals as deal}
                <div
                    class="deal-card"
                    style="opacity:{deal.is_active ? 1 : 0.6}"
                >
                    {#if deal.image_url}
                        <img
                            src={deal.image_url}
                            alt={deal.title}
                            class="deal-img"
                        />
                    {:else}
                        <div class="deal-placeholder">
                            <Ticket size={32} color="rgba(255,255,255,0.2)" />
                        </div>
                    {/if}

                    <div class="deal-content">
                        <div class="deal-header">
                            <h3>{deal.title}</h3>
                            <span class="deal-price"
                                >{formatPrice(deal.price)}</span
                            >
                        </div>
                        <p class="deal-desc">
                            {deal.description || "No description"}
                        </p>

                        <div class="deal-meta">
                            <span class="badge">{deal.type}</span>
                            {#if deal.validity}
                                <span class="validity">{deal.validity}</span>
                            {/if}
                        </div>

                        <div class="deal-actions">
                            <a
                                href="/admin/offers/{deal.id}"
                                class="btn btn-outline btn-sm"
                            >
                                <Edit2 size={14} /> Edit
                            </a>
                            <button
                                class="btn btn-ghost btn-sm"
                                onclick={() => toggleActive(deal)}
                            >
                                {deal.is_active ? "Deactivate" : "Activate"}
                            </button>
                            <button
                                class="btn btn-ghost btn-sm text-danger"
                                onclick={() => deleteDeal(deal.id)}
                            >
                                <Trash2 size={14} />
                            </button>
                        </div>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .admin-topbar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: var(--space-8);
    }
    .admin-topbar h1 {
        font-family: var(--font-display);
        font-size: var(--text-3xl);
        font-weight: var(--weight-bold);
    }

    .loading-state,
    .empty-state {
        padding: var(--space-12);
        text-align: center;
        color: var(--color-text-muted);
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-4);
    }

    .deals-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: var(--space-6);
    }

    .deal-card {
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        transition: transform var(--transition-base);
    }

    .deal-card:hover {
        border-color: var(--color-border-hover);
        transform: translateY(-2px);
    }

    .deal-img {
        width: 100%;
        height: 180px;
        object-fit: contain;
        background: rgba(255, 255, 255, 0.05);
    }

    .deal-placeholder {
        width: 100%;
        height: 180px;
        background: var(--color-bg-tertiary);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .deal-content {
        padding: var(--space-5);
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: var(--space-3);
    }

    .deal-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
    }

    .deal-header h3 {
        font-weight: var(--weight-bold);
        font-size: var(--text-lg);
        margin: 0;
    }

    .deal-price {
        font-weight: var(--weight-bold);
        color: var(--color-primary);
        font-size: var(--text-lg);
    }

    .deal-desc {
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        flex: 1;
    }

    .deal-meta {
        display: flex;
        gap: var(--space-3);
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        align-items: center;
    }

    .badge {
        background: var(--color-bg-tertiary);
        padding: 2px 8px;
        border-radius: var(--radius-sm);
        text-transform: capitalize;
    }

    .deal-actions {
        display: flex;
        gap: var(--space-2);
        margin-top: var(--space-4);
        padding-top: var(--space-4);
        border-top: 1px solid var(--color-border);
    }

    .text-danger {
        color: var(--color-danger);
    }
</style>
