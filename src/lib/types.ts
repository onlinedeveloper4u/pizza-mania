// ============================================================
// Database Types
// ============================================================

export type OrderType = 'delivery' | 'pickup' | 'dine_in';
export type OrderStatus =
    | 'new'
    | 'confirmed'
    | 'preparing'
    | 'ready'
    | 'out_for_delivery'
    | 'delivered'
    | 'picked_up'
    | 'served'
    | 'cancelled';
export type PaymentMethod = 'online' | 'counter';
export type PaymentStatus = 'pending' | 'paid' | 'failed';
export type UserRole = 'manager' | 'chef';

// ============================================================
// Database Row Types
// ============================================================

export interface Category {
    id: string;
    name: string;
    description: string | null;
    image_url: string | null;
    sort_order: number;
    is_active: boolean;
    created_at: string;
}

export interface MenuItemOption {
    name: string;
    type: 'single' | 'multiple';
    required: boolean;
    choices: {
        name: string;
        price_addition: number;
    }[];
}

export interface MenuItem {
    id: string;
    category_id: string;
    name: string;
    description: string | null;
    price: number;
    image_url: string | null;
    is_available: boolean;
    is_featured: boolean;
    sort_order: number;
    options: MenuItemOption[] | null;
    created_at: string;
}

export interface Order {
    id: string;
    tracking_token: string;
    order_type: OrderType;
    status: OrderStatus;
    customer_name: string;
    customer_phone: string;
    customer_email: string | null;
    delivery_address: string | null;
    table_id: string | null;
    subtotal: number;
    delivery_fee: number;
    total: number;
    payment_method: PaymentMethod;
    payment_status: PaymentStatus;
    stripe_session_id: string | null;
    estimated_minutes: number | null;
    scheduled_time: string | null;
    confirmed_by: string | null;
    created_at: string;
    updated_at: string;
}

export interface OrderItem {
    id: string;
    order_id: string;
    menu_item_id: string | null;
    deal_id?: string | null;
    item_name: string;
    item_price: number;
    quantity: number;
    selected_options: Record<string, string | string[]> | null;
    notes: string | null;
}

export interface Table {
    id: string;
    table_number: string;
    seats: number;
    is_active: boolean;
    qr_code_url: string | null;
    created_at: string;
}

export interface RestaurantSettings {
    id: string;
    restaurant_name: string;
    address: string;
    phone: string;
    email: string;
    operating_hours: Record<string, { open: string; close: string }>;
    delivery_fee: number;
    avg_prep_minutes: number;
    accepting_orders: boolean;
    currency: string;
    logo_url: string | null;
}

export interface Profile {
    id: string;
    email: string;
    full_name: string;
    role: UserRole;
    created_at: string;
}

export interface OrderStatusHistory {
    id: string;
    order_id: string;
    status: OrderStatus;
    changed_by: string | null;
    changed_at: string;
}

export interface NewsletterSubscriber {
    id: string;
    email: string;
    created_at: string;
}

// ============================================================
// Frontend Types
// ============================================================

export interface CartItem {
    id: string; // unique cart item id
    menuItem: MenuItem;
    quantity: number;
    selectedOptions: Record<string, string | string[]>;
    notes: string;
    unitPrice: number; // base price + option additions
}

export interface CartState {
    items: CartItem[];
    tableId: string | null;
    tableNumber: string | null;
    orderType: OrderType | null;
    deliveryAddress?: string | null;
    scheduledAt?: string | null;
}

// ============================================================
// API Types
// ============================================================

export interface CreateOrderPayload {
    order_type: OrderType;
    customer_name: string;
    customer_phone: string;
    customer_email?: string;
    delivery_address?: string;
    table_id?: string;
    payment_method: PaymentMethod;
    special_instructions?: string;
    scheduled_time?: string | null;
    items: {
        menu_item_id: string | null;
        deal_id?: string | null;
        item_name: string;
        item_price: number;
        quantity: number;
        selected_options?: Record<string, string | string[]>;
        notes?: string;
    }[];
}

export interface CreateOrderResponse {
    tracking_token: string;
    order_id: string;
    payment_url?: string; // Stripe checkout URL for online payment
}

// ============================================================
// Extended types with relations
// ============================================================

export interface OrderWithItems extends Order {
    order_items: OrderItem[];
    table?: Table | null;
}

export interface MenuItemWithCategory extends MenuItem {
    category: Category;
}
