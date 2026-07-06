const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

const applications = new Map();

function correlationId() {
  return uuidv4();
}

function resolveIdvStatus(persona) {
  const p = (persona || 'PASS').toUpperCase();
  if (p === 'REFER') return 'Refer';
  if (p === 'FAIL' || p === 'DECLINE') return 'Fail';
  return 'Pass';
}

function resolveScreening(persona) {
  const p = (persona || 'CLEAR').toUpperCase();
  if (p === 'SANCTIONS_HIT' || p === 'PEP_HIT' || p === 'ADVERSE_MEDIA') return 'POTENTIAL_MATCH';
  return 'CLEAR';
}

function resolveKyc(persona) {
  const p = (persona || 'PASS').toUpperCase();
  if (p === 'DECLINE') return 'Decline';
  if (p === 'REFER') return 'Refer';
  return 'Approve';
}

// Health
app.get('/api/v1/health', (_req, res) => {
  res.json({ status: 'ok', service: 'cb-mock-api', version: '1.0.0' });
});

// 1. Mock Onfido
app.post('/api/v1/mock/onfido/v1/sessions', (req, res) => {
  const sessionId = `mock-idv-${Date.now()}`;
  res.json({
    sessionId,
    status: 'PENDING',
    sessionUrl: `https://mock.cb.local/idv/${sessionId}`,
    correlationId: correlationId(),
    resolvedStatus: resolveIdvStatus(req.body.testPersona)
  });
});

// 2. Mock Companies House
app.get('/api/v1/mock/companies-house/v1/companies/:crn', (req, res) => {
  const crn = req.params.crn;
  if (crn === '11111111') {
    return res.status(404).json({ error: 'Company dissolved' });
  }
  res.json({
    companyNumber: crn,
    companyName: crn === '87654321' ? 'Flagged Holdings Ltd' : 'Clean Trading Ltd',
    companyStatus: 'active',
    nomineeDirectorFlag: crn === '87654321'
  });
});

app.get('/api/v1/mock/companies-house/v1/companies/:crn/persons-with-significant-control', (req, res) => {
  res.json({
    items: [{ name: 'Jane Director', naturesOfControl: ['ownership-of-shares-75-to-100-percent'] }]
  });
});

// 3. Mock Bureau
app.post('/api/v1/mock/bureau/v1/verify', (req, res) => {
  const persona = (req.body.testPersona || 'STRONG_MATCH').toUpperCase();
  res.json({ matchStrength: persona, requiresPoa: persona !== 'STRONG_MATCH' });
});

// 4. Mock Screening
app.post('/api/v1/mock/screening/v1/screen', (req, res) => {
  const status = resolveScreening(req.body.testPersona);
  res.json({ overallStatus: status, matchScore: status === 'CLEAR' ? 0 : 88 });
});

// 5. Mock KYC
app.post('/api/v1/mock/kyc/v1/prescore', (req, res) => {
  const nationality = req.body.nationality || 'GB';
  res.json({ riskTier: nationality === 'GB' ? 'LOW' : 'MEDIUM', correlationId: correlationId() });
});

app.post('/api/v1/mock/kyc/v1/assess', (req, res) => {
  res.json({ decision: resolveKyc(req.body.testPersona), reasonCode: null });
});

// 6. Mock Core Banking
app.post('/api/v1/mock/core/v1/customers', (req, res) => {
  res.json({ coreCustomerId: `CUST-${Date.now()}` });
});

app.post('/api/v1/mock/core/v1/accounts/open', (req, res) => {
  res.json({
    coreFinAccountId: `FA-${Date.now()}`,
    sortCode: '04-00-04',
    accountNumber: '12345678',
    iban: 'GB00MOCK00001234567890'
  });
});

// 7. Partner customer API
app.post('/api/v1/v1/onboarding/applications', (req, res) => {
  const id = `APP-${Date.now()}`;
  const appRecord = { id, ...req.body, status: 'Draft', createdAt: new Date().toISOString() };
  applications.set(id, appRecord);
  res.status(201).json(appRecord);
});

app.get('/api/v1/v1/onboarding/applications/:id', (req, res) => {
  const appRecord = applications.get(req.params.id);
  if (!appRecord) return res.status(404).json({ error: 'Not found' });
  res.json(appRecord);
});

app.post('/api/v1/v1/onboarding/applications/:id/submit', (req, res) => {
  const appRecord = applications.get(req.params.id);
  if (!appRecord) return res.status(404).json({ error: 'Not found' });
  appRecord.status = 'In_Progress';
  appRecord.correlationId = correlationId();
  res.json({ ...appRecord, events: ['CB_Onboarding_Submitted__e'] });
});

app.post('/api/v1/v1/onboarding/applications/:id/idv/sessions', (req, res) => {
  res.json({
    sessionId: `mock-partner-idv-${Date.now()}`,
    status: 'PENDING',
    resolvedStatus: resolveIdvStatus(req.body.testPersona)
  });
});

app.post('/api/v1/v1/kyb/entities/verify', (req, res) => {
  const crn = req.body.companyNumber || '12345678';
  res.json({
    verified: crn !== '11111111',
    companyStatus: crn === '11111111' ? 'dissolved' : 'active',
    riskFlags: crn === '87654321' ? ['nominee_director'] : []
  });
});

app.post('/api/v1/v1/screening', (req, res) => {
  res.json({ status: resolveScreening(req.body.testPersona) });
});

// Salesforce event ingress shim (optional local callback)
app.post('/api/v1/salesforce/events/:eventType', (req, res) => {
  res.json({ accepted: true, eventType: req.params.eventType, payload: req.body });
});

app.listen(PORT, () => {
  console.log(`CB mock API listening on http://localhost:${PORT}/api/v1`);
});
