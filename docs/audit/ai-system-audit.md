# Audit System & Governance AI Platform Lumina Jasa

**Tanggal Audit:** 2026-07-20  
**Status Audit:** PASS (All Compliance & Governance Requirements Satisfied)  
**Target Dokumen:** `docs/audit/ai-system-audit.md`  

---

## 1. Eksekutif & Summary Architecture

Audit ini melakukan evaluasi mendalam terhadap 6 (enam) fitur AI yang terintegrasi pada platform **Lumina Jasa**:
1. **AI Smart Matchmaking** (Penjodohan pelanggan dengan penyedia jasa)
2. **AI Predictive Pricing** (Estimasi rentang harga pekerjaan & durasi)
3. **AI Fraud Detection** (Deteksi risiko kecurangan, anomali, & pola ancaman)
4. **OCR Document Processing** (Ekstraksi teks dari dokumen KYC/KYB)
5. **Liveness Detection Callback** (Verifikasi kehadiran fisik manusia secara real-time)
6. **Face Matching** (Komparasi kemiripan foto identitas vs selfie liveness)

Seluruh pemanggilan fitur AI diatur oleh **Unified Core AI Governance Pipeline** (`src/lib/ai/pipeline.ts`) yang menjamin *strict schema validation*, sanitasi data sensitif (PII), perlindungan *prompt injection*, batas waktu latensi (*timeout*), retri terbatas dengan *exponential backoff*, pembatasan kuota (*rate limiting*), serta jalur *fallback* deterministik tanpa pernah memberikan wewenang otoritas kepada AI untuk mengubah peran pengguna, kepemilikan, status pembayaran, pencairan dana (*payout*), pengembalian dana (*refund*), atau otorisasi sistem.

---

## 2. Matriks Evaluasi 20 Dimensi Pemeriksaan AI

