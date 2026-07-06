// CB Wave 1 demo seed data — run with:
// sf apex run --target-org cb-dev --file scripts/seed-cb-demo.apex

CB_Integration_Settings__c settings = CB_Integration_Settings__c.getOrgDefaults();
if (settings == null) {
    settings = new CB_Integration_Settings__c();
}
settings.Ingress_Shared_Secret__c = 'cb-dev-ingress-secret';
settings.Async_Orchestration_Enabled__c = true;
upsert settings;

// Retail STP
CB_RetailOnboardingActions.CreateRequest passReq = new CB_RetailOnboardingActions.CreateRequest();
passReq.firstName = 'Anna';
passReq.lastName = 'Smith';
passReq.email = 'anna.demo@example.com';
passReq.testPersona = 'PASS';
CB_RetailOnboardingActions.createRetailApplication(new List<CB_RetailOnboardingActions.CreateRequest>{ passReq });

// Retail screening hit (for analyst resume demo)
CB_RetailOnboardingActions.CreateRequest hitReq = new CB_RetailOnboardingActions.CreateRequest();
hitReq.firstName = 'Bad';
hitReq.lastName = 'Actor';
hitReq.email = 'bad.demo@example.com';
hitReq.testPersona = 'SANCTIONS_HIT';
CB_RetailOnboardingActions.createRetailApplication(new List<CB_RetailOnboardingActions.CreateRequest>{ hitReq });

// SME clean
CB_SMEOnboardingActions.CreateRequest smeReq = new CB_SMEOnboardingActions.CreateRequest();
smeReq.companyName = 'Clean Trading Ltd';
smeReq.crn = CB_OnboardingConstants.CRN_CLEAN;
smeReq.testPersona = 'PASS';
CB_SMEOnboardingActions.createSmeApplication(new List<CB_SMEOnboardingActions.CreateRequest>{ smeReq });

// SME flagged KYB
CB_SMEOnboardingActions.CreateRequest smeFlagReq = new CB_SMEOnboardingActions.CreateRequest();
smeFlagReq.companyName = 'Flagged Holdings Ltd';
smeFlagReq.crn = CB_OnboardingConstants.CRN_FLAGGED;
smeFlagReq.testPersona = 'PASS';
CB_SMEOnboardingActions.createSmeApplication(new List<CB_SMEOnboardingActions.CreateRequest>{ smeFlagReq });

// Partner institution
CB_PartnerOnboardingActions.CreateRequest partnerReq = new CB_PartnerOnboardingActions.CreateRequest();
partnerReq.partnerName = 'Acme Partner Bank';
partnerReq.partnerId = 'PARTNER-DEMO-001';
partnerReq.testPersona = 'PASS';
CB_PartnerOnboardingActions.createPartnerInstitution(new List<CB_PartnerOnboardingActions.CreateRequest>{ partnerReq });

// Schedule daily expiry job if not already scheduled
if ([SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'CB Application Expiry Daily'] == 0) {
    CB_ApplicationExpiryScheduler.scheduleDaily();
}

System.debug('CB demo seed complete');
