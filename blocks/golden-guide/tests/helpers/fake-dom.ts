// Minimal DOM stub for node:test — just enough surface for snapshot + executor.
export interface FakeElement {
  tagName: string;
  attrs: Record<string, string>;
  textContent: string;
  classList: { add(c: string): void; remove(c: string): void; has(c: string): boolean };
  scrolled: boolean;
  getAttribute(name: string): string | null;
  scrollIntoView(opts?: unknown): void;
}

export function makeElement(tag: string, attrs: Record<string, string>, text = ''): FakeElement {
  const classes = new Set<string>();
  const el: FakeElement = {
    tagName: tag.toUpperCase(),
    attrs,
    textContent: text,
    scrolled: false,
    classList: {
      add: (c) => classes.add(c),
      remove: (c) => classes.delete(c),
      has: (c) => classes.has(c),
    },
    getAttribute: (name) => attrs[name] ?? null,
    scrollIntoView: () => {
      el.scrolled = true;
    },
  };
  return el;
}

export function makeDoc(elements: FakeElement[]): Document {
  const styleEls: Array<{ id: string; textContent: string }> = [];
  const doc = {
    querySelectorAll: (selector: string) =>
      selector === '[data-agent-id]' ? elements : [],
    querySelector: (selector: string) => {
      const m = selector.match(/^\[data-agent-id="(.+)"\]$/);
      if (!m) return null;
      return elements.find((e) => e.attrs['data-agent-id'] === m[1]) ?? null;
    },
    getElementById: (id: string) => styleEls.find((s) => s.id === id) ?? null,
    createElement: () => {
      const s = { id: '', textContent: '' };
      return s;
    },
    head: { appendChild: (s: { id: string; textContent: string }) => styleEls.push(s) },
  };
  return doc as unknown as Document;
}
