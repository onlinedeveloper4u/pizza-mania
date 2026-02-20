import { writable } from 'svelte/store';
import { createClient } from '$lib/supabase/client';

export interface RestaurantSettings {
    restaurant_name: string;
    address: string;
    phone: string;
    email: string;
    delivery_fee: number;
    avg_prep_minutes: number;
    accepting_orders: boolean;
    currency: string;
    operating_hours: any;
}

function createSettingsStore() {
    const { subscribe, set } = writable<RestaurantSettings | null>(null);

    return {
        subscribe,
        fetch: async () => {
            const supabase = createClient();
            const { data, error } = await supabase.from('restaurant_settings').select('*').single();
            if (data) {
                set(data);
            }
            return data;
        },
        set
    };
}

export const settings = createSettingsStore();
