<script lang="ts">
    import { X, MapPin, Calendar, Clock } from 'lucide-svelte';
    import { cn } from '$lib/utils';
    import { fade, scale, slide } from 'svelte/transition';
    import { settings } from '$lib/stores/settings';

    let { show = $bindable(false), onConfirm } = $props();

    let pickupTime: 'now' | 'later' = $state('now');
    let selectedDate = $state(new Date().toISOString().split('T')[0]);
    let selectedTime = $state(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false }));

    let dateInput: HTMLInputElement | undefined = $state();
    let timeInput: HTMLInputElement | undefined = $state();

    // Body Scroll Lock
    $effect(() => {
        if (show) {
            const originalStyle = window.getComputedStyle(document.body).overflow;
            document.body.style.overflow = 'hidden';
            return () => {
                document.body.style.overflow = originalStyle;
            };
        }
    });

    function handleStartOrder() {
        onConfirm({
            address: 'Pickup at ' + ($settings?.restaurant_name || 'Pizza Mania'),
            orderMethod: 'pickup',
            type: pickupTime,
            scheduledAt: pickupTime === 'later' ? `${selectedDate} ${selectedTime}` : null
        });
        show = false;
    }
</script>

{#if show}
    <div class="modal-overlay" transition:fade={{ duration: 200 }} role="button" tabindex="-1" onclick={() => show = false} onkeydown={(e) => e.key === 'Escape' && (show = false)}>
        <div class="modal-content glass" transition:scale={{ duration: 300, start: 0.95 }} role="dialog" tabindex="-1" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.key === 'Escape' && (show = false)}>
            <header class="modal-header">
                <h2>Confirm Pickup Info</h2>
                <button class="close-btn" onclick={() => show = false} aria-label="Close">
                    <X size={24} strokeWidth={2} />
                </button>
            </header>

            <div class="modal-body">
                <div class="pickup-info-box">
                    <MapPin size={24} class="pickup-icon" />
                    <div class="pickup-details">
                        <span class="pickup-store-name">{$settings?.restaurant_name || 'Pizza Mania'}</span>
                        <span class="pickup-store-address">{$settings?.address || 'Main Street, City Center'}</span>
                    </div>
                </div>

                <!-- Schedule Section -->
                <div class="form-section time-section">
                    <h3 class="section-title">Schedule Order</h3>
                    
                    <div class="time-radio-group">
                        <label class={cn("time-card", pickupTime === 'now' && "active")}>
                            <input type="radio" name="order-time" value="now" bind:group={pickupTime} />
                            <div class="custom-radio"></div>
                            <div class="time-card-content">
                                <span class="time-primary">Pickup Now</span>
                            </div>
                        </label>

                        <label class={cn("time-card", pickupTime === 'later' && "active")}>
                            <input type="radio" name="order-time" value="later" bind:group={pickupTime} />
                            <div class="custom-radio"></div>
                            <div class="time-card-content">
                                <span class="time-primary">Pickup Later</span>
                            </div>
                        </label>
                    </div>

                    {#if pickupTime === 'later'}
                        <div class="scheduled-picker" transition:slide>
                            <label class="picker-half">
                                <Calendar size={18} class="picker-icon" />
                                <span class="picker-val">{new Date(selectedDate).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })}</span>
                                <input 
                                    bind:this={dateInput}
                                    type="date" 
                                    bind:value={selectedDate} 
                                    min={new Date().toISOString().split('T')[0]} 
                                />
                            </label>
                            <div class="picker-divider"></div>
                            <label class="picker-half">
                                <Clock size={18} class="picker-icon" />
                                <span class="picker-val">{selectedTime}</span>
                                <input 
                                    bind:this={timeInput}
                                    type="time" 
                                    bind:value={selectedTime} 
                                />
                            </label>
                        </div>
                    {/if}
                </div>
            </div>

            <footer class="modal-footer">
                <button class="confirm-order-btn" onclick={handleStartOrder}>
                    <span>START ORDER</span>
                </button>
            </footer>
        </div>
    </div>
{/if}

