public with sharing class CB_RetailOnboardingActions {
    public class CreateRequest {
        @InvocableVariable(required=true) public String firstName;
        @InvocableVariable(required=true) public String lastName;
        @InvocableVariable public String email;
        @InvocableVariable public String phone;
        @InvocableVariable public Date dateOfBirth;
        @InvocableVariable public String nationality;
        @InvocableVariable public String addressLine1;
        @InvocableVariable public String city;
        @InvocableVariable public String postcode;
        @InvocableVariable public String testPersona;
    }

    public class CreateResult {
        @InvocableVariable public Id accountId;
        @InvocableVariable public Id applicationId;
        @InvocableVariable public String message;
        @InvocableVariable public String finalStatus;
        @InvocableVariable public String prescoreSummary;
        @InvocableVariable public String scenarioDescription;
        @InvocableVariable public String expectedOutcome;
    }

    @InvocableMethod(label='CB Create Retail Application' description='Creates Person Account and onboarding application for current account')
    public static List<CreateResult> createRetailApplication(List<CreateRequest> requests) {
        List<CreateResult> results = new List<CreateResult>();
        for (CreateRequest req : requests) {
            String persona = String.isBlank(req.testPersona) ? 'PASS' : req.testPersona.trim();
            String nationality = String.isBlank(req.nationality) ? 'GB' : req.nationality.trim().toUpperCase();
            CB_PrescoreService.PrescoreResult prescore = CB_PrescoreService.evaluate(nationality, persona);

            Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();
            Account person = new Account(
                RecordTypeId = personRtId,
                FirstName = req.firstName,
                LastName = req.lastName,
                PersonEmail = req.email,
                Phone = req.phone,
                PersonBirthdate = req.dateOfBirth,
                PersonMailingStreet = req.addressLine1,
                PersonMailingCity = req.city,
                PersonMailingPostalCode = req.postcode,
                PersonMailingCountry = nationality == 'GB' ? 'United Kingdom' : nationality,
                CB_Customer_Status__c = 'Prospect',
                CB_KYC_Status__c = 'Pending',
                CB_IDV_Status__c = 'Pending',
                CB_Risk_Rating__c = prescore.riskTier
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
                Entity_Type__c = 'Individual',
                Test_Persona__c = persona,
                Nationality__c = nationality,
                Risk_Tier__c = prescore.riskTier,
                CDD_Level__c = prescore.cddLevel
            );
            insert app;

            CB_PlatformEventPublisher.publishOnboardingSubmitted(app.Id, person.Id, correlationId);

            CreateResult result = new CreateResult();
            result.accountId = person.Id;
            result.applicationId = app.Id;
            result.prescoreSummary = prescore.summary;
            result.scenarioDescription = CB_OnboardingScenarioService.describeRetailScenario(persona);
            result.expectedOutcome = CB_OnboardingScenarioService.expectedRetailOutcome(persona);
            result.message = 'Application submitted. Prescore: ' + prescore.summary
                + '. Expected outcome: ' + result.expectedOutcome
                + '. Integrations run asynchronously — refresh the application record in a few seconds.';
            result.finalStatus = CB_OnboardingConstants.STATUS_IN_PROGRESS;
            results.add(result);
        }
        return results;
    }
}
