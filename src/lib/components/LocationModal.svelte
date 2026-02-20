<script lang="ts">
    import { X, MapPin, Navigation, Calendar, Clock, ChevronRight, Search, LocateFixed, Loader2 } from 'lucide-svelte';
    import { cn } from '$lib/utils';
    import { fade, scale, slide } from 'svelte/transition';
    import { createClient } from '$lib/supabase/client';
    import { PUBLIC_GOOGLE_MAPS_API_KEY } from '$env/static/public';

    let { show = $bindable(false), onConfirm } = $props();

    let address = $state('');
    let searchResults = $state<{ title: string, subtitle: string, placeId?: string }[]>([]);
    let isSearching = $state(false);
    let showResults = $state(false);
    let deliveryTime: 'now' | 'later' = $state('now');
    let selectedDate = $state(new Date().toISOString().split('T')[0]);
    let selectedTime = $state(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false }));
    
    let isLocating = $state(false);
    let mapMoved = $state(false);
    let searchTimeout: any;
    
    let dateInput: HTMLInputElement;
    let timeInput: HTMLInputElement;
    
    let googleMapsLoaded = $state(false);
    let placesLibrary: any;
    let geocoder: any;

    async function loadGoogleMaps() {
        if (window.google?.maps?.importLibrary) {
            initServices();
            return;
        }

        // Modern loading pattern (Bootstrap)
        const script = document.createElement('script');
        script.src = `https://maps.googleapis.com/maps/api/js?key=${PUBLIC_GOOGLE_MAPS_API_KEY}&loading=async&v=weekly`;
        script.async = true;
        script.onload = () => initServices();
        document.head.appendChild(script);
    }

    async function initServices() {
        try {
            // @ts-ignore
            placesLibrary = await google.maps.importLibrary("places");
            // @ts-ignore
            const { Geocoder } = await google.maps.importLibrary("geocoding");
            geocoder = new Geocoder();
            googleMapsLoaded = true;
        } catch (err) {
            console.error("Failed to load Google Maps libraries:", err);
        }
    }

    $effect(() => {
        if (show && !googleMapsLoaded) {
            loadGoogleMaps();
        }
    });

    async function performSearch(query: string) {
        if (query.length < 3 || !placesLibrary) {
            searchResults = [];
            return;
        }

        isSearching = true;
        try {
            // Using the modern AutocompleteSuggestion (Places API New)
            // If the user has "Places API (New)" enabled, this is the way.
            const { AutocompleteSessionToken, AutocompleteSuggestion } = placesLibrary;
            const token = new AutocompleteSessionToken();
            
            // Note: AutocompleteSuggestion is the recommended replacement for AutocompleteService
            // However, it might require a slightly different call or using the Place class.
            // Let's try the modern Place.getAutocompletePredictions if available, 
            // otherwise fallback to AutocompleteService (which still works for old projects).
            
            if (placesLibrary.AutocompleteService) {
                const service = new placesLibrary.AutocompleteService();
                service.getPlacePredictions(
                    { input: query, types: ['address'] },
                    (predictions: any, status: any) => {
                        if (status === 'OK' && predictions) {
                            searchResults = predictions.map((p: any) => ({
                                title: p.structured_formatting.main_text,
                                subtitle: p.structured_formatting.secondary_text,
                                placeId: p.place_id
                            }));
                        } else {
                            searchResults = [];
                        }
                        isSearching = false;
                    }
                );
            }
        } catch (err) {
            console.error("Search failed:", err);
            isSearching = false;
        }
    }

    function handleInput(e: Event) {
        const value = (e.target as HTMLInputElement).value;
        address = value;
        showResults = true;
        
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => performSearch(value), 400);
    }

    function selectAddress(res: { title: string, subtitle: string }) {
        address = res.title + (res.subtitle ? `, ${res.subtitle}` : '');
        showResults = false;
        mapMoved = true;
    }

    async function handleLocateMe() {
        if (!navigator.geolocation) {
            console.error("Geolocation is not supported");
            return;
        }

        isLocating = true;
        navigator.geolocation.getCurrentPosition(
            async (pos) => {
                const { latitude, longitude } = pos.coords;
                
                if (geocoder) {
                    geocoder.geocode({ location: { lat: latitude, lng: longitude } }, (results: any, status: any) => {
                        if (status === 'OK' && results[0]) {
                            address = results[0].formatted_address;
                            mapMoved = true;
                        } else {
                            address = "Current Location Detected";
                            mapMoved = true;
                        }
                        isLocating = false;
                        showResults = false;
                    });
                } else {
                    // Fallback to coordinates if geocoder failed or not loaded
                    address = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
                    mapMoved = true;
                    isLocating = false;
                    showResults = false;
                }
            },
            (err) => {
                isLocating = false;
                console.error("Geolocation error:", err);
            },
            { timeout: 10000 }
        );
    }

    function handleStartOrder() {
        if (!address.trim()) return;
        onConfirm({
            address,
            type: deliveryTime,
            scheduledAt: deliveryTime === 'later' ? `${selectedDate} ${selectedTime}` : null
        });
        show = false;
    }
