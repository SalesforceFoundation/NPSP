/**
* @author Salesforce.org
* @date 2020
* @group GE
* @group-content
* @description class to get the Eistein OCR JWT using the AUTH endpoint
*/
public class EOCR_JWTBearerFlow {

    /*
    * @description method get the access token
    * @param String the endpoint url
    * @param EOCR_JWT the jwt
    * @return String the access token
    */
    public static String getAccessToken(String tokenEndpoint, EOCR_JWT jwt) {
    
        String access_token = null;
        String body = 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt.issue();
        HttpRequest req = new HttpRequest();                            
        req.setMethod('POST');
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        req.setBody(body);
        Http http = new Http();               
        HTTPResponse res = http.send(req);
        
        if ( res.getStatusCode() == 200 ) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        return access_token;
        
    }
}
