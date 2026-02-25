<script lang="ts">
    import { goto } from "$app/navigation";
    import { onMount } from "svelte";
    import {
        Truck,
        Store,
        Clock,
        Ticket,
        Search,
        Star,
        Quote,
        ChefHat,
        Flame,
        Leaf,
        Award,
        Heart,
        Phone,
        Mail,
        MapPin,
        PartyPopper,
        GraduationCap,
        Building2,
        Cake,
        Users,
        ArrowRight,
        ChevronLeft,
        ChevronRight,
    } from "lucide-svelte";
    import { cart } from "$lib/stores/cart";
    import { cn } from "$lib/utils";
    import { settings } from "$lib/stores/settings";
    import type { OrderType } from "$lib/types";
    import LocationModal from "$lib/components/LocationModal.svelte";
    import PickupModal from "$lib/components/PickupModal.svelte";
    import { CONTACT_INFO } from "$lib/constants";
    import { createClient } from "$lib/supabase/client";

    interface LandingMedia {
        id: string;
        category: string;
        media_type: string;
        url: string;
        title: string;
        caption: string;
    }

    let showLocationModal = $state(false);
    let showPickupModal = $state(false);

    // Testimonial slider
    let currentTestimonial = $state(0);
    let testimonialInterval: ReturnType<typeof setInterval>;

    const testimonials = [
        {
            name: "Sophie L.",
            text: "Best pizza in Jumet, hands down! The crust is perfectly crispy and the toppings are always fresh. We order every Friday night — it's become our family tradition.",
            rating: 5,
            date: "2 weeks ago",
        },
        {
            name: "Marc D.",
            text: "The wood-fired taste is incredible. You can tell they use quality ingredients and real passion goes into every pizza. Fast delivery too!",
            rating: 5,
            date: "1 month ago",
        },
        {
            name: "Amira K.",
            text: "We booked Pizza Mania for our company event and everyone loved it! Great selection, generous portions, and the staff was super friendly. Highly recommend for events.",
            rating: 5,
            date: "3 weeks ago",
        },
        {
            name: "Lucas B.",
            text: "I've tried pizzerias all over Belgium and this one stands out. The dough is made fresh daily and you can really taste the difference. Authentic Italian flavors!",
            rating: 4,
            date: "1 week ago",
        },
    ];

    let craftMedia = $state<LandingMedia[]>([]);
    let ambianceMedia = $state<LandingMedia[]>([]);
    let galleryModal = $state<"craft" | "ambiance" | null>(null);

    const CRAFT_PREVIEW_LIMIT = 4;
    const AMBIANCE_PREVIEW_LIMIT = 5;

    function shuffle<T>(arr: T[]): T[] {
        const a = [...arr];
        for (let i = a.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [a[i], a[j]] = [a[j], a[i]];
        }
        return a;
    }

    const eventTypes = [
        {
            icon: Building2,
            title: "Corporate Events",
            desc: "Team lunches, meetings & company parties",
        },
        {
            icon: GraduationCap,
            title: "School Groups",
            desc: "Field trips, end-of-year celebrations",
        },
        {
            icon: Cake,
            title: "Birthday Parties",
            desc: "Special menus & group packages",
        },
        {
            icon: Users,
            title: "Private Parties",
            desc: "Communions, family get-togethers & more",
        },
    ];

    onMount(async () => {
        testimonialInterval = setInterval(() => {
            currentTestimonial = (currentTestimonial + 1) % testimonials.length;
        }, 5000);

        // Fetch dynamic media
        try {
            const supabase = createClient();
            const { data } = await supabase
                .from("landing_media")
                .select("id, category, media_type, url, title, caption")
                .order("created_at", { ascending: true });

            if (data) {
                craftMedia = shuffle(
                    data.filter((m: LandingMedia) => m.category === "craft"),
                );
                ambianceMedia = shuffle(
                    data.filter((m: LandingMedia) => m.category === "ambiance"),
                );
            }
        } catch (err) {
            console.error("Failed to load landing media:", err);
        }

        return () => clearInterval(testimonialInterval);
    });

    // Lock body scroll when gallery modal is open
    $effect(() => {
        if (galleryModal) {
            document.body.style.overflow = "hidden";
        } else {
            document.body.style.overflow = "";
        }
    });

    function nextTestimonial() {
        currentTestimonial = (currentTestimonial + 1) % testimonials.length;
    }

    function prevTestimonial() {
        currentTestimonial =
            (currentTestimonial - 1 + testimonials.length) %
            testimonials.length;
    }

    function selectOrderType(type: OrderType) {
        if (type === "delivery") {
            showLocationModal = true;
            return;
        }
        if (type === "pickup") {
            showPickupModal = true;
            return;
        }
        cart.setOrderType(type);
        goto("/menu");
    }

    function handleLocationConfirm(data: any) {
        cart.setOrderType("delivery");
        cart.setOrderDetails({
            address: data.address,
            scheduledAt: data.scheduledAt,
        });
        goto("/menu");
    }

    function handlePickupConfirm(data: any) {
        cart.setOrderType("pickup");
        cart.setOrderDetails({
            address: data.address,
            scheduledAt: data.scheduledAt,
        });
        goto("/menu");
    }
</script>

<svelte:head>
    <title
        >{$settings?.restaurant_name || "Pizza Mania"} — Crafted with Passion, Served
        with Love</title
    >
    <meta
        name="description"
        content="Order the best wood-fired pizza in Jumet. Fresh ingredients, authentic recipes, fast delivery or pickup. Book events & private parties."
    />
</svelte:head>

