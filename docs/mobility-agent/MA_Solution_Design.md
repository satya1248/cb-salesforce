# Mobility & Air Travel Requirements Agent — Solution Design

**Product codename:** Atlas (suggested)  
**Type:** Greenfield API-first agent platform  
**Channels:** Web (Next.js) · Mobile (React Native) · REST API  
**Geographic scope:** Global (commercial travel-doc APIs)  
**Document version:** 1.0

---

## 1. High-level architecture

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Web App    │  │ Mobile App  │  │ Partner API │
│  (Next.js)  │  │ (RN/Expo)   │  │  clients    │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┼────────────────┘
                        │ HTTPS / OAuth2
                        ▼
              ┌─────────────────────┐
              │   API Gateway       │
              │   (Kong / AWS ALB)  │
              └──────────┬──────────┘
                         │
       ┌─────────────────┼─────────────────┐
       ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Identity     │  │ Trip &       │  │ Assessment   │
│ Service      │  │ Profile Svc  │  │ Service      │
└──────────────┘  └──────────────┘  └──────┬───────┘
                                           │
                         ┌─────────────────┼─────────────────┐
                         ▼                 ▼                 ▼
                  ┌────────────┐   ┌────────────┐   ┌────────────┐
                  │ Agent      │   │ Rules      │   │ Notification│
                  │ Orchestrator│  │ Engine     │   │ Service     │
                  └─────┬──────┘   └─────┬──────┘   └────────────┘
                        │                │
                        ▼                ▼
                  ┌──────────┐    ┌──────────────────┐
                  │ LLM      │    │ Travel-doc APIs  │
                  │ (Claude/ │    │ Timatic · Sherpa │
                  │  GPT)    │    │ Gov link index   │
                  └──────────┘    └──────────────────┘
```

**Principle:** The **Rules Engine** fetches and normalizes facts from travel-doc APIs. The **Agent Orchestrator** uses the LLM only for conversation, explanation, and checklist narration — bound to structured facts.

---

## 2. Technology stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **API** | Python 3.12 + FastAPI | Strong AI/ML ecosystem, async, OpenAPI native |
| **Agent framework** | LangGraph (or Pydantic AI) | Stateful multi-turn flows, tool calling |
| **LLM** | Claude / GPT-4 class | Structured output, long context for explanations |
| **Primary DB** | PostgreSQL 16 | Relational integrity for orgs, trips, audit |
| **Cache** | Redis | Travel-doc API response cache (TTL 1–24h) |
| **Vector DB** | pgvector or Qdrant | Embassy/gov page RAG for supplemental context |
| **Queue** | Redis Streams or SQS | Async assessments, webhooks, notifications |
| **Web** | Next.js 15 (App Router) | SSR, API routes as BFF if needed |
| **Mobile** | React Native (Expo) | Shared TS types with web; single API client |
| **Auth** | Auth0 or Clerk | OAuth social + enterprise SSO path |
| **Infra** | AWS (ECS/Fargate) or Railway for MVP | Managed Postgres, secrets manager |
| **Observability** | OpenTelemetry + Datadog/Sentry | Trace assessment pipeline end-to-end |

---

## 3. Core services

### 3.1 Identity Service
- User registration, login, JWT issuance
- Organization (tenant) management for B2B
- Roles: `traveler`, `org_admin`, `mobility_specialist`, `api_client`
- API key management for partners

### 3.2 Profile Service
- Traveler profiles: nationalities, residency, passports, visas
- Employee profiles linked to org (B2B)
- Field-level encryption for document numbers

### 3.3 Trip Service
- Trip CRUD: segments, dates, purpose, travelers
- Assignment of trips to employees (B2B)
- Trip status: `draft` → `assessed` → `in_preparation` → `ready` → `completed`

### 3.4 Assessment Service
- Orchestrates rules fetch + agent narration
- Produces immutable `Assessment` records (versioned)
- Idempotent via `client_request_id`

### 3.5 Rules Engine
- Adapter pattern for travel-doc providers
- Normalizes provider responses into internal `Requirement` schema
- Applies business rules (passport validity buffer, processing time estimates)
- Never calls LLM

### 3.6 Agent Orchestrator
- Tools: `get_assessment`, `update_trip`, `compare_passports`, `explain_requirement`
- System prompt enforces: cite sources, ask clarifying questions, no invented rules
- Streams responses to web/mobile via SSE or WebSocket

---

## 4. Data model (core entities)

### TravelerProfile
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "nationalities": ["IN"],
  "country_of_residence": "GB",
  "passports": [
    {
      "country_code": "IN",
      "number_token": "tok_xxx",
      "expiry_date": "2028-03-15"
    }
  ],
  "visas": [
    {
      "type": "standard_visitor",
      "issuing_country": "GB",
      "expiry_date": "2027-06-01"
    }
  ]
}
```

