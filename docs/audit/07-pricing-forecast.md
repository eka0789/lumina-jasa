# 07 — Pricing & Demand Forecasting

**Audit date:** 2026-07-18  
**Auditor:** Automated + Manual  
**Status:** PASS (Deterministic Baseline)

---

## 1. AI Intake & Predictive Pricing Logic

Predictive pricing is implemented via the `suggest_job_intake(p_description, p_service_id)` RPC function. It generates budget recommendations based on actual active service catalog prices, preventing arbitrary user input from distorting market rates.

### The Budget Estimation Model
1. The function attempts to resolve the service category:
   - If `p_service_id` is provided, it confirms it exists and is active.
   - If not, it falls back to token matching by checking if the description contains the active service name: `lower(p_description) like '%'||lower(name)||'%'`.
   - If still unresolved, it defaults to the first active service in `sort_order`.
2. It calculates the **P50 median base price** of active catalog services matching that service:
   ```sql
   select coalesce(percentile_disc(0.5) within group(order by base_price), 250000)::bigint 
   into p50 
   from public.provider_services 
   where service_id = service_row.id and status = 'active' and base_price is not null;
   ```
3. It generates budget bounds from the median:
   - **Minimum Budget ($B_{\min}$):** 70% of the median ($0.70 \times P_{50}$)
   - **Maximum Budget ($B_{\max}$):** 140% of the median ($1.40 \times P_{50}$)
4. A **confidence score** is assigned based on match strength:
   - Service matched directly/term matched: `0.62`
   - Fallback default service: `0.32`
5. The recommendation is recorded in `ai_runs` and `ai_predictions`, returning the draft configuration for client confirmation.

---

## 2. Demand Forecasting Model

Demand forecasting operates on the 7-day scale using a moving average model of historic jobs data:

### Math Model (`forecastDemand`)
Given a historical vector of daily job volumes $H = [x_1, x_2, \dots, x_N]$:
1. Prune invalid entries ($x_i < 0$ or non-finite).
2. Calculate daily average:
   $$\mu = \frac{1}{|H_{clean}|} \sum_{x_i \in H_{clean}} x_i$$
3. Project future demand for horizon $T$ (defaults to 7 days):
   $$\text{Baseline} = \mu \times T$$
4. Project variance ranges to calculate P10, P50, and P90 confidence bands:
   - **P10 (Low Demand):** $\max(0, \lfloor\text{Baseline} \times 0.65\rfloor)$
   - **P50 (Median Demand):** $\lfloor\text{Baseline}\rfloor$
   - **P90 (High Demand):** $\lfloor\text{Baseline} \times 1.45\rfloor$

### Performance Metric (Weighted Absolute Percentage Error - WAPE)
Forecasting accuracy is evaluated using WAPE:
$$\text{WAPE} = \frac{\sum_{i=1}^M |A_i - F_i|}{\sum_{i=1}^M |A_i|}$$
Where $A$ is the actual demand array and $F$ is the forecasted demand array. If actual demand is zero, the model returns `null` to prevent division-by-zero errors.

---

## 3. Database Scheduling & Cron Integration

Forecast updates are processed through the `refresh_demand_forecast` RPC function, restricted to administrators (`admin` or `super_admin`) with active AAL2 authentication levels.

It queries the last 28 days of transaction history:
```sql
select coalesce(count(*)::numeric/28,0) into daily 
from public.jobs 
where service_id = p_service_id and created_at >= now() - interval '28 days';
```
It projects the next 7 days and records the forecast metrics in `demand_forecasts`, creating a structured audit log entry to track forecasting calculations over time.
