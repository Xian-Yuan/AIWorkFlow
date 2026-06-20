# TypeScript 6 + Vite 8 + Vitest 4 Common Fix Patterns

Collected from preproduction-workbench implementation session (2026-06-20).

## vite.config.ts — test property not recognized

**Error**: `Object literal may only specify known properties, and 'test' does not exist in type 'UserConfigExport'`

**Fix**: Add triple-slash directive at top of file:

```ts
/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.ts'],
    css: false,
  },
})
```

## useRef without initial value

**Error**: `Expected 1 arguments, but got 0` on `useRef<ReturnType<typeof setTimeout>>()`

**Fix**: Pass `undefined` as initial value:

```ts
const saveTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
```

## Unused destructured props

**Error**: `'brief' is declared but its value is never read` (TS6133)

**Fix**: Prefix with underscore in destructuring:

```ts
// Before
export function PromptLab({ brief, onTabChange }) { ... }

// After
export function PromptLab({ brief: _brief, onTabChange }) { ... }
```

For function params:

```ts
// Before
const handleFieldEdit = (cardType: CreativeCardType, fieldKey: string) => { ... }

// After
const handleFieldEdit = (_cardType: CreativeCardType, fieldKey: string) => { ... }
```

## FIELD_PROMPTS / FIELD_OPTIONS indexing with dynamic key

**Error**: `Element implicitly has an 'any' type because expression of type 'keyof CreativeBrief' can't be used to index type 'Record<RequiredField, string>'`

**Fix**: Cast to the narrower type or use `REQUIRED_FIELDS.find()`:

```ts
// Instead of:
FIELD_PROMPTS[nextMissing as keyof CreativeBrief]  // too wide

// Use:
FIELD_PROMPTS[nextMissing as typeof REQUIRED_FIELDS[number]]  // narrows to valid keys
// Or better: use REQUIRED_FIELDS.find() which already returns the right type
const nextMissing = REQUIRED_FIELDS.find((f) => !withBrief.brief[f]);
if (nextMissing) {
  const prompt = FIELD_PROMPTS[nextMissing];  // type-safe
}
```

## Vitest test file import paths

Test files in `src/` should import siblings with `./` not `../`:

```ts
// Wrong (causes "Failed to resolve import" in vitest)
import { emptyBrief } from '../models';

// Correct
import { emptyBrief } from './models';
```

## Vitest + Playwright 共存

When both Vitest and Playwright are in the same project, Vitest picks up Playwright spec files in `tests/` and tries to run them as unit tests, causing import errors.

**Fix**: Add `include` to `vite.config.ts` test config:

```ts
export default defineConfig({
  test: {
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    // ...
  },
})
```

**Directory convention**:
- `src/**/*.test.ts` → Vitest unit tests
- `tests/**/*.spec.ts` → Playwright E2E tests

## Playwright: use system Edge instead of downloading Chromium

Chromium download (~180MB) can timeout in restricted networks. If Microsoft Edge is installed, use it directly:

```ts
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  projects: [
    {
      name: 'edge',
      use: { channel: 'msedge' },
    },
  ],
})
```

Still need OS deps: `npx playwright install-deps` (no browser download needed).
