import mongoose from "mongoose";
import { connectDB } from "../lib/db";
import { CATEGORIES, MOCK_MENU } from "../lib/menu-data";
import Category from "../model/Category";
import MenuItem from "../model/MenuItem";

async function seed() {
  console.log("Connecting to MongoDB...");
  await connectDB();
  console.log("Connected successfully.");

  // Filter out the 'all' pseudo-category (UI-only filter)
  const realCategories = CATEGORIES.filter((c) => c.slug !== "all");

  let categoriesInserted = 0;
  let categoriesUpdated = 0;

  console.log(`Seeding ${realCategories.length} categories...`);
  for (let i = 0; i < realCategories.length; i++) {
    const cat = realCategories[i];
    const res = await Category.updateOne(
      { slug: cat.slug },
      {
        $set: {
          name: cat.name,
          slug: cat.slug,
          icon: cat.icon,
          sortOrder: i + 1,
        },
      },
      { upsert: true },
    );

    if (res.upsertedCount > 0) {
      categoriesInserted++;
    } else {
      categoriesUpdated++;
    }
  }

  let menuItemsInserted = 0;
  let menuItemsUpdated = 0;

  console.log(`Seeding ${MOCK_MENU.length} menu items...`);
  for (const item of MOCK_MENU) {
    const res = await MenuItem.updateOne(
      { name: item.name },
      {
        $set: {
          name: item.name,
          subtitle: item.subtitle,
          price: item.price,
          rating: item.rating,
          categorySlug: item.categorySlug,
          type: item.type,
          featured: item.featured,
          image: item.image,
          available: item.available,
        },
      },
      { upsert: true },
    );

    if (res.upsertedCount > 0) {
      menuItemsInserted++;
    } else {
      menuItemsUpdated++;
    }
  }

  console.log("\n--- Seed Summary ---");
  console.log(
    `Categories: ${categoriesInserted} inserted, ${categoriesUpdated} updated (Total: ${realCategories.length})`,
  );
  console.log(
    `Menu Items: ${menuItemsInserted} inserted, ${menuItemsUpdated} updated (Total: ${MOCK_MENU.length})`,
  );
  console.log("--------------------\n");
}

async function run() {
  try {
    await seed();
  } catch (error) {
    console.error("Failed to seed database:", error);
    process.exitCode = 1;
  } finally {
    console.log("Closing MongoDB connection...");
    await mongoose.disconnect();
    console.log("Connection closed.");
  }
}

run();
