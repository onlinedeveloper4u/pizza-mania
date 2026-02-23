<script lang="ts">
    import { onMount } from "svelte";
    import { createClient } from "$lib/supabase/client";
    import { toast } from "svelte-sonner";
    import {
        Upload,
        X,
        Loader2,
        Image,
        Video,
        ChefHat,
        Store,
        Trash2,
        Plus,
        Eye,
    } from "lucide-svelte";

    type MediaCategory = "craft" | "ambiance";
    type MediaType = "image" | "video";

    interface MediaItem {
        id: string;
        category: MediaCategory;
        media_type: MediaType;
        url: string;
        title: string;
        caption: string;
        file_name: string;
        file_size: number;
        created_at: string;
    }

    let loading = $state(true);
    let craftMedia = $state<MediaItem[]>([]);
    let ambianceMedia = $state<MediaItem[]>([]);
    let uploadingCraft = $state(false);
    let uploadingAmbiance = $state(false);
    let previewItem = $state<MediaItem | null>(null);

    let craftFileInput: HTMLInputElement;
    let ambianceFileInput: HTMLInputElement;

    const supabase = createClient();
    const BUCKET = "assets";
    const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
    const MAX_VIDEO_SIZE = 50 * 1024 * 1024; // 50MB

    onMount(async () => {
        await loadMedia();
    });

    async function loadMedia() {
        loading = true;
        try {
            const { data, error } = await supabase
                .from("landing_media")
                .select("*")
                .order("created_at", { ascending: false });

            if (error) throw error;

            craftMedia = (data || []).filter(
                (m: MediaItem) => m.category === "craft",
            );
            ambianceMedia = (data || []).filter(
                (m: MediaItem) => m.category === "ambiance",
            );
        } catch (err) {
            console.error("Error loading media:", err);
            toast.error("Failed to load media");
        } finally {
            loading = false;
        }
    }

    async function handleUpload(e: Event, category: MediaCategory) {
        const target = e.target as HTMLInputElement;
        const files = target.files;
        if (!files || files.length === 0) return;

        if (category === "craft") uploadingCraft = true;
        else uploadingAmbiance = true;

        try {
            for (const file of Array.from(files)) {
                const isVideo = file.type.startsWith("video/");
                const isImage = file.type.startsWith("image/");

                if (!isImage && !isVideo) {
                    toast.error(
                        `${file.name}: Only images and videos are allowed`,
                    );
                    continue;
                }

                const maxSize = isVideo ? MAX_VIDEO_SIZE : MAX_IMAGE_SIZE;
                if (file.size > maxSize) {
                    toast.error(
                        `${file.name}: File too large (max ${isVideo ? "50MB" : "5MB"})`,
                    );
                    continue;
                }

                // Upload to Supabase storage
                const fileExt = file.name.split(".").pop();
                const fileName = `${Date.now()}_${Math.random().toString(36).substring(2)}.${fileExt}`;
                const filePath = `media/${category}/${fileName}`;

                const { error: uploadError } = await supabase.storage
                    .from(BUCKET)
                    .upload(filePath, file);

                if (uploadError) {
                    toast.error(`Failed to upload ${file.name}`);
                    console.error(uploadError);
                    continue;
                }

                const {
                    data: { publicUrl },
                } = supabase.storage.from(BUCKET).getPublicUrl(filePath);

                // Save to database
                const { error: dbError } = await supabase
                    .from("landing_media")
                    .insert({
                        category,
                        media_type: isVideo ? "video" : "image",
                        url: publicUrl,
                        title: "",
                        caption: "",
                        file_name: file.name,
                        file_size: file.size,
                    });

                if (dbError) {
                    toast.error(`Failed to save ${file.name}`);
                    console.error(dbError);
                    continue;
                }

                toast.success(`Uploaded ${file.name}`);
            }

            await loadMedia();
        } catch (err) {
            console.error("Upload error:", err);
            toast.error("Upload failed");
        } finally {
            if (category === "craft") uploadingCraft = false;
            else uploadingAmbiance = false;
            target.value = "";
        }
    }

    async function deleteItem(item: MediaItem) {
        if (!confirm("Delete this media?")) return;

        try {
            // Extract path from URL
            const urlParts = item.url.split(
                "/storage/v1/object/public/assets/",
            );
            const storagePath = urlParts[1];

            if (storagePath) {
                await supabase.storage.from(BUCKET).remove([storagePath]);
            }

            const { error } = await supabase
                .from("landing_media")
                .delete()
                .eq("id", item.id);

            if (error) throw error;

            toast.success("Deleted");
            await loadMedia();
        } catch (err) {
            console.error(err);
            toast.error("Failed to delete");
        }
    }

    async function updateCaption(item: MediaItem, caption: string) {
        try {
            const { error } = await supabase
                .from("landing_media")
                .update({ caption })
                .eq("id", item.id);

            if (error) throw error;
            item.caption = caption;
        } catch (err) {
            console.error(err);
            toast.error("Failed to update caption");
        }
    }

    async function updateTitle(item: MediaItem, title: string) {
        try {
            const { error } = await supabase
                .from("landing_media")
                .update({ title })
                .eq("id", item.id);

            if (error) throw error;
            item.title = title;
        } catch (err) {
            console.error(err);
            toast.error("Failed to update title");
        }
    }

    function formatFileSize(bytes: number): string {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB";
    }
