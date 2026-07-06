trigger CB_ScreeningCompletedTrigger on CB_Screening_Completed__e (after insert) {
    CB_ScreeningCompletedHandler.handle(Trigger.new);
}
