# Phase 7 Scale Foundation

Phase 7 is an ongoing operating phase, not a one-time completion gate. This tranche establishes bounded primitives that can be evaluated quarterly before wider rollout.

## Implemented tranche

| Capability | Safety boundary | Evidence |
|---|---|---|
| Emergency dispatch | Only explicitly enabled services; customer confirms it is not life-threatening; maximum five verified providers; availability is not promised | `/pesan/darurat`, `submit_emergency_job_request`, pgTAP bounded-dispatch tests |
| Multichannel routing | Durable notification rows honor per-event provider preferences for email, push, WhatsApp and SMS; in-app remains the reliable baseline | emergency notification assertions and existing notification queue index |
| Fraud operations | Explainable signals, aggregated case score, AAL2 staff separation, human final decision, no automatic blacklist | `/admin/skala` and pgTAP role/no-auto-ban tests |
| Demand forecast | Pinned historical baseline with p10/p50/p90 interval, drivers and WAPE helper; no claim of learned accuracy | forecast SQL, `src/lib/ai/forecast.ts` and unit tests |
| Ranking evolution | Versioned registry starts with one deterministic active baseline; learned/canary models are not promoted implicitly | `ranking_model_versions` and active-baseline assertion |

## Quarterly gates

Emergency expansion requires documented category policy, provider response coverage, false-dispatch rate, completion/safety outcomes, support hours and legal approval. External notification channels require consent, template approval, delivery receipts, opt-out handling, provider certification, cost/error budgets and fallback evidence.

Fraud thresholds require labeled outcomes, calibration, false-positive and appeal-overturn reporting by relevant cohort. No LLM or anomaly score may independently blacklist, suspend, hold payout or reject a dispute. Ranking promotion requires offline NDCG/recall, exposure fairness, logged propensity, shadow traffic, a bounded canary, completion/cancellation guardrails and rollback. Forecast use requires WAPE and interval-coverage evidence by service/region and must remain advisory for capacity planning.

The scale phase remains open. Each quarterly review must record outcome, unit economics, reliability, privacy, fairness, operational load, owner and the next investment/rollback decision.
