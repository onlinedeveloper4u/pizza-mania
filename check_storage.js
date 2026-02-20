import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://qdqrtfjfnxgvqrgomrls.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkcXJ0ZmpmbnhndnFyZ29tcmxzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTE3NDUyOCwiZXhwIjoyMDg2NzUwNTI4fQ.lfpAT35z7rF7p8x28EoKecCLkAoHskFdl94fO0yYY50';
const supabase = createClient(supabaseUrl, supabaseKey);

async function checkStorage() {
    const { data, error } = await supabase.storage.getBucket('assets');
    console.log('Bucket "assets":', data ? 'Exists' : 'Not found or error');
    if (error) console.error(error);

    if (data) {
        console.log('Bucket details:', data);
    }
}

checkStorage();
