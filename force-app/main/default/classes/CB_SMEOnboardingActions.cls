public with sharing class CB_SMEOnboardingActions {
    public class CreateRequest {
        @InvocableVariable(required=true) public String companyName;
        @InvocableVariable(required=true) public String crn;
        @InvocableVariable public String directorFirstName;
        @InvocableVariable public String directorLastName;
        @InvocableVariable public String directorEmail;
        @InvocableVariable public String testPersona;
    }

    public class CreateResult {
        @InvocableVariable public Id accountId;
        @InvocableVariable public Id applicationId;
        @InvocableVariable public String message;
        @InvocableVariable public String finalStatus;
    }

    @InvocableMethod(label='CB Create SME Application' description='Creates business account and SME onboarding application')
    public static List<CreateResult> createSmeApplication(List<CreateRequest> requests) {
        List<CreateResult> results = new List<CreateResult>();
        for (CreateRequest req : requests) {
            Account business = new Account(
                Name = req.companyName,
                CB_Customer_Status__c = 'Prospect',
                CB_KYC_Status__c = 'Pending',
                CB_IDV_Status__c = 'Pending'
            );
            insert business;

            String correlationId = CB_Util.newCorrelationId();
            CB_Onboarding_Application__c app = new CB_Onboarding_Application__c(
                Account__c = business.Id,
                Application_Type__c = CB_OnboardingConstants.APP_TYPE_SME,
                Product_Code__c = CB_OnboardingConstants.PRODUCT_CURR_SME,
                Channel__c = CB_OnboardingConstants.CHANNEL_WEB,
                Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS,
                Correlation_Id__c = correlationId,
                CRN__c = req.crn,
                Entity_Type__c = 'Limited_Company'
            );
            insert app;

            CB_PlatformEventPublisher.publishOnboardingSubmitted(app.Id, business.Id, correlationId);
            CB_MockOrchestrator.Result mockResult = CB_MockOrchestrator.runSmeSingle(
                app.Id,
                req.crn,
                req.testPersona
            );

            CreateResult result = new CreateResult();
            result.accountId = business.Id;
            result.applicationId = app.Id;
            result.message = mockResult.message;
            result.finalStatus = mockResult.finalStatus;
            results.add(result);
        }
        return results;
    }
}
