# CB — Solution Design (Wave 1)

**Application:** CB (branding)  
**Type:** UK greenfield BaaS bank — Sales Cloud + Service Cloud (no FSC)  
**Wave 1 product:** Current account only (retail + SME business current account)  
**Integration:** MuleSoft primary + Salesforce Platform Events (async internal)  
**Wave 1 externals:** **All mock APIs** (Onfido, Companies House, bureau, screening, core banking)

---

## 1. Wave 1 scope


| In scope                                                          | Out of scope (later waves) |
| ----------------------------------------------------------------- | -------------------------- |
| Retail current account onboarding (UK residents, any nationality) | Savings, credit, mortgages |
| SME business current account (Ltd, LLP, sole trader, partnership) | Wealth, cards UI           |
| Partner institution full onboarding lifecycle                     | Live vendor integrations   |
| Partner customer origination APIs (mocked)                        | Transaction monitoring UI  |
| Experience Cloud (CB direct) + partner APIs                       | FSC migration              |


---

## 2. Architecture

```
Experience Cloud (direct) ──┐
Partner APIs (MuleSoft)  ───┼──► Salesforce CB CRM
                            │         ├── CB_Onboarding_Application__c
                            │         ├── Cases / Action Plans
                            │         └── Platform Events (async)
                            └──► MuleSoft ──► Mock services (Wave 1)
                                      ├── mock-onfido
                                      ├── mock-companies-house
                                      ├── mock-bureau
                                      ├── mock-screening
                                      └── mock-core-banking
```

**Principle:** Salesforce = engagement, orchestration, cases, audit. Decisions and ledger = external (mocked in Wave 1).

---

## 3. Custom objects


| Object                         | Purpose                                  |
| ------------------------------ | ---------------------------------------- |
| `CB_Onboarding_Application__c` | Master onboarding record                 |
| `CB_Fin_Account__c`            | Core account mirror (read-only balances) |
| `CB_Party_Relationship__c`     | UBOs, joint holders, signatories         |
| `CB_Compliance_Document__c`    | KYC/KYB evidence                         |
| `CB_Screening_Result__c`       | Screening summary                        |
| `CB_Customer_Alert__c`         | Agent alerts                             |
| `CB_Partner_Config__c`         | Partner API config                       |
| `CB_Integration_Log__c`        | Event/API audit                          |


---

## 4. Platform Events


| Event                        | Publisher          | Subscriber action                           |
| ---------------------------- | ------------------ | ------------------------------------------- |
| `CB_Onboarding_Submitted__e` | OmniScript / API   | Log; trigger mock orchestration             |
| `CB_IDV_Completed__e`        | MuleSoft mock      | Update application; branch on result        |
| `CB_Screening_Completed__e`  | MuleSoft mock      | Update screening; create Case if hit        |
| `CB_KYC_Decision__e`         | MuleSoft mock      | Approve → request account open              |
| `CB_Account_Opened__e`       | MuleSoft mock      | Create Fin_Account__c; complete application |
| `CB_Partner_Activated__e`    | Partner onboarding | Enable partner config                       |
| `CB_Application_Expired__e`  | Scheduled job      | Close stale applications                    |


**Standard payload fields:** `Correlation_Id__c`, `Application_Id__c`, `Account_Id__c`, `Partner_Id__c`, `Status__c`, `Reason_Code__c`, `Payload_Json__c`

---

## 5. Case record types (Wave 1)


| Record Type                | Queue                 |
| -------------------------- | --------------------- |
| `CB_KYC_CDD`               | CB_KYC_Operations     |
| `CB_Screening`             | CB_Financial_Crime    |
| `CB_KYB_Review`            | CB_KYB_Operations     |
| `CB_Partner_DD`            | CB_Partner_Onboarding |
| `CB_Partner_Certification` | CB_Partner_Onboarding |
| `CB_Ops_Service`           | CB_General_Service    |


---

## 6. Build phases


| Phase  | Deliverable                                              |
| ------ | -------------------------------------------------------- |
| **1a** | Custom objects + Platform Events + Integration Log       |
| **1b** | Retail OmniScript journey (mock IDV/KYC/screening/core)  |
| **1c** | SME OmniScript journey (mock CH/KYB/IDV)                 |
| **1d** | Partner institution onboarding (Case + Partner_Config)   |
| **1e** | MuleSoft mock APIs + webhook → Platform Event publishers |


---

## 7. Defaults applied (Wave 1)

- Non-UK nationality → Medium risk (enhanced CDD path)
- CB performs all CDD (no Reg. 39 reliance in Wave 1)
- Guest + email OTP for retail
- Application expiry: 30 days
- English only
- Shield on compliance fields (when enabled in org)
- Person Accounts enabled in scratch org

---

## 8. UK regulatory alignment

- MLR 2017 Reg. 28 (identity before transacting)
- 2026 amendments: FATF black-list EDD, £ thresholds
- FCA FG25/3: domestic vs foreign PEP differentiation (in mock rules)
- UK GDPR: lawful basis per purpose on consent records

See `docs/Mock_API_Catalog.md` for mock endpoint contracts.