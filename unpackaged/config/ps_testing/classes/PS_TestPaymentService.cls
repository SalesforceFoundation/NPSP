public with sharing class PS_TestPaymentService {
   
    // JWT secret key
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

    // TODO: use Org id 
    private static final String PRODUCT_ID = '00D6g0000000000EAA';


    public static Boolean testPaymentServiceFlow() {
        // create the payload
        String payload = JSON.serialize(JWT_PAYLOAD);

        // create the jwt
        String jwt = UTIL_Jwt.getSignedJWTFromString(payload, API_SECRET_KEY);
        System.debug('jwt = ' + jwt);


        // tokenize
        HttpResponse response = makeTokenizeCall();

        System.debug('status code = ' + response.getStatusCode());
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            //return JSON.serialize(response.getStatus());
            String status = JSON.serialize(response.getStatus());
            System.debug('status = ' + status);
        } else {
            //return JSON.serialize(response.getBody());
            String token = JSON.serialize(response.getBody());
            System.debug('token = ' + token);
        }
        //System.debug('token = ' + token);

        // purchase


        System.debug('testing payment services');

        return true;
    }

    private static HttpResponse makeTokenizeCall() {
        System.debug('url = ' + ENDPOINT_ROOT + TOKENIZE_ENDPOINT);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT_ROOT + TOKENIZE_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('productid', PRODUCT_ID);

        // Set the body as a JSON object...
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
