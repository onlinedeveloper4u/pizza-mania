import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://qdqrtfjfnxgvqrgomrls.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcXJ0ZmpmbnhndnFyZ29tcmxzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE3NDUyOCwiZXhwIjoyMDg2NzUwNTI4fQ.lfpAT35z7rF7p8x28EoKecCLkAoHskFdl94fO0yYY50';
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
    const { data: item } = await supabase.from('menu_items').select('*').eq('name', 'La Solo').single();

    if (!item) {
        console.log('Item not found');
        return;
    }

    console.log('Found item:', item);

    const { error } = await supabase.from('menu_items').insert({
        name: 'La Solo Copy',
        description: item.description,
        price: item.price,
        category_id: item.category_id,
        image_url: item.image_url,
        is_available: item.is_available,
        is_featured: item.is_featured,
        options: item.options,
        sort_order: item.sort_order + 1
    });

    if (error) {
        console.error('Error duplicating:', error);
    } else {
        console.log('Successfully duplicated!');
    }
}

run();
