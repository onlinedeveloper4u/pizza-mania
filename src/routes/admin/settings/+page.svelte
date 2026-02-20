<script lang="ts">
    import { onMount } from 'svelte';
    import { Save, Loader2, Clock, MapPin, Phone, Mail, Euro, Store } from 'lucide-svelte';
    import { createClient } from '$lib/supabase/client';
    import { toast } from 'svelte-sonner';
    import ImageUpload from '$lib/components/ImageUpload.svelte';

    let loading = $state(true);
    let saving = $state(false);
    let settings = $state({
        restaurant_name: '',
        address: '',
        phone: '',
        email: '',
        delivery_fee: 0,
        avg_prep_minutes: 30,
        accepting_orders: true,
        currency: 'EUR',
        operating_hours: {
            monday: { open: '11:00', close: '22:00', closed: false },
            tuesday: { open: '11:00', close: '22:00', closed: false },
            wednesday: { open: '11:00', close: '22:00', closed: false },
            thursday: { open: '11:00', close: '22:00', closed: false },
            friday: { open: '11:00', close: '23:00', closed: false },
            saturday: { open: '11:00', close: '23:00', closed: false },
            sunday: { open: '12:00', close: '21:00', closed: false }
        },
        logo_url: ''
    });

    const supabase = createClient();

    onMount(async () => {
        const { data, error } = await supabase.from('restaurant_settings').select('*').single();
        if (data) {
            // Merge defaults with DB data to ensure all days exist
            settings = { ...settings, ...data };
            // Ensure closed property exists for each day
            Object.keys(settings.operating_hours).forEach(day => {
                const h = (settings.operating_hours as any)[day];
                if (h.closed === undefined) h.closed = false;
            });
        }
        loading = false;
    });

    async function handleSave() {
        saving = true;
        try {
            // Remove id from the spread if it doesn't exist to avoid empty string/null issues if any,
            // though upsert usually handles it. But let's be safe.
            const { error } = await supabase
                .from('restaurant_settings')
                .upsert(settings)
                .select();
            
            if (error) throw error;
            toast.success('Settings updated successfully');
        } catch (err) {
            console.error(err);
            toast.error('Failed to update settings');
        } finally {
            saving = false;
        }
    }

    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
</script>

<svelte:head><title>Restaurant Settings — {settings.restaurant_name || 'Pizza Mania'} Admin</title></svelte:head>

