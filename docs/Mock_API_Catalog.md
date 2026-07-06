# CB — Mock API Catalog (Wave 1)

All external integrations are **mocked via MuleSoft** (or local mock service) for Wave 1.  
Salesforce publishes/subscribes via **Platform Events**; MuleSoft mock layer simulates vendor latency and test personas.

---

## Mock service base URL (dev)

```
https://mock.cb.local/api/v1
```

Configure in Salesforce **Named Credential**: `CB_Mock_Integration` (per environment).

---

## 1. Mock Onfido (ID&V)

### `POST /mock/onfido/v1/sessions`

**Request**
```json
{
  "applicationId": "a01...",
  "firstName": "Anna",
  "lastName": "Smith",
  "dateOfBirth": "1985-04-12",
  "testPersona": "PASS"
}
```

**testPersona values:** `PASS` | `REFER` | `FAIL`

**Response**
```json
{
  "sessionId": "mock-idv-001",
  "status": "PENDING",
  "sessionUrl": "https://mock.cb.local/idv/mock-idv-001"
}
```

**Async:** MuleSoft publishes `CB_IDV_Completed__e` to Salesforce Event Bus.

```json
{
  "Correlation_Id__c": "uuid",
  "Application_Id__c": "a01...",
  "Status__c": "PASS",
  "Reason_Code__c": null,
  "Payload_Json__c": "{\"vendorRef\":\"mock-idv-001\",\"matchScore\":98}"
}
```

---

## 2. Mock Companies House (KYB)

### `GET /mock/companies-house/v1/companies/{crn}`

**testCRN personas**

| CRN | Result |
|-----|--------|
| `12345678` | Active Ltd, clean PSC |
| `87654321` | Active, nominee director flag |
| `11111111` | Dissolved → error |

### `GET /mock/companies-house/v1/companies/{crn}/persons-with-significant-control`

Returns PSC list for ownership graph.

---

## 3. Mock Bureau (EV / address)

### `POST /mock/bureau/v1/verify`

**testPersona:** `STRONG_MATCH` | `WEAK_MATCH` | `NO_MATCH`

Weak/no match → Salesforce requests POA upload.

---

## 4. Mock Screening

### `POST /mock/screening/v1/screen`

**testPersona**

| Persona | Result |
|---------|--------|
| `CLEAR` | No hits |
| `PEP_HIT` | PEP potential match |
| `SANCTIONS_HIT` | Sanctions potential match |
| `ADVERSE_MEDIA` | Media hit |

Publishes `CB_Screening_Completed__e`.

---

## 5. Mock KYC / risk engine

### `POST /mock/kyc/v1/prescore`

Returns `riskTier`: LOW | MEDIUM | HIGH

### `POST /mock/kyc/v1/assess`

Returns `decision`: APPROVE | REFER | DECLINE

Publishes `CB_KYC_Decision__e`.

---

## 6. Mock core banking

### `POST /mock/core/v1/customers`

Creates mock `coreCustomerId`.

### `POST /mock/core/v1/accounts/open`

**Request**
```json
{
  "applicationId": "a01...",
  "coreCustomerId": "CUST-001",
  "productCode": "CB_CURR_RETAIL_UK",
  "currency": "GBP"
}
```

**Response**
```json
{
  "coreFinAccountId": "FA-001",
  "sortCode": "04-00-04",
  "accountNumber": "12345678",
  "iban": "GB00MOCK00001234567890"
}
```

Publishes `CB_Account_Opened__e`.

---

## 7. Partner customer API (mock Experience layer)

Mirrors production API shape; routes to same mock services.

| Method | Path |
|--------|------|
| POST | `/v1/onboarding/applications` |
| GET | `/v1/onboarding/applications/{id}` |
| POST | `/v1/onboarding/applications/{id}/submit` |
| POST | `/v1/onboarding/applications/{id}/idv/sessions` |
| POST | `/v1/kyb/entities/verify` |
| POST | `/v1/screening` |

---

## 8. Platform Event → mock orchestration sequence

```
CB_Onboarding_Submitted__e
  → MuleSoft: prescore → IDV session (retail/SME individuals)
  → CB_IDV_Completed__e
  → MuleSoft: bureau + screening + kyc assess
  → CB_Screening_Completed__e + CB_KYC_Decision__e
  → if APPROVE: mock core open account
  → CB_Account_Opened__e
  → Salesforce Flow: Fin_Account__c + complete Application
```

---

## 9. Test data quick reference

| Scenario | Persona / CRN |
|----------|---------------|
| Retail STP | IDV PASS + CLEAR + KYC APPROVE |
| Retail refer | IDV REFER |
| Screening hit | SANCTIONS_HIT or PEP_HIT |
| SME clean | CRN 12345678 + all PASS |
| SME red flag | CRN 87654321 |
| Non-UK national | prescore returns MEDIUM |

---

## 10. Wave 2 cutover

Replace mock base URL with real vendor endpoints in MuleSoft System APIs only — **no Salesforce metadata change** if event contracts stay stable.
