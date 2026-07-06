public with sharing class CB_ScreeningCompletedHandler {
    public static void handle(List<CB_Screening_Completed__e> events) {
        for (CB_Screening_Completed__e evt : events) {
            handleFromStatus(
                Id.valueOf(evt.Application_Id__c),
                String.isBlank(evt.Account_Id__c) ? null : Id.valueOf(evt.Account_Id__c),
                evt.Status__c,
                evt.Correlation_Id__c
            );
        }
    }

    public static void handleFromStatus(Id applicationId, Id accountId, String screeningStatus, String correlationId) {
        insert new CB_Screening_Result__c(
            Account__c = accountId,
            Onboarding_Application__c = applicationId,
            Overall_Status__c = screeningStatus == 'CLEAR' ? 'Clear' : 'Potential_Match',
            Sanctions_Status__c = screeningStatus == 'CLEAR' ? 'Clear' : 'Potential_Match',
            Screened_At__c = System.now(),
            Vendor_Reference__c = 'MOCK-SCR'
        );
        if (screeningStatus != 'CLEAR') {
            CB_OnboardingApplicationService.updateStatus(applicationId, CB_OnboardingConstants.STATUS_UNDER_REVIEW);
            CB_CaseFactory.createOnboardingCase(
                CB_OnboardingConstants.RT_SCREENING,
                accountId,
                applicationId,
                'Screening review required',
                correlationId
            );
        }
        CB_IntegrationLogService.log('CB_Screening_Completed__e', 'Inbound', 200, 'Success', correlationId, applicationId, screeningStatus, null);
    }
}