| Dimensi Pemeriksaan | AI Smart Matchmaking | AI Predictive Pricing | AI Fraud Detection | OCR Processing | Liveness Detection | Face Matching |
|---|---|---|---|---|---|---|
| **1. Sumber Input** | Kategori, deskripsi pekerjaan, lokasi, daftar kandidat terverifikasi | Kategori layanan, deskripsi pekerjaan, harga dasar katalog | Aggregat sinyal (kecepatan, perangkat, anomali), teks | File gambar identitas/KTP, data NIK/nama yang diklaim | Callback payload vendor (session_id, score, nonce, sig) | Foto dokumen KTP, foto selfie liveness |
| **2. Preprocessing** | Trimming teks, sanitasi kata pencarian, filter kualifikasi kandidat | Sanitasi PII (NIK, card, phone), pembersihan format angka | Redaksi kata sensitif, komputasi skor agregat sinyal | Crop area gambar, penyesuaian kontras | Ekstraksi raw header & body webhook HMAC | Deteksi crop area wajah pada dokumen & selfie |
| **3. Prompt Structure** | Isolasi XML `<user_input>`, instruksi ranking tanpa protected traits | Isolasi XML `<user_input>`, instruksi kalkulasi p10/p50/p90 | Isolasi XML `<user_input>`, instruksi analisis risiko additive | Isolasi XML `<user_input>`, ekstraksi bidang terstruktur | N/A (Server HMAC callback verification) | Isolasi XML `<user_input>`, instruksi skor kemiripan |
| **4. Pinned Model** | `matchmaking-gpt4o-v1` / `deterministic-bayesian-v1` | `pricing-gemini-v1` / `catalog-baseline-rules-v1` | `fraud-claude-v1` / `deterministic-fraud-rules-v1` | `ocr-vision-v1` / `ocr-fallback-v1` | `vendor-liveness-hmac-v1` | `facematch-vision-v1` / `facematch-fallback-v1` |
| **5. Output Parser** | Parser JSON terstruktur dengan penanganan *syntax error* | Parser JSON terstruktur dengan penanganan *syntax error* | Parser JSON terstruktur dengan penanganan *syntax error* | Parser JSON terstruktur dengan penanganan *syntax error* | Verification Parser HMAC & timestamp drift | Parser JSON terstruktur dengan penanganan *syntax error* |
| **6. Schema Validation** | `MatchmakingOutputSchema` (Zod strict parse) | `PredictivePricingOutputSchema` (Zod strict parse) | `FraudDetectionOutputSchema` (Zod strict parse) | `OCROutputSchema` (Zod strict parse) | `LivenessVerificationSchema` (Zod strict parse) | `FaceMatchOutputSchema` (Zod strict parse) |
| **7. Timeout Limit** | 5.000 ms (AbortController) | 5.000 ms (AbortController) | 3.000 ms (AbortController) | 5.000 ms (AbortController) | 3.000 ms (Server HMAC check) | 5.000 ms (AbortController) |
| **8. Retry Strategy** | Maksimal 1 retry + backoff 100ms/200ms + jitter | Maksimal 1 retry + backoff 100ms/200ms + jitter | Maksimal 1 retry + backoff 100ms/200ms + jitter | Maksimal 1 retry + backoff 100ms/200ms + jitter | 0 retry (Reject callback jika signature invalid) | Maksimal 1 retry + backoff 100ms/200ms + jitter |
| **9. Fallback Path** | Ranking deterministik Bayesian (`rankProviders`) | Estimasi berbasis median base price katalog ($0.70 - 1.40 \times P_{50}$) | Aturan ancaman deterministik + penandaan manual review | Penandaan dokumen *unprocessed* + routing operator review | Penolakan callback invalid (`isValid: false`, manual review) | Penandaan skor 0 + routing manual operator review |
| **10. Error Handling** | Fail-closed & graceful fallback tanpa bocor stack trace | Fail-closed & graceful fallback tanpa bocor stack trace | Fail-closed & graceful fallback tanpa bocor stack trace | Fail-closed & graceful fallback tanpa bocor stack trace | Fail-closed & reject invalid webhook signature | Fail-closed & graceful fallback tanpa bocor stack trace |
| **11. Structured Logging** | Record ke `ai_runs` (input_hash, latency, token, cost, status) | Record ke `ai_runs` (input_hash, latency, token, cost, status) | Record ke `ai_runs` & audit log kasus kecurangan | Record ke `ai_runs` & log verifikasi KYC | Log verifikasi callback & audit security header | Record ke `ai_runs` & log kasus verifikasi |
| **12. Privacy (PII)** | Tidak ada NIK/Kontak dimasukkan dalam prompt | Masking NIK, nomor telepon, email, & nomor kartu kredit | Redaksi data sensitif pengguna sebelum evaluasi prompt | Gambar disimpan di bucket `restricted`, presigned short-lived URL | Tidak ada PII disimpan dalam callback log, menggunakan session hash | Foto biometrik diisolasi di private storage terenkripsi |
| **13. Cost Control** | Cache deduplikasi SHA-256 (window 5 menit) | Cache deduplikasi SHA-256 (window 5 menit) | Deduplikasi hash sinyal risiko | Limitasi upload gambar (maks 8MB per dokumen) | Non-LLM execution (bebas biaya token) | Cache deduplikasi hash pasangan gambar |
| **14. Model Version** | Terpaku (*pinned*) pada versi snapshot tertentu | Terpaku (*pinned*) pada versi snapshot tertentu | Terpaku (*pinned*) pada versi snapshot tertentu | Terpaku (*pinned*) pada versi snapshot vendor/vision | Algoritma HMAC SHA-256 terstandarisasi | Terpaku (*pinned*) pada versi vision snapshot |
| **15. Confidence Score** | Mengembalikan skor 0.0 - 1.0; threshold min 0.60 | Mengembalikan skor 0.0 - 1.0; threshold min 0.60 | Mengembalikan skor 0.0 - 1.0; threshold min 0.60 | Mengembalikan skor 0.0 - 1.0; threshold min 0.80 | Skor kelayakan liveness vendor; threshold min 0.85 | Skor kemiripan 0.0 - 1.0; threshold min 0.85 |
| **16. Explainability** | Menyediakan `reasons` transparan (mis. "Lokasi cocok", "Respons cepat") | Menjelaskan asumsi, batasan pengerjaan, & item *included/excluded* | Menyediakan `detectedFlags` & rincian alasan sinyal risiko | Menandai bidang yang tidak cocok (`mismatchFields`) | Menyediakan alasan kegagalan (signature, drift, spoofing) | Menyediakan status (`matched`, `mismatch`, `manual_review`) |
| **17. Human Review** | Pengguna dapat memilih penyedia secara bebas | Harga rekomendasi bersifat *editable*; kuotasi final oleh mitra | Kasus risiko tinggi ($\ge 60$) wajib ditinjau staf komplikasi | Discrepancy OCR mewajibkan peninjauan manual operator | Callback tidak valid/mencurigakan dialihkan ke peninjauan manual | Skor kemiripan 0.70-0.84 dialihkan ke peninjauan operator |
| **18. Prompt Injection** | Pembersihan keyword injection & pembatasan `<user_input>` | Pembersihan keyword injection & pembatasan `<user_input>` | Pembersihan keyword injection & pembatasan `<user_input>` | Pembersihan keyword injection & pembatasan `<user_input>` | N/A (Webhooks verified via HMAC signature) | Pembersihan keyword injection & pembatasan `<user_input>` |
| **19. Abuse Prevention** | Ditolak jika payload > 10.000 karakter | Ditolak jika payload > 10.000 karakter | Ditolak jika payload > 10.000 karakter | Ditolak jika ukuran file > 8MB | Verifikasi timestamp drift ($\le 300$ detik) cegah replay | Ditolak jika payload > 10.000 karakter |
| **20. Rate Limiting** | Maksimal 30 permintaan/menit per pengguna | Maksimal 30 permintaan/menit per pengguna | Maksimal 30 permintaan/menit per pengguna | Maksimal 10 permintaan/menit per penyedia | Limiter IP & nonce unik per sesi | Maksimal 10 permintaan/menit per penyedia |

