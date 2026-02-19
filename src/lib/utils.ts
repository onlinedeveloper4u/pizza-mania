import { customAlphabet } from 'nanoid';
import { CURRENCY_SYMBOL } from './constants';

// Generate a short, URL-friendly tracking token like "ORD-A3X9K2"
const nanoid = customAlphabet('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 6);
export function generateTrackingToken(): string {
    return `ORD-${nanoid()}`;
}

// Format price
export function formatPrice(price: number): string {
    return `${CURRENCY_SYMBOL}${price.toFixed(2)}`;
}

// Format date
export function formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleDateString('en-GB', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
    });
}

// Format time
export function formatTime(dateStr: string): string {
    return new Date(dateStr).toLocaleTimeString('en-GB', {
        hour: '2-digit',
        minute: '2-digit',
    });
}

// Format date + time
export function formatDateTime(dateStr: string): string {
    return `${formatDate(dateStr)} at ${formatTime(dateStr)}`;
}

// Time ago
export function timeAgo(dateStr: string): string {
    const now = new Date();
    const date = new Date(dateStr);
    const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (seconds < 60) return 'just now';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
}

// Calculate cart item price including options
export function calculateItemPrice(
    basePrice: number,
    selectedOptions: Record<string, string | string[]>,
    menuOptions: { name: string; choices: { name: string; price_addition: number }[] }[] | null
): number {
    if (!menuOptions || !selectedOptions) return basePrice;

    let total = basePrice;
    for (const option of menuOptions) {
        const selected = selectedOptions[option.name];
        if (!selected) continue;

        const selectedArray = Array.isArray(selected) ? selected : [selected];
        for (const choiceName of selectedArray) {
            const choice = option.choices.find((c) => c.name === choiceName);
            if (choice) {
                total += choice.price_addition;
            }
        }
    }
    return total;
}

// Truncate text
export function truncate(text: string, maxLength: number): string {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

// cn - simple class name joiner
export function cn(...classes: (string | false | null | undefined)[]): string {
    return classes.filter(Boolean).join(' ');
}
