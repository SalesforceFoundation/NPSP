public with sharing class EOCR_Utilities {

    public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';

    public static final string ALGORITHM = 'RS256';
    public static final Integer VALID_FOR_SECONDS = 300;
    public static final string ISSUER = 'developer.force.com';

    public class EinsteinAuthException extends Exception {}

    //@AuraEnabled
    public static String getAccessToken() { 
        EOCR_JWT jwt = new EOCR_JWT(ALGORITHM, VALID_FOR_SECONDS);

        List<Einstein_OCR_Configuration__c> configs = [SELECT Id, Private_Key__c, Email__c
                                                        FROM Einstein_OCR_Configuration__c];
        if (configs.isEmpty()) {
            throw new EinsteinAuthException('Could not retrieve the Einstein OCR configuration.');
        }

        Einstein_OCR_Configuration__c config = configs[0];

        jwt.pkcs8 = config.Private_Key__c;
        jwt.iss = ISSUER;
        jwt.sub = config.Email__c;
        jwt.aud = AUTH;
        String accessToken = EOCR_JWTBearerFlow.getAccessToken(AUTH, jwt);

        system.debug(accessToken);
        return accessToken;
    }

}
