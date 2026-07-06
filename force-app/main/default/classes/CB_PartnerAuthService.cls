public with sharing class CB_PartnerAuthService {
    public class AuthResult {
        public Boolean success;
        public CB_Partner_Config__c config;
        public String errorMessage;
    }

    public static AuthResult authenticate() {
        RestRequest request = RestContext.request;
        String partnerId = request.headers.get('X-Partner-Id');
        String apiKey = request.headers.get('X-API-Key');

        if (String.isBlank(partnerId) || String.isBlank(apiKey)) {
            return failure('Missing X-Partner-Id or X-API-Key header');
        }

        List<CB_Partner_Config__c> configs = [
            SELECT Id, Partner_Account__c, Partner_Id__c, Status__c, API_Client_Id__c, API_Client_Secret__c
            FROM CB_Partner_Config__c
            WHERE Partner_Id__c = :partnerId AND Status__c = 'Active'
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            return failure('Active partner config not found');
        }

        CB_Partner_Config__c config = configs[0];
        if (String.isBlank(config.API_Client_Secret__c) || config.API_Client_Secret__c != apiKey) {
            return failure('Invalid API key');
        }

        AuthResult result = new AuthResult();
        result.success = true;
        result.config = config;
        return result;
    }

    private static AuthResult failure(String message) {
        AuthResult result = new AuthResult();
        result.success = false;
        result.errorMessage = message;
        return result;
    }
}
