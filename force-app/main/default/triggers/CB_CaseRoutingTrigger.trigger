trigger CB_CaseRoutingTrigger on Case (before insert) {
    CB_CaseRoutingService.route(Trigger.new);
}
