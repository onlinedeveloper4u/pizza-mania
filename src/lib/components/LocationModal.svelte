<script lang="ts">
    import { X, MapPin, Navigation, Calendar, Clock, ChevronRight, Search, LocateFixed, Loader2 } from 'lucide-svelte';
    import { cn } from '$lib/utils';
    import { fade, scale, slide } from 'svelte/transition';
    import { createClient } from '$lib/supabase/client';
    import { PUBLIC_GOOGLE_MAPS_API_KEY } from '$env/static/public';
    import { settings } from '$lib/stores/settings';

    let { show = $bindable(false), onConfirm } = $props();

    let address = $state('');
    let searchInput = $state('');
    let searchResults = $state<{ title: string, subtitle: string, placeId?: string }[]>([]);
    let isSearching = $state(false);
    let showResults = $state(false);
    let deliveryTime: 'now' | 'later' = $state('now');
    let selectedDate = $state(new Date().toISOString().split('T')[0]);
    let selectedTime = $state(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false }));
    
    let isLocating = $state(false);
    let mapMoved = $state(false);
    let searchTimeout: any;
    
    let dateInput: HTMLInputElement | undefined = $state();
    let timeInput: HTMLInputElement | undefined = $state();
    
    let googleMapsLoaded = $state(false);
    let placesLibrary: any;
    let geocoder: any;
    let map: any = $state(null);
    let mapElement: HTMLElement | undefined = $state();

    async function loadGoogleMaps() {
        if (window.google?.maps?.importLibrary) {
            initServices();
            return;
        }

        // The recommended modern inline bootstrap loader
        (g=>{var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;b=b[c]||(b[c]={});const d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>h||(h=new Promise(async(f,n)=>{await (a=m.createElement("script"));e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);e.set("callback",c+".maps."+q);a.src=`https://maps.${c}apis.com/maps/api/js?`+e;d[q]=f;a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n))})({
            key: PUBLIC_GOOGLE_MAPS_API_KEY,
            v: "weekly",
        });

        initServices();
    }

    async function initServices() {
        try {
            // @ts-ignore
            placesLibrary = await google.maps.importLibrary("places");
            // @ts-ignore
            const { Geocoder } = await google.maps.importLibrary("geocoding");
            geocoder = new Geocoder();
            
            // @ts-ignore
            const { Map } = await google.maps.importLibrary("maps");
            if (mapElement) {
                map = new Map(mapElement, {
                    center: { lat: 50.41, lng: 4.44 }, // Charleroi generic
                    zoom: 13,
                    mapId: 'DEMO_MAP_ID',
                    disableDefaultUI: true,
                    gestureHandling: 'greedy'
                });

                map.addListener('dragend', () => {
                    if (!geocoder) return;
                    const center = map.getCenter();
                    geocoder.geocode({ location: center }, (results: any, status: any) => {
                        if (status === 'OK' && results[0]) {
                            address = results[0].formatted_address;
                            searchInput = results[0].formatted_address;
                            mapMoved = true;
                        }
                    });
                });

                map.addListener('dragstart', () => {
                    mapMoved = true;
                    showResults = false;
                });
            }

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
        searchInput = value;
        showResults = true;
        
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => performSearch(value), 400);
    }

    function selectAddress(res: { title: string, subtitle: string, placeId?: string }) {
        const fullAddress = res.title + (res.subtitle ? `, ${res.subtitle}` : '');
        address = fullAddress;
        searchInput = fullAddress;
        showResults = false;
        mapMoved = true;

        if (res.placeId && geocoder && map) {
            geocoder.geocode({ placeId: res.placeId }, (results: any, status: any) => {
                if (status === 'OK' && results[0]) {
                    map.panTo(results[0].geometry.location);
                    map.setZoom(16);
                }
            });
        }
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
                            searchInput = results[0].formatted_address;
                            mapMoved = true;
                        } else {
                            address = "Current Location Detected";
                            searchInput = "Current Location Detected";
                            mapMoved = true;
                        }

                        if (map) {
                            map.panTo({ lat: latitude, lng: longitude });
                            map.setZoom(16);
                        }

                        isLocating = false;
                        showResults = false;
                    });
                } else {
                    // Fallback to coordinates if geocoder failed or not loaded
                    address = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
                    searchInput = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
                    mapMoved = true;
                    if (map) {
                        map.panTo({ lat: latitude, lng: longitude });
                        map.setZoom(16);
                    }
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
                                value={searchInput}
                                oninput={handleInput}
                                onfocus={() => showResults = true}
                            />
                            {#if isSearching}
                                <div class="loading-icon animate-spin">
                                    <Loader2 size={18} />
                                </div>
                            {/if}
                            {#if searchInput.length > 0 && !isSearching}
                                <button class="clear-input" onclick={() => { searchInput = ''; address = ''; searchResults = []; }} aria-label="Clear">
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
                        <div bind:this={mapElement} class="map-instance-container"></div>
                        <div class="map-grid" aria-hidden="true" style="pointer-events:none;"></div>
                        
                        <!-- Floating Controls -->
                        <div class="map-controls">
                            <button class="map-locate-btn" onclick={handleLocateMe} disabled={isLocating} aria-label="Locate me">
                                {#if isLocating}
                                    <Loader2 size={20} class="animate-spin" />
                                {:else}
                                    <LocateFixed size={20} />
                                {/if}
                            </button>
                        </div>

                        <!-- Central Marker -->
                        <div class="marker-container" style={mapMoved ? 'transform: translate(-50%, -65%)' : ''}>
                            <div class="marker-pin-wrapper">
                                <div class="marker-pin">
                                    <MapPin size={36} strokeWidth={3} />
                                    <div class="marker-pulse"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="map-info-footer">
                        <div class="map-store-badge">
                            STORE: {$settings?.restaurant_name?.toUpperCase() || 'JUMET CENTRE'}
                        </div>
                        <div class="map-footer-hint">
                            <Navigation size={14} />
                            <span>Drag the pin to adjust</span>
                        </div>
                    </div>
                </div>

                {#if address}
                    <div class="selected-address-box">
                        <MapPin size={20} class="selected-icon" />
                        <div class="selected-details">
                            <span class="selected-title">Delivery Address</span>
                            <span class="selected-text">{address}</span>
                        </div>
                    </div>
                {/if}

                <!-- Delivery Option Section -->
                <div class="form-section time-section">
                    <h3 class="section-title">Schedule Order</h3>
                    
                    <div class="time-radio-group">
                        <label class={cn("time-card", deliveryTime === 'now' && "active")}>
                            <input type="radio" name="order-time" value="now" bind:group={deliveryTime} />
                            <div class="custom-radio"></div>
                            <div class="time-card-content">
                                <span class="time-primary">Deliver Now</span>
                            </div>
                        </label>

                        <label class={cn("time-card", deliveryTime === 'later' && "active")}>
                            <input type="radio" name="order-time" value="later" bind:group={deliveryTime} />
                            <div class="custom-radio"></div>
                            <div class="time-card-content">
                                <span class="time-primary">Deliver Later</span>
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
        padding: var(--space-10) var(--space-4);
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
        padding: var(--space-5) var(--space-4) var(--space-2);
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
        padding: 0 var(--space-4) var(--space-4);
        max-height: 80vh;
        overflow-y: auto;
        scrollbar-width: none;
    }

    .modal-body::-webkit-scrollbar {
        display: none;
    }

    .modal-body {
        padding: 0 var(--space-4) var(--space-4);
        max-height: 80vh;
        overflow-y: auto;
        scrollbar-width: none;
    }

    .modal-body::-webkit-scrollbar {
        display: none;
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
        padding: 12px var(--space-4);
        padding-right: var(--space-10);
        font-size: 15px;
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
        border-radius: var(--radius-sm);
        overflow: hidden;
        border: 1px solid var(--color-border);
        background: #000;
    }

    .map-graphic {
        position: relative;
        height: 200px;
        background: radial-gradient(circle at center, #1a1a1a 0%, #000000 100%);
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .map-grid {
        position: absolute;
        inset: 0;
        background-color: transparent;
        background-image: 
            linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
        background-size: 40px 40px;
        background-position: center center;
        z-index: 1;
    }

    .map-instance-container {
        position: absolute;
        inset: 0;
        z-index: 0;
    }

    /* Target google maps UI to hide terms/logos neatly if disabled */
    .map-controls {
        position: absolute;
        top: var(--space-3);
        right: var(--space-3);
        z-index: 20;
    }

    .map-locate-btn {
        background: var(--color-bg-secondary);
        color: var(--color-primary);
        border: 1px solid var(--color-border);
        width: 44px;
        height: 44px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        cursor: pointer;
        transition: all var(--transition-base);
        box-shadow: var(--shadow-md);
        pointer-events: auto;
    }

    .map-locate-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        border-color: var(--color-primary);
    }

    .map-locate-btn:disabled {
        opacity: 0.8;
        cursor: wait;
    }

    .map-info-footer {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-1);
        padding: var(--space-3);
        background: var(--color-bg-secondary);
        border-top: 1px solid var(--color-border);
        border-bottom-left-radius: var(--radius-sm);
        border-bottom-right-radius: var(--radius-sm);
    }

    .map-store-badge {
        color: var(--color-amber);
        font-weight: 800;
        font-size: 13px;
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
        display: flex;
        align-items: center;
        gap: var(--space-2);
        color: var(--color-text-muted);
        font-size: 13px;
        font-weight: 500;
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
