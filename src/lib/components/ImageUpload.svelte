<script lang="ts">
    import { createClient } from '$lib/supabase/client';
    import { Upload, X, Loader2, ImageIcon } from 'lucide-svelte';
    import { toast } from 'svelte-sonner';

    let { 
        value = $bindable(''), 
        bucket = 'assets', 
        path = 'uploads',
        label = 'Upload Image'
    } = $props();

    let uploading = $state(false);
    let fileInput: HTMLInputElement;
    const supabase = createClient();

    async function handleUpload(e: Event) {
        const target = e.target as HTMLInputElement;
        const file = target.files?.[0];
        if (!file) return;

        // Basic validation
        if (!file.type.startsWith('image/')) {
            toast.error('Please upload an image file');
            return;
        }
        if (file.size > 2 * 1024 * 1024) {
            toast.error('Image size must be less than 2MB');
            return;
        }

        uploading = true;
        try {
            const fileExt = file.name.split('.').pop();
            const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
            const filePath = `${path}/${fileName}`;

            const { error: uploadError } = await supabase.storage
                .from(bucket)
                .upload(filePath, file);

            if (uploadError) throw uploadError;

            const { data: { publicUrl } } = supabase.storage
                .from(bucket)
                .getPublicUrl(filePath);

            value = publicUrl;
            toast.success('Image uploaded successfully');
        } catch (error) {
            console.error('Error uploading image:', error);
            toast.error('Failed to upload image');
        } finally {
            uploading = false;
        }
    }

    function removeImage() {
        value = '';
    }
</script>

<div class="image-upload-container">
    <label class="label">{label}</label>
    
    <div class="upload-box">
        {#if value}
            <div class="preview-area">
                <img src={value} alt="Preview" class="preview-img" />
                <button class="remove-btn" onclick={removeImage} type="button" aria-label="Remove image">
                    <X size={16} />
                </button>
            </div>
        {:else}
            <button 
                class="upload-trigger" 
                onclick={() => fileInput.click()} 
                disabled={uploading}
                type="button"
            >
                {#if uploading}
                    <Loader2 size={24} class="animate-spin" />
                    <span>Uploading...</span>
                {:else}
                    <Upload size={24} />
                    <span>Click to upload image</span>
                {/if}
            </button>
        {/if}
        
        <input 
            type="file" 
            accept="image/*" 
            bind:this={fileInput} 
            onchange={handleUpload} 
            style="display: none;" 
        />
    </div>
</div>

<style>
    .image-upload-container {
        margin-bottom: var(--space-4);
    }

    .label {
        display: block;
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        margin-bottom: var(--space-2);
    }

    .upload-box {
        border: 2px dashed var(--color-border);
        border-radius: var(--radius-xl);
        overflow: hidden;
        background: var(--color-bg-tertiary);
        transition: all var(--transition-fast);
        min-height: 120px;
        display: flex;
    }

    .upload-box:hover {
        border-color: var(--color-primary);
        background: rgba(230, 57, 70, 0.04);
    }

    .upload-trigger {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: var(--space-2);
        color: var(--color-text-muted);
        background: none;
        border: none;
        cursor: pointer;
        padding: var(--space-4);
        width: 100%;
        height: 100%;
    }

    .upload-trigger:hover {
        color: var(--color-primary);
    }

    .preview-area {
        position: relative;
        width: 100%;
        height: 100%;
        min-height: 120px;
    }

    .preview-img {
        width: 100%;
        height: 100%;
        min-height: 120px;
        object-fit: cover;
    }

    .remove-btn {
        position: absolute;
        top: var(--space-2);
        right: var(--space-2);
        width: 28px;
        height: 28px;
        border-radius: var(--radius-full);
        background: rgba(0, 0, 0, 0.6);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        border: none;
        cursor: pointer;
        transition: all var(--transition-fast);
        z-index: 1;
    }

    .remove-btn:hover {
        background: var(--color-danger);
        transform: scale(1.1);
    }

    @keyframes spin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
    }
    .animate-spin { animation: spin 1s linear infinite; }
</style>
