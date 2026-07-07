# Mobility & Air Travel Requirements Agent — Production Requirements

**Product:** Global mobility and air-travel requirements assistant  
**Primary users:** Individual travelers · Corporate HR / mobility teams  
**Channels:** Web app · Mobile app · Partner APIs  
**Build approach:** Greenfield custom agent (API-first)  
**Geographic scope:** Global from day one (authoritative data via commercial travel-doc APIs)  
**Document version:** 1.0  
**Status key:** ⬜ Not started · 🟡 Partial · ✅ Built · 🔮 Future wave

---

## 1. Vision & goals

Build an agent that gives **personalized, current, and actionable** immigration and air-travel requirements for any trip worldwide.

**North-star outcome:** A traveler or HR mobility specialist can enter a trip profile once and receive a verified checklist (visa, passport validity, transit rules, health docs, timelines) with official source links — without relying on outdated blog posts or generic LLM answers.

**Core principles**

| Principle | Requirement |
|-----------|-------------|
| **Facts from APIs** | Visa and entry rules MUST come from authoritative travel-doc providers; the LLM explains and orchestrates, never invents rules |
| **Personalized** | Answers depend on nationality, residency, existing visas, route, dates, and purpose |
| **Multi-audience** | Same engine serves B2C travelers and B2B HR teams managing employee relocations |
| **API-first** | Web and mobile are clients of the same core service; partners integrate via REST |
| **Trust & compliance** | Every response includes disclaimers, source attribution, and data-as-of timestamps |

---

## 2. Personas

| Persona | Description | Primary needs |
|---------|-------------|---------------|
| **Individual traveler** | Plans personal or business trips | Quick visa/transit answers, document checklist, deadline reminders |
| **Frequent flyer** | Multi-trip, multi-citizenship | Saved profile, trip history, change alerts |
| **HR mobility specialist** | Manages employee relocations and business travel | Bulk employee profiles, assignment tracking, policy compliance |
| **Relocation manager** | Long-term international assignments | Work permit pathways, dependent visas, timeline Gantt |
| **Travel manager (corporate)** | Approves business travel | Policy checks, risk flags, exportable reports |
| **Partner integrator** | Airline, TMC, HRIS, neobank | Stable REST API, webhooks, SLA |
| **Human advisor** | Immigration lawyer / mobility consultant | Escalation queue, case context, audit trail |

---

## 3. Scope

### In scope (MVP)

| Area | Capability |
|------|------------|
| **Trip intake** | Origin, destination, transit airports, dates, purpose (tourism, business, work, study, relocation) |
| **Traveler profile** | Nationality(ies), country of residence, passport(s), existing visas/permits |
| **Entry & transit** | Visa required / not required, visa type, transit visa rules |
| **Passport validity** | Minimum validity rules per destination |
| **Health docs** | Where returned by travel-doc API (vaccination, health declaration) |
| **Checklist output** | Structured requirements with deadlines, official links, confidence level |
| **Conversational agent** | Clarifying questions, "what if" scenarios (dual citizenship, layover changes) |
| **B2B basics** | Organization accounts, employee roster, assign trips to employees |
| **APIs** | REST for trip assessment, profile CRUD, checklist retrieval |
| **Channels** | Responsive web app, mobile app (iOS/Android), public API |

### Out of scope (post-MVP)

| Area | Wave |
|------|------|
| Live visa application filing | Wave 2+ |
| Payment / concierge booking | Wave 3+ |
| Full customs / prohibited-goods encyclopedia | Wave 2 (high-level only in MVP) |
| Airline baggage policy per carrier (granular) | Wave 2 |
| Automated embassy appointment booking | Wave 3+ |
| White-label Salesforce embed | Wave 2 (optional) |

---

## 4. Non-functional requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | PII encrypted at rest (AES-256) and in transit (TLS 1.3) |
| NFR-02 | Passport numbers and visa numbers stored tokenized or field-level encrypted |
| NFR-03 | GDPR + CCPA compliant; data residency configurable for enterprise |
| NFR-04 | API authentication: OAuth 2.0 (users), API keys + mTLS (enterprise partners) |
| NFR-05 | Travel-doc API responses cached ≤ 24h; cache invalidated on provider alert |
| NFR-06 | p95 API latency &lt; 3s for checklist generation (excluding LLM streaming) |
| NFR-07 | 99.9% availability for API tier |
| NFR-08 | Full audit log: inputs, API versions, rules applied, response ID |
| NFR-09 | WCAG 2.1 AA for web; mobile accessibility baseline |
| NFR-10 | i18n-ready (English MVP; UI strings externalized) |
| NFR-11 | Disclaimer on every assessment: informational only, not legal advice |
| NFR-12 | Rate limits per tier (free / pro / enterprise) |

---

## 5. Epics & user stories

### Epic E1 — Core data model & identity

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-1.1 | As a **traveler**, I want to create an account and save my nationality and passport details, so I don't re-enter them per trip. | Profile CRUD; passport expiry validation; multi-nationality supported | ⬜ |
| US-1.2 | As an **HR admin**, I want to create an organization and invite employees, so I can manage team travel centrally. | Org + roles (admin, mobility specialist, employee); SSO optional Wave 2 | ⬜ |
| US-1.3 | As a **partner**, I want API keys scoped to my organization, so I can integrate programmatically. | Key issuance, rotation, usage metering | ⬜ |

