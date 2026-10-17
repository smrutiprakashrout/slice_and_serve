import { describe, expect, it } from "vitest";
import {
  buildPartyListMessage,
  buildSingleDishMessage,
  buildWhatsAppUrl,
} from "@/lib/party-order-message";

describe("party order messages", () => {
  it("builds a numbered message for one dish", () => {
    expect(buildPartyListMessage(["Finger Chicken"])).toBe(
      "Hi Slice & Serve, I'd like to place a party order for:\n1. Finger Chicken\nPlease confirm availability, quantity and price.",
    );
  });

  it("numbers three dishes and separates each line", () => {
    expect(buildPartyListMessage(["Finger Chicken", "Chicken Kebab", "Chicken 65"])).toBe(
      "Hi Slice & Serve, I'd like to place a party order for:\n1. Finger Chicken\n2. Chicken Kebab\n3. Chicken 65\nPlease confirm availability, quantity and price.",
    );
  });

  it("builds the existing single-dish wording", () => {
    expect(buildSingleDishMessage("Finger Chicken")).toBe(
      "Hi Slice & Serve, I'd like to place a party order for Finger Chicken.",
    );
  });

  it("URL-encodes special characters and uses the WhatsApp endpoint", () => {
    const message = buildSingleDishMessage("Fish & Chips / 50% off?");
    const url = buildWhatsAppUrl(message);

    expect(url).toMatch(/^https:\/\/wa\.me\/919337867207\?text=/);
    expect(url).toContain(encodeURIComponent(message));
    expect(decodeURIComponent(url.split("?text=")[1])).toBe(message);
    expect(url).toContain("%26");
    expect(url).toContain("%2F");
    expect(url).toContain("%3F");
  });
});
