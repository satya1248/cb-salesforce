public with sharing class CB_IntegrationClient {
    public class OrchestrationRequest {
        public String applicationId;
        public String accountId;
        public String applicationType;
        public String correlationId;
        public String testPersona;
        public String crn;
    }

    public static HttpResponse postOrchestration(OrchestrationRequest request) {
        String body = JSON.serialize(request);
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('callout:CB_Mock_Integration/orchestration/onboarding-submitted');
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('X-CB-Ingress-Secret', CB_IntegrationSettings.getIngressSecret());
        httpRequest.setBody(body);
        httpRequest.setTimeout(120000);

        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        String status = response.getStatusCode() >= 200 && response.getStatusCode() < 300 ? 'Success' : 'Error';
        CB_IntegrationLogService.log(
            'orchestration/onboarding-submitted',
            'Outbound',
            response.getStatusCode(),
            status,
            request.correlationId,
            Id.valueOf(request.applicationId),
            body,
            response.getBody()
        );
        return response;
    }
}
