public with sharing class CB_MockOrchestrator {
  public class Request {
    @InvocableVariable(required=true)
    public Id applicationId;
    @InvocableVariable
    public String testPersona;
    @InvocableVariable
    public String crn;
  }

  public class Result {
    @InvocableVariable
    public String message;
    @InvocableVariable
    public String finalStatus;
  }

  @InvocableMethod(label='CB Run Mock Onboarding' description='Runs Wave 1 mock IDV, bureau, screening, KYC and core account open')
  public static List<Result> runMockOnboarding(List<Request> requests) {
    List<Result> results = new List<Result>();
    for (Request req : requests) {
      if (String.isNotBlank(req.crn)) {
        results.add(runSmeSingle(req.applicationId, req.crn, req.testPersona));
      } else {
        results.add(runRetailSingle(req.applicationId, req.testPersona));
      }
    }
    return results;
  }

  public static Result runSingle(Id applicationId, String testPersona) {
    return runRetailSingle(applicationId, testPersona);
  }

  public static Result runRetailSingle(Id applicationId, String testPersona) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    String persona = normalize(personaOrDefault(testPersona));
    String correlationId = correlationFor(app);

    CB_IntegrationLogService.log('mock/prescore', 'Inbound', 200, 'Success', correlationId, applicationId, persona, '{"riskTier":"Low"}');
    update new CB_Onboarding_Application__c(
      Id = applicationId,
      Correlation_Id__c = correlationId,
      Risk_Tier__c = isHighRiskPersona(persona) ? 'High' : 'Low',
      Status__c = CB_OnboardingConstants.STATUS_IDV_PENDING,
      Submitted_Date__c = System.now()
    );

    String idvStatus = resolveIdvStatus(persona);
    CB_IDVCompletedHandler.handleFromStatus(applicationId, app.Account__c, idvStatus, correlationId);
    if (idvStatus != CB_OnboardingConstants.IDV_PASS) {
      return result('IDV ' + idvStatus, currentStatus(applicationId));
    }

    CB_BureauService.VerifyResult bureau = CB_BureauService.verify(resolveBureauPersona(persona));
    if (!CB_BureauService.handleBureauResult(applicationId, app.Account__c, bureau.matchStrength, correlationId)) {
      return result('Proof of address required', CB_OnboardingConstants.STATUS_UNDER_REVIEW);
    }

    String screeningStatus = resolveScreeningStatus(persona);
    CB_ScreeningCompletedHandler.handleFromStatus(applicationId, app.Account__c, screeningStatus, correlationId);
    if (screeningStatus != 'CLEAR') {
      return result('Screening review required', CB_OnboardingConstants.STATUS_UNDER_REVIEW);
    }

    String kycDecision = resolveKycDecision(persona);
    CB_KYCDecisionHandler.handleFromStatus(applicationId, app.Account__c, kycDecision, correlationId);
    if (kycDecision == CB_OnboardingConstants.KYC_REFER) {
      return result('KYC refer', CB_OnboardingConstants.STATUS_UNDER_REVIEW);
    }
    if (kycDecision != CB_OnboardingConstants.KYC_APPROVE) {
      return result('KYC ' + kycDecision, CB_OnboardingConstants.STATUS_REJECTED);
    }

    return openAccount(applicationId, app);
  }

  public static Result runSmeSingle(Id applicationId, String crn, String testPersona) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    String persona = normalize(personaOrDefault(testPersona));
    String correlationId = correlationFor(app);

    update new CB_Onboarding_Application__c(
      Id = applicationId,
      Correlation_Id__c = correlationId,
      CRN__c = crn,
      Entity_Type__c = 'Limited_Company',
      Status__c = CB_OnboardingConstants.STATUS_IN_PROGRESS,
      Submitted_Date__c = System.now()
    );

    CB_CompaniesHouseService.CompanyProfile profile = CB_CompaniesHouseService.lookup(crn);
    if (!CB_CompaniesHouseService.handleKybProfile(applicationId, app.Account__c, profile, correlationId)) {
      if (profile.dissolved) {
        return result('Company dissolved', CB_OnboardingConstants.STATUS_REJECTED);
      }
      return result('KYB review required', CB_OnboardingConstants.STATUS_UNDER_REVIEW);
    }

    return runRetailSingle(applicationId, persona);
  }

  public static Result resumeFromIdv(Id applicationId) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    String correlationId = correlationFor(app);
    CB_IDVCompletedHandler.handleFromStatus(applicationId, app.Account__c, CB_OnboardingConstants.IDV_PASS, correlationId);
    return continueAfterIdv(applicationId, app, correlationId);
  }

  public static Result resumeFromBureau(Id applicationId) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    return continueAfterBureau(applicationId, app, correlationFor(app));
  }

  public static Result resumeFromScreening(Id applicationId) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    return continueAfterScreening(applicationId, app, correlationFor(app));
  }

  public static Result resumeFromKyc(Id applicationId) {
    CB_Onboarding_Application__c app = CB_OnboardingApplicationService.getRequired(applicationId);
    return continueAfterKyc(applicationId, app, correlationFor(app));
  }

  public static Result resumeFromKyb(Id applicationId) {
    return runRetailSingle(applicationId, 'PASS');
  }

  private static Result continueAfterIdv(Id applicationId, CB_Onboarding_Application__c app, String correlationId) {
    return continueAfterBureau(applicationId, app, correlationId);
  }

  private static Result continueAfterBureau(Id applicationId, CB_Onboarding_Application__c app, String correlationId) {
    return continueAfterScreening(applicationId, app, correlationId);
  }

  private static Result continueAfterScreening(Id applicationId, CB_Onboarding_Application__c app, String correlationId) {
    CB_ScreeningCompletedHandler.handleFromStatus(applicationId, app.Account__c, 'CLEAR', correlationId);
    return continueAfterKyc(applicationId, app, correlationId);
  }

  private static Result continueAfterKyc(Id applicationId, CB_Onboarding_Application__c app, String correlationId) {
    CB_KYCDecisionHandler.handleFromStatus(applicationId, app.Account__c, CB_OnboardingConstants.KYC_APPROVE, correlationId);
    return openAccount(applicationId, app);
  }

  private static Result openAccount(Id applicationId, CB_Onboarding_Application__c app) {
    String coreFinId = 'MOCK-FA-' + String.valueOf(Crypto.getRandomInteger()).replace('-', '');
    Map<String, Object> payload = new Map<String, Object>{
      'coreFinAccountId' => coreFinId,
      'sortCode' => '04-00-04',
      'accountNumber' => '12345678'
    };
    CB_AccountOpenedHandler.handleFromPayload(applicationId, app.Account__c, JSON.serialize(payload), app.Correlation_Id__c);
    return result('Account opened', CB_OnboardingConstants.STATUS_COMPLETED);
  }

  private static String resolveIdvStatus(String persona) {
    if (persona == 'REFER' || persona == 'IDV_REFER') {
      return CB_OnboardingConstants.IDV_REFER;
    }
    if (persona == 'FAIL' || persona == 'IDV_FAIL' || persona == 'DECLINE') {
      return CB_OnboardingConstants.IDV_FAIL;
    }
    return CB_OnboardingConstants.IDV_PASS;
  }

  private static String resolveBureauPersona(String persona) {
    if (persona == CB_OnboardingConstants.BUREAU_WEAK || persona == CB_OnboardingConstants.BUREAU_NONE) {
      return persona;
    }
    return CB_OnboardingConstants.BUREAU_STRONG;
  }

  private static String resolveScreeningStatus(String persona) {
    if (persona == 'SANCTIONS_HIT' || persona == 'PEP_HIT' || persona == 'ADVERSE_MEDIA') {
      return 'POTENTIAL_MATCH';
    }
    if (persona == 'CLEAR') {
      return 'CLEAR';
    }
    return 'CLEAR';
  }

  private static String resolveKycDecision(String persona) {
    if (persona == 'KYC_REFER') {
      return CB_OnboardingConstants.KYC_REFER;
    }
    if (persona == 'KYC_DECLINE') {
      return CB_OnboardingConstants.KYC_DECLINE;
    }
    return CB_OnboardingConstants.KYC_APPROVE;
  }

  private static Boolean isHighRiskPersona(String persona) {
    return persona == 'SANCTIONS_HIT' || persona == 'PEP_HIT' || persona == 'ADVERSE_MEDIA' || persona == 'KYC_DECLINE';
  }

  private static String personaOrDefault(String testPersona) {
    return String.isBlank(testPersona) ? 'PASS' : testPersona;
  }

  private static String normalize(String persona) {
    return persona.toUpperCase();
  }

  private static String correlationFor(CB_Onboarding_Application__c app) {
    return String.isBlank(app.Correlation_Id__c) ? CB_Util.newCorrelationId() : app.Correlation_Id__c;
  }

  private static String currentStatus(Id applicationId) {
    return [SELECT Status__c FROM CB_Onboarding_Application__c WHERE Id = :applicationId LIMIT 1].Status__c;
  }

  private static Result result(String message, String status) {
    Result r = new Result();
    r.message = message;
    r.finalStatus = status;
    return r;
  }
}