<style>
    .modal-overlay {
        position: fixed;
        inset: 0;
        background: var(--color-bg-overlay);
        backdrop-filter: blur(8px);
        z-index: var(--z-modal);
        display: flex;
        justify-content: center;
        align-items: center;
        padding: var(--space-4);
        overflow-y: auto;
    }

    .modal-content {
        background: var(--color-bg-secondary);
        width: 100%;
        max-width: 480px;
        max-height: 90vh;
        border-radius: var(--radius-2xl);
        display: flex;
        flex-direction: column;
        border: 1px solid var(--color-border);
        box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.7);
        overflow: hidden;
    }

    .modal-header {
        padding: var(--space-5) var(--space-4) var(--space-2);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .modal-header h2 {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: 800;
        margin: 0;
        color: var(--color-text-primary);
    }

    .close-btn {
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        color: var(--color-text-secondary);
        width: 36px;
        height: 36px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .close-btn:hover {
        background: var(--color-bg-hover);
        color: var(--color-text-primary);
        transform: rotate(90deg);
    }

    .modal-body {
        padding: var(--space-4);
        overflow-y: auto;
        flex: 1;
        scrollbar-width: none;
    }

    .modal-body::-webkit-scrollbar {
        display: none;
    }

    .pickup-info-box {
        display: flex;
        align-items: center;
        gap: var(--space-4);
        padding: var(--space-5);
        background: rgba(230, 57, 70, 0.05);
        border: 1px solid rgba(230, 57, 70, 0.2);
        border-radius: var(--radius-xl);
        margin-bottom: var(--space-6);
        margin-top: var(--space-4);
    }

    .pickup-icon {
        color: var(--color-primary);
    }

    .pickup-details {
        display: flex;
        flex-direction: column;
        gap: var(--space-1);
    }

    .pickup-store-name {
        font-weight: 800;
        font-size: var(--text-base);
        color: var(--color-text-primary);
        text-transform: uppercase;
    }

    .pickup-store-address {
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        font-weight: 500;
    }

    .form-section {
        margin-bottom: var(--space-6);
    }

    .time-section {
        margin-bottom: var(--space-2);
    }

    .section-title {
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        margin-bottom: var(--space-3);
    }

    .time-radio-group {
        display: flex;
        flex-direction: column;
        gap: var(--space-4);
        margin-bottom: var(--space-5);
    }

    .time-card {
        display: flex;
        flex-direction: row;
        align-items: center;
        padding: var(--space-4) var(--space-5);
        background: var(--color-bg-tertiary);
        border: 2px solid var(--color-border);
        border-radius: var(--radius-xl);
        cursor: pointer;
        transition: all var(--transition-base);
        position: relative;
    }

    .time-card input { display: none; }

    .time-card:hover { border-color: var(--color-border-hover); }

    .time-card.active {
        border-color: var(--color-primary);
        background: rgba(255, 0, 0, 0.05);
        box-shadow: var(--shadow-glow-primary);
    }

    .custom-radio {
        width: 22px;
        height: 22px;
        border: 2px solid var(--color-border);
        border-radius: 50%;
        margin-right: var(--space-4);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .active .custom-radio { border-color: var(--color-primary); }

    .active .custom-radio::after {
        content: '';
        width: 12px;
        height: 12px;
        background: var(--color-primary);
        border-radius: 50%;
    }

    .time-card-content {
        display: flex;
        flex-direction: column;
    }

    .time-primary {
        font-weight: 800;
        font-size: var(--text-base);
        display: block;
        margin-bottom: 2px;
    }

    .time-secondary {
        font-size: 13px;
        color: var(--color-text-muted);
        font-weight: 500;
    }

    .scheduled-picker {
        display: flex;
        align-items: center;
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        padding: 4px;
        margin-bottom: var(--space-4);
    }

    .picker-half {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-2);
        padding: var(--space-3);
        cursor: pointer;
        position: relative;
        border-radius: var(--radius-lg);
        transition: background var(--transition-fast);
    }

    .picker-half:hover {
        background: var(--color-bg-hover);
    }

    .picker-half input {
        position: absolute;
        inset: 0;
        opacity: 0;
        cursor: pointer;
    }

    .picker-icon {
        color: var(--color-primary);
    }

    .picker-val {
        font-weight: 600;
        font-size: var(--text-sm);
    }

    .picker-divider {
        width: 1px;
        height: 24px;
        background: var(--color-border);
    }

    .modal-footer {
        padding: 0 var(--space-4) var(--space-4);
    }

    .confirm-order-btn {
        width: 100%;
        background: linear-gradient(135deg, var(--color-primary), var(--color-primary-dark));
        color: white;
        border: none;
        padding: 16px;
        border-radius: var(--radius-xl);
        font-size: 18px;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: var(--shadow-glow-primary);
    }

    .confirm-order-btn:hover:not(:disabled) {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(230, 57, 70, 0.4);
    }

    .confirm-order-btn:active:not(:disabled) {
        transform: translateY(1px);
    }
</style>