<div class="settings-container">
    <div class="admin-topbar">
        <h1>Restaurant Settings</h1>
        <button class="btn btn-primary" onclick={handleSave} disabled={saving}>
            {#if saving}
                <Loader2 size={16} class="animate-spin" />
            {:else}
                <Save size={16} />
            {/if}
            Save Changes
        </button>
    </div>

    {#if loading}
        <div class="loading-state">
            <Loader2 size={32} class="animate-spin" />
            <span>Loading settings...</span>
        </div>
    {:else}
        <div class="settings-grid">
            <div class="settings-section card">
                <h3><Store size={18} /> General Information</h3>
                
                <div style="margin-bottom:var(--space-6)">
                    <ImageUpload 
                        bind:value={settings.logo_url} 
                        label="Restaurant Logo" 
                        path="branding" 
                    />
                </div>

                <div class="form-group">
                    <label for="res-name">Restaurant Name</label>
                    <input id="res-name" class="input" bind:value={settings.restaurant_name} />
                </div>
                <div class="form-group">
                    <label for="res-addr"><MapPin size={14} /> Address</label>
                    <textarea id="res-addr" class="input" rows="2" bind:value={settings.address}></textarea>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label for="res-phone"><Phone size={14} /> Phone</label>
                        <input id="res-phone" class="input" bind:value={settings.phone} />
                    </div>
                    <div class="form-group">
                        <label for="res-email"><Mail size={14} /> Email</label>
                        <input id="res-email" class="input" type="email" bind:value={settings.email} />
                    </div>
                </div>
            </div>

            <div class="settings-section card">
                <h3><Clock size={18} /> Operating Hours</h3>
                <div class="hours-list">
                    {#each days as day}
                        {@const dayHours = (settings.operating_hours as any)[day]}
                        <div class="hour-row" class:is-closed={dayHours.closed}>
                            <div class="day-name">{day.charAt(0).toUpperCase() + day.slice(1)}</div>
                            <div class="hour-inputs">
                                {#if !dayHours.closed}
                                    <input type="time" class="input input-sm" bind:value={dayHours.open} />
                                    <span>to</span>
                                    <input type="time" class="input input-sm" bind:value={dayHours.close} />
                                {:else}
                                    <span class="closed-label">Closed</span>
                                {/if}
                            </div>
                            <label class="toggle-closed">
                                <input type="checkbox" bind:checked={dayHours.closed} />
                                <span>Closed</span>
                            </label>
                        </div>
                    {/each}
                </div>
            </div>

            <div class="settings-section card">
                <h3><Euro size={18} /> Delivery & Operations</h3>
                <div class="form-row">
                    <div class="form-group">
                        <label for="res-delivery">Delivery Fee (€)</label>
                        <input id="res-delivery" class="input" type="number" step="0.01" bind:value={settings.delivery_fee} />
                    </div>
                    <div class="form-group">
                        <label for="res-prep">Avg. Prep Time (mins)</label>
                        <input id="res-prep" class="input" type="number" bind:value={settings.avg_prep_minutes} />
                    </div>
                </div>
                <div class="form-group" style="margin-top:var(--space-4)">
                    <label class="checkbox-label">
                        <input type="checkbox" bind:checked={settings.accepting_orders} />
                        <span>Currently accepting orders</span>
                    </label>
                    <p class="help-text">Directly controls if customers can place new orders on the website.</p>
                </div>
                <div class="form-group">
                    <label for="res-curr">Currency Code</label>
                    <input id="res-curr" class="input" bind:value={settings.currency} placeholder="EUR" />
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .settings-container { max-width: 1000px; margin: 0 auto; }
    .admin-topbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: var(--space-8); }
    .admin-topbar h1 { font-family: var(--font-display); font-size: var(--text-3xl); font-weight: var(--weight-bold); }

    .settings-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: var(--space-6); }
    .settings-grid > :first-child { grid-column: 1 / -1; }

    .card { background: var(--color-bg-glass); border: 1px solid var(--color-border); border-radius: var(--radius-xl); padding: var(--space-6); }
    .settings-section h3 { display: flex; align-items: center; gap: var(--space-2); font-size: var(--text-lg); font-weight: var(--weight-semibold); margin-bottom: var(--space-6); color: var(--color-primary); }

    .form-group { margin-bottom: var(--space-4); }
    .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: var(--space-4); }
    .label, label { display: block; font-size: var(--text-xs); font-weight: var(--weight-semibold); color: var(--color-text-secondary); text-transform: uppercase; margin-bottom: var(--space-2); display: flex; align-items: center; gap: 4px; }

    .hours-list { display: flex; flex-direction: column; gap: var(--space-2); }
    .hour-row { display: flex; align-items: center; justify-content: space-between; padding: var(--space-2) var(--space-4); background: var(--color-bg-tertiary); border-radius: var(--radius-lg); border: 1px solid var(--color-border); transition: all 0.2s; }
    .hour-row.is-closed { opacity: 0.6; background: rgba(0,0,0,0.2); }
    .day-name { font-weight: var(--weight-semibold); width: 100px; }
    .hour-inputs { flex: 1; display: flex; align-items: center; gap: var(--space-2); justify-content: center; }
    .hour-inputs span { font-size: var(--text-xs); color: var(--color-text-muted); }
    .closed-label { color: var(--color-danger); font-weight: var(--weight-bold); font-size: var(--text-xs); text-transform: uppercase; letter-spacing: 0.05em; }
    .toggle-closed { cursor: pointer; display: flex; align-items: center; gap: var(--space-2); font-size: 11px !important; margin: 0 !important; }

    .checkbox-label { display: flex !important; align-items: center; gap: var(--space-3); cursor: pointer; font-size: var(--text-sm) !important; color: var(--color-text-primary) !important; }
    .checkbox-label input { width: 18px; height: 18px; accent-color: var(--color-primary); }
    .help-text { font-size: var(--text-xs); color: var(--color-text-muted); margin-top: 4px; }

    .loading-state { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: var(--space-20); gap: var(--space-4); color: var(--color-text-muted); }

    @media (max-width: 768px) {
        .settings-grid { grid-template-columns: 1fr; }
        .form-row { grid-template-columns: 1fr; }
        .hour-row { flex-direction: column; gap: var(--space-3); padding: var(--space-4); }
        .day-name { width: 100%; text-align: center; }
    }
</style>
