@RestResource(urlMapping='/cb/v1/onboarding/*')
global with sharing class CB_PartnerCustomerRest {
    global class ApplicationRequest {
        public String partnerId;
        public String partnerReference;
        public String firstName;
        public String lastName;
        public String email;
        public String testPersona;
    }

    global class ApplicationResponse {
        public String applicationId;
        public String accountId;
        public String status;
        public String message;
    }

    @HttpPost
    global static ApplicationResponse createApplication() {
        ApplicationRequest body = (ApplicationRequest) JSON.deserialize(
            RestContext.request.requestBody.toString(),
            ApplicationRequest.class
        );

        List<CB_Partner_Config__c> configs = [
            SELECT Id, Partner_Account__c, Status__c
            FROM CB_Partner_Config__c
            WHERE Partner_Id__c = :body.partnerId AND Status__c = 'Active'
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            RestContext.response.statusCode = 400;
            ApplicationResponse error = new ApplicationResponse();
            error.message = 'Active partner config not found';
            return error;
        }

        CB_Partner_Config__c config = configs[0];
        Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        Account person = new Account(
            RecordTypeId = personRtId,
            FirstName = body.firstName,
            LastName = body.lastName,
            PersonEmail = body.email,
            CB_Customer_Status__c = 'Prospect',
            CB_KYC_Status__c = 'Pending',
            CB_IDV_Status__c = 'Pending'
        );
        insert person;

        String correlationId = CB_Util.newCorrelationId();
        CB_Onboarding_Application__c app = new CB_Onboarding_Application__c(
            Account__c = person.Id,
            Application_Type__c = CB_OnboardingConstants.APP_TYPE_PARTNER_CUSTOMER,
            Product_Code__c = CB_OnboardingConstants.PRODUCT_CURR_RETAIL,
            Channel__c = CB_OnboardingConstants.CHANNEL_PARTNER_API,
            Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS,
            Correlation_Id__c = correlationId,
            Entity_Type__c = 'Individual',
            Partner_Config__c = config.Id,
            Partner_Reference__c = body.partnerReference
        );
        insert app;

        CB_PlatformEventPublisher.publishOnboardingSubmitted(app.Id, person.Id, correlationId);
        CB_MockOrchestrator.Result mockResult = CB_MockOrchestrator.runRetailSingle(app.Id, body.testPersona);

        ApplicationResponse response = new ApplicationResponse();
        response.applicationId = app.Id;
        response.accountId = person.Id;
        response.status = mockResult.finalStatus;
        response.message = mockResult.message;
        RestContext.response.statusCode = 201;
        return response;
    }

    @HttpGet
    global static ApplicationResponse getApplication() {
        String applicationId = RestContext.request.requestURI.substring(
            RestContext.request.requestURI.lastIndexOf('/') + 1
        );
        CB_Onboarding_Application__c app = [
            SELECT Id, Account__c, Status__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        ApplicationResponse response = new ApplicationResponse();
        response.applicationId = app.Id;
        response.accountId = app.Account__c;
        response.status = app.Status__c;
        response.message = 'OK';
        return response;
    }
}
