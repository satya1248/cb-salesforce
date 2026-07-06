public with sharing class CB_OnboardingApplicationService {
    public static CB_Onboarding_Application__c getRequired(Id applicationId) {
        CB_Onboarding_Application__c app = [
            SELECT Id, Name, Account__c, Status__c, Application_Type__c, Correlation_Id__c,
                   IDV_Status__c, KYC_Decision__c, Risk_Tier__c, Product_Code__c, Channel__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        return app;
    }

    public static void updateStatus(Id applicationId, String status) {
        update new CB_Onboarding_Application__c(Id = applicationId, Status__c = status);
    }

    public static void updateIdvStatus(Id applicationId, String idvStatus) {
        update new CB_Onboarding_Application__c(
            Id = applicationId,
            IDV_Status__c = idvStatus,
            Status__c = idvStatus == CB_OnboardingConstants.IDV_PASS
                ? CB_OnboardingConstants.STATUS_KYC_PENDING
                : CB_OnboardingConstants.STATUS_UNDER_REVIEW
        );
    }

    public static void updateKycDecision(Id applicationId, String decision) {
        String status = CB_OnboardingConstants.STATUS_CORE_PROCESSING;
        if (decision == CB_OnboardingConstants.KYC_DECLINE) {
            status = CB_OnboardingConstants.STATUS_REJECTED;
        } else if (decision == CB_OnboardingConstants.KYC_REFER) {
            status = CB_OnboardingConstants.STATUS_UNDER_REVIEW;
        }
        update new CB_Onboarding_Application__c(
            Id = applicationId,
            KYC_Decision__c = decision,
            Status__c = status
        );
    }

    public static void completeApplication(Id applicationId, String coreFinAccountId) {
        update new CB_Onboarding_Application__c(
            Id = applicationId,
            Status__c = CB_OnboardingConstants.STATUS_COMPLETED,
            Core_Fin_Account_Id__c = coreFinAccountId,
            Completed_Date__c = System.now()
        );
    }

    public static void rejectApplication(Id applicationId, String reasonCode) {
        update new CB_Onboarding_Application__c(
            Id = applicationId,
            Status__c = CB_OnboardingConstants.STATUS_REJECTED,
            Rejection_Reason_Code__c = reasonCode,
            Completed_Date__c = System.now()
        );
    }
}
