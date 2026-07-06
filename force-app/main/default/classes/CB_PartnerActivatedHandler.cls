public with sharing class CB_PartnerActivatedHandler {
    public static void handle(List<CB_Partner_Activated__e> events) {
        for (CB_Partner_Activated__e evt : events) {
            CB_IntegrationLogService.log(
                'CB_Partner_Activated__e',
                'Inbound',
                200,
                'Success',
                evt.Correlation_Id__c,
                null,
                evt.Partner_Id__c,
                evt.Payload_Json__c
            );
        }
    }
}
