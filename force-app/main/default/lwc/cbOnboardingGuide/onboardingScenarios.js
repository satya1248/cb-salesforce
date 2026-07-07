const RETAIL_JOURNEY = [
    { step: 1, name: 'Pre-score', detail: 'Risk tier and CDD level from nationality + product (mock KYC engine).' },
    { step: 2, name: 'IDV', detail: 'Onfido identity verification — document + selfie check.' },
    { step: 3, name: 'Bureau', detail: 'Electoral roll / credit bureau address match.' },
    { step: 4, name: 'Screening', detail: 'Sanctions, PEP, and adverse media screening.' },
    { step: 5, name: 'KYC assess', detail: 'Risk engine final decision — approve, refer, or decline.' },
    { step: 6, name: 'Account open', detail: 'Core banking creates sort code + account number.' }
];

const SME_JOURNEY = [
    { step: 1, name: 'KYB', detail: 'Companies House lookup — company status, PSC, nominee director flags.' },
    { step: 2, name: 'Pre-score', detail: 'Director nationality drives risk tier and CDD level.' },
    { step: 3, name: 'IDV → Bureau → Screening → KYC', detail: 'Same individual checks as retail for the primary director.' },
    { step: 4, name: 'Account open', detail: 'Business current account opened in core banking.' }
];

const RETAIL_SCENARIOS = [
    { key: 'PASS', label: 'STP — all clear', outcome: 'Completed', caseType: '—', description: 'IDV pass, bureau strong match, screening clear, KYC approve. Account opened automatically.' },
    { key: 'REFER', label: 'IDV refer', outcome: 'Under Review', caseType: 'KYC/CDD', description: 'Identity check needs manual analyst review before continuing.' },
    { key: 'FAIL', label: 'IDV fail', outcome: 'Rejected', caseType: '—', description: 'Identity verification failed — application cannot proceed.' },
    { key: 'WEAK_MATCH', label: 'Bureau weak match', outcome: 'Under Review', caseType: 'KYC/CDD + POA', description: 'Address match weak — proof of address required and analyst case opened.' },
    { key: 'NO_MATCH', label: 'Bureau no match', outcome: 'Under Review', caseType: 'KYC/CDD + POA', description: 'No bureau match — POA document and KYC review required.' },
    { key: 'SANCTIONS_HIT', label: 'Sanctions hit', outcome: 'Under Review', caseType: 'Screening', description: 'FinCrime screening case — resolve via CB Resolve Onboarding Case to continue.' },
    { key: 'PEP_HIT', label: 'PEP hit', outcome: 'Under Review', caseType: 'Screening', description: 'Politically exposed person flagged — MLRO/FinCrime review required.' },
    { key: 'ADVERSE_MEDIA', label: 'Adverse media', outcome: 'Under Review', caseType: 'Screening', description: 'Adverse media match — enhanced due diligence case opened.' },
    { key: 'KYC_REFER', label: 'KYC refer', outcome: 'Under Review', caseType: 'KYC/CDD', description: 'Risk engine refers to analyst after automated checks pass.' },
    { key: 'KYC_DECLINE', label: 'KYC decline', outcome: 'Rejected', caseType: '—', description: 'Risk engine declines — no account opened.' }
];

const SME_CRN_SCENARIOS = [
    { crn: '12345678', label: 'Clean company', outcome: 'Completed (with PASS persona)', caseType: '—', description: 'Active company, PSC on file — continues to director KYC chain.' },
    { crn: '87654321', label: 'Nominee director flag', outcome: 'Under Review', caseType: 'KYB Review', description: 'Companies House flags nominee director — KYB analyst review before individual checks.' },
    { crn: '11111111', label: 'Dissolved company', outcome: 'Rejected', caseType: '—', description: 'Company dissolved at Companies House — application rejected immediately.' }
];

const PRESCORE_RULES = [
    { condition: 'UK national (GB)', risk: 'Low', cdd: 'Simplified', note: 'Domestic retail current account — lowest friction path.' },
    { condition: 'Non-UK national', risk: 'Medium', cdd: 'Standard', note: 'Enhanced data capture; standard CDD applies.' },
    { condition: 'Screening / PEP / sanctions persona', risk: 'High', cdd: 'Enhanced', note: 'Overrides nationality — enhanced due diligence regardless of origin.' }
];

export { RETAIL_JOURNEY, SME_JOURNEY, RETAIL_SCENARIOS, SME_CRN_SCENARIOS, PRESCORE_RULES };
