# viLilt Product Architecture & 3-Tier Specification

This document defines the 3-tier product architecture, branding, developer account distribution, feature scope, and Apple App Store compliance guidelines for the **viLilt** on-device neural voice and text AI companion.

---

## 1. Overview & Developer Account Distribution

| Tier Layer | Target App Name | Developer Account | Business Model & Ad Policy | Apple App Store Category |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Impact** | `viLilt` | `viaiforgood` (Nonprofit, `43SKUJ8Z35`) | **100% Free / No Ads / No IAP** | Productivity / Utilities |
| **Tier 2: Pro (Base)** | `viLilt Pro` | `VI AI INC` (Commercial, `3PY896HD7X`) | **Free Base Commercial License** | Productivity / Lifestyle |
| **Tier 3: Ultra (Paid)** | `viLilt Ultra` | `VI AI INC` (In-App Purchase) | **$3.99/mo or $39.99/yr / No Ads** | Productivity / Lifestyle |

---

## 2. Naming & App Store Metadata Matrix

### Tier 1: `viLilt` (Community Impact Edition)
* **Account**: `viaiforgood` (`43SKUJ8Z35`)
* **App Title**: `viLilt`
* **Subtitle**: `Private Voice & Text AI Chat` (27 chars)
* **Bundle ID**: `org.viaiforgood.vililt`
* **SKU**: `vililt-ios-impact`
* **App Group**: `group.org.viaiforgood.viclock` / `group.com.vi.viclock`
* **Ad Policy**: **No Ads** (100% clean community build)
* **Monetization**: **None** (No paywalls or subscriptions)

### Tier 2: `viLilt Pro` (Commercial Base Edition)
* **Account**: `VI AI INC` (`3PY896HD7X`)
* **App Title**: `viLilt Pro`
* **Subtitle**: `On-Device Voice AI Companion` (28 chars)
* **Bundle ID**: `com.vi.vililt`
* **SKU**: `vililt-pro-ios`
* **App Group**: `group.com.vi.viclock`
* **Ad Policy**: **No Ads / Upgrade Prompts**
* **Monetization**: Free starter tier for commercial/solo users with upgrade prompts to Ultra

### Tier 3: `viLilt Ultra` (Commercial Paid Unlock)
* **Account**: `VI AI INC` (In-App Purchase within `viLilt Pro`)
* **Product Name**: `viLilt Ultra`
* **Product IDs**:
  * Monthly: `com.vi.vililt.ultra.monthly` ($3.99/mo)
  * Yearly: `com.vi.vililt.ultra.yearly` ($39.99/yr)
* **Monetization**: In-App Subscription (StoreKit 2)

---

## 3. Feature Scope Matrix

| Feature Module | Tier 1: `viLilt` (Impact) | Tier 2: `viLilt Pro` (Commercial Base) | Tier 3: `viLilt Ultra` (Paid Upgrade) |
| :--- | :---: | :---: | :---: |
| **Commercial Rights** | Non-commercial / Civic | ✅ Commercial License | ✅ Commercial License |
| **On-Device LLM Models** | Up to 1.5B Weights (Qwen 2.5 0.5B/1.5B, Llama 3.2 1B) | Up to 3B Weights (Qwen 2.5 3B, Llama 3.2 3B) | **7B+ Pro Weights & Custom Quantization** |
| **Voice Call Mode** | ✅ Full Hands-Free Voice Orb | ✅ Full Hands-Free Voice Orb | ✅ Hands-Free + Ultra Low Latency Neural Streaming |
| **Companion Personas** | 5 Built-in Personas | 5 Built-in Personas | **Custom Persona Creator & Voice Tuning** |
| **Zero Cloud Guarantee** | 100% On-Device, zero telemetry | 100% On-Device, zero telemetry | 100% On-Device, zero telemetry |

---

## 4. Build & Deployment Commands

```bash
# Deploy Tier 1: Impact (viaiforgood / 43SKUJ8Z35)
bash scripts/build_testflight.sh

# Deploy Tier 2: Pro (VI AI INC / 3PY896HD7X)
bash scripts/build_testflight_pro.sh

# Deploy Both Tiers Sequentially
bash scripts/build_testflight_all.sh
```
