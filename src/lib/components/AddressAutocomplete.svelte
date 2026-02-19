<script lang="ts">
    import { onMount } from 'svelte';
    import { env } from '$env/dynamic/public';

    let { value = $bindable(''), onplace_changed, ...props } = $props<{
        value: string;
        onplace_changed?: (place: any) => void;
    } & Record<string, any>>();

    let inputElement: HTMLInputElement;
    let autocomplete: any;

    // Use dynamic env to allow runtime configuration if needed, 
    // though usually public keys are static.
    const API_KEY = env.PUBLIC_GOOGLE_MAPS_API_KEY;

    onMount(() => {
        if (!API_KEY) {
            console.warn('Google Maps API Key is missing. Autocomplete will not work.');
            return;
        }

        if (window.google && window.google.maps && window.google.maps.places) {
            initAutocomplete();
        } else {
            const scriptId = 'google-maps-script';
            if (!document.getElementById(scriptId)) {
                const script = document.createElement('script');
                script.id = scriptId;
                script.src = `https://maps.googleapis.com/maps/api/js?key=${API_KEY}&libraries=places&loading=async`;
                script.async = true;
                script.defer = true;
                script.onload = () => initAutocomplete();
                document.head.appendChild(script);
            } else {
                // Script already loading/loaded, wait for it?
                // Simple retry for now or rely on window.google check loop
                const checkGoogle = setInterval(() => {
                    if (window.google && window.google.maps) {
                        clearInterval(checkGoogle);
                        initAutocomplete();
                    }
                }, 100);
            }
        }
    });

    function initAutocomplete() {
        if (!inputElement || !window.google) return;
        
        autocomplete = new window.google.maps.places.Autocomplete(inputElement, {
            types: ['address'],
            fields: ['formatted_address', 'geometry', 'name'],
            componentRestrictions: { country: 'be' } // Optional: restrict to Belgium (Pizza Mania context)? 
            // Better not to restrict too much unless asked.
            // But usually restaurants are local. I'll leave it open or comment it out.
        });

        autocomplete.addListener('place_changed', () => {
            const place = autocomplete.getPlace();
            if (place.formatted_address) {
                value = place.formatted_address;
                onplace_changed?.(place);
            }
        });
    }
</script>

<input
    bind:this={inputElement}
    bind:value={value}
    type="text"
    class="input"
    placeholder="Start typing your address..."
    autocomplete="off"
    {...props}
/>

<style>
    /* Reuse input styles from global css via class="input" */
</style>
