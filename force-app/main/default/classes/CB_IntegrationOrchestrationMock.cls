@IsTest
public class CB_IntegrationOrchestrationMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
        Id applicationId = Id.valueOf((String) body.get('applicationId'));
        String applicationType = (String) body.get('applicationType');
        String testPersona = (String) body.get('testPersona');
        String crn = (String) body.get('crn');

        if (applicationType == CB_OnboardingConstants.APP_TYPE_SME) {
            CB_MockOrchestrator.runSmeSingle(applicationId, crn, testPersona);
        } else {
            CB_MockOrchestrator.runRetailSingle(applicationId, testPersona);
        }

        HttpResponse response = new HttpResponse();
        response.setStatusCode(202);
        response.setBody('{"status":"accepted"}');
        return response;
    }
}
