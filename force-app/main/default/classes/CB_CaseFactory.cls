public with sharing class CB_CaseFactory {
    public static Case createOnboardingCase(
        String recordTypeDeveloperName,
        Id accountId,
        Id applicationId,
        String subject,
        String correlationId
    ) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get(recordTypeDeveloperName)
            .getRecordTypeId();

        Case onboardingCase = new Case(
            RecordTypeId = recordTypeId,
            AccountId = accountId,
            Subject = subject,
            Origin = 'CB Onboarding',
            Status = 'New',
            CB_Onboarding_Application__c = applicationId,
            CB_Correlation_Id__c = correlationId
        );
        insert onboardingCase;
        return onboardingCase;
    }
}
