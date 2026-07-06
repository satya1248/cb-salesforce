public with sharing class CB_IntegrationSettings {
    private static final String DEFAULT_INGRESS_SECRET = 'cb-dev-ingress-secret';

    public static String getIngressSecret() {
        CB_Integration_Settings__c settings = CB_Integration_Settings__c.getOrgDefaults();
        if (settings != null && String.isNotBlank(settings.Ingress_Shared_Secret__c)) {
            return settings.Ingress_Shared_Secret__c;
        }
        return DEFAULT_INGRESS_SECRET;
    }

    public static Boolean isAsyncOrchestrationEnabled() {
        CB_Integration_Settings__c settings = CB_Integration_Settings__c.getOrgDefaults();
        return settings == null || settings.Async_Orchestration_Enabled__c != false;
    }
}
