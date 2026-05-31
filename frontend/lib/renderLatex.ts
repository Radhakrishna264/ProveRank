import katex from 'katex';

export function renderLatex(text: string): string {
  if (!text) return '';
  let h = text.replace(/\$\$([^$]+)\$\$/g, function(_: string, m: string) {
    try {
      return katex.renderToString(m, { displayMode: true, throwOnError: false });
    } catch(e) { return m; }
  });
  h = h.replace(/\$([^\n$]+)\$/g, function(_: string, m: string) {
    try {
      return katex.renderToString(m, { displayMode: false, throwOnError: false });
    } catch(e) { return m; }
  });
  return h;
}
