public with sharing class CB_PartnerOnboardingActions {
    public class CreateRequest {
        @InvocableVariable(required=true) public String partnerName;
        @InvocableVariable(required=true) public String partnerId;
        @InvocableVariable public String testPersona;
    }

    public class CreateResult {
        @InvocableVariable public Id partnerAccountId;
        @InvocableVariable public Id partnerConfigId;
        @InvocableVariable public Id caseId;
        @InvocableVariable public String message;
        @InvocableVariable public String finalStatus;
    }

    @InvocableMethod(label='CB Create Partner Institution' description='Starts partner institution onboarding lifecycle')
    public static List<CreateResult> createPartnerInstitution(List<CreateRequest> requests) {
        List<CreateResult> results = new List<CreateResult>();
        for (CreateRequest req : requests) {
            String persona = String.isBlank(req.testPersona) ? 'PASS' : req.testPersona.toUpperCase();
            String correlationId = CB_Util.newCorrelationId();

            Account partnerAccount = new Account(
                Name = req.partnerName,
                CB_Is_Partner__c = true,
                CB_Customer_Status__c = 'Prospect'
            );
            insert partnerAccount;

            CB_Partner_Config__c config = new CB_Partner_Config__c(
                Partner_Account__c = partnerAccount.Id,
                Partner_Id__c = req.partnerId,
                Status__c = 'Onboarding',
                API_Client_Id__c = 'mock-' + req.partnerId,
                Rate_Tier__c = 'Standard'
            );
            insert config;

            Case partnerCase = CB_CaseFactory.createOnboardingCase(
                CB_OnboardingConstants.RT_PARTNER_DD,
                partnerAccount.Id,
                null,
                'Partner due diligence review',
                correlationId
            );

            CreateResult result = new CreateResult();
            result.partnerAccountId = partnerAccount.Id;
            result.partnerConfigId = config.Id;
            result.caseId = partnerCase.Id;

            if (persona == 'PASS') {
                CB_PartnerActivationService.activate(config.Id, correlationId);
                partnerCase.Status = 'Closed';
                update partnerCase;
                result.message = 'Partner activated';
                result.finalStatus = 'Active';
            } else {
                result.message = 'Partner DD case created';
                result.finalStatus = 'Onboarding';
            }
            results.add(result);
        }
        return results;
    }
}
