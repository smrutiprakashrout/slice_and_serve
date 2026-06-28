// lib/cart-store.ts
// Single source of truth for cart state across all pages.
// Uses Zustand — install with: npm install zustand

import { create } from "zustand";
import { persist } from "zustand/middleware";

export type ItemType = "veg" | "nonveg";

export interface CartItem {
  id: string; // unique menu item id  e.g. "sand-01"
  name: string;
  image: string;
  price: number; // unit price from the MENU — never hardcoded in cart
  qty: number;
  type: ItemType;
}

interface CartStore {
  items: CartItem[];

  // Add 1 of an item (or create it if not present)
  addItem: (item: Omit<CartItem, "qty">) => void;

  // Remove 1 qty (deletes if qty reaches 0)
  removeItem: (id: string) => void;

  // Set exact qty (0 = delete)
  setQty: (id: string, qty: number) => void;

  // Wipe the whole cart
  clearCart: () => void;

  // Derived helpers
  totalItems: () => number;
  itemTotal: () => number;
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],

      addItem: (incoming) =>
        set((state) => {
          const existing = state.items.find((i) => i.id === incoming.id);
          if (existing) {
            return {
              items: state.items.map((i) =>
                i.id === incoming.id ? { ...i, qty: i.qty + 1 } : i,
              ),
            };
          }
          return { items: [...state.items, { ...incoming, qty: 1 }] };
        }),

      removeItem: (id) =>
        set((state) => {
          const existing = state.items.find((i) => i.id === id);
          if (!existing) return state;
          if (existing.qty <= 1) {
            return { items: state.items.filter((i) => i.id !== id) };
          }
          return {
            items: state.items.map((i) =>
              i.id === id ? { ...i, qty: i.qty - 1 } : i,
            ),
          };
        }),

      setQty: (id, qty) =>
        set((state) => {
          if (qty <= 0) {
            return { items: state.items.filter((i) => i.id !== id) };
          }
          return {
            items: state.items.map((i) => (i.id === id ? { ...i, qty } : i)),
          };
        }),

      clearCart: () => set({ items: [] }),

      totalItems: () => get().items.reduce((s, i) => s + i.qty, 0),
      itemTotal: () => get().items.reduce((s, i) => s + i.price * i.qty, 0),
    }),
    {
      name: "sns-cart", // persists in localStorage across refreshes
    },
  ),
);
