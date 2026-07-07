# CB — Production Requirements (Waves, Epics, Features, User Stories)

**Product:** CB — UK greenfield Banking-as-a-Service (BaaS) bank  
**Platform:** Salesforce Sales Cloud + Service Cloud (Wave 1–2); FSC evaluation in Wave 3  
**Integration:** MuleSoft (System / Process / Experience APIs) + Salesforce Platform Events  
**Document version:** 1.0  
**Status key:** ✅ Built (Wave 1 demo) · 🟡 Partial · ⬜ Not started · 🔮 Future wave

---

## 1. Vision & goals

CB needs a CRM-led onboarding and servicing hub that:

- Onboards **retail** and **SME** current account customers (UK, any nationality)
- Onboards **partner institutions** and supports **partner-originated** customer applications via API
- Orchestrates IDV, KYB, bureau, screening, KYC, and core account opening through MuleSoft
- Routes exceptions to the right operational queues (KYC, FinCrime, KYB, Partner DD)
- Maintains a full audit trail for regulators (MLR 2017, FCA conduct, UK GDPR)

**North-star outcome (production):** A customer or partner can complete onboarding digitally with straight-through processing where risk allows, and analysts can resolve referrals without breaking journey continuity or audit.

---

## 2. Personas

| Persona | Description |
|---------|-------------|
| **Retail applicant** | Individual applying for a personal current account (CB direct or partner) |
| **SME applicant** | Business user / director applying for a business current account |
| **Partner operations user** | Staff at a BaaS partner institution |
| **KYC/CDD analyst** | Reviews IDV refer, KYC refer, POA, enhanced CDD |
| **KYB analyst** | Reviews Companies House anomalies, PSC, nominee flags |
| **FinCrime / MLRO analyst** | Reviews screening hits (PEP, sanctions, adverse media) |
| **Partner onboarding manager** | Onboards partner institutions, issues API credentials |
| **Service agent** | General customer service (read-only onboarding context) |
| **Platform admin** | Configures integration settings, permission sets, environments |
| **Integration service** | MuleSoft / middleware calling Salesforce ingress and subscribing to events |

---

## 3. Architecture decision: Custom model vs FSC (Wave 0)

| Dimension | **CB custom model (current)** | **Salesforce FSC origination** |
|-----------|------------------------------|--------------------------------|
| **Application record** | `CB_Onboarding_Application__c` | `ApplicationForm`, `ApplicationFormProduct` |
| **Party model** | `Account` + `CB_Party_Relationship__c` | `PartyProfile`, `IdentityDocument`, `PartyScreeningSummary` |
| **Cases** | Standard `Case` with CB record types | FSC Action Plans, `Complaint`, integrated assessment |
| **Product catalog** | `Product_Code__c` picklist | `Product2` + FSC product catalog |
| **Best for** | Greenfield BaaS, full control, no FSC licence initially | Banks already on FSC, rich party/KYC datamodel out of the box |
| **Integration** | Platform Events + custom fields | FSC integration APIs + Data Cloud options |
| **CB decision** | **Wave 1–2:** custom model ✅ | **Wave 3:** evaluate migration if product portfolio grows |

**Requirement (ADR-001):** Wave 1–2 SHALL use the custom onboarding data model. FSC fit-gap and migration path SHALL be assessed before Wave 3 product expansion.

---

## 4. Non-functional requirements (all waves)

| ID | Requirement |
|----|-------------|
| NFR-01 | All PII and financial identifiers encrypted at rest (Shield Platform Encryption for production) |
| NFR-02 | Integration calls authenticated (Named Credentials, OAuth, API keys for partners) |
| NFR-03 | Correlation ID on every application and integration log entry |
| NFR-04 | Idempotent event processing (duplicate platform events must not double-open accounts) |
| NFR-05 | Application expiry: 30 days inactivity → `Rejected` / expired reason code |
| NFR-06 | English UI Wave 1–2; Welsh/localisation Wave 3+ |
| NFR-07 | Availability: 99.9% Salesforce; MuleSoft HA per enterprise standard |
| NFR-08 | Audit: `CB_Integration_Log__c` retains inbound/outbound payloads (retention policy TBD) |
| NFR-09 | Role-based access via permission sets / permission set groups |
| NFR-10 | No direct Salesforce → vendor callouts (all via MuleSoft) |

