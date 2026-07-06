public with sharing class CB_OnboardingSubmittedHandler {
    public static void handle(List<CB_Onboarding_Submitted__e> events) {
        for (CB_Onboarding_Submitted__e evt : events) {
            Id applicationId = Id.valueOf(evt.Application_Id__c);
            CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
            if (app.Status__c == CB_OnboardingConstants.STATUS_DRAFT) {
                CB_OnboardingApplicationService.updateStatus(applicationId, CB_OnboardingConstants.STATUS_IN_PROGRESS);
            }
            CB_IntegrationLogService.log(
                'CB_Onboarding_Submitted__e',
                'Inbound',
                200,
                'Success',
                evt.Correlation_Id__c,
                applicationId,
                evt.Status__c,
                evt.Payload_Json__c
            );
            if (CB_IntegrationSettings.isAsyncOrchestrationEnabled()) {
                System.enqueueJob(new CB_IntegrationOrchestrationQueueable(applicationId));
            } else {
                runSyncOrchestration(app);
            }
        }
    }

    private static void runSyncOrchestration(CB_Onboarding_Application__c app) {
        if (app.Application_Type__c == CB_OnboardingConstants.APP_TYPE_SME) {
            CB_MockOrchestrator.runSmeSingle(app.Id, app.CRN__c, app.Test_Persona__c);
            return;
        }
        CB_MockOrchestrator.runRetailSingle(app.Id, app.Test_Persona__c);
    }
}
