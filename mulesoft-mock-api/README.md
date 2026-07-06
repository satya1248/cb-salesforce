# CB MuleSoft Mock API

Local mock integration layer for Wave 1 CB onboarding. Implements endpoints from `docs/Mock_API_Catalog.md`.

## Quick start

```bash
cd mulesoft-mock-api
npm install
npm start
```

Base URL: `http://localhost:3001/api/v1`

## Integration-style testing (no MuleSoft)

This repo includes a Salesforce REST ingress at:

- `POST /services/apexrest/cb/v1/events/{eventType}`

To make the mock API publish callbacks into Salesforce directly:

1. Get scratch org `instanceUrl` and `accessToken`:

```bash
sf org display --target-org cb-dev --json
sf org auth show-access-token --target-org cb-dev --json --no-prompt
```

Use `--no-prompt` (or `--json`) to avoid the interactive confirmation prompt in scripts.

2. Start the mock API with env vars:

```bash
export SF_INSTANCE_URL="https://<yourdomain>.scratch.my.salesforce.com"
export SF_ACCESS_TOKEN="<token>"
npm start
```

3. Run an end-to-end callback simulation (publishes events to Salesforce):

```bash
curl -sS -X POST "http://localhost:3001/api/v1/mock/run-onboarding" \\
  -H "Content-Type: application/json" \\
  -d '{\"applicationId\":\"a01...\",\"accountId\":\"001...\",\"testPersona\":\"PASS\"}' | jq
```

Personas: `PASS`, `REFER`, `FAIL`, `SANCTIONS_HIT`, `DECLINE`

## Test personas

| Persona | Effect |
|---------|--------|
| `PASS` | STP retail path |
| `REFER` | IDV manual review |
| `FAIL` / `DECLINE` | Rejection |
| `SANCTIONS_HIT` | Screening case |

## OpenAPI

See `openapi.yaml` for endpoint summary.
