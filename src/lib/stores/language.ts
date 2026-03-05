import { writable, derived } from 'svelte/store';
import { translations } from '$lib/i18n';

export type Language = 'fr' | 'en';

function createLanguageStore() {
    const stored = typeof localStorage !== 'undefined' ? (localStorage.getItem('lang') as Language | null) : null;
    const initial: Language = stored === 'en' || stored === 'fr' ? stored : 'fr';

    const { subscribe, set, update } = writable<Language>(initial);

    return {
        subscribe,
        set: (lang: Language) => {
            if (typeof localStorage !== 'undefined') localStorage.setItem('lang', lang);
            set(lang);
        },
        toggle: () => {
            update(lang => {
                const next: Language = lang === 'fr' ? 'en' : 'fr';
                if (typeof localStorage !== 'undefined') localStorage.setItem('lang', next);
                return next;
            });
        }
    };
}

export const language = createLanguageStore();

export const t = derived(language, ($language) => {
    return (key: string): string => {
        return translations[$language]?.[key] ?? translations['fr']?.[key] ?? key;
    };
});