### Trip
```json
{
  "id": "uuid",
  "traveler_profile_id": "uuid",
  "organization_id": "uuid | null",
  "purpose": "tourism | business | work | study | relocation",
  "segments": [
    { "origin": "LHR", "destination": "DXB", "departure_date": "2026-08-01" },
    { "origin": "DXB", "destination": "BOM", "departure_date": "2026-08-02" }
  ],
  "return_date": "2026-08-15",
  "status": "draft"
}
```

### Assessment (immutable output)
```json
{
  "id": "uuid",
  "trip_id": "uuid",
  "version": 1,
  "assessed_at": "2026-07-07T14:30:00Z",
  "provider_refs": [
    { "provider": "timatic", "request_id": "...", "retrieved_at": "..." },
    { "provider": "sherpa", "request_id": "...", "retrieved_at": "..." }
  ],
  "overall_status": "action_required | ready | review_recommended",
  "requirements": [
    {
      "category": "visa | passport | transit | health | customs",
      "segment_index": 0,
      "title": "UAE tourist visa required",
      "status": "required",
      "detail": "Indian passport holders require...",
      "official_url": "https://...",
      "deadline_date": "2026-07-25",
      "confidence": "high",
      "source": "sherpa"
    }
  ],
  "disclaimer": "Informational only. Not legal advice.",
  "narrative": "LLM-generated human-readable summary bound to requirements[]"
}
```

---

## 5. Rules Engine — provider adapters

```python
# Conceptual interface
class TravelDocProvider(Protocol):
    async def assess_segment(
        self,
        traveler: TravelerContext,
        segment: TripSegment,
    ) -> list[RawRequirement]: ...

class TimaticAdapter(TravelDocProvider): ...
class SherpaAdapter(TravelDocProvider): ...
```

**Normalization pipeline**

1. For each trip segment × traveler passport option → call providers (parallel)
2. Merge + deduplicate requirements
3. Apply post-rules (passport 6-month validity, processing buffer)
4. Persist raw provider payloads for audit
5. Pass structured `requirements[]` to Agent for narrative only

**Caching key:** `hash(nationality, residency, origin, destination, purpose, date_bucket)`

---

## 6. Agent design

### 6.1 Agent modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Guided intake** | New trip, missing fields | Ask minimal questions to complete assessment |
| **Assessment explain** | Post-rules-engine | Explain checklist, answer follow-ups |
| **Passport compare** | Multi-nationality user | Run engine twice, summarize tradeoffs |
| **HR bulk query** | B2B dashboard | "Which employees need visas for Dubai offsite?" |

### 6.2 Tool definitions (LLM tools)

| Tool | Input | Output |
|------|-------|--------|
| `run_assessment` | trip_id | Assessment JSON |
| `get_requirement_detail` | requirement_id | Expanded explanation + official links |
| `update_trip_field` | trip_id, field, value | Updated trip |
| `list_org_trips` | org_id, filters | Trip summaries (B2B) |

### 6.3 Guardrails

- JSON schema validation on all structured outputs
- LLM system prompt: *"Never state a visa is or isn't required unless it appears in requirements[] from run_assessment"*
- Block "guaranteed entry" phrasing (output filter)
- Log prompt + tool calls per session for audit

---

## 7. API design (v1)

Base URL: `https://api.atlas-mobility.example/v1`

### Authentication
- `Authorization: Bearer <jwt>` — user sessions
- `X-Api-Key: <key>` — partner integrations

### Core endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/profiles` | Create traveler profile |
| GET | `/profiles/{id}` | Get profile |
| POST | `/trips` | Create trip |
| POST | `/trips/{id}/assess` | Run assessment (sync or async) |
| GET | `/assessments/{id}` | Get assessment result |
| POST | `/agent/sessions` | Start conversational session |
| POST | `/agent/sessions/{id}/messages` | Send message (SSE stream) |
| POST | `/organizations` | Create B2B org |
| POST | `/organizations/{id}/employees` | Add employee profile |
| GET | `/organizations/{id}/trips` | HR dashboard data |

### Example: assess trip

**Request**
```http
POST /v1/trips/{trip_id}/assess
Authorization: Bearer eyJ...
Content-Type: application/json

{
  "client_request_id": "550e8400-e29b-41d4-a716-446655440000",
  "options": {
    "compare_all_passports": true,
    "include_health": true
  }
}
```

**Response**
```http
HTTP/1.1 200 OK

{
  "assessment_id": "...",
  "overall_status": "action_required",
  "requirements": [ ... ],
  "narrative": "For your trip from London to Mumbai via Dubai...",
  "disclaimer": "...",
  "assessed_at": "2026-07-07T14:30:00Z"
}
```

OpenAPI 3.1 spec SHALL be published at `/v1/openapi.json`.

---

## 8. Web & mobile clients

### Web (Next.js)
- `/` — marketing + quick assess (guest mode, limited)
- `/app/trips` — trip list
- `/app/trips/new` — guided intake wizard
- `/app/trips/[id]` — checklist + chat panel
- `/app/org` — HR dashboard (B2B)
- `/developers` — API docs

