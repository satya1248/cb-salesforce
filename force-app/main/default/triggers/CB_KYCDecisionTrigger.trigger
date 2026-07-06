trigger CB_KYCDecisionTrigger on CB_KYC_Decision__e (after insert) {
    CB_KYCDecisionHandler.handle(Trigger.new);
}
