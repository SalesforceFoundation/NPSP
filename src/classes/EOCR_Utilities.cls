public with sharing class EOCR_Utilities {

    public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';
    private static String OCR_URL = 'https://api.einstein.ai/v2/vision/ocr';

    public static final string ALGORITHM = 'RS256';
    public static final Integer VALID_FOR_SECONDS = 300;
    public static final string ISSUER = 'developer.force.com';
    public static final Integer REQUEST_TIMEOUT = 30000;

    public class EinsteinAuthException extends Exception {}

    public static void connect() {
        String accessToken = getAccessToken();

        HttpRequest request = new HttpRequest();

        // set the headers
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Cache-Control', 'no-cache');
        
        // set the url
        request.setTimeout(REQUEST_TIMEOUT);
        request.setMethod('POST');
        request.setEndpoint(OCR_URL);

        // set the body
        String fileName = '@/Users/vmartinov/Desktop/checks/check1.jpeg';
        RequestBody bodyObject = new RequestBody('OCRModel',
                                      'text', 
                                      '');
        String body = bodyObject.getAsJson();
        request.setBody(body);
        
        // send the request
        Http http = new Http();
        HTTPResponse response = http.send(request);
        System.debug('response = ' + response.getBody());


    }

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

        system.debug('accessToken = ' + accessToken);
        return accessToken;
    }

    public class RequestBody {
        public String modelId;
        public String task;
        public String sampleBase64Content;

        public RequestBody(String theModel, String theTask, String theContent) {
            modelId = theModel;
            task = theTask;
            sampleBase64Content = theContent;
        }

        public String getAsJson() {
            return JSON.serialize(this);
        }
       
    }
}
