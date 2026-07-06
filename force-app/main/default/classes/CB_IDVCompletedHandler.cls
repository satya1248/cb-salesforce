public with sharing class CB_IDVCompletedHandler {
    public static void handle(List<CB_IDV_Completed__e> events) {
        for (CB_IDV_Completed__e evt : events) {
            handleFromStatus(
                Id.valueOf(evt.Application_Id__c),
                String.isBlank(evt.Account_Id__c) ? null : Id.valueOf(evt.Account_Id__c),
                evt.Status__c,
                evt.Correlation_Id__c
            );
        }
    }

    public static void handleFromStatus(Id applicationId, Id accountId, String idvStatus, String correlationId) {
        CB_OnboardingApplicationService.updateIdvStatus(applicationId, idvStatus);
        if (accountId != null) {
            update new Account(Id = accountId, CB_IDV_Status__c = idvStatus);
        }
        if (idvStatus == CB_OnboardingConstants.IDV_REFER) {
            CB_CaseFactory.createOnboardingCase(
                CB_OnboardingConstants.RT_KYC_CDD,
                accountId,
                applicationId,
                'IDV manual review required',
                correlationId
            );
        } else if (idvStatus == CB_OnboardingConstants.IDV_FAIL) {
            CB_OnboardingApplicationService.rejectApplication(applicationId, 'IDV_FAIL');
        }
        CB_IntegrationLogService.log('CB_IDV_Completed__e', 'Inbound', 200, 'Success', correlationId, applicationId, idvStatus, null);
    }
}
