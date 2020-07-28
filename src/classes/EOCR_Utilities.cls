public with sharing class EOCR_Utilities {

    public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';
    public class EinsteinAuthException extends Exception {}

    //@AuraEnabled
    public static String getAccessToken() { 
        EOCR_JWT jwt = new EOCR_JWT('RS256');

        jwt.pkcs8 = 'MIIEowIBAAKCAQEAiUqsRLqQrTbWWrm8Vyv7sH2oADiFmmLWyShOyBQcXQUJdD6L' + 
        '57QIi2I1+SQQqAG5npv5CRgx8tNfK2jVCFiV5GKPZG/f0iXIvk912xEhfjQ4/6NL' +
        'WhEpyAdTulhRbFpqIhcRHOnO5kJlhoVbvydVDmqEttXkTmgyGnPnxC0b6/T3lFyQ' +
        'TWIW0TRCk1seynjMr69sayLOjpZZpSm1VKWKc8Wwe8C97HLEYsCKm7P9IxdILvlr' +
        'lJRiDp5C2d7YhyiU1HXZUfkuwi58hnShL+vLbJWbPvaYEcTmd3IS/J9H5GngYtRT' +
        'uZdFVFb/zCKuE2G+atMBEb/PT9+ravPp9fbp/wIDAQABAoIBAGzxoXPEa+vXmQ9T' +
        'Vd4Cm+24OKk8MOCK0A+9+Y4RT1SNG6xvuYs6tJEOdO/nq4P2Inp3II4T8gbTrjB/' +
        'NpUx3nflsg2sLPrQWtSRr18P3/kKrbRFuxSUjAgbsFgtnycRNCkrDrxX2IOlanTt' +
        'vBkauAcBhaCkaE/DpQaStPZaKU751bB3ARXqGbYngtpA93S/oGLL3jr5d2qES09s' +
        'bHhPxrpQDEN+6N5UeBbfOaV3M9klCCdpmx+3/ZMB9psr20u93zUxRtTWc79goHjs' +
        'RdatVw9fPwliBliMDnGfssVY6qGkssKu8Urt8H4hAoX3rmVp/qkBi53dQXQFmNMb' +
        'FRLOnokCgYEA+lflJOgw2BdI0CHYzTVDQK1LVz0waqe6Lflvjw9zgSgD7Z1YFMig' +
        'f+FFjnMnwvq8FYdXyE1umGYhLEXNkjDniOOj9hk8VhleFv5bSIpupgHK21LcxCDM' +
        'MbhtO9PXYRfkfLZ6isIhkX62cZkb+7JJDQ4T1oI4PG2gwVGRKkdC/DUCgYEAjGTV' +
        'VczbR0zX9BiZDsAEBl0N4MJrQgeJp2HUkJC8jF/kNO2BbzMfwxgB1Q4EAyQS/Jo5' +
        'MTl6GwYdKIzWvN7KoPUa5kcrWxv4um3X1R/jdXcMOmiHfDKvsGkykctvYOQ4xZ8P' +
        'p9kWDyN7CDxWtkC+QR87nc/CpftrcfCbexsvC+MCgYBT8w+jbb2baUuAiCkkv3y6' +
        '/qHqMlm/Glnjuua/KaZJJHsUvpPf/FteJtPlbhZiWyShb45vXA//SRhMuWezY3Tx' +
        'Qa0lBNdn4//aZBeGXu21+5nkLIhduMXg0oDG9EYgiBuV+rdjOrB5Eu3pcDejEulO' +
        'WG8smuRy1yx2R30PmXAMFQKBgFF2wQOEV0jMIhMVotqYOL2oiUD+D1bFIO7rKXip' +
        'Q38AtV6w4gYwWCHQcF+8Pj/EUvAYXU9e1qePqKO69W+qp1E2aGFuso2vcWhcDH0y' +
        'f73NUl8iAFvk3WUz5ZALx5klVHv3jBINOWuXXvCscnRWpQ8MnH856ux9Mx9uSgnp' +
        'ACeZAoGBAPTmbuAiIgBAJ0OPIA5kOh8uawRPaGkPmB/d84wXYAu2eNvIrsytpWR2' +
        'XFlkTx5PaMP04iyOJgUTLHznYxXX06cAQEPo7cP7Z4qv39Tys/dKl3lqEMsLSlzm' +
        'YIO7nQ7GownMJm8mFO9dk9Ny7fD82hmjWGLQEQLMjvbjf0zPQ3sC';

        jwt.iss = 'developer.force.com';
        jwt.sub = 'vmartinov@salesforce.com';
        jwt.aud = AUTH;
        jwt.validFor = integer.valueOf(300);
        String accessToken = EOCR_JWTBearerFlow.getAccessToken(AUTH, jwt);

        system.debug(accessToken);
        return accessToken;
    }

    /*
    @AuraEnabled
    public static String getAccessToken_old() {

        EinsteinVision__c EV = EinsteinVision__c.getInstance();
        EOCR_JWT jwt = new EOCR_JWT('RS256');

        if (EV.CertName__c == null && EV.CertFile__c!=null){
        //newer file-based key version
        try{
            ContentVersion base64Content = [SELECT Title, VersionData FROM ContentVersion where Title=:EV.CertFile__c ORDER BY Title LIMIT 1];
            String keyContents = base64Content.VersionData.tostring();
            keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
            keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
            keyContents = keyContents.replace('\n', '');
            jwt.pkcs8 = keyContents;
        } catch (exception e){
            throw new AuraHandledException('The certificate file was not found.  Check that it is installed, named correctly in the custom settings, and visible to all users who need to use it');
        }
        //older self-signed certificate-based version
        } else if (EV.CertName__c != null && EV.CertFile__c==null){
            jwt.cert = EV.CertName__c;
        } else {
            throw new EinsteinAuthException('Your custom settings are not set up properly.  Either CertFile or CertName should be populated');
        }

       // there's a default stting, but it's still configurable.  Uses the default if you aren't configured.
        if (EV.certificateIssuer__c != null){
            jwt.iss = EV.certificateIssuer__c;
        } else {
            jwt.iss = 'developer.force.com';
        }
        jwt.sub = EV.EinsteinUsername__c;
        jwt.aud = AUTH;
        jwt.validFor = integer.valueOf(EV.TokenExpirationTime__c);
        String access_token = EOCR_JWTBearerFlow.getAccessToken(AUTH, jwt);

        system.debug(access_token);
        return access_token;
    }*/

}
