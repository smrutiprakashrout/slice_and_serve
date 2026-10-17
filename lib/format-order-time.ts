export function formatOrderTime(
  dateInput: string | Date | undefined,
  now: Date = new Date(),
): string {
  if (!dateInput) return "";

  const date = dateInput instanceof Date ? dateInput : new Date(dateInput);
  if (!Number.isFinite(date.getTime())) return "";

  const time = date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
  const isSameDay = (first: Date, second: Date) =>
    first.getFullYear() === second.getFullYear() &&
    first.getMonth() === second.getMonth() &&
    first.getDate() === second.getDate();

  if (isSameDay(date, now)) return `Today, ${time}`;

  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  if (isSameDay(date, yesterday)) return `Yesterday, ${time}`;

  const dayAndMonth = date.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
  });
  return `${dayAndMonth}, ${time}`;
}
