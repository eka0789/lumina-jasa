# Phase 5 AI/Realtime MVP Acceptance

Phase 5 introduces bounded decision support and realtime signals without placing AI on the booking, identity, or money control path.

## Repository evidence

| Capability | Guardrail | Evidence |
|---|---|---|
| Smart intake and pricing baseline | Editable output, confidence and assumptions; only a SHA-256 input hash is retained; unavailable models degrade to catalog rules | `suggest_job_intake`, request form, pgTAP fallback assertions |
| Interpretable ranking | Deterministic relevance, reputation, response, and area signals; visible reasons; stable tie-break | `src/lib/ai/ranking.ts` and unit tests |
| Realtime chat | Participant-only moderated command, publication-scoped subscription, persisted-message fallback and visible degraded state | booking chat plus pgTAP safe/flagged cases |
| Arrival tracking | Provider-member command, active-state and Indonesia-bound checks, opt-in geolocation, participant-only reads and reload fallback | booking tracking plus pgTAP role/state assertions |
| Moderation | Rules only create a case; AAL2 support/compliance/admin makes the reasoned final decision | `/admin/moderasi`, `moderation_cases`, negative AAL test |
| Model trace | Module/model/prompt/schema versions, status, hash, confidence, explanation and actor are persisted | `ai_runs` and `ai_predictions` assertions |

## Canary and degraded-mode gate

The pilot ships `deterministic_baseline/baseline-v1` as the safe fallback. A vendor model must not receive production traffic until an offline evaluation dataset, category/language slices, latency/cost limits, privacy review, and a rollback owner are recorded. Canary promotion must compare structured-field acceptance, correction rate, coverage and safety errors against this baseline. Model failure must continue to return the manual form or deterministic ranking; it must never block booking or mutate financial state.

Repository acceptance requires `npm run check` and the Supabase migration/pgTAP workflow. Operational sign-off still requires:

- realtime latency and reconnect evidence under the agreed load profile;
- tracking consent/content review and mobile-browser UAT;
- moderator false-positive/false-negative sampling in Bahasa Indonesia;
- offline evaluation and canary evidence for any external model;
- retention and deletion validation for location, AI traces, and moderation evidence.

Phase 5 is repository-complete only after these automated gates pass. The roadmap exit criterion remains pending until canary and degraded-mode evidence is signed off in staging.
