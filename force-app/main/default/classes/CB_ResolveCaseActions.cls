public with sharing class CB_ResolveCaseActions {
    public class Request {
        @InvocableVariable(required=true) public Id caseId;
        @InvocableVariable public String resolution;
        @InvocableVariable public Boolean clearAndContinue;
    }

    public class Result {
        @InvocableVariable public Id caseId;
        @InvocableVariable public Id applicationId;
        @InvocableVariable public String message;
        @InvocableVariable public String finalStatus;
    }

    @InvocableMethod(label='CB Resolve Onboarding Case' description='Closes an onboarding-related case and optionally resumes the application')
    public static List<Result> resolve(List<Request> requests) {
        Set<Id> caseIds = new Set<Id>();
        for (Request r : requests) {
            if (r.caseId != null) caseIds.add(r.caseId);
        }

        Map<Id, Case> casesById = caseIds.isEmpty()
            ? new Map<Id, Case>()
            : new Map<Id, Case>([
                SELECT Id, Status, CB_Onboarding_Application__c, RecordType.DeveloperName
                FROM Case
                WHERE Id IN :caseIds
            ]);

        List<Case> toUpdate = new List<Case>();
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Case c = casesById.get(req.caseId);
            Result r = new Result();
            r.caseId = req.caseId;
            r.applicationId = c == null ? null : c.CB_Onboarding_Application__c;

            if (c == null) {
                r.message = 'Case not found';
                results.add(r);
                continue;
            }

            toUpdate.add(new Case(Id = c.Id, Status = 'Closed'));

            if (req.clearAndContinue == true && c.CB_Onboarding_Application__c != null) {
                CB_MockOrchestrator.Result resumeResult = CB_OnboardingResumeService.resumeAfterCase(
                    c.CB_Onboarding_Application__c,
                    c.RecordType.DeveloperName
                );
                r.message = resumeResult.message;
                r.finalStatus = resumeResult.finalStatus;
            } else {
                r.message = 'Closed case';
            }
            results.add(r);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return results;
    }
}
