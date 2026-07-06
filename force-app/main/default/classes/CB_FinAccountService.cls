public with sharing class CB_FinAccountService {
    public static CB_Fin_Account__c createMirrorAccount(
        Id customerAccountId,
        Id applicationId,
        String coreFinAccountId,
        String sortCode,
        String accountNumber,
        String productCode
    ) {
        CB_Fin_Account__c finAccount = new CB_Fin_Account__c(
            Account__c = customerAccountId,
            Onboarding_Application__c = applicationId,
            Core_Fin_Account_Id__c = coreFinAccountId,
            Product_Code__c = productCode,
            Product_Type__c = 'Current_Account',
            Status__c = 'Active',
            Sort_Code__c = sortCode,
            Account_Number__c = accountNumber,
            IBAN_Last4__c = accountNumber == null ? null : accountNumber.right(4)
        );
        insert finAccount;
        return finAccount;
    }
}
