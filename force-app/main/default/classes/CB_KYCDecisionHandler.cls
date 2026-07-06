public with sharing class CB_KYCDecisionHandler {
    public static void handle(List<CB_KYC_Decision__e> events) {
        for (CB_KYC_Decision__e evt : events) {
            handleFromStatus(
                Id.valueOf(evt.Application_Id__c),
                String.isBlank(evt.Account_Id__c) ? null : Id.valueOf(evt.Account_Id__c),
                evt.Status__c,
                evt.Correlation_Id__c
            );
        }
    }

    public static void handleFromStatus(Id applicationId, Id accountId, String decision, String correlationId) {
        CB_OnboardingApplicationService.updateKycDecision(applicationId, decision);
        if (accountId != null) {
            update new Account(
                Id = accountId,
                CB_KYC_Status__c = decision == CB_OnboardingConstants.KYC_APPROVE ? 'Approved' : 'Referred'
            );
        }
        if (decision == CB_OnboardingConstants.KYC_REFER) {
            CB_CaseFactory.createOnboardingCase(
                CB_OnboardingConstants.RT_KYC_CDD,
                accountId,
                applicationId,
                'KYC manual review required',
                correlationId
            );
        } else if (decision == CB_OnboardingConstants.KYC_DECLINE) {
            CB_OnboardingApplicationService.rejectApplication(applicationId, 'KYC_DECLINE');
        }
        CB_IntegrationLogService.log('CB_KYC_Decision__e', 'Inbound', 200, 'Success', correlationId, applicationId, decision, null);
    }
}
