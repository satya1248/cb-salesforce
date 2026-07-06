public with sharing class CB_PartnerActivationService {
    public static void activate(Id partnerConfigId, String correlationId) {
        CB_Partner_Config__c config = [
            SELECT Id, Partner_Account__c, Partner_Id__c, Status__c
            FROM CB_Partner_Config__c
            WHERE Id = :partnerConfigId
            LIMIT 1
        ];

        update new CB_Partner_Config__c(
            Id = config.Id,
            Status__c = 'Active',
            API_Client_Secret__c = CB_Util.generateApiSecret()
        );
        if (config.Partner_Account__c != null) {
            update new Account(
                Id = config.Partner_Account__c,
                CB_Is_Partner__c = true,
                CB_Customer_Status__c = 'Active'
            );
        }

        CB_PlatformEventPublisher.publishPartnerActivated(
            null,
            config.Partner_Account__c,
            config.Partner_Id__c,
            'ACTIVE',
            correlationId,
            null,
            '{"partnerConfigId":"' + String.valueOf(config.Id) + '"}'
        );
        CB_IntegrationLogService.log('CB_Partner_Activated__e', 'Inbound', 200, 'Success', correlationId, null, config.Partner_Id__c, null);
    }
}
