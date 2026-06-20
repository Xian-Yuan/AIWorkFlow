# TypeScript 6 Breaking Changes Quick Reference

## useRef Requires Initial Value

In TypeScript 6, `useRef<T>()` without an initial value is a compile error.

**Before (TS5):**
```typescript
const timerRef = useRef<ReturnType<typeof setTimeout>>()
```

**After (TS6):**
```typescript
const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined)
```

The generic parameter alone no longer satisfies the compiler — you must pass an explicit initial value (`undefined`, `null`, `0`, etc.) matching the type.

## Other TS6 Notes

- Stricter type narrowing in switch/if blocks
- Unused parameters must be prefixed with `_` or explicitly marked with `@ts-ignore`
- Template literal types are more strictly inferred

## Vite + Vitest Type Reference

When using Vitest with Vite, `vite.config.ts` needs the triple-slash directive for type support:

```typescript
/// <reference types="vitest/config" />
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    // vitest options here
  },
})
```

Without this directive, `test` property in `defineConfig` will show a TypeScript error.
