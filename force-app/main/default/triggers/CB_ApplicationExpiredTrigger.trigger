trigger CB_ApplicationExpiredTrigger on CB_Application_Expired__e (after insert) {
    CB_ApplicationExpiredHandler.handle(Trigger.new);
}
