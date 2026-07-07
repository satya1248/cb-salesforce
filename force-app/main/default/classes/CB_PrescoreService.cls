public with sharing class CB_PrescoreService {
    public class PrescoreResult {
        public String riskTier;
        public String cddLevel;
        public String summary;
    }

    public static PrescoreResult evaluate(String nationality, String testPersona) {
        String nation = String.isBlank(nationality) ? 'GB' : nationality.trim().toUpperCase();
        String persona = String.isBlank(testPersona) ? 'PASS' : testPersona.trim().toUpperCase();

        PrescoreResult result = new PrescoreResult();
        result.riskTier = resolveRiskTier(nation, persona);
        result.cddLevel = resolveCddLevel(nation, result.riskTier);
        result.summary = buildSummary(nation, result.riskTier, result.cddLevel);
        return result;
    }

    private static String resolveRiskTier(String nationality, String persona) {
        if (isHighRiskPersona(persona)) {
            return 'High';
        }
        if (nationality != 'GB') {
            return 'Medium';
        }
        return 'Low';
    }

    private static String resolveCddLevel(String nationality, String riskTier) {
        if (riskTier == 'High') {
            return 'Enhanced';
        }
        if (riskTier == 'Medium' || nationality != 'GB') {
            return 'Standard';
        }
        return 'Simplified';
    }

    private static String buildSummary(String nationality, String riskTier, String cddLevel) {
        String origin = nationality == 'GB' ? 'UK national' : 'Non-UK national (' + nationality + ')';
        return origin + ' → ' + riskTier + ' risk tier, ' + cddLevel + ' CDD';
    }

    private static Boolean isHighRiskPersona(String persona) {
        return persona == 'SANCTIONS_HIT'
            || persona == 'PEP_HIT'
            || persona == 'ADVERSE_MEDIA'
            || persona == 'KYC_DECLINE';
    }
}