---

## 3. Verifikasi Aturan Mutlak Governance (Mandatory Checklist Verification)

Semua syarat keselamatan dan pembatasan wewenang AI platform telah diverifikasi dan dipenuhi:

- [x] **Validasi Schema Ketat:** Seluruh output AI diproses melalui Zod Schema Parser (`MatchmakingOutputSchema`, `PredictivePricingOutputSchema`, `FraudDetectionOutputSchema`, `OCROutputSchema`, `LivenessVerificationSchema`, `FaceMatchOutputSchema`).
- [x] **Proteksi Output Invalid:** Output JSON malformed atau tidak sesuai schema langsung dibuang dan memicu *fallback path* tanpa disimpan ke basis data bisnis utama.
- [x] **Pembatasan Wewenang Otoritas:** Pipeline AI mengimplementasikan `assertGovernanceRules()`. AI dilarang keras menentukan atau mengubah bidang `user_role`, `ownership`, `payment_status`, `payout_status`, `refund_status`, atau `authorization`.
- [x] **Anti Single-Point-Decision untuk Risiko Tinggi:** Keputusan kecurangan (*fraud banning*) dan verifikasi KYC wajib melalui peninjauan manusia (*human review*) pada antrean `moderation_cases` / `fraud_cases`. AI hanya memberikan penandaan sinyal dan skor indikatif.
- [x] **Hard Filter Matchmaking Sebelum Ranking AI:** Fungsi `filterEligibleProviders()` menyaring status aktif provider, verifikasi KYC, batas radius lokasi PostGIS, ketersediaan jadwal, dan status non-blacklist sebelum AI melakukan *ranking*.
- [x] **Rentang & Confidence Predictive Pricing:** Mengembalikan interval $P_{10}, P_{50}, P_{90}$ beserta tingkat confidence.
- [x] **Batas Harga Katalog & Kesepakatan Final:** Fungsi `applyCatalogPricingBounds()` mengunci estimasi harga AI pada rentang $0.50 \times P_{50}$ hingga $2.50 \times P_{50}$ dari harga dasar katalog. Harga final ditentukan melalui kesepakatan kuotasi pengguna & mitra, bukan keputusan tunggal AI.
- [x] **Fraud Score Transparan & Manual Review:** Menghasilkan rincian sinyal risiko (*explainable flags*) dan mengarahkan kasus risiko tinggi ($\ge 60$) ke antrean pemeriksaan staf kepatuhan.
- [x] **OCR Cross-Comparison:** Data hasil ekstraksi OCR KTP/identitas dibandingkan (*fuzzy distance*) dengan data nama & NIK yang diklaim pengguna (`crossCompareOCR()`). Ketidakcocokan langsung menandai `requiresHumanReview: true`.
- [x] **Verifikasi Server-Side Liveness:** Callback vendor liveness diuji di tingkat server menggunakan verifikasi HMAC-SHA256 signature, secret key, dan batas kesegaran timestamp ($\le 300$ detik) untuk mencegah serangan *replay*.
- [x] **Batas Bounded Latency (Timeout):** Setiap pemanggilan provider AI dilengkapi dengan `AbortSignal` dengan *timeout* default 5.000 ms (3.000 ms untuk fraud & liveness).
- [x] **Retry Terbatas & Exponential Backoff:** Retry dibatasi maksimal 1-2 kali dengan *delay backoff* (100ms, 200ms) dan *jitter*. Error non-retryable (Zod mismatch/JSON malformed) langsung berpindah ke fallback.
- [x] **Deterministik Fallback Path:** Seluruh modul AI memiliki fungsi *fallback* deterministik yang mengembalikan payload valid saat provider AI mengalami *downtime*.
- [x] **Pengendalian Biaya Token & Caching:** Menggunakan cache SHA-256 deduplikasi input hash dan *sliding window rate limiter* untuk membatasi eksekusi berulang.
- [x] **Sanitasi PII & Data Sensitif:** Fungsi `sanitizeInputText()` menyaring dan mengaburkan 16-digit NIK, nomor kartu kredit, email, dan nomor telepon sebelum prompt dikirim ke model AI.

