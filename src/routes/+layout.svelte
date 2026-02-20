<script lang="ts">
    import '../app.css';
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { Toaster } from 'svelte-sonner';
    import Header from '$lib/components/Header.svelte';
    import Footer from '$lib/components/Footer.svelte';
    import { settings } from '$lib/stores/settings';

    let { children } = $props();

    onMount(() => {
        settings.fetch();
    });

    let isAdmin = $derived($page.url.pathname.startsWith('/admin'));
</script>

<Toaster
    position="top-right"
    toastOptions={{
        style: 'background: #1A1A2E; color: #F1FAEE; border: 1px solid rgba(255, 255, 255, 0.08);'
    }}
/>

{#if isAdmin}
    {@render children()}
{:else}
    <Header />
    <main>
        {@render children()}
    </main>
    <footer class="app-footer">
        <Footer />
    </footer>
{/if}

<style>
</style>