---

# WAVE 1 — Current account onboarding MVP (internal + demo)

**Goal:** End-to-end onboarding for retail, SME, and partner institution with **mock** integrations.  
**Timeline:** Foundation for production; not production-ready without Wave 2.

| Epic | Status |
|------|--------|
| E1 Data model & security | ✅ |
| E2 Retail onboarding | 🟡 |
| E3 SME onboarding | 🟡 |
| E4 Partner institution onboarding | 🟡 |
| E5 Partner customer API | 🟡 |
| E6 Case management & analyst workflows | 🟡 |
| E7 Integration & async orchestration | ✅ |
| E8 Internal operations UX | ✅ |
| E9 Application lifecycle & scheduling | ✅ |

---

## Epic E1 — Data model & security foundation

### Feature F1.1 — Core custom objects ✅

| Object | Purpose |
|--------|---------|
| `CB_Onboarding_Application__c` | Master onboarding journey |
| `CB_Fin_Account__c` | Core account mirror |
| `CB_Party_Relationship__c` | PSC, directors, signatories |
| `CB_Compliance_Document__c` | POA, KYC evidence |
| `CB_Screening_Result__c` | Screening summary |
| `CB_Customer_Alert__c` | Agent alerts |
| `CB_Partner_Config__c` | Partner API configuration |
| `CB_Integration_Log__c` | API / event audit |

**User stories**

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-1.1.1 | As a **platform admin**, I want onboarding applications stored in a dedicated object, so that journey state is separate from Cases and Leads. | Application has status, product, channel, correlation ID, risk fields; links to Account | ✅ |
| US-1.1.2 | As a **compliance officer**, I want integration logs linked to applications, so that I can reconstruct decision trails. | Log records capture direction, HTTP status, correlation ID, payload | ✅ |
| US-1.1.3 | As an **operations user**, I want fin accounts created when core opens an account, so that agents see sort code / account number in CRM. | `CB_Fin_Account__c` created on `CB_Account_Opened__e` | ✅ |

### Feature F1.2 — Account extensions ✅

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-1.2.1 | As a **KYC analyst**, I want customer KYC/IDV status on Account, so that I see holistic customer state. | `CB_KYC_Status__c`, `CB_IDV_Status__c`, `CB_Customer_Status__c`, `CB_Risk_Rating__c` populated by handlers | ✅ |

### Feature F1.3 — Platform events ✅

Events: `CB_Onboarding_Submitted__e`, `CB_IDV_Completed__e`, `CB_Screening_Completed__e`, `CB_KYC_Decision__e`, `CB_Account_Opened__e`, `CB_Partner_Activated__e`, `CB_Application_Expired__e`.

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-1.3.1 | As **MuleSoft**, I want to publish completion events to Salesforce, so that application state updates asynchronously. | REST ingress `POST /cb/v1/events/{eventType}` with shared secret; triggers update handlers | ✅ |
| US-1.3.2 | As **Salesforce**, I want to publish `CB_Onboarding_Submitted__e` on application submit, so that orchestration starts without blocking the UI. | Event published; queueable / MuleSoft orchestration enqueued | ✅ |

### Feature F1.4 — Security model 🟡

Permission sets: `CB_Admin`, `CB_KYC_Analyst`, `CB_KYB_Analyst`, `CB_FinCrime_Analyst`, `CB_MLRO`, `CB_Partner_Manager`, `CB_Service_Agent`.  
Permission set groups: `CB_Platform_Admin`, `CB_Operations`, `CB_Partner_Onboarding`.

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-1.4.1 | As a **security admin**, I want role-based FLS on compliance fields, so that only authorised roles edit risk decisions. | FLS on application, screening, integration log fields per perm set | ✅ |
| US-1.4.2 | As a **security admin**, I want field-level encryption on NI number, DOB, and document references in production. | Shield encryption policies applied per data classification | ⬜ |

---

## Epic E2 — Retail current account onboarding

