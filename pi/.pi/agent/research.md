# Research: Bun JavaScript Runtime — Latest Stable Release (June 2026)

## Summary
Bun's latest stable release is **v1.3.14**, published May 13, 2026. Bun is now owned by Anthropic (acquired December 2025). Key v1.3.x features include built-in HMR, HTTP/2 multiplexing, TLS optimization, and an ongoing Zig-to-Rust rewrite.

## Findings

1. **Latest version: v1.3.14** — Released May 13, 2026. Available via `bun upgrade`. [Wikipedia](https://en.wikipedia.org/wiki/Bun_(software)) | [Bun Blog](https://bun.com/blog/bun-v1.3.14)

2. **Anthropic acquisition** — Anthropic acquired Oven (Bun's creator) in December 2025. Same team continues full-time development. [DevClass](https://www.devclass.com/ai-ml/2026/05/15/anthropics-bun-rust-rewrite-merged-at-speed-of-ai/5240541)

3. **Zig-to-Rust rewrite merged** — PR merged to main repo (May 2026). Still half-baked per official guide. Migration watched closely by community. [DevClass](https://www.devclass.com/ai-ml/2026/05/15/anthropics-bun-rust-rewrite-merged-at-speed-of-ai/5240541)

4. **v1.3.x key features:**
   - **HMR** in dev server (auto-updates on code changes)
   - **HTTP/2 multiplexing** — parallel fetches share TLS handshake and connection
   - **TLS optimization** — shared SSL_CTX cache reduces ~50KB per connection
   - **`bun test --isolate`** and `--parallel` flags
   - **`bun test --changed`** for incremental testing
   - **70+ Bun Shell bug fixes**
   - **`bun publish` sends README metadata** to registry
   - **macOS orphan process prevention** via kqueue watcher
   [Bun Blog](https://bun.com/blog/bun-v1.3.14)

5. **Performance vs Node.js** — Synthetic benchmarks: ~52K req/s (Bun) vs ~13K req/s (Node). Cold start ~290ms vs ~940ms. Idle memory 25–40% lower. [Tech Insider](https://tech-insider.org/bun-vs-node-2026)

6. **All-in-one toolkit** — Runtime, package manager (`bun install`), bundler (`bun build`), test runner (`bun test`), native SQLite/Postgres/MySQL/Redis clients. [Knightli](https://knightli.com/en/2026/05/17/bun-javascript-toolkit)

## bun:test Documentation

Basic test:
```ts
import { test, expect } from "bun:test";

test("hello world", () => {
  expect(1).toBe(1);
});
```

Run tests:
```sh
bun test                  # all tests
bun test path/to/dir      # directory
bun test specific.test.ts # specific file
```

New v1.3.x test flags:
```sh
bun test --isolate        # isolate test files
bun test --parallel       # run tests in parallel
bun test --changed        # only changed tests
```

Testing Library integration:
```tsx
import { test, expect } from "bun:test";
import { screen, render } from "@testing-library/react";
import { MyComponent } from "./myComponent";

test("Can use Testing Library", () => {
  render(MyComponent);
  const myComponent = screen.getByTestId("my-component");
  expect(myComponent).toBeInTheDocument();
});
```

## Sources

**Kept:**
- Wikipedia: Bun (software) — version confirmation, acquisition timeline
- Bun Blog: bun-v1.3.14 — official release notes, feature details
- Tech Insider: Bun vs Node.js 2026 — performance benchmarks
- PkgPulse: Bun vs Vite 2026 — version evidence, GitHub stats
- DevClass: Anthropic's Bun Rust rewrite — Zig-to-Rust migration status
- Knightli: Bun overview 2026 — feature summary, migration advice
- Context7 /oven-sh/bun — bun:test documentation, code examples

**Dropped:**
- Instagram Appwrite post — marketing fluff, no version data
- node-oracledb release notes — tangential
- TypeScript 6.0 docs — unrelated
- Reddit thread — no unique info beyond other sources

## Gaps

- **Exact Bun 2.0 timeline** — No evidence of 2.0 release; Rust rewrite still in progress.
- **Production adoption metrics** — GitHub stars (90K+) and forks (4.5K) available, but no official production user count.
- **Rust rewrite completion date** — Official guide says "half-baked," no ETA given.
