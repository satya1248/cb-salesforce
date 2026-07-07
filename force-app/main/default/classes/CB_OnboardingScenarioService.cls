public with sharing class CB_OnboardingScenarioService {
    public static String describeRetailScenario(String testPersona) {
        String persona = String.isBlank(testPersona) ? 'PASS' : testPersona.trim().toUpperCase();
        Map<String, String> scenarios = new Map<String, String>{
            'PASS' => 'Straight-through: IDV pass → bureau strong match → screening clear → KYC approve → account opened.',
            'CLEAR' => 'Same as PASS — all checks clear with no manual intervention.',
            'REFER' => 'IDV refer: application pauses for KYC/CDD analyst review of identity documents.',
            'IDV_REFER' => 'IDV refer: application pauses for KYC/CDD analyst review of identity documents.',
            'FAIL' => 'IDV fail: application rejected — customer cannot proceed.',
            'IDV_FAIL' => 'IDV fail: application rejected — customer cannot proceed.',
            'DECLINE' => 'IDV fail: application rejected — customer cannot proceed.',
            'WEAK_MATCH' => 'Bureau weak match: proof of address required and KYC/CDD case opened for analyst review.',
            'NO_MATCH' => 'Bureau no match: proof of address required and KYC/CDD case opened for analyst review.',
            'SANCTIONS_HIT' => 'Screening sanctions hit: FinCrime screening case opened; resolve via CB Resolve Onboarding Case to continue.',
            'PEP_HIT' => 'Screening PEP hit: politically exposed person review case opened for MLRO/FinCrime analyst.',
            'ADVERSE_MEDIA' => 'Screening adverse media hit: enhanced due diligence case opened for FinCrime review.',
            'KYC_REFER' => 'KYC refer: risk engine refers application to KYC/CDD analyst before account opening.',
            'KYC_DECLINE' => 'KYC decline: application rejected by risk engine — no account opened.'
        };
        return scenarios.containsKey(persona)
            ? scenarios.get(persona)
            : 'Custom persona — orchestration will follow mock integration rules for ' + persona + '.';
    }

    public static String describeSmeCrn(String crn) {
        String normalized = String.isBlank(crn) ? CB_OnboardingConstants.CRN_CLEAN : crn.trim();
        if (normalized == CB_OnboardingConstants.CRN_CLEAN) {
            return 'Clean Companies House profile: active company, PSC recorded — proceeds to individual KYC checks.';
        }
        if (normalized == CB_OnboardingConstants.CRN_FLAGGED) {
            return 'Flagged KYB: nominee director detected — KYB review case opened before individual checks.';
        }
        if (normalized == CB_OnboardingConstants.CRN_DISSOLVED) {
            return 'Dissolved company: application rejected immediately — cannot onboard inactive entity.';
        }
        return 'Companies House lookup runs for CRN ' + normalized + ' — outcome depends on company status and PSC data.';
    }

    public static String expectedRetailOutcome(String testPersona) {
        String persona = String.isBlank(testPersona) ? 'PASS' : testPersona.trim().toUpperCase();
        if (persona == 'FAIL' || persona == 'IDV_FAIL' || persona == 'DECLINE' || persona == 'KYC_DECLINE') {
            return CB_OnboardingConstants.STATUS_REJECTED;
        }
        if (persona == 'PASS' || persona == 'CLEAR') {
            return CB_OnboardingConstants.STATUS_COMPLETED;
        }
        return CB_OnboardingConstants.STATUS_UNDER_REVIEW;
    }

    public static String expectedSmeOutcome(String crn, String testPersona) {
        String normalized = String.isBlank(crn) ? CB_OnboardingConstants.CRN_CLEAN : crn.trim();
        if (normalized == CB_OnboardingConstants.CRN_DISSOLVED) {
            return CB_OnboardingConstants.STATUS_REJECTED;
        }
        if (normalized == CB_OnboardingConstants.CRN_FLAGGED) {
            return CB_OnboardingConstants.STATUS_UNDER_REVIEW;
        }
        return expectedRetailOutcome(testPersona);
    }
}
