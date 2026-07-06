public with sharing class CB_AccountOpenedHandler {
    public static void handle(List<CB_Account_Opened__e> events) {
        for (CB_Account_Opened__e evt : events) {
            handleFromPayload(
                Id.valueOf(evt.Application_Id__c),
                String.isBlank(evt.Account_Id__c) ? null : Id.valueOf(evt.Account_Id__c),
                evt.Payload_Json__c,
                evt.Correlation_Id__c
            );
        }
    }

    public static void handleFromPayload(Id applicationId, Id accountId, String payloadJson, String correlationId) {
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);
        String coreFinId = (String) payload.get('coreFinAccountId');
        String sortCode = (String) payload.get('sortCode');
        String accountNumber = (String) payload.get('accountNumber');
        CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
        CB_FinAccountService.createMirrorAccount(
            accountId,
            applicationId,
            coreFinId,
            sortCode,
            accountNumber,
            app.Product_Code__c
        );
        CB_OnboardingApplicationService.completeApplication(applicationId, coreFinId);
        if (accountId != null) {
            update new Account(
                Id = accountId,
                CB_Customer_Status__c = 'Active',
                CB_KYC_Status__c = 'Approved',
                CB_Core_Customer_Id__c = 'MOCK-CUST-' + accountId
            );
        }
        CB_IntegrationLogService.log('CB_Account_Opened__e', 'Inbound', 200, 'Success', correlationId, applicationId, coreFinId, payloadJson);
    }
}
