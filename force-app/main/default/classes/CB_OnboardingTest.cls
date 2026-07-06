@IsTest
private class CB_OnboardingTest {
    @IsTest
    static void testRetailOnboardingPass() {
        CB_RetailOnboardingActions.CreateRequest req = new CB_RetailOnboardingActions.CreateRequest();
        req.firstName = 'Anna';
        req.lastName = 'Smith';
        req.email = 'anna@example.com';
        req.testPersona = 'PASS';

        Test.startTest();
        List<CB_RetailOnboardingActions.CreateResult> results = CB_RetailOnboardingActions.createRetailApplication(
            new List<CB_RetailOnboardingActions.CreateRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, results[0].finalStatus);

        CB_Onboarding_Application__c app = [
            SELECT Status__c, KYC_Decision__c
            FROM CB_Onboarding_Application__c
            WHERE Id = :results[0].applicationId
        ];
        System.assertEquals(CB_OnboardingConstants.STATUS_COMPLETED, app.Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM CB_Fin_Account__c]);
    }

    @IsTest
    static void testRetailOnboardingSanctionsHit() {
        CB_RetailOnboardingActions.CreateRequest req = new CB_RetailOnboardingActions.CreateRequest();
        req.firstName = 'Bad';
        req.lastName = 'Actor';
        req.email = 'bad@example.com';
        req.testPersona = 'SANCTIONS_HIT';

        Test.startTest();
        List<CB_RetailOnboardingActions.CreateResult> results = CB_RetailOnboardingActions.createRetailApplication(
            new List<CB_RetailOnboardingActions.CreateRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(CB_OnboardingConstants.STATUS_UNDER_REVIEW, results[0].finalStatus);
        System.assert([SELECT COUNT() FROM Case WHERE CB_Onboarding_Application__c = :results[0].applicationId] > 0);
    }
}
