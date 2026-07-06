public with sharing class CB_BureauService {
    public class VerifyResult {
        public String matchStrength;
        public Boolean requiresPoa;
    }

    public static VerifyResult verify(String testPersona) {
        String persona = String.isBlank(testPersona) ? CB_OnboardingConstants.BUREAU_STRONG : testPersona.toUpperCase();
        VerifyResult result = new VerifyResult();
        result.matchStrength = persona;
        result.requiresPoa = persona != CB_OnboardingConstants.BUREAU_STRONG;
        return result;
    }

    public static Boolean handleBureauResult(
        Id applicationId,
        Id accountId,
        String matchStrength,
        String correlationId
    ) {
        if (matchStrength == CB_OnboardingConstants.BUREAU_STRONG) {
            return true;
        }

        insert new CB_Compliance_Document__c(
            Account__c = accountId,
            Onboarding_Application__c = applicationId,
            Document_Type__c = 'POA',
            Status__c = 'Required',
            Content_Document_Id__c = 'MOCK-POA-PENDING'
        );
        CB_OnboardingApplicationService.updateStatus(applicationId, CB_OnboardingConstants.STATUS_UNDER_REVIEW);
        CB_CaseFactory.createOnboardingCase(
            CB_OnboardingConstants.RT_KYC_CDD,
            accountId,
            applicationId,
            'Proof of address required',
            correlationId
        );
        CB_IntegrationLogService.log('mock/bureau/verify', 'Inbound', 200, 'Success', correlationId, applicationId, matchStrength, '{"requiresPoa":true}');
        return false;
    }
}
