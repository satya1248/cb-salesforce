public with sharing class CB_RetailOnboardingActions {
    public class CreateRequest {
        @InvocableVariable(required=true) public String firstName;
        @InvocableVariable(required=true) public String lastName;
        @InvocableVariable public String email;
        @InvocableVariable public String testPersona;
    }

    public class CreateResult {
        @InvocableVariable public Id accountId;
        @InvocableVariable public Id applicationId;
        @InvocableVariable public String message;
        @InvocableVariable public String finalStatus;
    }

    @InvocableMethod(label='CB Create Retail Application' description='Creates Person Account and onboarding application for current account')
    public static List<CreateResult> createRetailApplication(List<CreateRequest> requests) {
        List<CreateResult> results = new List<CreateResult>();
        for (CreateRequest req : requests) {
            Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();
            Account person = new Account(
                RecordTypeId = personRtId,
                FirstName = req.firstName,
                LastName = req.lastName,
                PersonEmail = req.email,
                CB_Customer_Status__c = 'Prospect',
                CB_KYC_Status__c = 'Pending',
                CB_IDV_Status__c = 'Pending'
            );
            insert person;

            String correlationId = CB_Util.newCorrelationId();
            CB_Onboarding_Application__c app = new CB_Onboarding_Application__c(
                Account__c = person.Id,
                Application_Type__c = CB_OnboardingConstants.APP_TYPE_RETAIL,
                Product_Code__c = CB_OnboardingConstants.PRODUCT_CURR_RETAIL,
                Channel__c = CB_OnboardingConstants.CHANNEL_WEB,
                Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS,
                Correlation_Id__c = correlationId,
                Entity_Type__c = 'Individual'
            );
            insert app;

            CB_PlatformEventPublisher.publishOnboardingSubmitted(app.Id, person.Id, correlationId);
            CB_MockOrchestrator.Result mockResult = CB_MockOrchestrator.runSingle(app.Id, req.testPersona);

            CreateResult result = new CreateResult();
            result.accountId = person.Id;
            result.applicationId = app.Id;
            result.message = mockResult.message;
            result.finalStatus = mockResult.finalStatus;
            results.add(result);
        }
        return results;
    }
}
