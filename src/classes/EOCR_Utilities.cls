/**
* @author Salesforce.org
* @date 2020
* @group GE
* @group-content
* @description provides utility methods to analyze the text in scannned images
*/
public with sharing class EOCR_Utilities {
    // TODO
    // decide which methods can be made private

    public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';
    private static String OCR_URL = 'https://api.einstein.ai/v2/vision/ocr';

    public static final string ALGORITHM = 'RS256';
    public static final Integer VALID_FOR_SECONDS = 300;
    public static final string ISSUER = 'developer.force.com';
    public static final Integer REQUEST_TIMEOUT = 30000;

    // custom exception class for Einstein OCR
    public class EinsteinAuthException extends Exception {}


    /*
    * @description method to process the images captured with input file html element
    * @param String check document id
    * @param String reply device document id
    * @param String other document id
    */
    @AuraEnabled
    public static void processMobileGift(String checkBase64) {

        // TODO
        // decide if we are going to use input file html element
        // add 2 new params: device base 64 and other base 64
        // and implement the method
        // System.debug('submitted checkBase64 = ' + checkBase64);
        
    }



    /*
    * @description method to process the images captured with lightning-file-upload
    * @param String check document id
    * @param String reply device document id
    * @param String other document id
    */
    @AuraEnabled
    public static void processMobileGift(String checkDocumentId, 
                                String deviceDocumentId,
                                String otherDocumentId) {

        // TODO
        // decide if we are going to use lightning-file-upload
        // and implement the method
    }

    /*
    * @description method to analyze the images attached to the gift record
    */
    public static void analyzeGift() {
        String giftName = 'Scanned Gift-00003';
        String base64ImageContent = getBase64ImageContent(giftName);
        //system.debug('base64ImageContent = ' + base64ImageContent);

        analyzeText(base64ImageContent);

        // TODO
        // this method will need to take the gift as a parameter, instead of hard-coding it
        // it will also need to check how many images are attached
        // identify the check and reply device and analyze them
    }

    /*
    * @description method to analyze the image encoded in base 64
    * @param String encoded image
    */
    public static void analyzeText(String base64ImageContent) {
        String model = 'OCRModel';
        String task = 'text';

        makeRequest(model, task, base64ImageContent);

        // TODO
        // we will most likely use a 'check' template to pass as a parameter
        // instead of using 'text'
        // once the functionality is ready in einstein ocr
    }

    /*
    * @description method to submit the analyze request to EOCR endpoint
    * @param String model to be used
    * @param String task (template)
    * @param String encoded image
    */
    public static void makeRequest(String model, String task, String base64ImageContent) {
        // get token
        String accessToken = getAccessToken();

        // create request
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
        RequestBody bodyObject = new RequestBody(model, task, base64ImageContent);
        String body = bodyObject.getAsJson();
        request.setBody(body);
        
        // send the request
        Http http = new Http();
        HTTPResponse response = http.send(request);

        // TODO
        // add error handling
        // System.debug('response = ' + response.getBody());
    }

    /*
    * @description method to get the base 64 encoding for an image attached to a gift
    * @param String gift record name
    * @return String encoded image
    */
    public static String getBase64ImageContent(String giftName) {

        // TODO
        // this method assumes there is only one image attached to a gift
        // add a parameter to specify if we want to get the check or the reply device
        // add handling of case where ContentDocumentLink is not found
        // and ContentVersion is not found

        // get the gift record
        List<Einstein_OCR_Gift__c> gifts = [SELECT Id, Name
                                            FROM Einstein_OCR_Gift__c
                                            WHERE Name = :giftName];

        if (!gifts.isEmpty()) {
            // get the content document link
            ContentDocumentLink cdl = [SELECT ContentDocumentId 
                                       FROM ContentDocumentLink 
                                       WHERE LinkedEntityId = :gifts[0].Id];

            // get the content file (version)
            ContentVersion cv = [SELECT VersionData 
                                 FROM ContentVersion 
                                 WHERE ContentDocumentId = :cdl.ContentDocumentId];

            String base64ImageContent = EncodingUtil.base64Encode(cv.VersionData);
            return base64ImageContent;
        }

        return null;
    }

    
    /*
    * @description gets the EOCR access token (JWT)
    * @return String access token
    */
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

        // TODO
        // decide what to do if we fail to get the JWT
        
        //system.debug('accessToken = ' + accessToken);
        return accessToken;
    }

    /*
    * @description class to store the request content for analyzing text
    * @return String access token
    */
    public class RequestBody {
        public String modelId;
        public String task;
        public String sampleBase64Content;

        /*
        * @description constructor
        * @param String the model
        * @param String the task
        * @param String the base 64 content
        */
        public RequestBody(String theModel, String theTask, String theContent) {
            modelId = theModel;
            task = theTask;
            sampleBase64Content = theContent;
        }

        /*
        * @description returns the clas instance as json
        * @return String 
        */
        public String getAsJson() {
            return JSON.serialize(this);
        }
       
    }
}
