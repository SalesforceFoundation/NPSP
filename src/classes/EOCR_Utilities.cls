public with sharing class EOCR_Utilities {

    public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';
    public class EinsteinAuthException extends Exception {}

    //@AuraEnabled
    public static String getAccessToken() { 
        EOCR_JWT jwt = new EOCR_JWT('RS256');

        List<Einstein_OCR_Configuration__c> configs = [SELECT Id, Private_Key__c, Email__c
                                                        FROM Einstein_OCR_Configuration__c];
        if (configs.isEmpty()) {
            throw new EinsteinAuthException('Could not retrieve the Einstein OCR configuration.');
        }

        Einstein_OCR_Configuration__c config = configs[0];

        jwt.pkcs8 = config.Private_Key__c;
        jwt.iss = 'developer.force.com';
        jwt.sub = config.Email__c;
        jwt.aud = AUTH;
        jwt.validFor = integer.valueOf(300);
        String accessToken = EOCR_JWTBearerFlow.getAccessToken(AUTH, jwt);

        system.debug(accessToken);
        return accessToken;
    }

}
