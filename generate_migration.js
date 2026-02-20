import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://qdqrtfjfnxgvqrgomrls.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcXJ0ZmpmbnhndnFyZ29tcmxzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE3NDUyOCwiZXhwIjoyMDg2NzUwNTI4fQ.lfpAT35z7rF7p8x28EoKecCLkAoHskFdl94fO0yYY50';
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
    const { data: cat } = await supabase.from('categories').select('id').eq('name', 'Nos Pizzas').single();
    const { data: items } = await supabase.from('menu_items').select('*').eq('category_id', cat.id);

    let sql = '-- Migration 009: Separate S and M pizza sizes\nDO $$\nBEGIN\n';

    for (const item of items) {
        if (item.name === 'Compose Ta Pizza') continue;

        // Create new options without 'Size'
        let newOptions = [];
        if (item.options) {
            newOptions = item.options.filter(o => o.name !== 'Size');
        }
        const optionsStr = newOptions.length > 0 ? `'${JSON.stringify(newOptions).replace(/'/g, "''")}'::jsonb` : 'NULL';

        // For M size we add 4.50 to the base price
        const priceM = item.price + 4.50;

        sql += `    -- Update original item to be Size M\n`;
        sql += `    UPDATE menu_items SET name = '${item.name.replace(/'/g, "''")} M', price = ${priceM}, options = ${optionsStr} WHERE id = '${item.id}';\n\n`;

        sql += `    -- Insert new item for Size S\n`;
        sql += `    INSERT INTO menu_items (id, name, description, price, category_id, image_url, is_available, is_featured, options, sort_order)\n`;
        sql += `    VALUES (gen_random_uuid(), '${item.name.replace(/'/g, "''")} S', '${(item.description || '').replace(/'/g, "''")}', ${item.price}, '${item.category_id}', ${item.image_url ? `'${item.image_url}'` : 'NULL'}, ${item.is_available}, ${item.is_featured}, ${optionsStr}, ${item.sort_order});\n\n`;
    }

    sql += 'END $$;\n';

    fs.writeFileSync('supabase/migrations/009_separate_sizes.sql', sql);
    console.log('Migration generated.');
}

run();
