public with sharing class CB_MockOrchestrator {
  public class Request {
    @InvocableVariable(required=true)
    public Id applicationId;
    @InvocableVariable
    public String testPersona;
  }

  public class Result {
    @InvocableVariable
    public String message;
    @InvocableVariable
    public String finalStatus;
  }

  @InvocableMethod(label='CB Run Mock Onboarding' description='Runs Wave 1 mock IDV, screening, KYC and core account open')
  public static List<Result> runMockOnboarding(List<Request> requests) {
    List<Result> results = new List<Result>();
    for (Request req : requests) {
      results.add(runSingle(req.applicationId, req.testPersona));
    }
    return results;
  }

  public static Result runSingle(Id applicationId, String testPersona) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    String persona = String.isBlank(testPersona) ? 'PASS' : testPersona.toUpperCase();
    String correlationId = String.isBlank(app.Correlation_Id__c)
      ? CB_Util.newCorrelationId()
      : app.Correlation_Id__c;

    CB_IntegrationLogService.log('mock/prescore', 'Inbound', 200, 'Success', correlationId, applicationId, persona, '{"riskTier":"Low"}');
    update new CB_Onboarding_Application__c(
      Id = applicationId,
      Correlation_Id__c = correlationId,
      Risk_Tier__c = persona == 'SANCTIONS_HIT' ? 'High' : 'Low',
      Status__c = CB_OnboardingConstants.STATUS_IDV_PENDING,
      Submitted_Date__c = System.now()
    );

    String idvStatus = resolveIdvStatus(persona);
    CB_IDVCompletedHandler.handleFromStatus(applicationId, app.Account__c, idvStatus, correlationId);

    if (idvStatus != CB_OnboardingConstants.IDV_PASS) {
      return result('IDV ' + idvStatus, CB_OnboardingConstants.STATUS_UNDER_REVIEW);
    }

    String screeningStatus = persona == 'SANCTIONS_HIT' ? 'POTENTIAL_MATCH' : 'CLEAR';
    CB_ScreeningCompletedHandler.handleFromStatus(applicationId, app.Account__c, screeningStatus, correlationId);

    if (screeningStatus != 'CLEAR') {
      return result('Screening review required', CB_OnboardingConstants.STATUS_UNDER_REVIEW);
    }

    String kycDecision = persona == 'DECLINE' ? CB_OnboardingConstants.KYC_DECLINE : CB_OnboardingConstants.KYC_APPROVE;
    CB_KYCDecisionHandler.handleFromStatus(applicationId, app.Account__c, kycDecision, correlationId);

    if (kycDecision != CB_OnboardingConstants.KYC_APPROVE) {
      return result('KYC ' + kycDecision, CB_OnboardingConstants.STATUS_REJECTED);
    }

    String coreFinId = 'MOCK-FA-' + String.valueOf(Crypto.getRandomInteger()).replace('-', '');
    Map<String, Object> payload = new Map<String, Object>{
      'coreFinAccountId' => coreFinId,
      'sortCode' => '04-00-04',
      'accountNumber' => '12345678'
    };
    CB_AccountOpenedHandler.handleFromPayload(applicationId, app.Account__c, JSON.serialize(payload), correlationId);
    return result('Account opened', CB_OnboardingConstants.STATUS_COMPLETED);
  }

  private static String resolveIdvStatus(String persona) {
    if (persona == 'REFER') {
      return CB_OnboardingConstants.IDV_REFER;
    }
    if (persona == 'FAIL' || persona == 'DECLINE') {
      return CB_OnboardingConstants.IDV_FAIL;
    }
    return CB_OnboardingConstants.IDV_PASS;
  }

  private static Result result(String message, String status) {
    Result r = new Result();
    r.message = message;
    r.finalStatus = status;
    return r;
  }
}
