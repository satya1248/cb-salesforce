@IsTest
private class CB_OnboardingScenariosTest {
    private static void enableOrchestrationMock() {
        Test.setMock(HttpCalloutMock.class, new CB_IntegrationOrchestrationMock());
    }

    @IsTest
    static void testPepHit() {
        enableOrchestrationMock();
        assertPersona('PEP_HIT', CB_OnboardingConstants.STATUS_UNDER_REVIEW, false);
    }

    @IsTest
    static void testKycRefer() {
        enableOrchestrationMock();
        assertPersona('KYC_REFER', CB_OnboardingConstants.STATUS_UNDER_REVIEW, false);
    }

    @IsTest
    static void testKycDecline() {
        enableOrchestrationMock();
        assertPersona('KYC_DECLINE', CB_OnboardingConstants.STATUS_REJECTED, false);
    }

    @IsTest
    static void testWeakBureauMatch() {
        enableOrchestrationMock();
        assertPersona('WEAK_MATCH', CB_OnboardingConstants.STATUS_UNDER_REVIEW, false);
        System.assertEquals(1, [SELECT COUNT() FROM CB_Compliance_Document__c WHERE Document_Type__c = 'POA']);
    }

    @IsTest
    static void testSmeClean() {
        enableOrchestrationMock();
        CB_SMEOnboardingActions.CreateRequest req = buildSmeRequest(
            'Clean Trading Ltd',
            CB_OnboardingConstants.CRN_CLEAN,
            'PASS'
        );
        Test.startTest();
        CB_SMEOnboardingActions.CreateResult result = CB_SMEOnboardingActions.createSmeApplication(
            new List<CB_SMEOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, [
            SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :result.applicationId
        ].Status__c);
    }

    @IsTest
    static void testSmeFlaggedCrn() {
        enableOrchestrationMock();
        CB_SMEOnboardingActions.CreateRequest req = buildSmeRequest(
            'Flagged Holdings Ltd',
            CB_OnboardingConstants.CRN_FLAGGED,
            'PASS'
        );
        Test.startTest();
        CB_SMEOnboardingActions.CreateResult result = CB_SMEOnboardingActions.createSmeApplication(
            new List<CB_SMEOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(CB_OnboardingConstants.STATUS_UNDER_REVIEW, [
            SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :result.applicationId
        ].Status__c);
        System.assert([SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'CB_KYB_Review'] > 0);
    }

    @IsTest
    static void testSmeDissolvedCrn() {
        enableOrchestrationMock();
        CB_SMEOnboardingActions.CreateRequest req = buildSmeRequest(
            'Dissolved Co Ltd',
            CB_OnboardingConstants.CRN_DISSOLVED,
            'PASS'
        );
        Test.startTest();
        CB_SMEOnboardingActions.CreateResult result = CB_SMEOnboardingActions.createSmeApplication(
            new List<CB_SMEOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(CB_OnboardingConstants.STATUS_REJECTED, [
            SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :result.applicationId
        ].Status__c);
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
        System.assertNotEquals(null, [SELECT API_Client_Secret__c FROM CB_Partner_Config__c WHERE Id = :result.partnerConfigId].API_Client_Secret__c);
    }

    @IsTest
    static void testPartnerCustomerApi() {
        enableOrchestrationMock();
        CB_PartnerOnboardingActions.CreateRequest partnerReq = new CB_PartnerOnboardingActions.CreateRequest();
        partnerReq.partnerName = 'API Partner Bank';
        partnerReq.partnerId = 'PARTNER-API-001';
        partnerReq.testPersona = 'PASS';
        CB_PartnerOnboardingActions.CreateResult partner = CB_PartnerOnboardingActions.createPartnerInstitution(
            new List<CB_PartnerOnboardingActions.CreateRequest>{ partnerReq }
        )[0];
        String apiKey = [SELECT API_Client_Secret__c FROM CB_Partner_Config__c WHERE Id = :partner.partnerConfigId].API_Client_Secret__c;

        RestRequest createReq = new RestRequest();
        RestResponse createRes = new RestResponse();
        createReq.requestURI = '/services/apexrest/cb/v1/onboarding/applications';
        createReq.httpMethod = 'POST';
        createReq.headers.put('X-Partner-Id', 'PARTNER-API-001');
        createReq.headers.put('X-API-Key', apiKey);
        createReq.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'partnerReference' => 'REF-1001',
            'firstName' => 'Sam',
            'lastName' => 'Lee',
            'email' => 'sam@example.com',
            'testPersona' => 'PASS'
        }));
        RestContext.request = createReq;
        RestContext.response = createRes;

