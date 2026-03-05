<script lang="ts">
    import { Instagram, Facebook, Twitter } from "lucide-svelte";
    import { APP_TAGLINE } from "$lib/constants";
    import { settings } from "$lib/stores/settings";
    import { t } from "$lib/stores/language";
</script>

<footer class="footer">
    <div class="footer-grid">
        <div class="footer-brand">
            <div class="footer-logo">
                {#if $settings?.logo_url}
                    <img
                        src={$settings.logo_url}
                        alt={$settings?.restaurant_name || "Pizza Mania"}
                        class="footer-logo-img"
                    />
                {:else}
                    <h3 class="footer-logo-text">
                        {$settings?.restaurant_name || "Pizza Mania"}
                    </h3>
                {/if}
            </div>
            <p class="footer-desc">
                {APP_TAGLINE}{$t("footer.desc")}
            </p>
            <div class="footer-socials">
                <a
                    href="https://www.instagram.com/"
                    target="_blank"
                    aria-label="Instagram"
                >
                    <Instagram size={20} />
                </a>
                <a
                    href="https://www.facebook.com/"
                    target="_blank"
                    aria-label="Facebook"
                >
                    <Facebook size={20} />
                </a>
                <a
                    href="https://www.twitter.com/"
                    target="_blank"
                    aria-label="Twitter"
                >
                    <Twitter size={20} />
                </a>
            </div>
        </div>
        <div class="footer-links">
            <h4>{$t("footer.links.title")}</h4>
            <ul>
                <li><a href="/menu">{$t("footer.links.menu")}</a></li>
                <li><a href="/offers">{$t("footer.links.offers")}</a></li>
                <li><a href="/order">{$t("footer.links.track")}</a></li>
                <li><a href="/#events">{$t("footer.links.book")}</a></li>
            </ul>
        </div>
        <div class="footer-links">
            <h4>{$t("footer.order.title")}</h4>
            <ul>
                <li><a href="/menu">{$t("footer.order.delivery")}</a></li>
                <li><a href="/menu">{$t("footer.order.takeaway")}</a></li>
                <li><a href="/menu">{$t("footer.order.dine_in")}</a></li>
            </ul>
        </div>
        <div class="footer-links">
            <h4>{$t("footer.contact.title")}</h4>
            <ul>
                {#if $settings?.phone}
                    <li>
                        <a href={`tel:${$settings.phone}`}>{$settings.phone}</a>
                    </li>
                {/if}
                {#if $settings?.email}
                    <li>
                        <a href={`mailto:${$settings.email}`}
                            >{$settings.email}</a
                        >
                    </li>
                {/if}
                {#if $settings?.address}
                    <li>{$settings.address}</li>
                {/if}
            </ul>
        </div>
    </div>
    <div class="footer-bottom">
        <p>
            © {new Date().getFullYear()}
            {$settings?.restaurant_name || "Pizza Mania"}. {$t("footer.rights")}
        </p>
        <p>
            {$settings?.address || ""}
            {#if $settings?.address && $settings?.phone}
                |
            {/if}
            {$settings?.phone || ""}
        </p>
    </div>
</footer>

<style>
    .footer {
        background: var(--color-bg-secondary);
        border-top: 1px solid var(--color-border);
        padding: var(--space-16) 0 var(--space-8);
    }

    .footer-grid {
        display: grid;
        grid-template-columns: 2fr 1fr 1fr 1fr;
        gap: var(--space-8);
        max-width: var(--container-xl);
        margin: 0 auto;
        padding: 0 var(--space-6);
    }

    .footer-brand {
        display: flex;
        flex-direction: column;
        gap: var(--space-4);
    }

    .footer-logo {
        display: flex;
        align-items: center;
    }

    .footer-logo-img {
        height: 72px;
        width: auto;
        object-fit: contain;
        mix-blend-mode: lighten;
    }

    .footer-desc {
        color: var(--color-text-muted);
        font-size: var(--text-sm);
        line-height: var(--leading-relaxed);
        max-width: 300px;
    }

    .footer-socials {
        display: flex;
        gap: var(--space-3);
    }

    .footer-socials a {
        color: var(--color-text-muted);
        transition: color var(--transition-fast);
    }

    .footer-socials a:hover {
        color: var(--color-primary);
    }

    .footer-links h4 {
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        color: var(--color-text-primary);
        margin-bottom: var(--space-4);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .footer-links ul {
        display: flex;
        flex-direction: column;
        gap: var(--space-3);
    }

    .footer-links a,
    .footer-links li {
        color: var(--color-text-muted);
        font-size: var(--text-sm);
        transition: color var(--transition-fast);
        text-decoration: none;
    }

    .footer-links a:hover {
        color: var(--color-text-primary);
    }

    .footer-bottom {
        margin-top: var(--space-12);
        padding-top: var(--space-6);
        border-top: 1px solid var(--color-border);
        display: flex;
        justify-content: space-between;
        align-items: center;
        max-width: var(--container-xl);
        margin-left: auto;
        margin-right: auto;
        padding-left: var(--space-6);
        padding-right: var(--space-6);
    }

    .footer-bottom p {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
    }

    @media (max-width: 768px) {
        .footer-grid {
            grid-template-columns: 1fr;
            gap: var(--space-8);
        }

        .footer-bottom {
            flex-direction: column;
            gap: var(--space-2);
            text-align: center;
        }
    }
</style>
