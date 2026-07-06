trigger CB_IDVCompletedTrigger on CB_IDV_Completed__e (after insert) {
    CB_IDVCompletedHandler.handle(Trigger.new);
}