---

## 4. Laporan Pengujian Otomatis (Automated Test Suite Results)

Pengujian otomatis telah dibuat dan diverifikasi pada `src/lib/ai/pipeline.test.ts`. Seluruh 15 unit test berhasil lulus (*100% Pass Rate*):

```text
 RUN  v3.2.7 C:/Users/Admin/lumina-jasa

 ✓ src/lib/ai/pipeline.test.ts (15 tests) 349ms
   ✓ 1. valid response: processes valid JSON matching strict Zod schema with high confidence
   ✓ 2. invalid JSON: catches malformed JSON from provider and triggers fallback path
   ✓ 3. missing field: rejects JSON missing required Zod fields and triggers fallback path
   ✓ 4. timeout: aborts slow provider request exceeding latency limit and executes fallback
   ✓ 5. provider error: handles 500/503 HTTP provider errors with retries and fallback
   ✓ 6. rate limit: blocks excessive requests exceeding quota before calling provider
   ✓ 7. malicious user prompt: sanitizes prompt injection attempts and PII data
   ✓ 8. oversized input: rejects payloads larger than 10,000 characters immediately
   ✓ 9. confidence rendah: flags low-confidence provider outputs (<0.60) for human review
   ✓ 10. fallback path: returns valid deterministic baseline payload when AI provider is unconfigured
   ✓ AI Feature Specific Guardrail & Rule Tests
     ✓ AI Predictive Pricing: enforces catalog bounds (0.50x to 2.50x base price)
     ✓ AI Fraud Detection: aggregates signals and assigns explainable risk band
     ✓ OCR Processing: detects NIK mismatch and flags for operator review
     ✓ Liveness Callback: verifies HMAC signature and timestamp freshness
     ✓ Face Matching: routes borderline facial scores (0.70-0.84) to human review

 Test Files  1 passed (1)
      Tests  15 passed (15)
   Duration  8.01s
```

---

## 5. Kesimpulan Audit & Panduan Operasional

1. **Rekomendasi Rilis:** Seluruh fitur AI dinyatakan **LULUS (PASS)** dan aman untuk digunakan di lingkungan produksi (*Production Ready*).
2. **Monitoring & Alerting:** Seluruh eksekusi AI mencatat metrik latensi, token, dan biaya ke tabel `ai_runs`. Disarankan untuk memasang alarm pemantauan apabila rasio status `fallback` melebihi 5% dalam kurun waktu 1 jam.
3. **Penyimpanan Biometrik:** Gambar KTP dan selfie liveness tetap tersimpan pada bucket terisolasi (`restricted`) dengan *short-lived presigned URL* dan hak akses berbasis RLS ketat.
