@RestResource(urlMapping='/cb/v1/events/*')
global with sharing class CB_EventIngressRest {
    global class EventRequest {
        public String applicationId;
        public String accountId;
        public String status;
        public String correlationId;
        public String reasonCode;
        public String payloadJson;
    }

    @HttpPost
    global static String postEvent() {
        RestRequest req = RestContext.request;
        String eventType = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        EventRequest body = (EventRequest) JSON.deserialize(req.requestBody.toString(), EventRequest.class);
        Id applicationId = Id.valueOf(body.applicationId);
        Id accountId = String.isBlank(body.accountId) ? null : Id.valueOf(body.accountId);

        if (eventType == 'idv-completed') {
            CB_PlatformEventPublisher.publishIdvCompleted(applicationId, accountId, body.status, body.correlationId, body.reasonCode, body.payloadJson);
        } else if (eventType == 'screening-completed') {
            CB_PlatformEventPublisher.publishScreeningCompleted(applicationId, accountId, body.status, body.correlationId, body.reasonCode, body.payloadJson);
        } else if (eventType == 'kyc-decision') {
            CB_PlatformEventPublisher.publishKycDecision(applicationId, accountId, body.status, body.correlationId, body.reasonCode, body.payloadJson);
        } else if (eventType == 'account-opened') {
            CB_PlatformEventPublisher.publishAccountOpened(applicationId, accountId, body.status, body.correlationId, body.reasonCode, body.payloadJson);
        } else {
            RestContext.response.statusCode = 400;
            return '{"error":"Unknown event type"}';
        }
        return '{"status":"accepted"}';
    }
}
