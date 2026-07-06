public with sharing class CB_IntegrationLogService {
    public static void log(
        String apiName,
        String direction,
        Integer httpStatus,
        String status,
        String correlationId,
        Id applicationId,
        String requestSummary,
        String responseSummary
    ) {
        insert new CB_Integration_Log__c(
            API_Name__c = apiName,
            Direction__c = direction,
            HTTP_Status__c = httpStatus,
            Status__c = status,
            Correlation_Id__c = correlationId,
            Onboarding_Application__c = applicationId,
            Request_Summary__c = truncate(requestSummary, 5000),
            Response_Summary__c = truncate(responseSummary, 5000)
        );
    }

    private static String truncate(String value, Integer maxLen) {
        if (value == null) {
            return null;
        }
        return value.length() > maxLen ? value.substring(0, maxLen) : value;
    }
}
