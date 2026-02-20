import { writable, derived, get } from 'svelte/store';
import type { CartItem, CartState, MenuItem, OrderType } from '$lib/types';
import { calculateItemPrice } from '$lib/utils';
import { nanoid } from 'nanoid';
import { browser } from '$app/environment';

// ============================================================
// Initial State
// ============================================================
const initialState: CartState = {
    items: [],
    tableId: null,
    tableNumber: null,
    orderType: null,
    deliveryAddress: null,
    scheduledAt: null,
};

// ============================================================
// Load from localStorage
// ============================================================
function loadState(): CartState {
    if (!browser) return initialState;
    try {
        const saved = localStorage.getItem('restaurant-cart');
        if (saved) return JSON.parse(saved) as CartState;
    } catch {
        // ignore
    }
    return initialState;
}

// ============================================================
// Store
// ============================================================
const cartStore = writable<CartState>(loadState());

// Persist on every change
if (browser) {
    cartStore.subscribe((state) => {
        try {
            localStorage.setItem('restaurant-cart', JSON.stringify(state));
        } catch {
            // ignore
        }
    });
}

// ============================================================
// Actions
// ============================================================
function addItem(
    item: MenuItem,
    quantity: number,
    selectedOptions: Record<string, string | string[]>,
    notes: string
) {
    cartStore.update((state) => {
        const unitPrice = calculateItemPrice(item.price, selectedOptions, item.options);
        const newItem: CartItem = {
            id: nanoid(8),
            menuItem: item,
            quantity,
            selectedOptions,
            notes,
            unitPrice,
        };
        return { ...state, items: [...state.items, newItem] };
    });
}

function removeItem(cartItemId: string) {
    cartStore.update((state) => ({
        ...state,
        items: state.items.filter((i) => i.id !== cartItemId),
    }));
}

function updateQuantity(cartItemId: string, quantity: number) {
    cartStore.update((state) => ({
        ...state,
        items: state.items.map((i) =>
            i.id === cartItemId ? { ...i, quantity: Math.max(1, quantity) } : i
        ),
    }));
}

function setTable(tableId: string, tableNumber: string) {
    cartStore.update((state) => ({
        ...state,
        tableId,
        tableNumber,
        orderType: 'dine_in' as OrderType,
    }));
}

function setOrderType(orderType: OrderType) {
    cartStore.update((state) => ({ ...state, orderType }));
}

function setOrderDetails({ address, scheduledAt }: { address?: string; scheduledAt?: string | null }) {
    cartStore.update((state) => ({ ...state, deliveryAddress: address ?? state.deliveryAddress, scheduledAt: scheduledAt !== undefined ? scheduledAt : state.scheduledAt }));
}

function clearCart() {
    cartStore.set(initialState);
}

// ============================================================
// Derived Values
// ============================================================
const itemCount = derived(cartStore, ($cart) =>
    $cart.items.reduce((sum, item) => sum + item.quantity, 0)
);

const subtotal = derived(cartStore, ($cart) =>
    $cart.items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0)
);

const isDineIn = derived(cartStore, ($cart) => $cart.orderType === 'dine_in');

// ============================================================
// Export
// ============================================================
export const cart = {
    subscribe: cartStore.subscribe,
    addItem,
    removeItem,
    updateQuantity,
    setTable,
    setOrderType,
    setOrderDetails,
    clearCart,
    itemCount,
    subtotal,
    isDineIn,
    getState: () => get(cartStore),
};
