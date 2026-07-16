# UX, Wireframes and Design System

## 1. Experience principles

- **Trust before speed:** show verification, totals, policies, evidence and recourse at the decision point.
- **AI drafts, people decide:** suggestions are editable and show assumptions/confidence.
- **One next action:** each workflow page has a dominant action and a visible status/timeline.
- **Progressive disclosure:** customer flows stay simple; business/operations detail appears when relevant.
- **Mobile-field ready:** provider tasks support one hand, poor networks, retries and clear saved state.
- **Accessible by default:** WCAG 2.2 AA, keyboard use, 44×44 px touch targets and reduced motion.

Primary language is Bahasa Indonesia with plain terms. Avoid claiming “guaranteed,” “verified,” “AI accurate,” or “escrow” beyond the approved legal/operational meaning.

## 2. Information architecture

| Surface | Navigation |
|---|---|
| Public | Home, categories, search, provider profile, trust/safety, help |
| Customer | Requests, bookings, chat, payments/invoices, favorites, profile |
| Business | Overview, requests, approvals, bookings, members, invoices, reports, settings |
| Provider | Today, leads, calendar, services, jobs, messages, earnings, verification |
| Staff | Work queues, case workspace, users/providers, finance, catalog, analytics, audit, settings |

Staff navigation is capability-driven; hidden modules are not fetched. Restricted fields are masked until an authorized case action requires access.

## 3. Critical wireframes

### AI-assisted request — mobile

```text
┌─────────────────────────────────┐
│ ← Jelaskan kebutuhan       1/4  │
│ [progress bar]                  │
│ Apa yang perlu dibantu?         │
│ ┌─────────────────────────────┐ │
│ │ Pipa dapur bocor sejak...   │ │
│ └─────────────────────────────┘ │
│ [Tambah foto] [Ambil video]     │
│                                 │
│ Saran AI (dapat diubah)         │
│ Perbaikan pipa · 74% yakin      │
│ Asumsi: area mudah dijangkau    │
│ [Ubah]                          │
│ ⚠ Matikan sumber air bila aman  │
│                                 │
│            [Lanjutkan]          │
└─────────────────────────────────┘
```

### Match comparison — desktop

```text
┌ Filters ─────┬ 5 penyedia cocok ─────────────────────────┐
│ Date         │ [Verified] Budi Teknik   2.1 km  4.8 (92) │
│ Distance     │ Available 10:00 · IDR 200–350k             │
│ Price        │ Why: available today, similar job history  │
│ Rating       │ [View profile]              [Choose]       │
│              ├─────────────────────────────────────────────┤
│              │ Explain estimate / fees / cancellation      │
└──────────────┴─────────────────────────────────────────────┘
```

### Active job

```text
Status: Dalam perjalanan · ETA 12 menit · updated 20 sec ago
[Map / last-known fallback]
Timeline: Paid ✓  Accepted ✓  En route ●  Working ○  Complete ○
[Chat] [Call via protected contact] [Safety/help]
Primary action changes by actor/state; dispute is not a competing primary CTA.
```

### Operations case workspace

```text
Queue filters | Case header + SLA + risk | Allowed actions
              | Identity (masked)        | [Request evidence]
              | Booking/payment timeline | [Recommend decision]
              | Evidence + conversation  | [Escalate]
              | Decision reason/history  | dual approval if required
```

## 4. Three-layer tokens

The system follows primitive → semantic → component tokens so themes and status meanings do not leak raw values into components.

