import readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import { connectDB } from "../lib/db";
import Admin from "../model/Admin";

async function main() {
  const rl = readline.createInterface({ input, output });

  try {
    console.log("Connecting to MongoDB...");
    await connectDB();
    console.log("Connected successfully.\n");

    const username = (await rl.question("Enter admin username: ")).trim();
    if (!username) {
      console.error("Error: Username cannot be empty.");
      process.exitCode = 1;
      return;
    }

    const password = (await rl.question("Enter admin password: ")).trim();
    if (!password) {
      console.error("Error: Password cannot be empty.");
      process.exitCode = 1;
      return;
    }

    const existingAdmin = await Admin.findOne();
    if (existingAdmin) {
      console.warn(
        `\n⚠️  Warning: An admin already exists: "${existingAdmin.username}". This script only ever creates ONE admin.`,
      );
      const confirm = (
        await rl.question(
          "Do you want to overwrite this admin? Type 'yes' to confirm: ",
        )
      )
        .trim()
        .toLowerCase();

      if (confirm !== "yes") {
        console.log("Operation aborted. Existing admin was not modified.");
        return;
      }

      const passwordHash = await bcrypt.hash(password, 10);
      await Admin.deleteMany({});
      await Admin.create({
        username,
        passwordHash,
        fcmTokens: [],
      });
      console.log(`\n✅ Admin "${username}" successfully overwritten.`);
    } else {
      const passwordHash = await bcrypt.hash(password, 10);
      await Admin.create({
        username,
        passwordHash,
        fcmTokens: [],
      });
      console.log(`\n✅ Admin "${username}" successfully created.`);
    }
  } catch (error) {
    console.error("Failed to create admin:", error instanceof Error ? error.message : "Unknown error");
    process.exitCode = 1;
  } finally {
    rl.close();
    await mongoose.disconnect();
    console.log("MongoDB connection closed.");
  }
}

main();
