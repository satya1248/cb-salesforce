public with sharing class CB_PlatformEventPublisher {
    public static void publishIdvCompleted(Id applicationId, Id accountId, String status, String correlationId, String reasonCode, String payloadJson) {
        EventBus.publish(buildEvent(
            new CB_IDV_Completed__e(),
            applicationId,
            accountId,
            status,
            correlationId,
            reasonCode,
            payloadJson
        ));
    }

    public static void publishScreeningCompleted(Id applicationId, Id accountId, String status, String correlationId, String reasonCode, String payloadJson) {
        EventBus.publish(buildEvent(
            new CB_Screening_Completed__e(),
            applicationId,
            accountId,
            status,
            correlationId,
            reasonCode,
            payloadJson
        ));
    }

    public static void publishKycDecision(Id applicationId, Id accountId, String status, String correlationId, String reasonCode, String payloadJson) {
        EventBus.publish(buildEvent(
            new CB_KYC_Decision__e(),
            applicationId,
            accountId,
            status,
            correlationId,
            reasonCode,
            payloadJson
        ));
    }

    public static void publishAccountOpened(Id applicationId, Id accountId, String status, String correlationId, String reasonCode, String payloadJson) {
        EventBus.publish(buildEvent(
            new CB_Account_Opened__e(),
            applicationId,
            accountId,
            status,
            correlationId,
            reasonCode,
            payloadJson
        ));
    }

    public static void publishOnboardingSubmitted(Id applicationId, Id accountId, String correlationId) {
        EventBus.publish(buildEvent(
            new CB_Onboarding_Submitted__e(),
            applicationId,
            accountId,
            'SUBMITTED',
            correlationId,
            null,
            null
        ));
    }

    private static SObject buildEvent(
        SObject eventRecord,
        Id applicationId,
        Id accountId,
        String status,
        String correlationId,
        String reasonCode,
        String payloadJson
    ) {
        eventRecord.put('Application_Id__c', String.valueOf(applicationId));
        eventRecord.put('Account_Id__c', accountId == null ? null : String.valueOf(accountId));
        eventRecord.put('Status__c', status);
        eventRecord.put('Correlation_Id__c', correlationId);
        eventRecord.put('Reason_Code__c', reasonCode);
        eventRecord.put('Payload_Json__c', payloadJson);
        return eventRecord;
    }
}
