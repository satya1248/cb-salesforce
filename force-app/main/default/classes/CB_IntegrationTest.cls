@IsTest
private class CB_IntegrationTest {
    @IsTest
    static void testIngressRejectsMissingSecret() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/cb/v1/events/idv-completed';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"applicationId":"001000000000000","status":"Pass","correlationId":"abc"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String response = CB_EventIngressRest.postEvent();
        Test.stopTest();

        System.assertEquals(401, res.statusCode);
        System.assert(response.contains('Unauthorized'));
    }

    @IsTest
    static void testIngressAcceptsValidSecret() {
        Account person = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            FirstName = 'Ingress',
            LastName = 'Test',
            PersonEmail = 'ingress@example.com'
        );
        insert person;
        CB_Onboarding_Application__c app = new CB_Onboarding_Application__c(
            Account__c = person.Id,
            Application_Type__c = CB_OnboardingConstants.APP_TYPE_RETAIL,
            Product_Code__c = CB_OnboardingConstants.PRODUCT_CURR_RETAIL,
            Channel__c = CB_OnboardingConstants.CHANNEL_WEB,
            Status__c = CB_OnboardingConstants.STATUS_IDV_PENDING,
            Correlation_Id__c = CB_Util.newCorrelationId(),
            Entity_Type__c = 'Individual'
        );
        insert app;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/cb/v1/events/idv-completed';
        req.httpMethod = 'POST';
        req.headers.put('X-CB-Ingress-Secret', CB_IntegrationSettings.getIngressSecret());
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'applicationId' => app.Id,
            'accountId' => person.Id,
            'status' => CB_OnboardingConstants.IDV_PASS,
            'correlationId' => app.Correlation_Id__c
        }));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String response = CB_EventIngressRest.postEvent();
        Test.getEventBus().deliver();
        Test.stopTest();

        System.assertEquals('{"status":"accepted"}', response);
        System.assertEquals(CB_OnboardingConstants.IDV_PASS, [
            SELECT IDV_Status__c FROM CB_Onboarding_Application__c WHERE Id = :app.Id
        ].IDV_Status__c);
    }

    @IsTest
    static void testPartnerApiRejectsMissingAuth() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/cb/v1/onboarding/applications';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"firstName":"A","lastName":"B"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CB_PartnerCustomerRest.ApplicationResponse response = CB_PartnerCustomerRest.postApplication();
        Test.stopTest();

        System.assertEquals(401, res.statusCode);
        System.assertNotEquals(null, response.message);
    }

    @IsTest
    static void testQueueableFallbackWhenCalloutFails() {
        Test.setMock(HttpCalloutMock.class, new CB_IntegrationCalloutFailureMock());

        Account person = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            FirstName = 'Fallback',
            LastName = 'User',
            PersonEmail = 'fallback@example.com'
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
            Test_Persona__c = 'PASS'
        );
        insert app;

        Test.startTest();
        System.enqueueJob(new CB_IntegrationOrchestrationQueueable(app.Id));
        Test.stopTest();

        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, [
            SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :app.Id
        ].Status__c);
    }

    private class CB_IntegrationCalloutFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setBody('{"error":"mock unavailable"}');
            return response;
        }
    }
}
