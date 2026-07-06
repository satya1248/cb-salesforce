trigger CB_PartnerActivatedTrigger on CB_Partner_Activated__e (after insert) {
    CB_PartnerActivatedHandler.handle(Trigger.new);
}
