import mongoose, { Schema, Model, Types } from "mongoose";

export interface ILoyaltyCard {
  customerId: Types.ObjectId;
  stamps: number;
  totalRequired: number;
  rewardReady: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface LoyaltyCard extends ILoyaltyCard {}

const loyaltyCardSchema = new Schema<ILoyaltyCard>(
  {
    customerId: {
      type: Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
      unique: true,
      index: true,
    },
    stamps: {
      type: Number,
      default: 0,
    },
    totalRequired: {
      type: Number,
      default: 10,
    },
    rewardReady: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  },
);

export const LoyaltyCard: Model<ILoyaltyCard> =
  (mongoose.models.LoyaltyCard as Model<ILoyaltyCard>) ||
  mongoose.model<ILoyaltyCard>("LoyaltyCard", loyaltyCardSchema);

export default LoyaltyCard;
