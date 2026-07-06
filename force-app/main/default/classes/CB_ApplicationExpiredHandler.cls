public with sharing class CB_ApplicationExpiredHandler {
    public static void handle(List<CB_Application_Expired__e> events) {
        for (CB_Application_Expired__e evt : events) {
            if (String.isBlank(evt.Application_Id__c)) {
                continue;
            }
            handleFromApplication(
                Id.valueOf(evt.Application_Id__c),
                String.isBlank(evt.Account_Id__c) ? null : Id.valueOf(evt.Account_Id__c),
                evt.Correlation_Id__c,
                evt.Reason_Code__c
            );
        }
    }

    public static void handleFromApplication(Id applicationId, Id accountId, String correlationId, String reasonCode) {
        CB_OnboardingApplicationService.rejectApplication(applicationId, reasonCode);
        CB_IntegrationLogService.log(
            'CB_Application_Expired__e',
            'Inbound',
            200,
            'Success',
            correlationId,
            applicationId,
            reasonCode,
            null
        );
    }
}
