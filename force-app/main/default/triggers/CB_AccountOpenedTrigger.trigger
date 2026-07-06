trigger CB_AccountOpenedTrigger on CB_Account_Opened__e (after insert) {
    CB_AccountOpenedHandler.handle(Trigger.new);
}
