# Day 23 Lab Reflection

> Fill in each section. Grader reads the "What I'd change" paragraph closest.

**Student:** Hà Hữu An
**Submission date:** 2026-05-11
**Lab repo URL:** https://github.com/Han0811/Day23-Track2-Observability-Lab
---

## 1. Hardware + setup output

Paste output of `python3 00-setup/verify-docker.py`:

```json
{
  "docker": {
    "ok": true,
    "version": "29.4.0"
  },
  "compose_v2": {
    "ok": true,
    "version": "5.1.1"
  },
  "ram_gb_available": 7.47,
  "ram_ok": true,
  "required_ports": [
    8000,
    9090,
    9093,
    3000,
    3100,
    16686,
    4317,
    4318,
    8888
  ],
  "bound_ports": [],
  "all_ports_free": true
}
```

---

## 2. Track 02 — Dashboards & Alerts

### 6 essential panels (screenshot)

Drop `submission/screenshots/dashboard-overview.png`.

### Burn-rate panel

Drop `submission/screenshots/slo-burn-rate.png`.

### Alert fire + resolve

| When | What | Evidence |
|---|---|---|
| _T0_ | killed `day23-app`         | screenshot `alertmanager-firing.png` |
| _T0+90s_ | `ServiceDown` fired   | screenshot `slack-firing.png` |
| _T1_ | restored app              | — |
| _T1+60s_ | alert resolved        | screenshot `slack-resolved.png` |

### One thing surprised me about Prometheus / Grafana

Nó rất mạnh mẽ trong việc thu thập và hiển thị số liệu theo thời gian thực. Việc tích hợp với OpenTelemetry giúp việc theo dõi các ứng dụng AI trở nên dễ dàng hơn, đặc biệt là khả năng tự động tạo bảng điều khiển từ các file cấu hình có sẵn.

---

## 3. Track 03 — Tracing & Logs

### One trace screenshot from Jaeger

Drop `submission/screenshots/jaeger-trace.png` showing `embed-text → vector-search → generate-tokens` spans.

### Log line correlated to trace

Paste the log line and the trace_id it links to:

```
... Hãy chạy lệnh 'docker logs day23-app' và copy một dòng log có chứa trace_id dán vào đây ...
```

### Tail-sampling math

If your service produced N traces/sec, what fraction did the policy keep? Show the calculation.

Dựa vào cấu hình trong `otel-config.yaml`:
- Giữ lại 100% các vết bị lỗi (`keep-errors`).
- Giữ lại 100% các vết có độ trễ > 2000ms (`keep-slow`).
- Giữ lại 1% số lượng các vết bình thường còn lại (`probabilistic-1pct`).

Công thức tính tỉ lệ giữ lại:
`Fraction = (Số_vết_lỗi + Số_vết_chậm + 0.01 * Số_vết_bình_thường) / Tổng_số_vết`
Nếu tất cả các vết đều bình thường và nhanh, hệ thống sẽ giữ lại đúng **1%** (0.01 * N).

---

## 4. Track 04 — Drift Detection

### PSI scores

Paste `04-drift-detection/reports/drift-summary.json`:

```json
{
  "prompt_length": {
    "psi": 3.461,
    "kl": 1.7982,
    "ks_stat": 0.702,
    "ks_pvalue": 0.0,
    "drift": "yes"
  },
  "embedding_norm": {
    "psi": 0.0187,
    "kl": 0.0324,
    "ks_stat": 0.052,
    "ks_pvalue": 0.133853,
    "drift": "no"
  },
  "response_length": {
    "psi": 0.0162,
    "kl": 0.0178,
    "ks_stat": 0.056,
    "ks_pvalue": 0.086899,
    "drift": "no"
  },
  "response_quality": {
    "psi": 8.8486,
    "kl": 13.5011,
    "ks_stat": 0.941,
    "ks_pvalue": 0.0,
    "drift": "yes"
  }
}
```

### Which test fits which feature?

- `prompt_length`: Chọn **PSI** (Population Stability Index) vì nó giúp đánh giá sự thay đổi phân bố của độ dài prompt theo các khoảng (buckets) rất trực quan.
- `embedding_norm`: Chọn **KS test** vì độ chuẩn hóa vector thường là biến liên tục và KS test rất mạnh trong việc so sánh hai phân phối liên tục.
- `response_quality`: Chọn **PSI** hoặc **KL Divergence** để đo lường mức độ lệch của chất lượng phản hồi so với phân phối chuẩn ban đầu.

---

## 5. Track 05 — Cross-Day Integration

### Which prior-day metric was hardest to expose? Why?

Phần khó nhất là việc đồng bộ hóa dữ liệu từ các ngày trước (như vector DB hoặc logs) vào hệ thống tập trung của ngày hôm nay, do sự khác biệt về định dạng log và cách thức expose metrics của từng dịch vụ.

---

## 6. The single change that mattered most

> **Grader reads this closest.** What one thing about your stack design — a metric you added, a label you dropped, a panel you reorganized, an alert threshold you tuned — made the biggest difference between "works" and "useful"? Write 1-2 paragraphs. Connect it to a concept from the deck.

Việc cấu hình chính xác cổng ánh xạ (port mapping) cho `day23-app` từ `8000/tcp` thành `127.0.0.1:8000:8000` là thay đổi quan trọng nhất giúp hệ thống chuyển từ trạng thái "chạy ngầm" (works) sang "có ích" (useful). Nếu không mở cổng này, các công cụ test tải như Locust không thể truy cập vào ứng dụng để tạo dữ liệu, dẫn đến toàn bộ hệ thống quan sát (Prometheus, Grafana, Jaeger) đều rơi vào tình trạng "No data".

Thay đổi này kết nối trực tiếp với khái niệm về **Khả năng tiếp cận (Reachability)** và **Luồng dữ liệu (Data Pipeline)** trong hệ thống quan sát. Một hệ thống không thể quan sát được nếu dữ liệu không thể chảy qua các thành phần. Việc đảm bảo các cổng được cấu hình đúng giúp hoàn thiện chuỗi xích từ client -> app -> collector -> dashboards.
