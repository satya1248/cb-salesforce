trigger CB_OnboardingSubmittedTrigger on CB_Onboarding_Submitted__e (after insert) {
    CB_OnboardingSubmittedHandler.handle(Trigger.new);
}
