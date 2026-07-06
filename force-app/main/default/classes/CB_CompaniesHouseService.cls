public with sharing class CB_CompaniesHouseService {
    public class CompanyProfile {
        public String crn;
        public String companyName;
        public String companyStatus;
        public Boolean nomineeDirectorFlag;
        public Boolean dissolved;
    }

    public static CompanyProfile lookup(String crn) {
        String normalized = String.isBlank(crn) ? CB_OnboardingConstants.CRN_CLEAN : crn.trim();
        CompanyProfile profile = new CompanyProfile();
        profile.crn = normalized;

        if (normalized == CB_OnboardingConstants.CRN_DISSOLVED) {
            profile.dissolved = true;
            profile.companyStatus = 'dissolved';
            profile.companyName = 'Dissolved Co Ltd';
            return profile;
        }

        profile.dissolved = false;
        profile.companyStatus = 'active';
        profile.nomineeDirectorFlag = normalized == CB_OnboardingConstants.CRN_FLAGGED;
        profile.companyName = profile.nomineeDirectorFlag ? 'Flagged Holdings Ltd' : 'Clean Trading Ltd';
        return profile;
    }

    public static Boolean handleKybProfile(
        Id applicationId,
        Id accountId,
        CompanyProfile profile,
        String correlationId
    ) {
        if (profile.dissolved) {
            CB_OnboardingApplicationService.rejectApplication(applicationId, 'COMPANY_DISSOLVED');
            CB_IntegrationLogService.log('mock/companies-house', 'Inbound', 404, 'Error', correlationId, applicationId, profile.crn, '{"error":"dissolved"}');
            return false;
        }

        insert new CB_Party_Relationship__c(
            Primary_Account__c = accountId,
            Related_Account__c = accountId,
            Onboarding_Application__c = applicationId,
            Relationship_Type__c = 'PSC',
            Ownership_Percentage__c = 100
        );

        if (profile.nomineeDirectorFlag) {
            CB_OnboardingApplicationService.updateStatus(applicationId, CB_OnboardingConstants.STATUS_UNDER_REVIEW);
            CB_CaseFactory.createOnboardingCase(
                CB_OnboardingConstants.RT_KYB_REVIEW,
                accountId,
                applicationId,
                'KYB review required - nominee director flag',
                correlationId
            );
            CB_IntegrationLogService.log('mock/companies-house', 'Inbound', 200, 'Success', correlationId, applicationId, profile.crn, '{"riskFlags":["nominee_director"]}');
            return false;
        }

        CB_IntegrationLogService.log('mock/companies-house', 'Inbound', 200, 'Success', correlationId, applicationId, profile.crn, '{"companyStatus":"active"}');
        return true;
    }
}
