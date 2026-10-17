export function buildPartyListMessage(names: string[]): string {
  const numberedNames = names.map((name, index) => `${index + 1}. ${name}`).join("\n");

  return `Hi Slice & Serve, I'd like to place a party order for:\n${numberedNames}\nPlease confirm availability, quantity and price.`;
}

export function buildSingleDishMessage(name: string): string {
  return `Hi Slice & Serve, I'd like to place a party order for ${name}.`;
}

export function buildWhatsAppUrl(message: string): string {
  return `https://wa.me/919337867207?text=${encodeURIComponent(message)}`;
}
