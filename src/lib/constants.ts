// ============================================================
// Application Constants
// ============================================================

import type { OrderStatus, OrderType } from '$lib/types';

// Branding Defaults (Source of Truth is restaurant_settings table)
export const APP_NAME = 'Pizza Mania';
export const APP_TAGLINE = 'Crafted with Passion, Served with Love';
export const CURRENCY_SYMBOL = '€';
export const DELIVERY_FEE = 3.99;

// Order Settings
export const MIN_ORDER_AMOUNT = 15.00;
export const AVG_PREP_MINUTES = 25;

// Status Labels
export const ORDER_STATUS_LABELS: Record<string, string> = {
    new: 'New Order',
    confirmed: 'Confirmed',
    preparing: 'Preparing',
    ready: 'Ready',
    out_for_delivery: 'Out for Delivery',
    delivered: 'Delivered',
    picked_up: 'Picked Up',
    served: 'Served',
    cancelled: 'Cancelled',
};

// Status Flow per Order Type
export const ORDER_STATUS_FLOW: Record<OrderType, OrderStatus[]> = {
    delivery: ['new', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered'],
    pickup: ['new', 'confirmed', 'preparing', 'ready', 'picked_up'],
    dine_in: ['new', 'confirmed', 'preparing', 'ready', 'served'],
};

// Order Type Labels
export const ORDER_TYPE_LABELS: Record<OrderType, string> = {
    delivery: 'Home Delivery',
    pickup: 'Self Pickup',
    dine_in: 'Dine In',
};

// Status Colors
export const ORDER_STATUS_COLORS: Record<string, string> = {
    new: '#457B9D',
    confirmed: '#2A9D8F',
    preparing: '#E9C46A',
    ready: '#2A9D8F',
    out_for_delivery: '#E76F51',
    delivered: '#52B788',
    picked_up: '#52B788',
    served: '#52B788',
    cancelled: '#E63946',
};

// Contact Defaults
export const CONTACT_INFO = {
    address: "Rue puissant d\'Agimont 27, 6040 Jumet",
    phone: '+32470972953',
    email: 'hello@pizzamania.be',
    whatsapp: '+32470972953'
};