### Feature F2.1 — Retail application capture 🟡

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-2.1.1 | As a **retail applicant**, I want to enter personal details (name, email, phone, DOB, address, nationality), so that CB can perform IDV and pre-score. | Screen flow captures fields; Person Account created | ✅ |
| US-2.1.2 | As a **retail applicant**, I want to see what happens after I submit, so that I understand wait times and outcomes. | Result screen shows prescore summary, expected outcome, application ID | ✅ |
| US-2.1.3 | As a **retail applicant** on Experience Cloud, I want to complete onboarding on mobile without an agent. | Responsive Experience Cloud site with OTP login | ⬜ Wave 2 |
| US-2.1.4 | As a **retail applicant**, I want to upload POA when bureau match is weak. | Document upload component; `CB_Compliance_Document__c` POA type; analyst notification | 🟡 POA record created; upload UI ⬜ |

### Feature F2.2 — Retail integration journey ✅ (mock)

Sequence: pre-score → IDV → bureau → screening → KYC assess → core account open.

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-2.2.1 | As **CB**, I want UK nationals pre-scored as Low/Simplified CDD and non-UK as Medium/Standard, so that risk tier drives the journey. | `CB_PrescoreService` sets `Risk_Tier__c`, `CDD_Level__c` | ✅ |
| US-2.2.2 | As **CB**, I want IDV Pass to continue STP and IDV Refer/Fail to pause or reject. | Handlers update status; refer creates `CB_KYC_CDD` case | ✅ |
| US-2.2.3 | As **CB**, I want sanctions/PEP hits to create screening cases without auto-rejecting until reviewed. | `CB_Screening` case; application `Under_Review` | ✅ |
| US-2.2.4 | As **CB**, I want KYC Approve to trigger core account opening. | `CB_Account_Opened__e` → fin account + application `Completed` | ✅ |

### Feature F2.3 — Retail demo / internal UX ✅

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-2.3.1 | As a **demo presenter**, I want a scenario guide on the onboarding tab, so that I can explain personas and outcomes. | `cbOnboardingGuide` with journey, prescore rules, scenario table | ✅ |
| US-2.3.2 | As a **demo presenter**, I want to pick demo personas (PASS, SANCTIONS_HIT, etc.) without typing codes. | Flow dropdown scenarios | ✅ |

---

## Epic E3 — SME business current account onboarding

### Feature F3.1 — SME application capture 🟡

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-3.1.1 | As an **SME applicant**, I want to enter company details and CRN, so that CB can verify the business at Companies House. | Business Account + application with `CRN__c` | ✅ |
| US-3.1.2 | As an **SME applicant**, I want to provide primary director details, so that individual KYC can run after KYB. | Director Person Account created; nationality on application | ✅ |
| US-3.1.3 | As an **SME applicant**, I want to onboard as sole trader, LLP, or partnership. | Entity type selection and journey variants | ⬜ Wave 2 (currently `Limited_Company` only) |

### Feature F3.2 — KYB integration ✅ (mock)

| CRN | Outcome |
|-----|---------|
| `12345678` | Clean — continue director checks |
| `87654321` | Nominee flag — `CB_KYB_Review` case |
| `11111111` | Dissolved — rejected |

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-3.2.1 | As **CB**, I want dissolved companies rejected before individual checks. | Application `Rejected`, reason `COMPANY_DISSOLVED` | ✅ |
| US-3.2.2 | As a **KYB analyst**, I want a case when nominee director is flagged. | Case created; application `Under_Review` | ✅ |
| US-3.2.3 | As **CB**, I want PSC data stored as party relationships. | `CB_Party_Relationship__c` on clean CRN | ✅ |

---

## Epic E4 — Partner institution onboarding

### Feature F4.1 — Partner lifecycle 🟡

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-4.1.1 | As a **partner onboarding manager**, I want to register a partner institution with due diligence. | `CB_Partner_Onboarding` flow; `CB_Partner_Config__c`; DD case | ✅ |
| US-4.1.2 | As a **partner onboarding manager**, I want PASS persona to activate partner and issue API credentials. | Config `Active`; API secret generated | ✅ |
| US-4.1.3 | As a **partner onboarding manager**, I want REFER persona to keep partner in onboarding with open DD case. | Config not active; case open | ✅ |
| US-4.1.4 | As **CB**, I want partner certification and periodic re-certification cases. | `CB_Partner_Certification` record type and workflow | ⬜ Wave 2 |

