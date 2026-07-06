public with sharing class CB_CaseRoutingService {
    private static Map<String, Id> queueIdByDevName;

    private static Id queueId(String devName) {
        if (queueIdByDevName == null) {
            queueIdByDevName = new Map<String, Id>();
            for (Group g : [
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = 'Queue' AND DeveloperName IN ('CB_KYC_Queue','CB_Screening_Queue','CB_KYB_Queue','CB_Partner_Queue','CB_Service_Queue')
            ]) {
                queueIdByDevName.put(g.DeveloperName, g.Id);
            }
        }
        return queueIdByDevName.get(devName);
    }

    public static void route(List<Case> newCases) {
        Map<Id, String> rtDevNameById = new Map<Id, String>();
        for (Schema.RecordTypeInfo rti : Schema.SObjectType.Case.getRecordTypeInfos()) {
            if (rti.getRecordTypeId() != null) {
                rtDevNameById.put(rti.getRecordTypeId(), rti.getDeveloperName());
            }
        }

        for (Case c : newCases) {
            if (c.OwnerId != null) {
                continue;
            }
            String rtDev = c.RecordTypeId == null ? null : rtDevNameById.get(c.RecordTypeId);
            if (rtDev == null) {
                continue;
            }
            if (rtDev == CB_OnboardingConstants.RT_KYC_CDD) {
                Id q = queueId('CB_KYC_Queue');
                if (q != null) c.OwnerId = q;
            } else if (rtDev == CB_OnboardingConstants.RT_SCREENING) {
                Id q = queueId('CB_Screening_Queue');
                if (q != null) c.OwnerId = q;
            } else if (rtDev == CB_OnboardingConstants.RT_KYB_REVIEW) {
                Id q = queueId('CB_KYB_Queue');
                if (q != null) c.OwnerId = q;
            } else if (rtDev == CB_OnboardingConstants.RT_PARTNER_DD) {
                Id q = queueId('CB_Partner_Queue');
                if (q != null) c.OwnerId = q;
            } else if (rtDev == CB_OnboardingConstants.RT_OPS_SERVICE) {
                Id q = queueId('CB_Service_Queue');
                if (q != null) c.OwnerId = q;
            }
        }
    }
}
