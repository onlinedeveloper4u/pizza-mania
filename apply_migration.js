import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://qdqrtfjfnxgvqrgomrls.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcXJ0ZmpmbnhndnFyZ29tcmxzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE3NDUyOCwiZXhwIjoyMDg2NzUwNTI4fQ.lfpAT35z7rF7p8x28EoKecCLkAoHskFdl94fO0yYY50';
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
    console.log('Fetching Nos Pizzas category...');
    const { data: cat } = await supabase.from('categories').select('id').eq('name', 'Nos Pizzas').single();
    const { data: items } = await supabase.from('menu_items').select('*').eq('category_id', cat.id);

    for (const item of items) {
        if (item.name === 'Compose Ta Pizza') continue;

        // Create new options without 'Size'
        let newOptions = [];
        if (item.options) {
            newOptions = item.options.filter(o => o.name !== 'Size');
        }
        const optionsObj = newOptions.length > 0 ? newOptions : null;

        const isMedium = item.name.endsWith(' M');
        const isSmall = item.name.endsWith(' S');
        if (isMedium || isSmall) {
            console.log(`Skipping already processed item: ${item.name}`);
            continue;
        }

        // For M size we add 4.50 to the base price
        const priceM = item.price + 4.50;

        console.log(`Updating ${item.name} to S and M...`);

        // Update original item to be Size M
        const { error: updErr } = await supabase.from('menu_items').update({
            name: item.name + ' M',
            price: priceM,
            options: optionsObj
        }).eq('id', item.id);

        if (updErr) console.error('Error updating to M:', updErr);

        // Insert new item for Size S
        const { error: insErr } = await supabase.from('menu_items').insert({
            name: item.name + ' S',
            description: item.description,
            price: item.price,
            category_id: item.category_id,
            image_url: item.image_url,
            is_available: item.is_available,
            is_featured: item.is_featured,
            options: optionsObj,
            sort_order: item.sort_order
        });

        if (insErr) console.error('Error inserting S:', insErr);
    }

    console.log('Migration complete.');
}

run();