```css
:root {
  /* primitives */
  --teal-50: 166 76% 97%; --teal-600: 173 80% 27%; --teal-700: 175 84% 22%;
  --amber-500: 38 92% 50%; --red-600: 0 72% 51%; --green-600: 142 72% 29%;
  --slate-50: 210 40% 98%; --slate-200: 214 32% 91%; --slate-600: 215 16% 47%; --slate-950: 222 47% 11%;
  --space-1: .25rem; --space-2: .5rem; --space-3: .75rem; --space-4: 1rem;
  --space-6: 1.5rem; --space-8: 2rem; --space-12: 3rem; --space-16: 4rem;
  --radius-sm: .375rem; --radius-md: .625rem; --radius-lg: 1rem;
  --duration-fast: 150ms; --duration-normal: 200ms;

  /* semantic */
  --background: var(--slate-50); --foreground: var(--slate-950);
  --primary: var(--teal-600); --primary-hover: var(--teal-700); --primary-foreground: 0 0% 100%;
  --border: var(--slate-200); --muted-foreground: var(--slate-600);
  --success: var(--green-600); --warning: var(--amber-500); --destructive: var(--red-600);
  --focus-ring: var(--teal-600);

  /* component */
  --button-primary-bg: var(--primary); --button-primary-fg: var(--primary-foreground);
  --button-radius: var(--radius-md); --input-border: var(--border);
  --card-radius: var(--radius-lg); --status-active: var(--success);
}
```

Use space-separated HSL variables for Tailwind opacity modifiers and shadcn alignment. Dark mode overrides semantic tokens only. Contrast must be tested; status never relies on color alone.

### Typography and layout

- Self-host **Plus Jakarta Sans** or a privacy-approved equivalent; system fallback `ui-sans-serif`.
- Scale: 12, 14, 16, 18, 20, 24, 30, 38, 48 px; body 16 px/1.5.
- 4 px spacing base. Page max width 1280 px; readable prose max 68 characters.
- Breakpoints follow content behavior, roughly 640/768/1024/1280 px; do not design by device brand.

## 5. Component specifications

| Component | Variants/states | Lumina-specific requirement |
|---|---|---|
| Button | primary, secondary, outline, ghost, destructive; loading/disabled | Loading preserves label width and announces state |
| Input/form | default, focus, error, disabled, readonly | Persistent label, helper/error association, Indonesian examples |
| Provider card | compact/full/skeleton | verification meaning, distance freshness, price qualifier, reason codes |
| Price estimate | compact/detail/low-confidence | interval, inclusions, assumptions, confidence and “not final quote” |
| Trust badge | identity/business/skill | tooltip explains verifier, scope and expiry; never generic shield |
| Job status | timeline/mobile stepper | actor, timestamp, stale/offline state and next action |
| Data table | compact/default; loading/empty/error | keyboard sort, column labels, mobile card alternative |
| Dialog/drawer | confirmation/form/destructive | destructive shows consequence and typed/reason confirmation if high impact |
| File uploader | idle/uploading/scanning/clean/rejected | retry, type/size, scan result and accessible progress |
| Map | live/stale/unavailable | text ETA/status fallback; never sole carrier of information |
| AI suggestion | ready/low-confidence/fallback | AI label, editable fields, assumptions and feedback |

Interactive state priority: disabled → loading → active → focus → hover → default. Visible focus ring is 2 px plus 2 px offset. Motion is 150–300 ms and disabled/reduced for `prefers-reduced-motion`.

## 6. Forms and content states

React Hook Form + Zod powers multi-step input. Save drafts locally and server-side when authenticated, show last-saved time and avoid clearing on recoverable errors. Validation appears at field and summary; focus moves to the summary on failed submit. Server errors map to stable codes, not brittle message matching.

Every screen designs: initial loading, background refresh, empty, partial, success, field error, permission denied, offline/stale and dependency-degraded states. Skeletons mirror layout and do not loop indefinitely.

## 7. Accessibility acceptance

- Semantic headings/landmarks; skip link; logical focus order and no keyboard traps.
- Labels/instructions do not depend on placeholder. Errors use `aria-describedby`; async state uses polite live regions.
- Normal text contrast ≥4.5:1; large text/non-text UI ≥3:1; 200% zoom and 320 CSS px reflow.
- Maps/charts have text/table equivalents. Chat supports screen-reader announcements without stealing focus.
- Touch targets at least 44×44 px and adequate spacing.
- Test axe plus keyboard, NVDA/VoiceOver, zoom, reduced motion and high-contrast behavior on critical flows.

## 8. Figma/handoff checklist

Create token variables first, then primitives, composite marketplace components and page templates. Document responsive rules, content limits, empty/error/loading states and interaction annotations. Component names mirror code. A design is ready only when strings, validation, permissions, analytics events and accessibility notes are included.
