public with sharing class CB_SMEOnboardingActions {
    public class CreateRequest {
        @InvocableVariable(required=true) public String companyName;
        @InvocableVariable(required=true) public String crn;
        @InvocableVariable public String registeredAddressLine1;
        @InvocableVariable public String registeredCity;
        @InvocableVariable public String registeredPostcode;
        @InvocableVariable(required=true) public String directorFirstName;
        @InvocableVariable(required=true) public String directorLastName;
        @InvocableVariable public String directorEmail;
        @InvocableVariable public String directorPhone;
        @InvocableVariable public Date directorDateOfBirth;
        @InvocableVariable public String directorNationality;
        @InvocableVariable public String testPersona;
    }

    public class CreateResult {
        @InvocableVariable public Id accountId;
        @InvocableVariable public Id applicationId;
        @InvocableVariable public String message;
        @InvocableVariable public String finalStatus;
        @InvocableVariable public String prescoreSummary;
        @InvocableVariable public String scenarioDescription;
        @InvocableVariable public String kybDescription;
        @InvocableVariable public String expectedOutcome;
    }

    @InvocableMethod(label='CB Create SME Application' description='Creates business account and SME onboarding application')
    public static List<CreateResult> createSmeApplication(List<CreateRequest> requests) {
        List<CreateResult> results = new List<CreateResult>();
        for (CreateRequest req : requests) {
            String persona = String.isBlank(req.testPersona) ? 'PASS' : req.testPersona.trim();
            String nationality = String.isBlank(req.directorNationality) ? 'GB' : req.directorNationality.trim().toUpperCase();
            CB_PrescoreService.PrescoreResult prescore = CB_PrescoreService.evaluate(nationality, persona);

            Account business = new Account(
                Name = req.companyName,
                BillingStreet = req.registeredAddressLine1,
                BillingCity = req.registeredCity,
                BillingPostalCode = req.registeredPostcode,
                BillingCountry = 'United Kingdom',
                CB_Customer_Status__c = 'Prospect',
                CB_KYC_Status__c = 'Pending',
                CB_IDV_Status__c = 'Pending',
                CB_Risk_Rating__c = prescore.riskTier
            );
            insert business;

            Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId();
            Account director = new Account(
                RecordTypeId = personRtId,
                FirstName = req.directorFirstName,
                LastName = req.directorLastName,
                PersonEmail = req.directorEmail,
                Phone = req.directorPhone,
                PersonBirthdate = req.directorDateOfBirth,
                PersonMailingCountry = nationality == 'GB' ? 'United Kingdom' : nationality,
                CB_Customer_Status__c = 'Prospect',
                CB_KYC_Status__c = 'Pending',
                CB_IDV_Status__c = 'Pending'
            );
            insert director;

            String correlationId = CB_Util.newCorrelationId();
            CB_Onboarding_Application__c app = new CB_Onboarding_Application__c(
                Account__c = business.Id,
                Application_Type__c = CB_OnboardingConstants.APP_TYPE_SME,
                Product_Code__c = CB_OnboardingConstants.PRODUCT_CURR_SME,
                Channel__c = CB_OnboardingConstants.CHANNEL_WEB,
                Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS,
                Correlation_Id__c = correlationId,
                CRN__c = req.crn,
                Entity_Type__c = 'Limited_Company',
                Test_Persona__c = persona,
                Nationality__c = nationality,
                Risk_Tier__c = prescore.riskTier,
                CDD_Level__c = prescore.cddLevel
            );
            insert app;

            CB_PlatformEventPublisher.publishOnboardingSubmitted(app.Id, business.Id, correlationId);

            CreateResult result = new CreateResult();
            result.accountId = business.Id;
            result.applicationId = app.Id;
            result.prescoreSummary = prescore.summary;
            result.kybDescription = CB_OnboardingScenarioService.describeSmeCrn(req.crn);
            result.scenarioDescription = CB_OnboardingScenarioService.describeRetailScenario(persona);
            result.expectedOutcome = CB_OnboardingScenarioService.expectedSmeOutcome(req.crn, persona);
            result.message = 'SME application submitted. KYB: ' + result.kybDescription
                + ' Prescore (director): ' + prescore.summary
                + '. Expected outcome: ' + result.expectedOutcome
                + '. Integrations run asynchronously.';
            result.finalStatus = CB_OnboardingConstants.STATUS_IN_PROGRESS;
            results.add(result);
        }
        return results;
    }
}