        Test.startTest();
        CB_PartnerCustomerRest.ApplicationResponse created = CB_PartnerCustomerRest.postApplication();
        System.assertEquals(201, createRes.statusCode);
        System.assertEquals(CB_OnboardingConstants.STATUS_DRAFT, created.status);

        RestRequest submitReq = new RestRequest();
        RestResponse submitRes = new RestResponse();
        submitReq.requestURI = '/services/apexrest/cb/v1/onboarding/applications/' + created.applicationId + '/submit';
        submitReq.httpMethod = 'POST';
        submitReq.headers.put('X-Partner-Id', 'PARTNER-API-001');
        submitReq.headers.put('X-API-Key', apiKey);
        RestContext.request = submitReq;
        RestContext.response = submitRes;
        CB_PartnerCustomerRest.ApplicationResponse submitted = CB_PartnerCustomerRest.postApplication();
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals(202, submitRes.statusCode);
        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, [
            SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :created.applicationId
        ].Status__c);
        System.assertEquals('Partner_API', [SELECT Channel__c FROM CB_Onboarding_Application__c WHERE Id = :created.applicationId].Channel__c);
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

    @IsTest
    static void testResumeAfterScreeningCase() {
        enableOrchestrationMock();
        CB_RetailOnboardingActions.CreateRequest req = new CB_RetailOnboardingActions.CreateRequest();
        req.firstName = 'Resume';
        req.lastName = 'Screening';
        req.email = 'resume.screen@example.com';
        req.testPersona = 'SANCTIONS_HIT';

        Test.startTest();
        CB_RetailOnboardingActions.CreateResult created = CB_RetailOnboardingActions.createRetailApplication(
            new List<CB_RetailOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.getEventBus().deliver();
        Test.stopTest();

        Case screeningCase = [
            SELECT Id
            FROM Case
            WHERE CB_Onboarding_Application__c = :created.applicationId
            LIMIT 1
        ];

        CB_ResolveCaseActions.Request resolveReq = new CB_ResolveCaseActions.Request();
        resolveReq.caseId = screeningCase.Id;
        resolveReq.clearAndContinue = true;

        CB_ResolveCaseActions.Result resolved = CB_ResolveCaseActions.resolve(
            new List<CB_ResolveCaseActions.Request>{ resolveReq }
        )[0];

        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, resolved.finalStatus);
        System.assertEquals(1, [SELECT COUNT() FROM CB_Fin_Account__c WHERE Onboarding_Application__c = :created.applicationId]);
    }

    @IsTest
    static void testPrescoreNonUkNationality() {
        CB_PrescoreService.PrescoreResult result = CB_PrescoreService.evaluate('FR', 'PASS');
        System.assertEquals('Medium', result.riskTier);
        System.assertEquals('Standard', result.cddLevel);

        CB_RetailOnboardingActions.CreateRequest req = new CB_RetailOnboardingActions.CreateRequest();
        req.firstName = 'Marie';
        req.lastName = 'Dupont';
        req.email = 'marie@example.com';
        req.nationality = 'FR';
        req.testPersona = 'PASS';
        Test.startTest();
        CB_RetailOnboardingActions.CreateResult created = CB_RetailOnboardingActions.createRetailApplication(
            new List<CB_RetailOnboardingActions.CreateRequest>{ req }
        )[0];
        Test.stopTest();
        CB_Onboarding_Application__c app = [
            SELECT Nationality__c, Risk_Tier__c, CDD_Level__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :created.applicationId
        ];
        System.assertEquals('FR', app.Nationality__c);
        System.assertEquals('Medium', app.Risk_Tier__c);
        System.assertEquals('Standard', app.CDD_Level__c);
    }

    private static CB_SMEOnboardingActions.CreateRequest buildSmeRequest(String companyName, String crn, String persona) {
        CB_SMEOnboardingActions.CreateRequest req = new CB_SMEOnboardingActions.CreateRequest();
        req.companyName = companyName;
        req.crn = crn;
        req.testPersona = persona;
        req.directorFirstName = 'Jane';
        req.directorLastName = 'Director';
        req.directorEmail = 'jane.director@example.com';
        req.directorNationality = 'GB';
        return req;
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
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(expectedStatus, [
            SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :result.applicationId
        ].Status__c);
        Integer finCount = [SELECT COUNT() FROM CB_Fin_Account__c WHERE Onboarding_Application__c = :result.applicationId];
        System.assertEquals(expectFinAccount ? 1 : 0, finCount);
    }
}
