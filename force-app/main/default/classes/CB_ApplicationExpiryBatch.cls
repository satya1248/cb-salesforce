public with sharing class CB_ApplicationExpiryBatch implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime cutoff = System.now().addDays(-1 * CB_OnboardingConstants.APPLICATION_EXPIRY_DAYS);
        return Database.getQueryLocator([
            SELECT Id, Correlation_Id__c, Account__c
            FROM CB_Onboarding_Application__c
            WHERE Status__c IN (
                'Draft', 'In_Progress', 'IDV_Pending', 'KYC_Pending', 'Under_Review', 'Core_Processing'
            )
            AND Submitted_Date__c != NULL
            AND Submitted_Date__c < :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<CB_Onboarding_Application__c> scope) {
        for (CB_Onboarding_Application__c app : scope) {
            String correlationId = String.isBlank(app.Correlation_Id__c)
                ? CB_Util.newCorrelationId()
                : app.Correlation_Id__c;
            CB_PlatformEventPublisher.publishApplicationExpired(
                app.Id,
                app.Account__c,
                'EXPIRED',
                correlationId,
                'APPLICATION_EXPIRED',
                '{"expiredAfterDays":' + CB_OnboardingConstants.APPLICATION_EXPIRY_DAYS + '}'
            );
            CB_ApplicationExpiredHandler.handleFromApplication(app.Id, app.Account__c, correlationId, 'APPLICATION_EXPIRED');
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CB_ApplicationExpiryBatch(), 200);
    }
}