### Mobile (React Native)
- Same screens; offline cache of last assessment
- Push notifications (Wave 2) via FCM/APNs
- Share checklist as PDF

**Shared:** TypeScript API client generated from OpenAPI (`openapi-typescript-codegen`).

---

## 9. B2B / HR flows

```
HR Admin creates org
    → Invites employees (email / SSO Wave 2)
    → Employee completes profile (or HR enters on behalf with consent)
    → HR creates assignment trip (relocation) or employee creates business trip
    → Assessment runs → status on dashboard
    → Red items block "travel ready" flag (policy configurable)
    → Export CSV/PDF for compliance records
```

**Policy engine (Wave 2):** Org rules like "work trips to sanctioned countries require manual approval."

---

## 10. Security & compliance

| Area | Implementation |
|------|----------------|
| **Encryption** | AES-256 at rest (RDS); TLS 1.3 in transit |
| **PII** | Passport numbers tokenized (Vault/KMS); minimal retention |
| **Audit** | Append-only `audit_events` table; 7-year retention option for enterprise |
| **GDPR** | Export/delete endpoints; lawful basis = contract + legitimate interest |
| **Disclaimer** | Required field on every Assessment; shown before first checklist view |
| **Pen test** | Before public launch |

---

## 11. Deployment topology (MVP)

```
AWS Region: eu-west-2 (primary) + us-east-1 (DR read replica)

├── Route 53
├── ALB → ECS Fargate (api, agent-worker)
├── RDS PostgreSQL (Multi-AZ)
├── ElastiCache Redis
├── Secrets Manager (API keys: Timatic, Sherpa, LLM)
├── S3 (PDF exports, audit archive)
└── CloudFront → Vercel (web) or S3 static
```

Mobile apps point to same API; no channel-specific backends.

---

## 12. Build phases

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **0 — Foundation** | 2 weeks | Monorepo, CI/CD, Auth, Postgres schema, OpenAPI skeleton |
| **1 — Rules Engine** | 3 weeks | Timatic + Sherpa adapters, Assessment service, caching |
| **2 — Agent** | 2 weeks | LangGraph orchestrator, guided intake, explain mode |
| **3 — API v1** | 2 weeks | Full REST surface, API keys, rate limits |
| **4 — Web MVP** | 3 weeks | Trip wizard, checklist UI, chat panel |
| **5 — Mobile MVP** | 3 weeks | RN app, core flows (can parallel with Phase 4) |
| **6 — B2B** | 2 weeks | Org model, HR dashboard, employee roster |
| **7 — Hardening** | 2 weeks | Load test, security review, observability, beta launch |

**Total:** ~17 weeks to beta (Phases 4+5 parallel → ~14 weeks elapsed).

---

## 13. Monorepo structure (proposed)

```
atlas-mobility/
├── apps/
│   ├── api/                 # FastAPI services
│   ├── agent/               # LangGraph agent worker
│   ├── web/                 # Next.js
│   └── mobile/              # Expo / React Native
├── packages/
│   ├── shared-types/        # Trip, Assessment, Profile types
│   ├── api-client/          # Generated TS client
│   └── rules-engine/        # Provider adapters (Python)
├── infra/                   # Terraform / CDK
├── docs/
│   ├── openapi.yaml
│   └── runbooks/
└── docker-compose.yml       # Local dev
```

---

## 14. Cost drivers (global MVP)

| Item | Estimate (monthly at beta) |
|------|------------------------------|
| Timatic / IATA API | $2k–10k+ (volume-based) |
| Sherpa / visa API | $1k–5k+ |
| LLM inference | $500–3k |
| AWS infra | $500–2k |
| Auth0 / Clerk | $0–500 |

Enterprise pricing must cover per-assessment API costs.

---

## 15. Open decisions

| ID | Decision | Options | Recommendation |
|----|----------|---------|----------------|
| ADR-002 | LLM provider | Anthropic vs OpenAI vs multi | Anthropic primary (structured output quality) |
| ADR-003 | Mobile framework | Expo vs Flutter | Expo (shared TS with web) |
| ADR-004 | Auth provider | Clerk vs Auth0 | Clerk for speed; Auth0 if enterprise SSO day 1 |
| ADR-005 | Repo location | New repo vs subfolder in cb-salesforce | **New repo** — unrelated to CB banking domain |

---

## 16. Next implementation step

Scaffold Phase 0 in a new repository:

1. `docker-compose` with Postgres + Redis
2. FastAPI app with `/health`, `/v1/profiles`, `/v1/trips`
3. Mock `TimaticAdapter` returning fixture data (global routes)
4. Minimal LangGraph agent with `run_assessment` tool
5. OpenAPI spec + generated TS client

This unblocks web/mobile teams immediately while commercial API contracts are finalized.
