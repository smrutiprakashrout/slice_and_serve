import mongoose, { Schema, Model } from "mongoose";

export interface IMenuItem {
  name: string;
  subtitle: string;
  price: number;
  rating: number;
  categorySlug: string;
  type: "veg" | "non-veg";
  featured?: boolean;
  image: string;
  available?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

const menuItemSchema = new Schema<IMenuItem>(
  {
    name: { type: String, required: true },
    subtitle: { type: String, required: true },
    price: { type: Number, required: true },
    rating: { type: Number, required: true },
    categorySlug: { type: String, required: true, index: true },
    type: {
      type: String,
      required: true,
      enum: ["veg", "non-veg"],
    },
    featured: { type: Boolean, default: false },
    image: { type: String, required: true },
    available: { type: Boolean, default: true },
  },
  {
    timestamps: true,
  },
);

export const MenuItem: Model<IMenuItem> =
  (mongoose.models.MenuItem as Model<IMenuItem>) ||
  mongoose.model<IMenuItem>("MenuItem", menuItemSchema);

export default MenuItem;