---

## Epic E5 — Partner customer origination API

### Feature F5.1 — Partner REST API 🟡

Base: `/services/apexrest/cb/v1/onboarding/*`  
Auth: `X-Partner-Id` + `X-API-Key`

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-5.1.1 | As a **partner system**, I want to create a draft onboarding application via API. | `POST /applications` returns application ID | ✅ |
| US-5.1.2 | As a **partner system**, I want to submit an application to start orchestration. | `POST /applications/{id}/submit` publishes submitted event | ✅ |
| US-5.1.3 | As a **partner system**, I want to poll application status. | `GET /applications/{id}` returns status and correlation ID | ✅ |
| US-5.1.4 | As a **partner system**, I want IDV session creation for embedded partner UX. | `POST /applications/{id}/idv/sessions` | 🟡 Mock shape only |
| US-5.1.5 | As **CB security**, I want API rate limiting and IP allowlisting per partner. | MuleSoft policies + partner config | ⬜ Wave 2 |

---

## Epic E6 — Case management & analyst workflows

### Feature F6.1 — Case record types & queues ✅

| Record type | Queue |
|-------------|-------|
| `CB_KYC_CDD` | CB_KYC_Operations |
| `CB_Screening` | CB_Financial_Crime |
| `CB_KYB_Review` | CB_KYB_Operations |
| `CB_Partner_DD` | CB_Partner_Onboarding |
| `CB_Partner_Certification` | CB_Partner_Onboarding |
| `CB_Ops_Service` | CB_General_Service |

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-6.1.1 | As a **KYC analyst**, I want cases linked to applications and accounts. | `CB_Onboarding_Application__c` on Case | ✅ |
| US-6.1.2 | As a **FinCrime analyst**, I want to resolve a screening case and resume the application. | `CB_Resolve_Onboarding_Case` flow; `CB_ResolveCaseActions` | ✅ |
| US-6.1.3 | As an **MLRO**, I want a queue view of open screening cases with risk tier visible. | List views / reports on Case + Application risk | 🟡 |
| US-6.1.4 | As a **KYC analyst**, I want Action Plans for enhanced CDD steps. | Salesforce Action Plans on Case | ⬜ Wave 2 |

### Feature F6.2 — Analyst console ⬜

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-6.2.1 | As an **analyst**, I want a unified onboarding workbench showing application, documents, screening, and integration log. | Lightning app page with related lists and timeline | 🟡 Record page exists; workbench ⬜ |
| US-6.2.2 | As an **MLRO**, I want to record escalation decisions with immutable audit. | MLRO decision fields + field history / Shield | ⬜ Wave 2 |

---

## Epic E7 — Integration & async orchestration

### Feature F7.1 — MuleSoft orchestration ✅ (mock)

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-7.1.1 | As **CB**, I want Salesforce to call MuleSoft on application submit without blocking the user. | Queueable + Named Credential; 202 async pattern | ✅ |
| US-7.1.2 | As **CB**, I want fallback in-org mock orchestration when MuleSoft is unreachable. | `CB_MockOrchestrator` fallback | ✅ |
| US-7.1.3 | As **CB**, I want integration settings configurable per environment. | `CB_Integration_Settings__c` hierarchy custom setting | ✅ |

### Feature F7.2 — Event contracts ✅

See `docs/Mock_API_Catalog.md` for full contracts.

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-7.2.1 | As **integration lead**, I want stable event schemas so Wave 2 vendor swap does not require Salesforce changes. | Event fields documented; versioned payloads in `Payload_Json__c` | ✅ |

---

## Epic E8 — Internal operations UX

### Feature F8.1 — CB Onboarding app ✅

Tabs: Retail Onboarding, SME Onboarding, Partner Onboarding, Applications, Fin Accounts, Cases, Screening Results, Integration Logs, Partner Config.

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-8.1.1 | As an **internal user**, I want one app for onboarding demos and operations. | `CB_Onboarding` Lightning app deployed | ✅ |
| US-8.1.2 | As an **internal user**, I want list views showing all applications, not only recently viewed. | `All_Applications` list view | ✅ |

