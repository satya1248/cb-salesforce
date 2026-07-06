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
    global static ApplicationResponse postApplication() {
        String resourcePath = getResourcePath();
        if (resourcePath.endsWith('/submit')) {
            return submitApplication(resourcePath);
        }
        return createApplication();
    }

    @HttpGet
    global static ApplicationResponse getApplication() {
        CB_PartnerAuthService.AuthResult auth = CB_PartnerAuthService.authenticate();
        if (!auth.success) {
            return unauthorized(auth.errorMessage);
        }

        String applicationId = getApplicationIdFromPath(getResourcePath());
        CB_Onboarding_Application__c app = [
            SELECT Id, Account__c, Status__c, Partner_Config__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :applicationId AND Partner_Config__c = :auth.config.Id
            LIMIT 1
        ];
        ApplicationResponse response = new ApplicationResponse();
        response.applicationId = app.Id;
        response.accountId = app.Account__c;
        response.status = app.Status__c;
        response.message = 'OK';
        return response;
    }

    private static ApplicationResponse createApplication() {
        CB_PartnerAuthService.AuthResult auth = CB_PartnerAuthService.authenticate();
        if (!auth.success) {
            return unauthorized(auth.errorMessage);
        }

        ApplicationRequest body = (ApplicationRequest) JSON.deserialize(
            RestContext.request.requestBody.toString(),
            ApplicationRequest.class
        );

        if (String.isNotBlank(body.partnerId) && body.partnerId != auth.config.Partner_Id__c) {
            return badRequest('partnerId does not match authenticated partner');
        }

        if (String.isNotBlank(body.partnerReference)) {
            Integer existing = [
                SELECT COUNT()
                FROM CB_Onboarding_Application__c
                WHERE Partner_Config__c = :auth.config.Id AND Partner_Reference__c = :body.partnerReference
            ];
            if (existing > 0) {
                return badRequest('Duplicate partnerReference');
            }
        }

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
            Status__c = CB_OnboardingConstants.STATUS_DRAFT,
            Correlation_Id__c = correlationId,
            Entity_Type__c = 'Individual',
            Partner_Config__c = auth.config.Id,
            Partner_Reference__c = body.partnerReference,
            Test_Persona__c = body.testPersona
        );
        insert app;

        CB_IntegrationLogService.log(
            'partner/onboarding/applications',
            'Inbound',
            201,
            'Success',
            correlationId,
            app.Id,
            JSON.serialize(body),
            'Draft created'
        );

        ApplicationResponse response = new ApplicationResponse();
        response.applicationId = app.Id;
        response.accountId = person.Id;
        response.status = app.Status__c;
        response.message = 'Application created';
        RestContext.response.statusCode = 201;
        return response;
    }

    private static ApplicationResponse submitApplication(String resourcePath) {
        CB_PartnerAuthService.AuthResult auth = CB_PartnerAuthService.authenticate();
        if (!auth.success) {
            return unauthorized(auth.errorMessage);
        }

        String applicationId = getApplicationIdFromPath(resourcePath.replace('/submit', ''));
        CB_Onboarding_Application__c app = [
            SELECT Id, Account__c, Status__c, Correlation_Id__c, Test_Persona__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :applicationId AND Partner_Config__c = :auth.config.Id
            LIMIT 1
        ];

        if (app.Status__c != CB_OnboardingConstants.STATUS_DRAFT) {
            return badRequest('Application is not in Draft status');
        }

        update new CB_Onboarding_Application__c(
            Id = app.Id,
            Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS
        );
        CB_PlatformEventPublisher.publishOnboardingSubmitted(app.Id, app.Account__c, app.Correlation_Id__c);

        ApplicationResponse response = new ApplicationResponse();
        response.applicationId = app.Id;
        response.accountId = app.Account__c;
        response.status = CB_OnboardingConstants.STATUS_IN_PROGRESS;
        response.message = 'Application submitted for processing';
        RestContext.response.statusCode = 202;
        return response;
    }

    private static String getResourcePath() {
        String uri = RestContext.request.requestURI;
        Integer idx = uri.indexOf('/onboarding/');
        if (idx < 0) {
            return '';
        }
        return uri.substring(idx + '/onboarding/'.length());
    }

    private static String getApplicationIdFromPath(String resourcePath) {
        String trimmed = resourcePath == null ? '' : resourcePath.removeEnd('/submit');
        if (trimmed.startsWith('applications/')) {
            trimmed = trimmed.substring('applications/'.length());
        }
        return trimmed;
    }

    private static ApplicationResponse unauthorized(String message) {
        RestContext.response.statusCode = 401;
        ApplicationResponse response = new ApplicationResponse();
        response.message = message;
        return response;
    }

    private static ApplicationResponse badRequest(String message) {
        RestContext.response.statusCode = 400;
        ApplicationResponse response = new ApplicationResponse();
        response.message = message;
        return response;
    }
}
