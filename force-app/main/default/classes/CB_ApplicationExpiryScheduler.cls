public with sharing class CB_ApplicationExpiryScheduler {
    public static String scheduleDaily() {
        return System.schedule(
            'CB Application Expiry Daily',
            '0 0 2 * * ?',
            new CB_ApplicationExpiryBatch()
        );
    }
}