---

## Epic E9 — Application lifecycle

| ID | Story | Acceptance criteria | Status |
|----|-------|---------------------|--------|
| US-9.1.1 | As **CB**, I want stale applications expired after 30 days. | `CB_ApplicationExpiryScheduler` + batch | ✅ |
| US-9.1.2 | As a **customer**, I want to resume a saved application within the expiry window. | Save & resume (Experience Cloud / draft status) | ⬜ Wave 2 |

---

# WAVE 2 — Production readiness (live integrations & customer channels)

**Goal:** Replace mocks with real vendors; launch customer-facing channels; meet operational SLAs.

| Epic | Summary |
|------|---------|
| E10 Experience Cloud — CB direct | Customer-facing retail/SME onboarding |
| E11 Live vendor integrations | Onfido, Companies House, bureau, screening, KYC engine, core banking |
| E12 Operational excellence | SLAs, monitoring, runbooks, alerting |
| E13 Security & compliance hardening | Shield, consent, SAR, retention |
| E14 Document & evidence management | POA upload, virus scan, retention |
| E15 Partner production API | Rate limits, sandbox, certification, webhooks |

---

## Epic E10 — Experience Cloud (CB direct)

### Feature F10.1 — Retail digital onboarding ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-10.1.1 | As a **retail applicant**, I want to register with email OTP, so that I can start onboarding without a branch visit. | Experience Cloud site; OTP verification; guest → authenticated |
| US-10.1.2 | As a **retail applicant**, I want embedded Onfido IDV in the journey, so that I complete selfie/document check on my phone. | Onfido SDK / redirect; real session status polling |
| US-10.1.3 | As a **retail applicant**, I want status updates by email/SMS when my application is referred or completed. | Marketing Cloud or Service notifications on status change |

### Feature F10.2 — SME digital onboarding ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-10.2.1 | As an **SME applicant**, I want to search Companies House by company name, so that I don't mistype CRN. | Typeahead CH search API |
| US-10.2.2 | As an **SME applicant**, I want to add multiple directors/UBOs, so that KYB captures full ownership. | Multi-party capture UI + `CB_Party_Relationship__c` |

---

## Epic E11 — Live vendor integrations

### Feature F11.1 — Replace mock layer ⬜

| Integration | Production requirement |
|-------------|------------------------|
| Onfido | Live IDV sessions, webhook → `CB_IDV_Completed__e` |
| Companies House | Live CRN lookup + PSC |
| Credit bureau | Live electoral roll / address match |
| Screening (e.g. Refinitiv / ComplyAdvantage) | Live PEP/sanctions/adverse media |
| KYC / risk engine | Live prescore + assess |
| Core banking | Live customer + account APIs |

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-11.1.1 | As **integration lead**, I want to swap mock base URL for production System APIs in MuleSoft only. | No Salesforce metadata change for event contracts |
| US-11.1.2 | As **CB**, I want vendor timeouts and circuit breakers, so that partial failures don't corrupt application state. | MuleSoft retry policies; compensating transactions documented |

---

## Epic E12 — Operational excellence ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-12.1.1 | As **operations manager**, I want SLA milestones on onboarding cases. | Entitlements + milestones per record type |
| US-12.1.2 | As **SRE**, I want Datadog/Splunk alerts on integration failure rates. | Log streaming from MuleSoft + Salesforce Event Monitoring |
| US-12.1.3 | As **product owner**, I want onboarding funnel dashboards. | Reports: submitted → completed conversion, refer rates, TAT |

---

## Epic E13 — Security & compliance hardening ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-13.1.1 | As **DPO**, I want consent records with lawful basis per processing purpose. | Consent object / CB consent fields on Application |
| US-13.1.2 | As **compliance**, I want FATF high-risk country list to force Enhanced CDD. | Country risk reference data in prescore |
| US-13.1.3 | As **security**, I want secrets rotated and not stored in custom fields unencrypted. | API secrets in vault; masked in UI |

---

