import mongoose, { Schema, Model } from "mongoose";

export interface ICategory {
  name: string;
  slug: string;
  icon?: string;
  sortOrder?: number;
}

const categorySchema = new Schema<ICategory>(
  {
    name: { type: String, required: true },
    slug: { type: String, required: true, unique: true },
    icon: { type: String, default: "" },
    sortOrder: { type: Number, default: 0 },
  },
);

export const Category: Model<ICategory> =
  (mongoose.models.Category as Model<ICategory>) ||
  mongoose.model<ICategory>("Category", categorySchema);

export default Category;
