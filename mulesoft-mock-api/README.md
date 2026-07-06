# CB MuleSoft Mock API

Local mock integration layer for Wave 1 CB onboarding. Implements endpoints from `docs/Mock_API_Catalog.md`.

## Quick start

```bash
cd mulesoft-mock-api
npm install
npm start
```

Base URL: `http://localhost:3001/api/v1`

## Test personas

| Persona | Effect |
|---------|--------|
| `PASS` | STP retail path |
| `REFER` | IDV manual review |
| `FAIL` / `DECLINE` | Rejection |
| `SANCTIONS_HIT` | Screening case |

## OpenAPI

See `openapi.yaml` for endpoint summary.