</script>

{#if show}
    <div class="modal-overlay" transition:fade={{ duration: 200 }} role="button" tabindex="-1" onclick={() => show = false} onkeydown={(e) => e.key === 'Escape' && (show = false)}>
        <div class="modal-content glass" transition:scale={{ duration: 300, start: 0.95 }} role="dialog" tabindex="-1" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.key === 'Escape' && (show = false)}>
            <header class="modal-header">
                <h2>Confirm Your Location</h2>
                <button class="close-btn" onclick={() => show = false} aria-label="Close">
                    <X size={24} strokeWidth={2} />
                </button>
            </header>

            <div class="modal-body">
                <!-- Address Section -->
                <div class="form-section">
                    <label class="input-label" for="address-input">Enter Delivery Address</label>
                    <div class="search-wrapper">
                        <div class="input-container">
                            <input 
                                id="address-input"
                                type="text" 
                                class="main-address-input" 
                                placeholder="Street, number, area..." 
                                value={address}
                                oninput={handleInput}
                                onfocus={() => showResults = true}
                            />
                            {#if isSearching}
                                <div class="loading-icon animate-spin">
                                    <Loader2 size={18} />
                                </div>
                            {/if}
                            {#if address.length > 0 && !isSearching}
                                <button class="clear-input" onclick={() => { address = ''; searchResults = []; }} aria-label="Clear">
                                    <X size={20} strokeWidth={2.5} />
                                </button>
                            {/if}
                        </div>

                        {#if showResults && searchResults.length > 0}
                            <div class="search-dropdown-overlay" onclick={() => showResults = false} role="presentation"></div>
                            <div class="search-dropdown" transition:slide>
                                {#each searchResults as res}
                                    <button class="search-item" onclick={() => selectAddress(res)}>
                                        <div class="item-icon-box">
                                            <MapPin size={16} />
                                        </div>
                                        <div class="item-content">
                                            <div class="item-title">{res.title}</div>
                                            <div class="item-subtitle">{res.subtitle}</div>
                                        </div>
                                    </button>
                                {/each}
                            </div>
                        {/if}
                    </div>
                </div>

                <!-- Map Section (Domino's Layout + Dark Theme) -->
                <div class="map-area">
                    <div class="map-graphic">
                        <div class="map-grid" aria-hidden="true"></div>
                        
                        <!-- Floating Controls -->
                        <div class="map-controls">
                            <button class="map-locate-btn" onclick={handleLocateMe} disabled={isLocating}>
                                <div class="btn-content">
                                    {#if isLocating}
                                        <Loader2 size={18} class="animate-spin" />
                                        <span>Locating...</span>
                                    {:else}
                                        <LocateFixed size={18} />
                                        <span>Locate me</span>
                                    {/if}
                                </div>
                            </button>
                            <div class="map-store-badge">
                                STORE: JUMET CENTRE
                            </div>
                        </div>

                        <!-- Central Marker -->
                        <div class="marker-container" style={mapMoved ? 'transform: translate(-50%, -65%)' : ''}>
                            <div class="marker-pin-wrapper">
                                <div class="marker-tooltip" transition:fade>
                                    <div class="tooltip-text">Confirm your location</div>
                                    <div class="tooltip-arrow"></div>
                                </div>
                                <div class="marker-pin">
                                    <MapPin size={36} strokeWidth={3} />
                                    <div class="marker-pulse"></div>
                                </div>
                            </div>
                        </div>

                        <!-- Map Footer Hint -->
                        <div class="map-footer-hint">
                            <Navigation size={12} />
                            <span>Drag the pin to adjust</span>
                        </div>
                    </div>
                </div>

                <!-- Delivery Option Section -->
                <div class="form-section time-section">
                    <h3 class="section-title">Schedule Order</h3>
                    
                    <div class="time-radio-group">
                        <label class={cn("time-card", deliveryTime === 'now' && "active")}>
                            <input type="radio" name="order-time" value="now" bind:group={deliveryTime} />
                            <div class="custom-radio"></div>
                            <div class="time-card-content">
                                <span class="time-primary">Deliver Now</span>
                                <span class="time-secondary">ASAP • 35-45 mins</span>
                            </div>
                        </label>

                        <label class={cn("time-card", deliveryTime === 'later' && "active")}>
                            <input type="radio" name="order-time" value="later" bind:group={deliveryTime} />
                            <div class="custom-radio"></div>
                            <div class="time-card-content">
                                <span class="time-primary">Deliver Later</span>
                                <span class="time-secondary">Schedule for later</span>
                            </div>
                        </label>
                    </div>

                    {#if deliveryTime === 'later'}
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
                <button class="confirm-order-btn" onclick={handleStartOrder} disabled={!address.trim()}>
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
        z-index: 1000;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: var(--space-4);
    }

    .modal-content {
        background: var(--color-bg-secondary);
        color: var(--color-text-primary);
        width: 100%;
        max-width: 480px;
        border-radius: var(--radius-2xl);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        border: 1px solid var(--color-border);
        box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.7);
    }

    .modal-header {
        padding: var(--space-6) var(--space-6) var(--space-4);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .modal-header h2 {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: 800;
        letter-spacing: -0.01em;
    }

    .close-btn {
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        color: var(--color-text-secondary);
        cursor: pointer;
        padding: var(--space-2);
        border-radius: var(--radius-full);
        transition: all var(--transition-fast);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .close-btn:hover {
        background: var(--color-primary);
        color: white;
        transform: rotate(90deg);
    }

    .modal-body {
        padding: 0 var(--space-6) var(--space-6);
        max-height: 80vh;
        overflow-y: auto;
    }

    .form-section {
        margin-bottom: var(--space-6);
    }

    .input-label {
        display: block;
        font-weight: 700;
        font-size: var(--text-sm);
        color: var(--color-text-secondary);
        margin-bottom: var(--space-2);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .search-wrapper {
        position: relative;
        z-index: 50;
    }

    .input-container {
        position: relative;
        display: flex;
        align-items: center;
        background: var(--color-bg-tertiary);
        border: 2px solid var(--color-border);
        border-radius: var(--radius-xl);
        transition: all var(--transition-base);
    }

    .input-container:focus-within {
        border-color: var(--color-primary);
        box-shadow: var(--shadow-glow-primary);
    }

    .main-address-input {
        width: 100%;
        border: none;
        background: none;
        padding: var(--space-4);
        padding-right: var(--space-10);
        font-size: 16px;
        font-weight: 600;
        color: var(--color-text-primary);
        outline: none;
    }

    .loading-icon, .clear-input {
        position: absolute;
        right: var(--space-3);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .clear-input {
        color: var(--color-primary);
        background: none;
        cursor: pointer;
        transition: transform 0.2s;
        padding: 4px;
    }

    .clear-input:hover {
        transform: scale(1.1);
    }

    .loading-icon {
        color: var(--color-text-muted);
    }

    /* Map Graphic Refinement */
    .map-area {
        margin-bottom: var(--space-6);
        border-radius: var(--radius-2xl);
        overflow: hidden;
        border: 1px solid var(--color-border);
        background: #000;
    }

    .map-graphic {
        position: relative;
        height: 240px;
        background: radial-gradient(circle at center, #1a1a1a 0%, #000000 100%);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .map-grid {
        position: absolute;
        inset: 0;
        background-color: transparent;
        opacity: 0.1;
        background-image: 
            linear-gradient(rgba(255,255,255,0.2) 1px, transparent 1px), 
            linear-gradient(90deg, rgba(255,255,255,0.2) 1px, transparent 1px);
        background-size: 40px 40px;
    }

    .map-controls {
        position: absolute;
        top: var(--space-4);
        left: 0;
        right: 0;
        padding: 0 var(--space-4);
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-2);
        z-index: 20;
    }

    .map-locate-btn {
        background: var(--color-primary);
        color: white;
        border: none;
        padding: 8px 18px;
        border-radius: var(--radius-full);
        font-weight: 700;
        font-size: var(--text-sm);
        cursor: pointer;
        transition: all var(--transition-base);
        box-shadow: var(--shadow-glow-primary);
        pointer-events: auto;
    }

    .map-locate-btn:hover {
        transform: translateY(-2px);
        background: var(--color-primary-dark);
        box-shadow: 0 0 30px rgba(255, 0, 0, 0.4);
    }

    .map-locate-btn:disabled {
        opacity: 0.8;
        cursor: wait;
    }

    .map-store-badge {
        background: var(--color-bg-tertiary);
        color: var(--color-amber);
        padding: 4px 12px;
        font-weight: 800;
        font-size: 11px;
        border-radius: var(--radius-full);
        border: 1px solid var(--color-border);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    /* Marker Refinement */
    .marker-container {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 10;
        transition: transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1);
    }

    .marker-pin-wrapper {
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .marker-tooltip {
        background: rgba(0, 0, 0, 0.9);
        backdrop-filter: blur(4px);
        color: white;
        padding: 8px 14px;
        border-radius: var(--radius-lg);
        font-size: 13px;
        font-weight: 600;
        white-space: nowrap;
        position: relative;
        margin-bottom: 10px;
        border: 1px solid var(--color-border);
        box-shadow: 0 10px 25px rgba(0,0,0,0.5);
    }

    .tooltip-arrow {
        position: absolute;
        bottom: -6px;
        left: 50%;
        transform: translateX(-50%);
        border-left: 6px solid transparent;
        border-right: 6px solid transparent;
        border-top: 6px solid var(--color-border);
    }

    .marker-pin {
        color: var(--color-primary);
        position: relative;
        filter: drop-shadow(0 0 15px rgba(255, 0, 0, 0.6));
        animation: markerFloat 3s ease-in-out infinite;
    }

    @keyframes markerFloat {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-10px); }
    }

    .marker-pulse {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 40px;
        height: 40px;
        background: rgba(255, 0, 0, 0.2);
        border-radius: 50%;
        animation: pulse 2s infinite;
        z-index: -1;
    }

    @keyframes pulse {
        0% { transform: translate(-50%, -50%) scale(0.5); opacity: 1; }
        100% { transform: translate(-50%, -50%) scale(2); opacity: 0; }
    }

    .map-footer-hint {
        position: absolute;
        bottom: var(--space-4);
        left: var(--space-4);
        background: rgba(0, 0, 0, 0.7);
        backdrop-filter: blur(4px);
        color: var(--color-text-secondary);
        padding: 5px 12px;
        border-radius: var(--radius-full);
        font-size: 11px;
        font-weight: 600;
        display: flex;
        align-items: center;
        gap: 8px;
        border: 1px solid var(--color-border);
    }

    /* Time Selection Refinement */
    .section-title {
        font-weight: 800;
        font-size: var(--text-base);
        margin-bottom: var(--space-4);
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--color-text-secondary);
    }

    .time-radio-group {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: var(--space-3);
        margin-bottom: var(--space-4);
    }

    .time-card {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        padding: var(--space-4);
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
        width: 18px;
        height: 18px;
        border: 2px solid var(--color-border);
        border-radius: 50%;
        margin-bottom: var(--space-3);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .active .custom-radio { border-color: var(--color-primary); }

    .active .custom-radio::after {
        content: '';
        width: 10px;
        height: 10px;
        background: var(--color-primary);
        border-radius: 50%;
    }

    .time-primary {
        font-weight: 800;
        font-size: var(--text-sm);
        display: block;
        margin-bottom: 4px;
    }

    .time-secondary {
        font-size: 11px;
        color: var(--color-text-muted);
        font-weight: 600;
    }

    .scheduled-picker {
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        display: flex;
        align-items: stretch;
        font-weight: 700;
        color: var(--color-text-primary);
        overflow: hidden;
    }

    .picker-half {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-3);
        padding: var(--space-4);
        position: relative;
        cursor: pointer;
        transition: background 0.2s;
    }

    .picker-half:hover {
        background: var(--color-bg-glass);
    }

    .picker-half input {
        position: absolute;
        inset: 0;
        opacity: 0;
        cursor: pointer;
        width: 100%;
        height: 100%;
        z-index: 10;
        pointer-events: auto;
    }

    .picker-divider {
        width: 1px;
        background: var(--color-border);
        margin: var(--space-2) 0;
    }

    .picker-icon { color: var(--color-primary); }
    .picker-val { font-size: var(--text-sm); }

    /* Action Footer */
    .modal-footer {
        padding: var(--space-4) var(--space-6) var(--space-6);
    }

    .confirm-order-btn {
        width: 100%;
        background: linear-gradient(135deg, var(--color-primary), var(--color-primary-dark));
        color: white;
        border: none;
        padding: 18px;
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
        transform: translateY(-2px) scale(1.02);
        box-shadow: 0 15px 30px rgba(255, 0, 0, 0.4);
    }

    .confirm-order-btn:disabled {
        opacity: 0.5;
        cursor: not-allowed;
        filter: grayscale(1);
    }

    /* Dropdown UI Refinement */
    .search-dropdown {
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: var(--color-bg-secondary);
        border-radius: var(--radius-xl);
        box-shadow: 0 20px 40px rgba(0,0,0,0.6);
        margin-top: 8px;
        overflow: hidden;
        border: 1px solid var(--color-border);
        backdrop-filter: blur(20px);
    }

    .search-item {
        width: 100%;
        display: flex;
        align-items: flex-start;
        gap: var(--space-4);
        padding: var(--space-4);
        background: none;
        border: none;
        cursor: pointer;
        text-align: left;
        border-bottom: 1px solid var(--color-border);
        transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    }

    .search-item:hover {
        background: var(--color-bg-tertiary);
        padding-left: var(--space-6);
    }

    .item-icon-box {
        padding: 8px;
        background: rgba(255, 0, 0, 0.1);
        color: var(--color-primary);
        border-radius: var(--radius-md);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .item-content { flex: 1; }

    .item-title {
        font-weight: 800;
        font-size: var(--text-sm);
        color: var(--color-text-primary);
        margin-bottom: 4px;
    }

    .item-subtitle {
        font-size: 12px;
        color: var(--color-text-secondary);
        line-height: 1.4;
    }

    .search-dropdown-overlay {
        position: fixed;
        inset: 0;
        z-index: -1;
    }
</style>
