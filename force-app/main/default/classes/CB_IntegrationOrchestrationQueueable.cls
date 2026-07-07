public with sharing class CB_IntegrationOrchestrationQueueable implements Queueable, Database.AllowsCallouts {
    private final Id applicationId;

    public CB_IntegrationOrchestrationQueueable(Id applicationId) {
        this.applicationId = applicationId;
    }

    public void execute(QueueableContext context) {
        CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
        if (!CB_IntegrationSettings.isAsyncOrchestrationEnabled()) {
            runFallback(app);
            return;
        }

        CB_IntegrationClient.OrchestrationRequest request = new CB_IntegrationClient.OrchestrationRequest();
        request.applicationId = String.valueOf(app.Id);
        request.accountId = String.valueOf(app.Account__c);
        request.applicationType = app.Application_Type__c;
        request.correlationId = app.Correlation_Id__c;
        request.testPersona = app.Test_Persona__c;
        request.crn = app.CRN__c;
        request.nationality = app.Nationality__c;

        try {
            HttpResponse response = CB_IntegrationClient.postOrchestration(request);
            if (response.getStatusCode() != 202) {
                runFallback(app);
            }
        } catch (Exception ex) {
            CB_IntegrationLogService.log(
                'orchestration/onboarding-submitted',
                'Outbound',
                0,
                'Error',
                app.Correlation_Id__c,
                app.Id,
                JSON.serialize(request),
                ex.getMessage()
            );
            runFallback(app);
        }
    }

    private static void runFallback(CB_Onboarding_Application__c app) {
        CB_Onboarding_Application__c fullApp = [
            SELECT Id, Application_Type__c, CRN__c, Test_Persona__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :app.Id
        ];
        if (fullApp.Application_Type__c == CB_OnboardingConstants.APP_TYPE_SME) {
            CB_MockOrchestrator.runSmeSingle(fullApp.Id, fullApp.CRN__c, fullApp.Test_Persona__c);
            return;
        }
        CB_MockOrchestrator.runRetailSingle(fullApp.Id, fullApp.Test_Persona__c);
    }
}