### Epic E2 — Trip assessment engine

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-2.1 | As a **traveler**, I want to enter a trip (from, to, dates, purpose) and get visa/entry requirements, so I know what to arrange before booking. | Checklist returned with visa type, processing hint, official links | ⬜ |
| US-2.2 | As a **traveler** with a layover, I want transit visa rules for each stop, so I don't get denied boarding. | Multi-segment route parsing; per-segment requirements | ⬜ |
| US-2.3 | As a **traveler** with dual citizenship, I want to compare which passport is best for a route, so I minimize visa burden. | Side-by-side assessment per passport | ⬜ |
| US-2.4 | As the **system**, I must call authoritative travel-doc APIs for facts, so answers are not LLM-hallucinated. | Provider response stored; version + timestamp on output | ⬜ |

### Epic E3 — Conversational agent

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-3.1 | As a **traveler**, I want to ask follow-up questions in natural language, so I can clarify edge cases. | Agent retains trip + profile context; cites sources | ⬜ |
| US-3.2 | As a **traveler**, I want the agent to ask clarifying questions when my trip is incomplete, so I get accurate results. | Missing-field detection; guided intake | ⬜ |
| US-3.3 | As an **HR specialist**, I want to ask "what changed since last month" for an assignment country, so I can proactively notify employees. | Diff against prior assessment snapshot | 🔮 Wave 2 |

### Epic E4 — Checklist & notifications

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-4.1 | As a **traveler**, I want a downloadable checklist with deadlines, so I can track document preparation. | PDF/ICS export; deadline = departure − processing buffer | ⬜ |
| US-4.2 | As a **traveler**, I want email/push reminders before deadlines, so I don't miss visa application windows. | Configurable reminders; opt-in | 🔮 Wave 2 |
| US-4.3 | As an **HR specialist**, I want a dashboard of upcoming trips and compliance status, so I see risk across my workforce. | Org-level trip list; red/amber/green status | ⬜ |

### Epic E5 — APIs & integrations

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-5.1 | As a **partner**, I want `POST /v1/assessments` with traveler + trip JSON, so I receive a structured checklist. | OpenAPI spec; idempotent via `client_request_id` | ⬜ |
| US-5.2 | As a **partner**, I want webhooks when rules change for a saved trip, so my app can notify users. | Webhook registration; signed payloads | 🔮 Wave 2 |
| US-5.3 | As a **mobile app**, I want the same APIs as web, so behavior is consistent across channels. | Single backend; channel-agnostic contracts | ⬜ |

### Epic E6 — Trust, audit & escalation

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-6.1 | As a **user**, I want to see official source links and "rules as of" date on every requirement, so I can verify independently. | Source URL + provider + retrieved_at on each item | ⬜ |
| US-6.2 | As a **compliance officer**, I want an audit log of assessments, so we can reconstruct advice given. | Immutable log; retention policy | ⬜ |
| US-6.3 | As a **traveler** with a complex case, I want to request human advisor review, so I get expert help. | Escalation ticket with full context export | 🔮 Wave 2 |

---

## 6. Commercial data providers (global MVP)

| Provider | Coverage | Use |
|----------|----------|-----|
| **IATA Timatic** (or equivalent) | Global entry/transit/health | Primary air-travel document rules |
| **Sherpa°** or **VisaHQ API** | Global visa requirements | Visa categories, document lists |
| **Government open data** | Per-country supplements | Deep links, processing times where available |

**Requirement (ADR-001):** MVP SHALL integrate at least one IATA-grade travel-document API and one visa-requirements API. LLM layer SHALL NOT be the source of truth for binary visa/entry decisions.

---

## 7. Pricing tiers (product)

| Tier | Audience | Limits |
|------|----------|--------|
| **Free** | Individual travelers | N assessments/month, basic checklist |
| **Pro** | Frequent travelers | Unlimited assessments, saved trips, exports |
| **Team** | HR / mobility (≤50 employees) | Org roster, dashboard, API access |
| **Enterprise** | Large HR, airlines, TMCs | SSO, SLA, custom webhooks, dedicated support |

---

## 8. Success metrics

| Metric | Target (6 months post-launch) |
|--------|-------------------------------|
| Assessment completion rate | &gt; 85% |
| User-reported accuracy (CSAT) | &gt; 4.2 / 5 |
| Time to first checklist | &lt; 60 seconds |
| B2B API uptime | 99.9% |
| Escalation rate (complex cases) | &lt; 10% of assessments |

---

## 9. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Rule changes between assessment and travel | Show as-of date; optional change alerts (Wave 2) |
| API provider outage | Cached responses + degraded mode banner |
| LLM hallucination | Structured output schema; facts only from API layer |
| Legal liability | Prominent disclaimer; no "guaranteed entry" language |
| Global data cost | Usage-based provider billing passed through enterprise tier |
