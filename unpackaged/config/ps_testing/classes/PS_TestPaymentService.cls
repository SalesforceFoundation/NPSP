public with sharing class PS_TestPaymentService {
   
    // JWT secret key
    // TODO: use the value stored in the protected object when available
    private static final string API_SECRET_KEY = 'a5146b4b-3d2b-4fc4-a5e5-8387968859a4';

    // JWT payload; exp is in miliseconds - we make the JWT valid for 1 minute
    private static final Map<String, String> JWT_PAYLOAD = 
            new Map<String, String> { 'iss' => 'ApiKeyManager',
                                      'sub' => UserInfo.getUserName(),
                                      'sfdo.roles' => 'Payments.Purchase',
                                      'sfdo.product' => 'CRM',
                                      'exp' => String.valueOf(Datetime.now().getTime() + 60 * 1000)};

    // endpoints
    // TODO: at the moment we use the dev1 env, we should replace with a QA env when it becomes available
    private static final String ENDPOINT_ROOT = 'https://7jpea5zk79.execute-api.us-west-2.amazonaws.com/v1/payments';
    private static final String TOKENIZE_ENDPOINT = '/public/tokens';
    private static final String PURCHASE_ENDPOINT = '/verified/purchase';
    private static final String TOKEN_FIELD_NAME = 'token';

    // TODO: use Org id 
    private static final String PRODUCT_ID = '00D6g0000000000EAA';

    /**
     * @description method for testing the end to end payment processing
     * @return  Boolean: true is successful, false if failed
     */
    public static Boolean testPaymentServiceFlow() {
        // create the payload JSON string for the jwt creation
        String payload = JSON.serialize(JWT_PAYLOAD);

        // create the jwt
        String jwt = UTIL_Jwt.getSignedJWTFromString(payload, API_SECRET_KEY);

        // tokenize the card
        HttpResponse response = tokenize();

        // parse the tokenize response
        if (response.getStatusCode() != 201) {
            // failed
            String status = JSON.serialize(response.getStatus());
            System.assert(false, 'Failed to tokenize card. ' + status);
            return false;
        } else {
            // success
            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == TOKEN_FIELD_NAME)) {
                    // read the token
                    parser.nextToken();
                    String token = parser.getText();
                }
            }
        
            
            
        }
        //System.debug('token = ' + token);
       
       
        
        


        

        // purchase


        System.debug('testing payment services');

        return true;
    }

    // get the credit card token
    private static HttpResponse tokenize() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT_ROOT + TOKENIZE_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('productid', PRODUCT_ID);

        // set the request body
        request.setBody('{"cardNumber": "4111111111111111",' +
            '"nameOnCard": "John Doe",' +
            '"expMonth": "' + String.valueOf(Date.today().month()) + '",' +
            '"expYear": "' + String.valueOf(Date.today().year() + 1) + '",' +
            '"cvc": "123",' +
            '"gatewayType": "CONFIGURED"' + '}');

        HttpResponse response = http.send(request);
        return response;
    }

}
