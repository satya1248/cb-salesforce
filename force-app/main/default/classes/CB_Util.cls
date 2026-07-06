public with sharing class CB_Util {
    public static String newCorrelationId() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(128)).left(32);
    }

    public static String generateApiSecret() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(128));
    }
}
