import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://qdqrtfjfnxgvqrgomrls.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcXJ0ZmpmbnhndnFyZ29tcmxzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE3NDUyOCwiZXhwIjoyMDg2NzUwNTI4fQ.lfpAT35z7rF7p8x28EoKecCLkAoHskFdl94fO0yYY50';
const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const { data: cat } = await supabase.from('categories').select('id').eq('name', 'Nos Pizzas').single();
  
  if (!cat) {
    console.error('Category not found');
    return;
  }
  
  const { data: items, error } = await supabase.from('menu_items').select('id, name, price, options').eq('category_id', cat.id);
  if (error) {
    console.error('Error:', error);
  } else {
    for (const item of items) {
      console.log(item.name + ' - Price: ' + item.price);
      if (item.options) {
        console.log('Options type single:', item.options.filter(o => o.type === 'single').map(o => o.name));
      }
    }
  }
}

run();