<div class="landing-page">
    <!-- ============================================================
         SECTION 1: HERO
         ============================================================ -->
    <section class="hero" id="hero">
        <div class="hero-bg">
            <picture>
                <source
                    media="(min-width: 768px)"
                    srcset="/images/hero-bg-desktop.jpg"
                />
                <img
                    src="/images/hero-bg-mobile.jpg"
                    alt=""
                    class="hero-bg-img"
                />
            </picture>
            <div class="hero-bg-overlay"></div>
        </div>

        <!-- Top: Branding + CTA -->
        <div class="hero-top">
            <div class="hero-logo">
                {#if $settings?.logo_url}
                    <img
                        src={$settings.logo_url}
                        alt={$settings?.restaurant_name || "Pizza Mania"}
                        class="hero-logo-img"
                    />
                {/if}
                <div class="hero-logo-glow"></div>
            </div>
        </div>

        <!-- Bottom: Order Panel -->
        <div class="hero-bottom">
            <div class="hero-panel">
                <p class="hero-panel-title">How would you like your order?</p>

                <div class="order-cards">
                    <button
                        class="order-card delivery-card"
                        onclick={() => selectOrderType("delivery")}
                    >
                        <div class="order-card-icon delivery-icon">
                            <Truck size={26} />
                        </div>
                        <div class="order-card-info">
                            <h2>Delivery</h2>
                            <p>To your door</p>
                        </div>
                        <div class="order-card-meta">
                            <Clock size={12} />
                            <span>30–45 min</span>
                        </div>
                    </button>

                    <button
                        class="order-card pickup-card"
                        onclick={() => selectOrderType("pickup")}
                    >
                        <div class="order-card-icon pickup-icon">
                            <Store size={26} />
                        </div>
                        <div class="order-card-info">
                            <h2>Pickup</h2>
                            <p>At the counter</p>
                        </div>
                        <div class="order-card-meta">
                            <Clock size={12} />
                            <span>15–20 min</span>
                        </div>
                    </button>
                </div>

                <div class="hero-actions">
                    <a href="/offers" class="action-link offers">
                        <Ticket size={16} />
                        <span>Special Offers</span>
                    </a>
                    <a href="/order" class="action-link track">
                        <Search size={16} />
                        <span>Track Order</span>
                    </a>
                </div>

                <p class="dine-in-hint">
                    Dining in? Scan the <strong>QR code</strong> at your table
                </p>
            </div>
        </div>

        <!-- Scroll hint -->
        <div class="hero-scroll-hint">
            <div class="scroll-line"></div>
        </div>
    </section>

    <!-- ============================================================
         SECTION 2: OUR STORY (Personal Branding)
         ============================================================ -->
    <section class="section story-section" id="our-story">
        <div class="container">
            <div class="section-header">
                <span class="section-label"><Heart size={14} /> Our Story</span>
                <h2 class="section-title">
                    A Family Passion for <span class="text-gradient"
                        >Authentic Pizza</span
                    >
                </h2>
            </div>
            <div class="story-grid">
                <div class="story-image-wrapper">
                    <img
                        src="/images/founder-portrait.png"
                        alt="Our Founder"
                        class="story-image"
                    />
                    <div class="story-image-badge">
                        <Award size={16} />
                        <span>Since 2025</span>
                    </div>
                </div>
                <div class="story-content">
                    <p class="story-lead">
                        It all started with a simple love for good food and good
                        company. I’m Suleman, and I wanted to create a place
                        where people could feel at home, share a laugh, and
                        enjoy dishes made with care.
                    </p>
                    <p>
                        Every recipe here has a bit of my story — memories from
                        my childhood kitchen, flavors I discovered while
                        traveling, and a passion for bringing people together.
                        Our goal is simple: serve food that makes you smile and
                        a space where everyone belongs.
                    </p>
                    <p>Welcome to our table — make yourself at home.</p>
                    <div class="story-values">
                        <div class="value-item">
                            <div class="value-icon"><Flame size={18} /></div>
                            <div>
                                <strong>Wood-Fired</strong>
                                <span>Traditional brick oven at 450°C</span>
                            </div>
                        </div>
                        <div class="value-item">
                            <div class="value-icon"><Leaf size={18} /></div>
                            <div>
                                <strong>Fresh Daily</strong>
                                <span>Dough made fresh every morning</span>
                            </div>
                        </div>
                        <div class="value-item">
                            <div class="value-icon"><Heart size={18} /></div>
                            <div>
                                <strong>Made with Love</strong>
                                <span>Family recipes, crafted with passion</span
                                >
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- ============================================================
         SECTION 3: CUSTOMER TESTIMONIALS
         ============================================================ -->
    <section class="section testimonials-section" id="testimonials">
        <div class="container">
            <div class="section-header">
                <span class="section-label"
                    ><Star size={14} /> Testimonials</span
                >
                <h2 class="section-title">
                    What Our Customers <span class="text-gradient">Say</span>
                </h2>
                <p class="section-desc">
                    Real reviews from our happy customers
                </p>
            </div>

            <div class="testimonial-slider">
                <button
                    class="slider-arrow slider-prev"
                    onclick={prevTestimonial}
                    aria-label="Previous testimonial"
                >
                    <ChevronLeft size={20} />
                </button>

                <div class="testimonial-viewport">
                    {#each testimonials as t, i}
                        <div
                            class="testimonial-card glass"
                            class:active={i === currentTestimonial}
                            style="transform: translateX({(i -
                                currentTestimonial) *
                                110}%);"
                        >
                            <div class="testimonial-quote">
                                <Quote size={24} />
                            </div>
                            <p class="testimonial-text">{t.text}</p>
                            <div class="testimonial-stars">
                                {#each Array(5) as _, s}
                                    <Star
                                        size={16}
                                        fill={s < t.rating
                                            ? "var(--color-gold)"
                                            : "none"}
                                        color={s < t.rating
                                            ? "var(--color-gold)"
                                            : "var(--color-text-muted)"}
                                    />
                                {/each}
                            </div>
                            <div class="testimonial-author">
                                <div class="testimonial-avatar">
                                    {t.name.charAt(0)}
                                </div>
                                <div>
                                    <strong>{t.name}</strong>
                                    <span>{t.date}</span>
                                </div>
                            </div>
                        </div>
                    {/each}
                </div>

                <button
                    class="slider-arrow slider-next"
                    onclick={nextTestimonial}
                    aria-label="Next testimonial"
                >
                    <ChevronRight size={20} />
                </button>
            </div>

            <!-- Dots -->
            <div class="slider-dots">
                {#each testimonials as _, i}
                    <button
                        class="slider-dot"
                        class:active={i === currentTestimonial}
                        onclick={() => (currentTestimonial = i)}
                        aria-label="Go to testimonial {i + 1}"
                    ></button>
                {/each}
            </div>
        </div>
    </section>

    <!-- ============================================================
         SECTION 4: PIZZA PREPARATION MEDIA
         ============================================================ -->
    <section class="section prep-section" id="preparation">
        <div class="container">
            <div class="section-header">
                <span class="section-label"
                    ><ChefHat size={14} /> Our Craft</span
                >
                <h2 class="section-title">
                    From Dough to <span class="text-gradient">Perfection</span>
                </h2>
                <p class="section-desc">
                    Every pizza is a masterpiece — handcrafted with the finest
                    ingredients
                </p>
            </div>

            <div class="prep-showcase" class:has-one={craftMedia.length === 1}>
                <!-- Large Hero Image -->
                {#if craftMedia.length > 0}
                    <div class="prep-hero">
                        {#if craftMedia[0].media_type === "video"}
                            <video
                                src={craftMedia[0].url}
                                class="prep-hero-img"
                                autoplay
                                muted
                                loop
                                playsinline
                            >
                                <track kind="captions" />
                            </video>
                        {:else}
                            <img
                                src={craftMedia[0].url}
                                alt={craftMedia[0].caption ||
                                    craftMedia[0].title}
                                class="prep-hero-img"
                            />
                        {/if}
                        <div class="prep-hero-overlay">
                            <h3>{craftMedia[0].title || "The Art of Dough"}</h3>
                            {#if craftMedia[0].caption}
                                <p>{craftMedia[0].caption}</p>
                            {/if}
                        </div>
                    </div>
                {/if}

                <!-- Side Grid (limited) -->
                {#if craftMedia.length > 1}
                    <div class="prep-details">
                        {#each craftMedia.slice(1, CRAFT_PREVIEW_LIMIT) as item, idx}
                            {@const isLast =
                                idx ===
                                Math.min(
                                    craftMedia.length - 2,
                                    CRAFT_PREVIEW_LIMIT - 2,
                                )}
                            {@const remaining =
                                craftMedia.length - CRAFT_PREVIEW_LIMIT}
                            <div
                                class="prep-card"
                                class:clickable={isLast && remaining > 0}
                                role={isLast && remaining > 0
                                    ? "button"
                                    : undefined}
                                tabindex={isLast && remaining > 0
                                    ? 0
                                    : undefined}
                                onclick={() =>
                                    isLast &&
                                    remaining > 0 &&
                                    (galleryModal = "craft")}
                                onkeydown={(e) =>
                                    isLast &&
                                    remaining > 0 &&
                                    e.key === "Enter" &&
                                    (galleryModal = "craft")}
                            >
                                {#if item.media_type === "video"}
                                    <video
                                        src={item.url}
                                        class="prep-card-img"
                                        autoplay
                                        muted
                                        loop
                                        playsinline
                                    >
                                        <track kind="captions" />
                                    </video>
                                {:else}
                                    <img
                                        src={item.url}
                                        alt={item.caption || item.title}
                                        class="prep-card-img"
                                    />
                                {/if}
                                {#if isLast && remaining > 0}
                                    <div class="more-overlay">
                                        <span class="more-count"
                                            >+{remaining}</span
                                        >
                                        <span class="more-label">View All</span>
                                    </div>
                                {:else}
                                    <div class="prep-card-overlay">
                                        <h4>{item.title}</h4>
                                        {#if item.caption}
                                            <p>{item.caption}</p>
                                        {/if}
                                    </div>
                                {/if}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>

            <div class="prep-stats">
                <div class="stat-item">
                    <span class="stat-number">48h</span>
                    <span class="stat-label">Dough Fermentation</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">450°C</span>
                    <span class="stat-label">Oven Temperature</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">10min</span>
                    <span class="stat-label">Cooking Time</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">100%</span>
                    <span class="stat-label">Fresh Ingredients</span>
                </div>
            </div>
        </div>
    </section>

    <!-- ============================================================
         SECTION 5: PIZZERIA PHOTOS GALLERY
         ============================================================ -->
    <section class="section gallery-section" id="gallery">
        <div class="container">
            <div class="section-header">
                <span class="section-label"
                    ><Award size={14} /> Our Pizzeria</span
                >
                <h2 class="section-title">
                    Experience the <span class="text-gradient">Ambiance</span>
                </h2>
                <p class="section-desc">
                    A warm, welcoming space where great food meets great moments
                </p>
            </div>

            <div class="gallery-grid">
                {#each ambianceMedia.slice(0, AMBIANCE_PREVIEW_LIMIT) as item, i}
                    {@const isLast =
                        i ===
                        Math.min(
                            ambianceMedia.length - 1,
                            AMBIANCE_PREVIEW_LIMIT - 1,
                        )}
                    {@const remaining =
                        ambianceMedia.length - AMBIANCE_PREVIEW_LIMIT}
                    <div
                        class="gallery-item"
                        class:gallery-item-large={i === 0}
                        class:span-col-2={ambianceMedia.length === 4 && i === 3}
                        class:span-row-2={ambianceMedia.length === 2 && i === 1}
                        class:span-col-2-row-2={ambianceMedia.length === 3 &&
                            i >= 1}
                        class:clickable={isLast && remaining > 0}
                        role={isLast && remaining > 0 ? "button" : undefined}
                        tabindex={isLast && remaining > 0 ? 0 : undefined}
                        onclick={() =>
                            isLast &&
                            remaining > 0 &&
                            (galleryModal = "ambiance")}
                        onkeydown={(e) =>
                            isLast &&
                            remaining > 0 &&
                            e.key === "Enter" &&
                            (galleryModal = "ambiance")}
                    >
                        {#if item.media_type === "video"}
                            <video
                                src={item.url}
                                class="gallery-img"
                                autoplay
                                muted
                                loop
                                playsinline
                            >
                                <track kind="captions" />
                            </video>
                        {:else}
                            <img
                                src={item.url}
                                alt={item.caption || item.title}
                                class="gallery-img"
                                loading="lazy"
                            />
                        {/if}
                        {#if isLast && remaining > 0}
                            <div class="more-overlay">
                                <span class="more-count">+{remaining}</span>
                                <span class="more-label">View All</span>
                            </div>
                        {:else}
                            <div class="gallery-overlay">
                                <span class="gallery-label">{item.title}</span>
                            </div>
                        {/if}
                    </div>
                {/each}
            </div>

            <!-- Virtual Tour -->
            <div class="virtual-tour">
                <div class="virtual-tour-header">
                    <span class="virtual-tour-badge">📍 360° Virtual Tour</span>
                    <p class="virtual-tour-desc">
                        Explore our pizzeria from the comfort of your home
                    </p>
                </div>
                <div class="virtual-tour-frame">
                    <iframe
                        src="https://www.google.com/maps/embed?pb=!4v1708700000000!6m8!1m7!1sf8SGQCW8Bs40MuqSc0ucmA!2m2!1d50.4!2d4.43!3f143.2!4f0!5f0.7820865974627469"
                        width="100%"
                        height="100%"
                        style="border:0;"
                        allowfullscreen
                        loading="lazy"
                        referrerpolicy="no-referrer-when-downgrade"
                        title="Pizza Mania 360° Virtual Tour"
                    ></iframe>
                </div>
                <a
                    href="https://www.google.com/local/place/fid/0x47c22f6d23975635:0x83092d5fb9d950ad/photosphere?iu=https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid%3Df8SGQCW8Bs40MuqSc0ucmA%26cb_client%3Dsearch.gws-prod.gps%26yaw%3D143.19789%26pitch%3D0%26thumbfov%3D100%26w%3D0%26h%3D0&ik=CAISFmY4U0dRQ1c4QnM0ME11cVNjMHVjbUE%3D"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="virtual-tour-link"
                >
                    Open full experience in Google Maps →
                </a>
            </div>
        </div>
    </section>

    <!-- ============================================================
         SECTION 6: EVENT RESERVATIONS
         ============================================================ -->
    <section class="section events-section" id="events">
        <div class="container">
            <div class="events-content">
                <div class="section-header">
                    <span class="section-label"
                        ><PartyPopper size={14} /> Events</span
                    >
                    <h2 class="section-title">
                        Host Your Next Event <span class="text-gradient"
                            >With Us</span
                        >
                    </h2>
                    <p class="section-desc">
                        From intimate gatherings to large celebrations — we've
                        got you covered
                    </p>
                </div>

                <div class="events-grid">
                    {#each eventTypes as event}
                        <div class="event-card glass">
                            <div class="event-card-icon">
                                <event.icon size={24} />
                            </div>
                            <h3>{event.title}</h3>
                            <p>{event.desc}</p>
                        </div>
                    {/each}
                </div>

                <div class="events-cta">
                    <div class="events-phone">
                        <Phone size={24} />
                        <div>
                            <span class="phone-label">Call us to book</span>
                            <a
                                href="tel:{$settings?.phone ||
                                    CONTACT_INFO.phone}"
                                class="phone-number"
                            >
                                {$settings?.phone || CONTACT_INFO.phone}
                            </a>
                        </div>
                    </div>
                    <div class="events-buttons">
                        <a
                            href="tel:{$settings?.phone || CONTACT_INFO.phone}"
                            class="btn btn-primary btn-lg"
                        >
                            <Phone size={18} />
                            Book an Event
                        </a>
                        <a
                            href="https://wa.me/{(
                                CONTACT_INFO.whatsapp || ''
                            ).replace('+', '')}"
                            target="_blank"
                            class="btn btn-outline btn-lg"
                        >
                            <Mail size={18} />
                            WhatsApp Us
                        </a>
                    </div>
                </div>

                <div class="events-info">
                    <div class="info-item">
                        <MapPin size={16} />
                        <span>{$settings?.address || CONTACT_INFO.address}</span
                        >
                    </div>
                    <div class="info-item">
                        <Mail size={16} />
                        <a
                            href="mailto:{$settings?.email ||
                                CONTACT_INFO.email}"
                            >{$settings?.email || CONTACT_INFO.email}</a
                        >
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>

<!-- Gallery Modal -->
{#if galleryModal}
    {@const items = galleryModal === "craft" ? craftMedia : ambianceMedia}
    <div
        class="gallery-modal-overlay"
        role="dialog"
        aria-modal="true"
        tabindex="-1"
        onkeydown={(e) => e.key === "Escape" && (galleryModal = null)}
    >
        <div class="gallery-modal">
            <div class="gallery-modal-header">
                <h2>
                    {galleryModal === "craft"
                        ? "🍕 Our Craft"
                        : "🏠 Our Pizzeria"}
                </h2>
                <button
                    class="gallery-modal-close"
                    onclick={() => (galleryModal = null)}>✕</button
                >
            </div>
            <div class="gallery-modal-grid">
                {#each items as item}
                    <div class="gallery-modal-item">
                        {#if item.media_type === "video"}
                            <video
                                src={item.url}
                                class="gallery-modal-media"
                                controls
                                playsinline
                            >
                                <track kind="captions" />
                            </video>
                        {:else}
                            <img
                                src={item.url}
                                alt={item.caption || item.title}
                                class="gallery-modal-media"
                            />
                        {/if}
                        {#if item.title || item.caption}
                            <div class="gallery-modal-info">
                                {#if item.title}<h4>{item.title}</h4>{/if}
                                {#if item.caption}<p>{item.caption}</p>{/if}
                            </div>
                        {/if}
                    </div>
                {/each}
            </div>
        </div>
    </div>
{/if}

<LocationModal
    bind:show={showLocationModal}
    onConfirm={handleLocationConfirm}
/>

<PickupModal bind:show={showPickupModal} onConfirm={handlePickupConfirm} />

<style>
    /* ============================================================
       LANDING PAGE GLOBAL
       ============================================================ */
    .landing-page {
        overflow-x: hidden;
    }

    .section {
        padding: var(--space-20) 0;
        position: relative;
    }

    .section:nth-child(even) {
        background: var(--color-bg-secondary);
    }

    .section-header {
        text-align: center;
        margin-bottom: var(--space-12);
    }

    .section-label {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        font-size: var(--text-xs);
        font-weight: var(--weight-semibold);
        text-transform: uppercase;
        letter-spacing: 0.1em;
        color: var(--color-accent);
        margin-bottom: var(--space-3);
        background: rgba(255, 140, 0, 0.1);
        padding: var(--space-1) var(--space-3);
        border-radius: var(--radius-full);
    }

    .section-title {
        font-family: var(--font-display);
        font-size: var(--text-4xl);
        font-weight: var(--weight-bold);
        color: var(--color-text-primary);
        line-height: var(--leading-tight);
        margin-bottom: var(--space-4);
    }

    .section-desc {
        font-size: var(--text-lg);
        color: var(--color-text-secondary);
        max-width: 600px;
        margin: 0 auto;
    }

    .text-gradient {
        background: linear-gradient(
            135deg,
            var(--color-primary),
            var(--color-accent)
        );
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
    }

    /* ============================================================
       HERO
       ============================================================ */
    .hero {
        position: relative;
        min-height: 100dvh;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        overflow: hidden;
    }

    .hero-bg {
        position: absolute;
        inset: 0;
        z-index: 0;
        overflow: hidden;
    }

    .hero-bg picture {
        display: block;
        width: 100%;
        height: 100%;
    }

    .hero-bg-img {
        width: 100%;
        height: 100%;
        rotate: unset;
        object-fit: cover;
        object-position: center 30%;
        animation: heroZoom 10s ease-in-out infinite alternate;
    }

    @keyframes heroZoom {
        0% {
            transform: scale(1);
        }
        100% {
            transform: scale(1.08);
        }
    }

    .hero-bg-overlay {
        position: absolute;
        inset: 0;
        background: linear-gradient(
            180deg,
            rgba(0, 0, 0, 0.7) 0%,
            rgba(0, 0, 0, 0.5) 25%,
            rgba(0, 0, 0, 0.2) 45%,
            rgba(0, 0, 0, 0.25) 60%,
            rgba(0, 0, 0, 0.85) 100%
        );
    }

    /* Hero Top — Branding */
    .hero-top {
        position: relative;
        z-index: 1;
        display: flex;
        justify-content: center; /* horizontal center */
        align-items: center; /* vertical center */
        padding: 0;
        margin: 0;
        text-align: center;
    }

    .hero-logo {
        width: 100%;
        margin: 0;
        display: flex;
        justify-content: center;
        align-items: center;
        line-height: 0; /* removes inline gap */
    }

    .hero-logo-img {
        width: 90%;
        max-width: 90%;
        height: auto;
        display: block;
        object-fit: contain;
        filter: drop-shadow(0 4px 12px rgba(0, 0, 0, 0.5));
    }

    @media (min-width: 768px) {
        .hero-logo-img {
            max-width: 520px; /* adjust if needed */
            padding-top: 60px;
        }
    }

    @keyframes shimmerText {
        0%,
        100% {
            background-position: 0% center;
        }
        50% {
            background-position: 200% center;
        }
    }

    .hero-logo-glow {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 120%;
        height: 200%;
        background: radial-gradient(
            ellipse at center,
            rgba(255, 160, 60, 0.15) 0%,
            transparent 70%
        );
        pointer-events: none;
        animation: glowPulse 3s ease-in-out infinite;
    }

    @keyframes glowPulse {
        0%,
        100% {
            opacity: 0.5;
            transform: translate(-50%, -50%) scale(1);
        }
        50% {
            opacity: 1;
            transform: translate(-50%, -50%) scale(1.1);
        }
    }

    /* Tagline */
    .hero-tagline-wrapper {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        margin-bottom: var(--space-4);
        animation: heroFadeIn 0.8s ease-out 0.2s both;
    }

    .tagline-decoration {
        width: 32px;
        height: 1px;
        background: linear-gradient(
            90deg,
            transparent,
            rgba(255, 200, 120, 0.6)
        );
        flex-shrink: 0;
    }

    .tagline-decoration:last-child {
        background: linear-gradient(
            90deg,
            rgba(255, 200, 120, 0.6),
            transparent
        );
    }

    .hero-tagline {
        font-family: var(--font-display);
        font-size: var(--text-lg);
        color: rgba(255, 255, 255, 0.95);
        font-weight: var(--weight-semibold);
        font-style: italic;
        text-shadow:
            0 1px 6px rgba(0, 0, 0, 0.8),
            0 0 20px rgba(0, 0, 0, 0.4);
        letter-spacing: 0.02em;
    }

    /* Badges */
    .hero-badges {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        animation: heroFadeIn 0.8s ease-out 0.4s both;
    }

    .hero-badge-pill {
        display: inline-flex;
        align-items: center;
        gap: var(--space-1);
        font-size: var(--text-xs);
        font-weight: var(--weight-semibold);
        color: rgba(255, 255, 255, 0.85);
        background: rgba(255, 255, 255, 0.08);
        backdrop-filter: blur(8px);
        -webkit-backdrop-filter: blur(8px);
        border: 1px solid rgba(255, 255, 255, 0.1);
        padding: var(--space-1) var(--space-3);
        border-radius: var(--radius-full);
        transition: all var(--transition-fast);
        cursor: default;
    }

    .hero-badge-pill:hover {
        background: rgba(255, 255, 255, 0.15);
        border-color: rgba(255, 200, 120, 0.3);
        transform: translateY(-2px);
        color: white;
    }

    @keyframes heroFadeIn {
        from {
            opacity: 0;
            transform: translateY(-16px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    /* Hero Bottom — Order Panel */
    .hero-bottom {
        position: relative;
        z-index: 1;
        padding: 0 var(--space-4) var(--space-10);
        animation: fadeInUp 0.6s ease-out 0.15s both;
    }

    .hero-panel {
        max-width: 520px;
        margin: 0 auto;
        background: rgba(10, 10, 20, 0.75);
        backdrop-filter: blur(24px);
        -webkit-backdrop-filter: blur(24px);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: var(--radius-2xl);
        padding: var(--space-6);
    }

    .hero-panel-title {
        font-size: var(--text-base);
        font-weight: var(--weight-semibold);
        color: var(--color-text-primary);
        text-align: center;
        margin-bottom: var(--space-4);
    }

    /* Order Cards */
    .order-cards {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: var(--space-3);
        width: 100%;
        margin-bottom: var(--space-4);
    }

    .order-card {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-2);
        padding: var(--space-5) var(--space-4);
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: var(--radius-xl);
        cursor: pointer;
        transition: all var(--transition-base);
        text-align: center;
        width: 100%;
        color: var(--color-text-primary);
        -webkit-tap-highlight-color: transparent;
    }

    .order-card:hover {
        border-color: rgba(255, 255, 255, 0.2);
        transform: translateY(-3px);
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        background: rgba(255, 255, 255, 0.1);
    }

    .order-card:active {
        transform: scale(0.97);
        box-shadow: none;
    }

    .order-card-icon {
        width: 50px;
        height: 50px;
        border-radius: var(--radius-lg);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .delivery-icon {
        background: rgba(59, 130, 246, 0.15);
        color: #60a5fa;
    }

    .delivery-card:hover {
        border-color: rgba(59, 130, 246, 0.4);
        background: rgba(59, 130, 246, 0.1);
    }

    .pickup-icon {
        background: rgba(42, 157, 143, 0.15);
        color: #4fd1c5;
    }

    .pickup-card:hover {
        border-color: rgba(42, 157, 143, 0.4);
        background: rgba(42, 157, 143, 0.1);
    }

    .order-card-info h2 {
        font-size: var(--text-base);
        font-weight: var(--weight-bold);
        margin-bottom: 1px;
    }

    .order-card-info p {
        font-size: var(--text-xs);
        color: rgba(255, 255, 255, 0.5);
    }

    .order-card-meta {
        display: inline-flex;
        align-items: center;
        gap: 3px;
        font-size: 10px;
        color: rgba(255, 255, 255, 0.45);
        background: rgba(255, 255, 255, 0.06);
        padding: 2px 8px;
        border-radius: var(--radius-full);
        white-space: nowrap;
        margin-top: var(--space-1);
    }

    .hero-actions {
        display: flex;
        gap: var(--space-3);
        width: 100%;
        margin-bottom: var(--space-3);
    }

    .action-link {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-2);
        font-weight: var(--weight-medium);
        font-size: var(--text-xs);
        text-decoration: none;
        padding: var(--space-2) var(--space-4);
        border-radius: var(--radius-full);
        transition: all var(--transition-fast);
        flex: 1;
    }

    .action-link.offers {
        color: var(--color-accent);
        background: rgba(255, 140, 0, 0.12);
    }

    .action-link.offers:hover {
        background: rgba(255, 140, 0, 0.22);
        transform: translateY(-1px);
    }

    .action-link.track {
        color: rgba(255, 255, 255, 0.6);
        background: rgba(255, 255, 255, 0.06);
        border: 1px solid rgba(255, 255, 255, 0.08);
    }

    .action-link.track:hover {
        background: rgba(255, 255, 255, 0.1);
        border-color: rgba(255, 255, 255, 0.15);
        color: white;
        transform: translateY(-1px);
    }

    .dine-in-hint {
        font-size: var(--text-xs);
        color: rgba(255, 255, 255, 0.35);
        text-align: center;
    }

    .dine-in-hint strong {
        color: rgba(255, 255, 255, 0.55);
    }

    /* Scroll Hint */
    .hero-scroll-hint {
        position: absolute;
        bottom: var(--space-4);
        left: 50%;
        transform: translateX(-50%);
        z-index: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .scroll-line {
        width: 2px;
        height: 28px;
        border-radius: 2px;
        background: linear-gradient(
            180deg,
            rgba(255, 255, 255, 0.4),
            rgba(255, 255, 255, 0)
        );
        animation: scrollPulse 2s ease-in-out infinite;
    }

    @keyframes scrollPulse {
        0%,
        100% {
            opacity: 0.3;
            transform: scaleY(0.6);
        }
        50% {
            opacity: 1;
            transform: scaleY(1);
        }
    }

    /* ============================================================
       OUR STORY
       ============================================================ */
    .story-grid {
        display: grid;
        grid-template-columns: 1fr 1.2fr;
        gap: var(--space-12);
        align-items: center;
    }

    .story-image-wrapper {
        position: relative;
        border-radius: var(--radius-2xl);
        overflow: hidden;
    }

    .story-image {
        width: 100%;
        height: 500px;
        object-fit: cover;
        border-radius: var(--radius-2xl);
        transition: transform var(--transition-slow);
    }

    .story-image-wrapper:hover .story-image {
        transform: scale(1.03);
    }

    .story-image-badge {
        position: absolute;
        bottom: var(--space-4);
        left: var(--space-4);
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        background: rgba(0, 0, 0, 0.7);
        backdrop-filter: blur(10px);
        padding: var(--space-2) var(--space-4);
        border-radius: var(--radius-full);
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        color: var(--color-gold);
    }

    .story-content {
        display: flex;
        flex-direction: column;
        gap: var(--space-4);
    }

    .story-lead {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: var(--weight-semibold);
        color: var(--color-text-primary);
        line-height: var(--leading-snug);
    }

    .story-content p {
        font-size: var(--text-base);
        color: var(--color-text-secondary);
        line-height: var(--leading-relaxed);
    }

    .story-values {
        display: flex;
        flex-direction: column;
        gap: var(--space-4);
        margin-top: var(--space-4);
        padding-top: var(--space-6);
        border-top: 1px solid var(--color-border);
    }

    .value-item {
        display: flex;
        align-items: center;
        gap: var(--space-4);
    }

    .value-icon {
        width: 44px;
        height: 44px;
        border-radius: var(--radius-lg);
        background: rgba(255, 140, 0, 0.1);
        color: var(--color-accent);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .value-item strong {
        display: block;
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        color: var(--color-text-primary);
    }

    .value-item span {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
    }

    /* ============================================================
       TESTIMONIALS
       ============================================================ */
    .testimonial-slider {
        position: relative;
        display: flex;
        align-items: center;
        gap: var(--space-4);
        max-width: 700px;
        margin: 0 auto;
    }

    .testimonial-viewport {
        position: relative;
        overflow: hidden;
        flex: 1;
        min-height: 280px;
    }

    .testimonial-card {
        position: absolute;
        inset: 0;
        padding: var(--space-8);
        border-radius: var(--radius-2xl);
        transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
        opacity: 0;
        pointer-events: none;
    }

    .testimonial-card.active {
        opacity: 1;
        pointer-events: auto;
    }

    .testimonial-quote {
        color: var(--color-accent);
        margin-bottom: var(--space-4);
        opacity: 0.5;
    }

    .testimonial-text {
        font-size: var(--text-base);
        color: var(--color-text-secondary);
        line-height: var(--leading-relaxed);
        margin-bottom: var(--space-4);
        font-style: italic;
    }

    .testimonial-stars {
        display: flex;
        gap: 2px;
        margin-bottom: var(--space-4);
    }

    .testimonial-author {
        display: flex;
        align-items: center;
        gap: var(--space-3);
    }

    .testimonial-avatar {
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        background: linear-gradient(
            135deg,
            var(--color-primary),
            var(--color-accent)
        );
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: var(--weight-bold);
        font-size: var(--text-sm);
    }

    .testimonial-author strong {
        display: block;
        font-size: var(--text-sm);
        color: var(--color-text-primary);
    }

    .testimonial-author span {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
    }

    .slider-arrow {
        width: 40px;
        height: 40px;
        border-radius: var(--radius-full);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        color: var(--color-text-secondary);
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all var(--transition-fast);
        flex-shrink: 0;
    }

    .slider-arrow:hover {
        background: var(--color-bg-glass-hover);
        color: var(--color-text-primary);
        border-color: var(--color-border-hover);
    }

    .slider-dots {
        display: flex;
        justify-content: center;
        gap: var(--space-2);
        margin-top: var(--space-6);
    }

    .slider-dot {
        width: 8px;
        height: 8px;
        border-radius: var(--radius-full);
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        cursor: pointer;
        transition: all var(--transition-fast);
    }

    .slider-dot.active {
        background: var(--color-primary);
        border-color: var(--color-primary);
        width: 24px;
    }

    /* ============================================================
       PIZZA PREPARATION
       ============================================================ */
    .prep-showcase {
        display: grid;
        grid-template-columns: 1.5fr 1fr;
        gap: var(--space-6);
        margin-bottom: var(--space-12);
    }

    .prep-showcase.has-one {
        grid-template-columns: 1fr;
    }

    .prep-hero {
        position: relative;
        border-radius: var(--radius-2xl);
        overflow: hidden;
        height: 500px;
    }

    .prep-hero-img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        transition: transform var(--transition-slow);
    }

    .prep-hero:hover .prep-hero-img {
        transform: scale(1.05);
    }

    .prep-hero-overlay {
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        padding: var(--space-8) var(--space-6);
        background: linear-gradient(transparent, rgba(0, 0, 0, 0.85));
    }

    .prep-hero-overlay h3 {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: var(--weight-bold);
        color: white;
        margin-bottom: var(--space-2);
    }

    .prep-hero-overlay p {
        font-size: var(--text-sm);
        color: rgba(255, 255, 255, 0.7);
    }

    .prep-details {
        display: flex;
        flex-direction: column;
        gap: var(--space-6);
    }

    .prep-card {
        position: relative;
        border-radius: var(--radius-xl);
        overflow: hidden;
        flex: 1;
    }

    .prep-card-img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        transition: transform var(--transition-slow);
    }

    .prep-card:hover .prep-card-img {
        transform: scale(1.05);
    }

    .prep-card-overlay {
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        padding: var(--space-4);
        background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
    }

    .prep-card-overlay h4 {
        font-size: var(--text-sm);
        font-weight: var(--weight-bold);
        color: white;
        margin-bottom: 2px;
    }

    .prep-card-overlay p {
        font-size: var(--text-xs);
        color: rgba(255, 255, 255, 0.7);
    }

    .prep-stats {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: var(--space-6);
    }

    .stat-item {
        text-align: center;
        padding: var(--space-6);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-xl);
        transition: all var(--transition-base);
    }

    .stat-item:hover {
        border-color: var(--color-border-hover);
        transform: translateY(-2px);
    }

    .stat-number {
        display: block;
        font-family: var(--font-display);
        font-size: var(--text-3xl);
        font-weight: var(--weight-bold);
        color: var(--color-accent);
        margin-bottom: var(--space-2);
    }

    .stat-label {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    /* ============================================================
       GALLERY
       ============================================================ */
    .gallery-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        grid-template-rows: auto auto;
        gap: var(--space-4);
    }

    .gallery-item {
        position: relative;
        border-radius: var(--radius-xl);
        overflow: hidden;
        height: 280px;
    }

    .gallery-item-large {
        grid-row: span 2;
        height: 100%;
    }

    .span-col-2 {
        grid-column: span 2;
    }

    .span-row-2 {
        grid-row: span 2;
        height: 100%;
    }

    .span-col-2-row-2 {
        grid-column: span 2;
        height: 280px; /* Force height so it doesn't stretch badly, or keep 100% depending on flex*/
    }

    .gallery-img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        transition: transform var(--transition-slow);
    }

    .gallery-item:hover .gallery-img {
        transform: scale(1.08);
    }

    .gallery-overlay {
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        padding: var(--space-4);
        background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
        opacity: 0;
        transition: opacity var(--transition-base);
    }

    .gallery-item:hover .gallery-overlay {
        opacity: 1;
    }

    .gallery-label {
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        color: white;
    }

    /* +N More Overlay */
    .clickable {
        cursor: pointer;
    }

    .more-overlay {
        position: absolute;
        inset: 0;
        background: rgba(0, 0, 0, 0.7);
        backdrop-filter: blur(3px);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: var(--space-1);
        z-index: 2;
        transition: background var(--transition-fast);
    }

    .clickable:hover .more-overlay {
        background: rgba(0, 0, 0, 0.55);
    }

    .more-count {
        font-size: 2.5rem;
        font-weight: var(--weight-bold);
        color: white;
        line-height: 1;
    }

    .more-label {
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: rgba(255, 255, 255, 0.7);
        text-transform: uppercase;
        letter-spacing: 0.08em;
    }

    /* Gallery Modal */
    .gallery-modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.85);
        backdrop-filter: blur(8px);
        z-index: 200;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: var(--space-6);
    }

    .gallery-modal {
        width: min(90vw, 1200px);
        height: 85vh;
        background: var(--color-bg-primary);
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }

    .gallery-modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--space-5) var(--space-6);
        border-bottom: 1px solid var(--color-border);
        flex-shrink: 0;
    }

    .gallery-modal-header h2 {
        font-family: var(--font-display);
        font-size: var(--text-xl);
        font-weight: var(--weight-bold);
    }

    .gallery-modal-close {
        width: 36px;
        height: 36px;
        border-radius: var(--radius-full);
        background: var(--color-bg-glass);
        border: 1px solid var(--color-border);
        color: var(--color-text-secondary);
        font-size: var(--text-base);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all var(--transition-fast);
    }

    .gallery-modal-close:hover {
        background: var(--color-bg-glass-hover);
        color: var(--color-text-primary);
    }

    .gallery-modal-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(min(100%, 280px), 1fr));
        gap: var(--space-5);
        padding: var(--space-6);
        overflow-y: auto;
        flex: 1;
        align-content: start; /* PREVENTS VERTICAL STRETCHING */
    }

    .gallery-modal-item {
        border-radius: var(--radius-xl);
        background: var(--color-bg-tertiary);
        border: 1px solid var(--color-border);
        display: flex;
        flex-direction: column;
    }

    .gallery-modal-item img,
    .gallery-modal-item video {
        overflow: hidden;
        border-radius: var(--radius-xl);
    }

    .gallery-modal-item:hover {
        border-color: var(--color-border-hover);
        transform: translateY(-2px);
        box-shadow: var(--shadow-lg);
    }

    .gallery-modal-media {
        width: 100%;
        aspect-ratio: 4 / 3;
        flex-shrink: 0;
        object-fit: cover;
        display: block;
    }

    .gallery-modal-info {
        padding: var(--space-3) var(--space-4);
    }

    .gallery-modal-info h4 {
        font-size: var(--text-sm);
        font-weight: var(--weight-semibold);
        margin-bottom: 2px;
    }

    .gallery-modal-info p {
        font-size: var(--text-xs);
        color: var(--color-text-muted);
    }

    /* Virtual Tour */
    .virtual-tour {
        margin-top: var(--space-10);
        text-align: center;
    }

    .virtual-tour-header {
        margin-bottom: var(--space-6);
    }

    .virtual-tour-badge {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        font-size: var(--text-sm);
        font-weight: var(--weight-bold);
        color: var(--color-accent);
        background: rgba(255, 140, 0, 0.1);
        padding: var(--space-2) var(--space-4);
        border-radius: var(--radius-full);
        margin-bottom: var(--space-3);
    }

    .virtual-tour-desc {
        font-size: var(--text-base);
        color: var(--color-text-secondary);
    }

    .virtual-tour-frame {
        width: 100%;
        aspect-ratio: 16 / 9;
        border-radius: var(--radius-2xl);
        overflow: hidden;
        border: 1px solid var(--color-border);
        box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3);
    }

    .virtual-tour-frame iframe {
        width: 100%;
        height: 100%;
        display: block;
    }

    .virtual-tour-link {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        margin-top: var(--space-4);
        font-size: var(--text-sm);
        font-weight: var(--weight-medium);
        color: var(--color-text-secondary);
        text-decoration: none;
        transition: color var(--transition-fast);
    }

    .virtual-tour-link:hover {
        color: var(--color-accent);
    }

    /* ============================================================
       EVENTS
       ============================================================ */
    .events-content {
        max-width: 900px;
        margin: 0 auto;
    }

    .events-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: var(--space-4);
        margin-bottom: var(--space-8);
    }

    .event-card {
        padding: var(--space-6);
        text-align: center;
        border-radius: var(--radius-xl);
        transition: all var(--transition-base);
    }

    .event-card:hover {
        transform: translateY(-4px);
        border-color: var(--color-border-hover);
    }

    .event-card-icon {
        width: 56px;
        height: 56px;
        border-radius: var(--radius-xl);
        background: rgba(255, 140, 0, 0.1);
        color: var(--color-accent);
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto var(--space-4);
    }

    .event-card h3 {
        font-size: var(--text-lg);
        font-weight: var(--weight-bold);
        margin-bottom: var(--space-2);
    }

    .event-card p {
        font-size: var(--text-sm);
        color: var(--color-text-muted);
    }

    .events-cta {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: var(--space-6);
        padding: var(--space-8);
        background: linear-gradient(
            135deg,
            rgba(255, 0, 0, 0.08),
            rgba(255, 140, 0, 0.08)
        );
        border: 1px solid var(--color-border);
        border-radius: var(--radius-2xl);
        margin-bottom: var(--space-6);
    }

    .events-phone {
        display: flex;
        align-items: center;
        gap: var(--space-4);
        color: var(--color-text-primary);
    }

    .phone-label {
        display: block;
        font-size: var(--text-xs);
        color: var(--color-text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .phone-number {
        font-family: var(--font-display);
        font-size: var(--text-2xl);
        font-weight: var(--weight-bold);
        color: var(--color-primary);
        text-decoration: none;
    }

    .phone-number:hover {
        color: var(--color-primary-light);
    }

    .events-buttons {
        display: flex;
        gap: var(--space-4);
    }

    .events-info {
        display: flex;
        justify-content: center;
        gap: var(--space-8);
        flex-wrap: wrap;
    }

    .info-item {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        font-size: var(--text-sm);
        color: var(--color-text-muted);
    }

    .info-item a {
        color: var(--color-text-secondary);
        text-decoration: none;
    }

    .info-item a:hover {
        color: var(--color-primary);
    }

    /* ============================================================
       RESPONSIVE
       ============================================================ */
    @media (min-width: 769px) {
        .hero-logo-text {
            font-size: 4rem;
        }

        .hero-tagline {
            font-size: var(--text-2xl);
        }

        .tagline-decoration {
            width: 48px;
        }

        .hero-badge-pill {
            font-size: var(--text-sm);
            padding: var(--space-2) var(--space-4);
        }

        .hero-panel {
            padding: var(--space-8);
            max-width: 560px;
        }

        .hero-panel-title {
            font-size: var(--text-lg);
        }

        .order-cards {
            gap: var(--space-4);
        }

        .order-card {
            padding: var(--space-6);
        }

        .order-card-icon {
            width: 56px;
            height: 56px;
        }

        .order-card-info h2 {
            font-size: var(--text-lg);
        }

        .order-card-meta {
            font-size: var(--text-xs);
            padding: 3px 10px;
        }

        .hero-actions {
            gap: var(--space-4);
        }

        .action-link {
            font-size: var(--text-sm);
            padding: var(--space-3) var(--space-5);
        }

        .hero-scroll-hint {
            bottom: var(--space-6);
        }

        .scroll-line {
            height: 36px;
        }
    }

    @media (max-width: 768px) {
        /* Hero mobile */
        .hero-top {
            padding-top: calc(var(--header-height) + var(--space-6));
            padding-bottom: var(--space-2);
        }

        .hero-logo-text {
            font-size: 2.6rem;
        }

        .tagline-decoration {
            width: 20px;
        }

        .hero-tagline {
            font-size: var(--text-base);
        }

        .hero-badge-pill {
            font-size: 11px;
            padding: 3px 10px;
        }

        .hero-bottom {
            padding: 0 var(--space-3) var(--space-6);
        }

        .hero-panel {
            padding: var(--space-5);
            border-radius: var(--radius-xl);
        }

        .hero-panel-title {
            font-size: var(--text-sm);
            margin-bottom: var(--space-3);
        }

        .order-card {
            padding: var(--space-4) var(--space-3);
            gap: var(--space-1);
        }

        .order-card-icon {
            width: 44px;
            height: 44px;
        }

        .order-card-info h2 {
            font-size: var(--text-sm);
        }

        .hero-bg-overlay {
            background: linear-gradient(
                180deg,
                rgba(0, 0, 0, 0.75) 0%,
                rgba(0, 0, 0, 0.5) 25%,
                rgba(0, 0, 0, 0.15) 45%,
                rgba(0, 0, 0, 0.3) 60%,
                rgba(0, 0, 0, 0.85) 85%,
                rgba(0, 0, 0, 0.95) 100%
            );
        }

        .hero-scroll-hint {
            display: none;
        }

        .section {
            padding: var(--space-12) 0;
        }

        .section-title {
            font-size: var(--text-2xl);
        }

        .section-desc {
            font-size: var(--text-base);
        }

        /* Story */
        .story-grid {
            grid-template-columns: 1fr;
            gap: var(--space-8);
        }

        .story-image {
            height: 300px;
        }

        /* Prep */
        .prep-showcase {
            grid-template-columns: 1fr;
        }

        .prep-hero {
            height: 300px;
        }

        .prep-details {
            flex-direction: row;
        }

        .prep-card {
            height: 200px;
        }

        .prep-stats {
            grid-template-columns: repeat(2, 1fr);
        }

        /* Gallery */
        .gallery-grid {
            grid-template-columns: 1fr 1fr;
        }

        .gallery-item {
            height: 200px;
        }

        .gallery-item-large {
            grid-column: span 2;
            height: 250px;
        }

        .gallery-overlay {
            opacity: 1;
        }

        /* Events */
        .events-grid {
            grid-template-columns: 1fr;
        }

        .events-buttons {
            flex-direction: column;
            width: 100%;
        }

        .events-buttons .btn {
            width: 100%;
        }

        .events-info {
            flex-direction: column;
            align-items: center;
        }

        .phone-number {
            font-size: var(--text-xl);
        }

        /* Testimonials */
        .slider-arrow {
            display: none;
        }

        .testimonial-viewport {
            min-height: 320px;
        }
    }
</style>
