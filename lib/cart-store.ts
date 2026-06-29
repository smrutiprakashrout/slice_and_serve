// lib/cart-store.ts
// Run once: npm install zustand

import { create } from "zustand";
import { persist } from "zustand/middleware";

export type ItemType = "veg" | "nonveg";

export interface CartItem {
  id: string;
  name: string;
  image: string;
  price: number; // always from MOCK_MENU — never hardcoded
  qty: number;
  type: ItemType;
}

interface CartStore {
  items: CartItem[];
  addItem: (item: Omit<CartItem, "qty">) => void;
  removeOne: (id: string) => void;
  removeAll: (id: string) => void;
  clearCart: () => void;
  getQty: (id: string) => number;
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

      removeOne: (id) =>
        set((state) => {
          const existing = state.items.find((i) => i.id === id);
          if (!existing) return state;
          if (existing.qty <= 1)
            return { items: state.items.filter((i) => i.id !== id) };
          return {
            items: state.items.map((i) =>
              i.id === id ? { ...i, qty: i.qty - 1 } : i,
            ),
          };
        }),

      removeAll: (id) =>
        set((state) => ({ items: state.items.filter((i) => i.id !== id) })),

      clearCart: () => set({ items: [] }),

      getQty: (id) => get().items.find((i) => i.id === id)?.qty ?? 0,

      totalItems: () => get().items.reduce((s, i) => s + i.qty, 0),

      itemTotal: () => get().items.reduce((s, i) => s + i.price * i.qty, 0),
    }),
    { name: "sns-cart" }, // persists across page refreshes
  ),
);
