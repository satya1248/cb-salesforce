# CB — UK Greenfield BaaS Banking CRM

Salesforce CRM for **CB**, a UK greenfield Banking-as-a-Service institution.

## Wave 1 scope

- **Product:** Current account only (retail + SME business current account)
- **Customers:** CB direct (Experience Cloud) + partner-originated (APIs)
- **Partner:** Full partner institution onboarding lifecycle
- **Platform:** Sales Cloud + Service Cloud + custom objects (**no FSC**)
- **Integration:** MuleSoft (primary) + Platform Events (async internal)
- **Externals:** **All mock APIs** in Wave 1

## Documentation

| Document | Description |
|----------|-------------|
| [docs/CB_Solution_Design.md](docs/CB_Solution_Design.md) | Architecture, objects, events, phases |
| [docs/Mock_API_Catalog.md](docs/Mock_API_Catalog.md) | Mock endpoint contracts & test personas |

## Metadata created (Phase 1a)

### Custom objects
- `CB_Onboarding_Application__c`
- `CB_Fin_Account__c`
- `CB_Party_Relationship__c`
- `CB_Compliance_Document__c`
- `CB_Screening_Result__c`
- `CB_Customer_Alert__c`
- `CB_Partner_Config__c`
- `CB_Integration_Log__c`

### Account fields
- `CB_Customer_Status__c`, `CB_KYC_Status__c`, `CB_IDV_Status__c`, `CB_Risk_Rating__c`, `CB_Core_Customer_Id__c`, `CB_Is_Partner__c`

### Platform Events
- `CB_Onboarding_Submitted__e`
- `CB_IDV_Completed__e`
- `CB_Screening_Completed__e`
- `CB_KYC_Decision__e`
- `CB_Account_Opened__e`
- `CB_Partner_Activated__e`
- `CB_Application_Expired__e`

## Quick start

### Prerequisites
- Salesforce CLI (`sf`)
- Dev Hub authenticated

### Create scratch org
```bash
sf org create scratch -f config/project-scratch-def.json -a cb-dev -d 30
sf org open -o cb-dev
```

### Deploy metadata
```bash
sf project deploy start -o cb-dev
```

## Build phases

| Phase | Status |
|-------|--------|
| 1a Core data model + Platform Events | **Done** |
| 1b Retail OmniScript journey | Planned |
| 1c SME OmniScript journey | Planned |
| 1d Partner institution onboarding | Planned |
| 1e MuleSoft mock APIs | Planned |

## Mock API strategy (Wave 1)

All vendor and core-banking calls go to **MuleSoft mock services**.  
Salesforce never calls vendors directly. Results return via **Platform Events**.

See `docs/Mock_API_Catalog.md` for test personas.