</script>

<svelte:head>
    <title>Media Gallery — Pizza Mania Admin</title>
</svelte:head>

<div class="media-container">
    <div class="admin-topbar">
        <div>
            <h1>Media Gallery</h1>
            <p class="topbar-desc">
                Upload photos & videos for your landing page
            </p>
        </div>
    </div>

    {#if loading}
        <div class="loading-state">
            <Loader2 size={32} class="animate-spin" />
            <span>Loading media...</span>
        </div>
    {:else}
        <!-- OUR CRAFT SECTION -->
        <div class="media-section">
            <div class="section-head">
                <div class="section-head-left">
                    <div class="section-icon craft-icon">
                        <ChefHat size={20} />
                    </div>
                    <div>
                        <h2>Our Craft</h2>
                        <p>Pizza preparation, ingredients, oven shots</p>
                    </div>
                </div>
                <button
                    class="btn btn-primary btn-sm"
                    onclick={() => craftFileInput.click()}
                    disabled={uploadingCraft}
                >
                    {#if uploadingCraft}
                        <Loader2 size={14} class="animate-spin" />
                        Uploading...
                    {:else}
                        <Plus size={14} />
                        Upload
                    {/if}
                </button>
                <input
                    type="file"
                    accept="image/*,video/*"
                    multiple
                    bind:this={craftFileInput}
                    onchange={(e) => handleUpload(e, "craft")}
                    style="display: none;"
                />
            </div>

            {#if craftMedia.length === 0}
                <div
                    class="empty-state"
                    role="button"
                    tabindex="0"
                    onclick={() => craftFileInput.click()}
                    onkeydown={(e) =>
                        e.key === "Enter" && craftFileInput.click()}
                >
                    <Upload size={32} />
                    <p>No craft media yet</p>
                    <span
                        >Click to upload photos or videos of your pizza
                        preparation</span
                    >
                </div>
            {:else}
                <div class="media-grid">
                    {#each craftMedia as item}
                        <div class="media-card">
                            {#if item.media_type === "video"}
                                <div class="media-thumb">
                                    <video
                                        src={item.url}
                                        class="media-img"
                                        preload="metadata"
                                    >
                                        <track kind="captions" />
                                    </video>
                                    <div class="media-type-badge">
                                        <Video size={12} /> Video
                                    </div>
                                </div>
                            {:else}
                                <div class="media-thumb">
                                    <img
                                        src={item.url}
                                        alt={item.caption || item.file_name}
                                        class="media-img"
                                    />
                                    <div class="media-type-badge">
                                        <Image size={12} /> Photo
                                    </div>
                                </div>
                            {/if}
                            <div class="media-info">
                                <input
                                    class="title-input"
                                    type="text"
                                    placeholder="Add title..."
                                    value={item.title}
                                    onblur={(e) =>
                                        updateTitle(
                                            item,
                                            (e.target as HTMLInputElement)
                                                .value,
                                        )}
                                />
                                <input
                                    class="caption-input"
                                    type="text"
                                    placeholder="Add caption..."
                                    value={item.caption}
                                    onblur={(e) =>
                                        updateCaption(
                                            item,
                                            (e.target as HTMLInputElement)
                                                .value,
                                        )}
                                />
                                <div class="media-meta">
                                    <span class="file-size"
                                        >{formatFileSize(item.file_size)}</span
                                    >
                                    <div class="media-actions">
                                        <button
                                            class="action-btn"
                                            onclick={() => (previewItem = item)}
                                            title="Preview"
                                        >
                                            <Eye size={14} />
                                        </button>
                                        <button
                                            class="action-btn danger"
                                            onclick={() => deleteItem(item)}
                                            title="Delete"
                                        >
                                            <Trash2 size={14} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    {/each}

                    <!-- Add More -->
                    <button
                        class="media-card add-card"
                        onclick={() => craftFileInput.click()}
                    >
                        <Plus size={24} />
                        <span>Add More</span>
                    </button>
                </div>
            {/if}
        </div>

        <!-- AMBIANCE SECTION -->
        <div class="media-section">
            <div class="section-head">
                <div class="section-head-left">
                    <div class="section-icon ambiance-icon">
                        <Store size={20} />
                    </div>
                    <div>
                        <h2>Ambiance</h2>
                        <p>Restaurant interior, exterior, dining area</p>
                    </div>
                </div>
                <button
                    class="btn btn-primary btn-sm"
                    onclick={() => ambianceFileInput.click()}
                    disabled={uploadingAmbiance}
                >
                    {#if uploadingAmbiance}
                        <Loader2 size={14} class="animate-spin" />
                        Uploading...
                    {:else}
                        <Plus size={14} />
                        Upload
                    {/if}
                </button>
                <input
                    type="file"
                    accept="image/*,video/*"
                    multiple
                    bind:this={ambianceFileInput}
                    onchange={(e) => handleUpload(e, "ambiance")}
                    style="display: none;"
                />
            </div>

            {#if ambianceMedia.length === 0}
                <div
                    class="empty-state"
                    role="button"
                    tabindex="0"
                    onclick={() => ambianceFileInput.click()}
                    onkeydown={(e) =>
                        e.key === "Enter" && ambianceFileInput.click()}
                >
                    <Upload size={32} />
                    <p>No ambiance media yet</p>
                    <span
                        >Click to upload photos or videos of your restaurant</span
                    >
                </div>
            {:else}
                <div class="media-grid">
                    {#each ambianceMedia as item}
                        <div class="media-card">
                            {#if item.media_type === "video"}
                                <div class="media-thumb">
                                    <video
                                        src={item.url}
                                        class="media-img"
                                        preload="metadata"
                                    >
                                        <track kind="captions" />
                                    </video>
                                    <div class="media-type-badge">
                                        <Video size={12} /> Video
                                    </div>
                                </div>
                            {:else}
                                <div class="media-thumb">
                                    <img
                                        src={item.url}
                                        alt={item.caption || item.file_name}
                                        class="media-img"
                                    />
                                    <div class="media-type-badge">
                                        <Image size={12} /> Photo
                                    </div>
                                </div>
                            {/if}
                            <div class="media-info">
                                <input
                                    class="title-input"
                                    type="text"
                                    placeholder="Add title..."
                                    value={item.title}
                                    onblur={(e) =>
                                        updateTitle(
                                            item,
                                            (e.target as HTMLInputElement)
                                                .value,
                                        )}
                                />
                                <input
                                    class="caption-input"
                                    type="text"
                                    placeholder="Add caption..."
                                    value={item.caption}
                                    onblur={(e) =>
                                        updateCaption(
                                            item,
                                            (e.target as HTMLInputElement)
                                                .value,
                                        )}
                                />
                                <div class="media-meta">
                                    <span class="file-size"
                                        >{formatFileSize(item.file_size)}</span
                                    >
                                    <div class="media-actions">
                                        <button
                                            class="action-btn"
                                            onclick={() => (previewItem = item)}
                                            title="Preview"
                                        >
                                            <Eye size={14} />
                                        </button>
                                        <button
                                            class="action-btn danger"
                                            onclick={() => deleteItem(item)}
                                            title="Delete"
                                        >
                                            <Trash2 size={14} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    {/each}

                    <button
                        class="media-card add-card"
                        onclick={() => ambianceFileInput.click()}
                    >
                        <Plus size={24} />
                        <span>Add More</span>
                    </button>
                </div>
            {/if}
        </div>
    {/if}
</div>

<!-- Preview Modal -->
{#if previewItem}
    <div
        class="preview-overlay"
        onclick={() => (previewItem = null)}
        onkeydown={(e) => e.key === "Escape" && (previewItem = null)}
        role="dialog"
        aria-modal="true"
        tabindex="-1"
    >
        <button class="preview-close" onclick={() => (previewItem = null)}
            ><X size={24} /></button
        >
        <div
            class="preview-content"
            role="document"
            onclick={(e) => e.stopPropagation()}
            onkeydown={() => {}}
        >
            {#if previewItem.media_type === "video"}
                <video
                    src={previewItem.url}
                    controls
                    class="preview-media"
                    autoplay
                >
                    <track kind="captions" />
                </video>
            {:else}
                <img
                    src={previewItem.url}
                    alt={previewItem.caption || previewItem.file_name}
                    class="preview-media"
                />
            {/if}
            {#if previewItem.caption}
                <p class="preview-caption">{previewItem.caption}</p>
            {/if}
        </div>
    </div>
{/if}

<style>
    .media-container {
        max-width: 1100px;
        margin: 0 auto;
    }

    .admin-topbar {
        margin-bottom: var(--space-8);
    }
    .admin-topbar h1 {
        font-family: var(--font-display);
        font-size: var(--text-3xl);
        font-weight: var(--weight-bold);
    }
    .topbar-desc {
        font-size: var(--text-sm);
        color: var(--color-text-muted);
        margin-top: var(--space-1);
    }

    .loading-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: var(--space-20);
        gap: var(--space-4);
        color: var(--color-text-muted);
    }

    /* Section */
    .media-section {
        margin-bottom: var(--space-10);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        padding: var(--space-6);
    }

    .section-head {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: var(--space-6);
    }

    .section-head-left {
        display: flex;
        align-items: center;
        gap: var(--space-4);
    }

    .section-icon {
        width: 44px;
        height: 44px;
        border-radius: var(--radius-lg);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .craft-icon {
        background: rgba(255, 140, 0, 0.12);
        color: var(--color-accent);
    }

    .ambiance-icon {
        background: rgba(59, 130, 246, 0.12);
        color: var(--color-info);
    }

    .section-head h2 {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
    }
    .section-head p {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        margin-top: 2px;
    }

    /* Empty State */
    .empty-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: var(--space-3);
        padding: var(--space-12);
        border: 2px dashed var(--color-border);
        border-radius: var(--radius-xl);
        color: var(--color-text-muted);
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .empty-state:hover {
        border-color: var(--color-primary);
        color: var(--color-text-secondary);
        background: rgba(230, 57, 70, 0.04);
    }

    .empty-state p {
        font-weight: var(--weight-semibold);
        font-size: var(--text-base);
    }
    .empty-state span {
        font-size: var(--text-xs);
    }

    /* Media Grid */
    .media-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: var(--space-4);
    }

    .media-card {
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        overflow: hidden;
        transition: all var(--transition-fast);
    }

    .media-card:hover {
        border-color: var(--color-border-hover);
        transform: translateY(-2px);
        box-shadow: var(--shadow-lg);
    }

    .media-thumb {
        position: relative;
        height: 160px;
        overflow: hidden;
    }

    .media-img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: block;
    }

    .media-type-badge {
        position: absolute;
        top: var(--space-2);
        left: var(--space-2);
        display: inline-flex;
        align-items: center;
        gap: 3px;
        font-size: 10px;
        font-weight: var(--weight-bold);
        color: white;
        background: rgba(0, 0, 0, 0.6);
        backdrop-filter: blur(4px);
        padding: 2px 8px;
        border-radius: var(--radius-full);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .media-info {
        padding: var(--space-3);
    }

    .title-input {
        width: 100%;
        background: none;
        border: none;
        border-bottom: 1px solid transparent;
        color: var(--color-text-primary);
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        padding: var(--space-1) 0;
        outline: none;
        transition: border-color var(--transition-fast);
        margin-bottom: var(--space-1);
    }

    .title-input::placeholder {
        color: var(--color-text-muted);
    }
    .title-input:focus {
        border-bottom-color: var(--color-primary);
    }

    .caption-input {
        width: 100%;
        background: none;
        border: none;
        border-bottom: 1px solid transparent;
        color: var(--color-text-primary);
        font-size: var(--text-xs);
        padding: var(--space-1) 0;
        outline: none;
        transition: border-color var(--transition-fast);
    }

    .caption-input::placeholder {
        color: var(--color-text-muted);
    }
    .caption-input:focus {
        border-bottom-color: var(--color-primary);
    }

    .media-meta {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-top: var(--space-2);
    }

    .file-size {
        font-size: 10px;
        color: var(--color-text-muted);
    }

    .media-actions {
        display: flex;
        gap: var(--space-1);
    }

    .action-btn {
        width: 28px;
        height: 28px;
        border-radius: var(--radius-md);
        background: none;
        border: 1px solid var(--color-border);
        color: var(--color-text-muted);
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .action-btn:hover {
        background: var(--color-bg-glass-hover);
        color: var(--color-text-primary);
        border-color: var(--color-border-hover);
    }

    .action-btn.danger:hover {
        background: rgba(230, 57, 70, 0.1);
        color: var(--color-danger);
        border-color: rgba(230, 57, 70, 0.3);
    }

    /* Add Card */
    .add-card {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: var(--space-2);
        min-height: 200px;
        border-style: dashed;
        cursor: pointer;
        color: var(--color-text-muted);
        background: transparent;
    }

    .add-card span {
        font-size: var(--text-xs);
        font-weight: var(--weight-medium);
    }

    .add-card:hover {
        border-color: var(--color-primary);
        color: var(--color-primary);
        background: rgba(230, 57, 70, 0.04);
    }

    /* Preview Modal */
    .preview-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.9);
        z-index: var(--z-modal, 100);
        display: flex;
        align-items: center;
        justify-content: center;
        padding: var(--space-6);
    }

    .preview-close {
        position: absolute;
        top: var(--space-4);
        right: var(--space-4);
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        background: rgba(255, 255, 255, 0.1);
        border: none;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .preview-close:hover {
        background: rgba(255, 255, 255, 0.2);
    }

    .preview-content {
        max-width: 900px;
        max-height: 80vh;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .preview-media {
        max-width: 100%;
        max-height: 75vh;
        border-radius: var(--radius-xl);
        object-fit: contain;
    }

    .preview-caption {
        margin-top: var(--space-4);
        font-size: var(--text-sm);
        color: rgba(255, 255, 255, 0.7);
        text-align: center;
    }

    @media (max-width: 768px) {
        .media-grid {
            grid-template-columns: repeat(2, 1fr);
        }
        .section-head {
            flex-direction: column;
            align-items: flex-start;
            gap: var(--space-4);
        }
        .section-head .btn {
            width: 100%;
        }
    }
</style>
