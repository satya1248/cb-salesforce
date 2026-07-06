@IsTest
private class CB_OnboardingScenariosTest {
    @IsTest
    static void testPepHit() {
        assertPersona('PEP_HIT', CB_OnboardingConstants.STATUS_UNDER_REVIEW, false);
    }

    @IsTest
    static void testKycRefer() {
        assertPersona('KYC_REFER', CB_OnboardingConstants.STATUS_UNDER_REVIEW, false);
    }

    @IsTest
    static void testKycDecline() {
        assertPersona('KYC_DECLINE', CB_OnboardingConstants.STATUS_REJECTED, false);
    }

    @IsTest
    static void testWeakBureauMatch() {
        assertPersona('WEAK_MATCH', CB_OnboardingConstants.STATUS_UNDER_REVIEW, false);
        System.assertEquals(1, [SELECT COUNT() FROM CB_Compliance_Document__c WHERE Document_Type__c = 'POA']);
    }

    @IsTest
    static void testSmeClean() {
        CB_SMEOnboardingActions.CreateRequest req = new CB_SMEOnboardingActions.CreateRequest();
        req.companyName = 'Clean Trading Ltd';
        req.crn = CB_OnboardingConstants.CRN_CLEAN;
        req.testPersona = 'PASS';
        Test.startTest();
        CB_SMEOnboardingActions.CreateResult result = CB_SMEOnboardingActions.createSmeApplication(
            new List<CB_SMEOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.stopTest();
        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, result.finalStatus);
    }

    @IsTest
    static void testSmeFlaggedCrn() {
        CB_SMEOnboardingActions.CreateRequest req = new CB_SMEOnboardingActions.CreateRequest();
        req.companyName = 'Flagged Holdings Ltd';
        req.crn = CB_OnboardingConstants.CRN_FLAGGED;
        req.testPersona = 'PASS';
        Test.startTest();
        CB_SMEOnboardingActions.CreateResult result = CB_SMEOnboardingActions.createSmeApplication(
            new List<CB_SMEOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.stopTest();
        System.assertEquals(CB_OnboardingConstants.STATUS_UNDER_REVIEW, result.finalStatus);
        System.assert([SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'CB_KYB_Review'] > 0);
    }

    @IsTest
    static void testSmeDissolvedCrn() {
        CB_SMEOnboardingActions.CreateRequest req = new CB_SMEOnboardingActions.CreateRequest();
        req.companyName = 'Dissolved Co Ltd';
        req.crn = CB_OnboardingConstants.CRN_DISSOLVED;
        req.testPersona = 'PASS';
        Test.startTest();
        CB_SMEOnboardingActions.CreateResult result = CB_SMEOnboardingActions.createSmeApplication(
            new List<CB_SMEOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.stopTest();
        System.assertEquals(CB_OnboardingConstants.STATUS_REJECTED, result.finalStatus);
    }

    @IsTest
    static void testPartnerInstitutionPass() {
        CB_PartnerOnboardingActions.CreateRequest req = new CB_PartnerOnboardingActions.CreateRequest();
        req.partnerName = 'Acme Bank Partner';
        req.partnerId = 'PARTNER-001';
        req.testPersona = 'PASS';
        Test.startTest();
        CB_PartnerOnboardingActions.CreateResult result = CB_PartnerOnboardingActions.createPartnerInstitution(
            new List<CB_PartnerOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.stopTest();
        System.assertEquals('Active', result.finalStatus);
        System.assertEquals('Active', [SELECT Status__c FROM CB_Partner_Config__c WHERE Id = :result.partnerConfigId].Status__c);
    }

    @IsTest
    static void testPartnerCustomerApi() {
        CB_PartnerOnboardingActions.CreateRequest partnerReq = new CB_PartnerOnboardingActions.CreateRequest();
        partnerReq.partnerName = 'API Partner Bank';
        partnerReq.partnerId = 'PARTNER-API-001';
        partnerReq.testPersona = 'PASS';
        CB_PartnerOnboardingActions.createPartnerInstitution(new List<CB_PartnerOnboardingActions.CreateRequest>{ partnerReq });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/cb/v1/onboarding/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'partnerId' => 'PARTNER-API-001',
            'partnerReference' => 'REF-1001',
            'firstName' => 'Sam',
            'lastName' => 'Lee',
            'email' => 'sam@example.com',
            'testPersona' => 'PASS'
        }));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CB_PartnerCustomerRest.ApplicationResponse response = CB_PartnerCustomerRest.createApplication();
        Test.stopTest();

        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, response.status);
        System.assertEquals('Partner_API', [SELECT Channel__c FROM CB_Onboarding_Application__c WHERE Id = :response.applicationId].Channel__c);
    }

    @IsTest
    static void testApplicationExpiryBatch() {
        Account person = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            FirstName = 'Old',
            LastName = 'App',
            PersonEmail = 'old@example.com'
        );
        insert person;
        CB_Onboarding_Application__c app = new CB_Onboarding_Application__c(
            Account__c = person.Id,
            Application_Type__c = CB_OnboardingConstants.APP_TYPE_RETAIL,
            Product_Code__c = CB_OnboardingConstants.PRODUCT_CURR_RETAIL,
            Channel__c = CB_OnboardingConstants.CHANNEL_WEB,
            Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS,
            Correlation_Id__c = CB_Util.newCorrelationId(),
            Entity_Type__c = 'Individual',
            Submitted_Date__c = System.now().addDays(-31)
        );
        insert app;

        Test.startTest();
        Database.executeBatch(new CB_ApplicationExpiryBatch(), 50);
        Test.stopTest();

        System.assertEquals(CB_OnboardingConstants.STATUS_REJECTED, [SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :app.Id].Status__c);
    }

    private static void assertPersona(String persona, String expectedStatus, Boolean expectFinAccount) {
        CB_RetailOnboardingActions.CreateRequest req = new CB_RetailOnboardingActions.CreateRequest();
        req.firstName = 'Test';
        req.lastName = persona;
        req.email = persona.toLowerCase() + '@example.com';
        req.testPersona = persona;
        Test.startTest();
        CB_RetailOnboardingActions.CreateResult result = CB_RetailOnboardingActions.createRetailApplication(
            new List<CB_RetailOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.stopTest();
        System.assertEquals(expectedStatus, result.finalStatus);
        Integer finCount = [SELECT COUNT() FROM CB_Fin_Account__c WHERE Onboarding_Application__c = :result.applicationId];
        System.assertEquals(expectFinAccount ? 1 : 0, finCount);
    }
}
