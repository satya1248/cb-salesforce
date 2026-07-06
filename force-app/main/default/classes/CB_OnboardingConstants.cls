public with sharing class CB_OnboardingConstants {
    public static final String PRODUCT_CURR_RETAIL = 'CB_CURR_RETAIL_UK';
    public static final String PRODUCT_CURR_SME = 'CB_CURR_SME_UK';
    public static final String APP_TYPE_RETAIL = 'Retail';
    public static final String APP_TYPE_SME = 'SME';
    public static final String APP_TYPE_PARTNER_CUSTOMER = 'Partner_Customer';
    public static final String CHANNEL_WEB = 'Web';
    public static final String CHANNEL_PARTNER_API = 'Partner_API';

    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_IN_PROGRESS = 'In_Progress';
    public static final String STATUS_IDV_PENDING = 'IDV_Pending';
    public static final String STATUS_KYC_PENDING = 'KYC_Pending';
    public static final String STATUS_UNDER_REVIEW = 'Under_Review';
    public static final String STATUS_CORE_PROCESSING = 'Core_Processing';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_REJECTED = 'Rejected';

    public static final String IDV_PASS = 'Pass';
    public static final String IDV_REFER = 'Refer';
    public static final String IDV_FAIL = 'Fail';

    public static final String KYC_APPROVE = 'Approve';
    public static final String KYC_REFER = 'Refer';
    public static final String KYC_DECLINE = 'Decline';

    public static final String BUREAU_STRONG = 'STRONG_MATCH';
    public static final String BUREAU_WEAK = 'WEAK_MATCH';
    public static final String BUREAU_NONE = 'NO_MATCH';

    public static final String CRN_CLEAN = '12345678';
    public static final String CRN_FLAGGED = '87654321';
    public static final String CRN_DISSOLVED = '11111111';

    public static final Integer APPLICATION_EXPIRY_DAYS = 30;

    public static final String RT_KYC_CDD = 'CB_KYC_CDD';
    public static final String RT_SCREENING = 'CB_Screening';
    public static final String RT_KYB_REVIEW = 'CB_KYB_Review';
    public static final String RT_PARTNER_DD = 'CB_Partner_DD';
    public static final String RT_OPS_SERVICE = 'CB_Ops_Service';
}
