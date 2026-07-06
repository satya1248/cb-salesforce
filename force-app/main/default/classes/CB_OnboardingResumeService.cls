public with sharing class CB_OnboardingResumeService {
    public static CB_MockOrchestrator.Result resumeAfterCase(Id applicationId, String caseRecordTypeDeveloperName) {
        CB_Onboarding_Application__c app = [
            SELECT Id, Account__c, Correlation_Id__c, IDV_Status__c, KYC_Decision__c, Application_Type__c, CRN__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        if (caseRecordTypeDeveloperName == CB_OnboardingConstants.RT_SCREENING) {
            return CB_MockOrchestrator.resumeFromScreening(applicationId);
        }
        if (caseRecordTypeDeveloperName == CB_OnboardingConstants.RT_KYB_REVIEW) {
            return CB_MockOrchestrator.resumeFromKyb(applicationId);
        }
        if (caseRecordTypeDeveloperName == CB_OnboardingConstants.RT_KYC_CDD) {
            if (app.IDV_Status__c == CB_OnboardingConstants.IDV_REFER) {
                return CB_MockOrchestrator.resumeFromIdv(applicationId);
            }
            if (hasPendingPoa(applicationId)) {
                verifyPoa(applicationId);
                return CB_MockOrchestrator.resumeFromBureau(applicationId);
            }
            if (app.KYC_Decision__c == CB_OnboardingConstants.KYC_REFER) {
                return CB_MockOrchestrator.resumeFromKyc(applicationId);
            }
            return CB_MockOrchestrator.resumeFromIdv(applicationId);
        }
        return CB_MockOrchestrator.resumeFromScreening(applicationId);
    }

    private static Boolean hasPendingPoa(Id applicationId) {
        return [
            SELECT COUNT()
            FROM CB_Compliance_Document__c
            WHERE Onboarding_Application__c = :applicationId
              AND Document_Type__c = 'POA'
              AND Status__c = 'Required'
        ] > 0;
    }

    private static void verifyPoa(Id applicationId) {
        List<CB_Compliance_Document__c> docs = [
            SELECT Id
            FROM CB_Compliance_Document__c
            WHERE Onboarding_Application__c = :applicationId
              AND Document_Type__c = 'POA'
              AND Status__c = 'Required'
        ];
        for (CB_Compliance_Document__c doc : docs) {
            doc.Status__c = 'Verified';
        }
        if (!docs.isEmpty()) {
            update docs;
        }
    }
}
