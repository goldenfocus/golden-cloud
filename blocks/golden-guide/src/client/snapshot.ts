import type { PageSnapshot, SnapshotElement } from '../shared/types';

/** ~800 tokens ≈ 3200 chars: hard, tested grounding budget (small models degrade past this). */
const MAX_CHARS = 3200;

export function collectSnapshot(doc: Document, route: string, maxChars = MAX_CHARS): PageSnapshot {
  const elements: SnapshotElement[] = [];
  let used = 0;
  for (const el of Array.from(doc.querySelectorAll('[data-agent-id]'))) {
    const id = el.getAttribute('data-agent-id') ?? '';
    const label = (el.getAttribute('aria-label') ?? el.textContent ?? '')
      .trim()
      .replace(/\s+/g, ' ')
      .slice(0, 60);
    const entry: SnapshotElement = { id, tag: el.tagName.toLowerCase(), label };
    const cost = entry.id.length + entry.tag.length + entry.label.length + 8;
    if (used + cost > maxChars) break;
    used += cost;
    elements.push(entry);
  }
  return { route, elements };
}
