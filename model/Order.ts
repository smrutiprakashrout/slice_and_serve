import mongoose, { Schema, Model, Types } from "mongoose";

export type OrderFulfillment = "dine-in" | "pickup";
export type OrderStatus = "pending" | "accepted" | "completed" | "rejected";

export interface IOrderItem {
  _id?: Types.ObjectId;
  menuItemId: Types.ObjectId;
  name: string;
  price: number;
  quantity: number;
}

export interface OrderItem extends IOrderItem {}

export interface IOrder {
  customerId: Types.ObjectId;
  customerName: string;
  fulfillment: OrderFulfillment;
  tableNumber?: string;
  items: IOrderItem[];
  itemTotal: number;
  total: number;
  status: OrderStatus;
  placedAt: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface OrderDoc extends IOrder {}

const orderItemSchema = new Schema<IOrderItem>(
  {
    menuItemId: {
      type: Schema.Types.ObjectId,
      ref: "MenuItem",
      required: true,
    },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, required: true, min: 1 },
  },
  {
    _id: true,
  },
);

const orderSchema = new Schema<IOrder>(
  {
    customerId: {
      type: Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
      index: true,
    },
    customerName: { type: String, required: true },
    fulfillment: {
      type: String,
      required: true,
      enum: ["dine-in", "pickup"],
    },
    tableNumber: { type: String },
    items: {
      type: [orderItemSchema],
      required: true,
    },
    itemTotal: { type: Number, required: true },
    total: { type: Number, required: true },
    status: {
      type: String,
      required: true,
      enum: ["pending", "accepted", "completed", "rejected"],
      default: "pending",
    },
    placedAt: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

orderSchema.index({ status: 1, placedAt: -1 });

export const Order: Model<IOrder> =
  (mongoose.models.Order as Model<IOrder>) ||
  mongoose.model<IOrder>("Order", orderSchema);

export default Order;
