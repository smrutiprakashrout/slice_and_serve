import mongoose, { Schema, Model } from "mongoose";

export interface IAdmin {
  username: string;
  passwordHash: string;
  fcmTokens: string[];
}

export interface Admin extends IAdmin {}

const adminSchema = new Schema<IAdmin>({
  username: {
    type: String,
    required: true,
    unique: true,
  },
  passwordHash: {
    type: String,
    required: true,
  },
  fcmTokens: {
    type: [String],
    default: [],
  },
});

export const Admin: Model<IAdmin> =
  (mongoose.models.Admin as Model<IAdmin>) ||
  mongoose.model<IAdmin>("Admin", adminSchema);

export default Admin;
