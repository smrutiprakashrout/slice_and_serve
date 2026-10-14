import mongoose, { Schema, Model } from "mongoose";

export interface ICustomerPreferences {
  vegOnly: boolean;
  orderUpdates: boolean;
  offers: boolean;
  newItems: boolean;
}

export interface CustomerPreferences extends ICustomerPreferences {}

export interface ICustomer {
  googleId: string;
  name: string;
  email: string;
  photo?: string;
  preferences: ICustomerPreferences;
  stampToken: string;
  redeemToken: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface CustomerDoc extends ICustomer {}

const preferencesSchema = new Schema<ICustomerPreferences>(
  {
    vegOnly: { type: Boolean, default: false },
    orderUpdates: { type: Boolean, default: true },
    offers: { type: Boolean, default: true },
    newItems: { type: Boolean, default: false },
  },
  {
    _id: false,
  },
);

const customerSchema = new Schema<ICustomer>(
  {
    googleId: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    photo: { type: String },
    preferences: {
      type: preferencesSchema,
      default: () => ({
        vegOnly: false,
        orderUpdates: true,
        offers: true,
        newItems: false,
      }),
    },
    stampToken: { type: String, required: true, unique: true, index: true },
    redeemToken: { type: String, required: true, unique: true, index: true },
  },
  {
    timestamps: true,
  },
);

export const Customer: Model<ICustomer> =
  (mongoose.models.Customer as Model<ICustomer>) ||
  mongoose.model<ICustomer>("Customer", customerSchema);

export default Customer;
