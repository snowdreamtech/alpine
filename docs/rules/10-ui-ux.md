# 10 · UI/UX

> Standards for frontend development, accessibility, styling, and user experience quality.

::: tip Source
This page summarizes [`.agent/rules/10-ui-ux.md`](https://github.com/snowdreamtech/template/blob/main/.agent/rules/10-ui-ux.md).
:::

## Styling Architecture

- Use **CSS custom properties** (variables) for design tokens — colors, spacing, typography, radii
- Follow **utility-first** principles: small, composable style units
- Avoid inline styles in components
- Global styles live in `src/styles/` or similar; component scoped styles co-locate with the component

```css
/* ✅ Design tokens */
:root {
  --color-primary: #6366f1;
  --spacing-md: 1rem;
  --radius-md: 0.5rem;
}
```

## Accessibility (a11y)

All user-facing interfaces MUST meet **WCAG 2.1 AA** standards:

- Every interactive element has a visible focus indicator
- All images have descriptive `alt` attributes
- Color contrast ratio ≥ 4.5:1 for normal text, 3:1 for large text
- All forms have associated labels (`<label for="...">`)
- Keyboard navigable — never trap focus
- Use semantic HTML (`<nav>`, `<main>`, `<button>`, `<heading>`) over `<div>` soup
- Test with a screen reader (VoiceOver / NVDA) before shipping UI changes

## Responsive Design

- **Mobile-first**: start with mobile constraints, add larger breakpoints
- Standard breakpoints: `sm: 640px`, `md: 768px`, `lg: 1024px`, `xl: 1280px`
- Never hide important content behind hover — touch devices have no hover state
- Test on real devices or device emulation before shipping

## Performance

- Lazy-load images: `<img loading="lazy">`
- Code-split at route level in SPAs
- Target Core Web Vitals:
  - **LCP** (Largest Contentful Paint) ≤ 2.5s
  - **INP** (Interaction to Next Paint) ≤ 200ms
  - **CLS** (Cumulative Layout Shift) ≤ 0.1

## Internationalization (i18n)

- Never hard-code user-visible strings — use an i18n library from day one
- Store translations in structured files (`en.json`, `zh.json`)
- Handle RTL (right-to-left) languages with CSS logical properties (`margin-inline-start`)

## Component Design

- Keep components focused: one responsibility per component
- Props define the component's contract — keep them minimal and typed
- Prefer composition over inheritance
- Write visual regression tests for UI-critical components