## Epic E14 — Document & evidence management ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-14.1.1 | As a **customer**, I want to upload POA securely when requested. | File upload to encrypted storage; linked to `CB_Compliance_Document__c` |
| US-14.1.2 | As a **KYC analyst**, I want to approve/reject documents with reason codes. | Document status workflow |

---

## Epic E15 — Partner production API ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-15.1.1 | As a **partner**, I want a sandbox environment with test personas. | Separate NC + partner config per env |
| US-15.1.2 | As a **partner**, I want webhooks for application status changes. | MuleSoft Experience API callbacks |
| US-15.1.3 | As **CB**, I want partner certification before production keys. | Certification case + checklist |

---

# WAVE 3 — Scale, products & platform evolution

**Goal:** Additional products, advanced compliance, optional FSC alignment.

| Epic | Summary |
|------|---------|
| E16 Additional products | Savings, cards (servicing), credit (referral) |
| E17 Transaction monitoring handoff | Alerts to FinCrime (external TM platform) |
| E18 FSC fit-gap & migration | Evaluate `ApplicationForm` vs custom model |
| E19 Multi-language & accessibility | Welsh, WCAG 2.1 AA |
| E20 Reg 39 reliance | Reliance on partner CDD where approved |

---

## Epic E18 — FSC fit-gap (custom vs FSC deep dive)

### When FSC adds value

- Standard **party** and **due diligence** objects reduce custom build for complex ownership
- **Action Plans** and **Business Milestones** for structured CDD
- **Discovery Framework** for assessments
- **Integration** with Data Cloud / Customer 360 for enterprise analytics

### Migration features (if pursued) ⬜

| ID | Story | Acceptance criteria |
|----|-------|---------------------|
| US-18.1.1 | As **enterprise architect**, I want a mapping document from `CB_Onboarding_Application__c` to FSC `ApplicationForm`. | Signed fit-gap and migration strategy |
| US-18.2.1 | As **CB**, I want dual-write period during migration. | Parallel run with reconciliation reports |

---

# Appendix A — Application status reference

| Status | Meaning |
|--------|---------|
| `Draft` | Created, not submitted |
| `In_Progress` | Submitted; orchestration running |
| `IDV_Pending` | Awaiting identity verification |
| `KYC_Pending` | IDV passed; KYC in flight |
| `Under_Review` | Manual case open |
| `Core_Processing` | KYC approved; core account opening |
| `Completed` | Account opened |
| `Rejected` | Terminal failure |

---

# Appendix B — Test personas (retail / integration)

| Persona | Typical outcome |
|---------|-----------------|
| `PASS` | STP completed |
| `REFER` / `IDV_REFER` | IDV case |
| `FAIL` / `IDV_FAIL` | Rejected |
| `WEAK_MATCH` / `NO_MATCH` | POA + KYC case |
| `SANCTIONS_HIT` / `PEP_HIT` / `ADVERSE_MEDIA` | Screening case |
| `KYC_REFER` | KYC case |
| `KYC_DECLINE` | Rejected |

---

# Appendix C — Traceability matrix (epic → primary artefacts)

| Epic | Flows | Apex / REST | Objects | Events |
|------|-------|-------------|---------|--------|
| E2 Retail | `CB_Retail_Onboarding` | `CB_RetailOnboardingActions` | Application, Account | Submitted, IDV, Screening, KYC, Account Opened |
| E3 SME | `CB_SME_Onboarding` | `CB_SMEOnboardingActions` | Application, Party | Same + KYB via CH mock |
| E4 Partner | `CB_Partner_Onboarding` | `CB_PartnerOnboardingActions` | Partner Config, Case | Partner Activated |
| E5 Partner API | — | `CB_PartnerCustomerRest` | Application | Submitted |
| E6 Cases | `CB_Resolve_Onboarding_Case` | `CB_CaseFactory`, `CB_ResolveCaseActions` | Case | — |
| E7 Integration | — | `CB_IntegrationOrchestrationQueueable`, `CB_EventIngressRest` | Integration Log, Settings | All |

---

# Appendix D — Document maintenance

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-07 | CB programme | Initial production requirements from Wave 1 build + target state |

**Related documents:** [CB_Solution_Design.md](./CB_Solution_Design.md) · [Mock_API_Catalog.md](./Mock_API_Catalog.md)
