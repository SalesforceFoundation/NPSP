public with sharing class PS_TestPaymentService {

    // endpoints
    // TODO: at the moment we use the dev1 env, we should replace with a QA env when it becomes available
    private static final String ENDPOINT_ROOT = 'https://7jpea5zk79.execute-api.us-west-2.amazonaws.com/v1/payments';
    private static final String TOKENIZE_ENDPOINT = '/public/tokens';
    private static final String PURCHASE_ENDPOINT = '/verified/purchase';

    private static final String BASE_PURCHASE_CALL_BODY = '{"amount":5,"email":"test@test.test","firstName":"Test First Name","lastName":"Test Last Name","metadata":{},';
    private static final String TOKEN_FIELD_NAME = 'token';
    private static final String STATUS_FIELD_NAME = 'status';
    private static final String STATUS_FIELD_SUCCESS = 'CAPTURED';

    // TODO: use Org id 
    private static final String PRODUCT_ID = '00D6g0000000000EAA';

    /**
     * @description method for testing the end to end payment processing
     * @return  Boolean: true is successful, false if failed
     */
    public static Boolean testPaymentServiceFlow() {   
        Boolean success = true;

        try {
            // tokenize the card
            HttpResponse tokenHttpResponse = makeTokenizeCall();
            String token = getToken(tokenHttpResponse);

            // purchase
            GE_PaymentServices paymentServices = new GE_PaymentServices();
            String requestBodyParameters = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + token + '"}';
            paymentServices.setPurchaseCallBody(requestBodyParameters);
            GE_PaymentServices.ResponseWrapper purchaseResponse = paymentServices.createTransaction();
            checkPurchaseStatus(purchaseResponse);
            
            System.debug('Payment Service Flow successful.');
        } catch(Exception ex) {
            success = false;
            System.debug(ex.getStackTraceString());
        } 

        return success;
    }

    // submit the tokenize request
    private static HttpResponse makeTokenizeCall() {
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

    // read the token from the tokenize response
    private static String getToken(HttpResponse response) {
        if (response.getStatusCode() != 201) {
            // failed
            String status = JSON.serialize(response.getStatus());
            System.assert(false, 'Failed to tokenize card. ' + status);
        } else {
            // success
            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == TOKEN_FIELD_NAME)) {
                    // read the token
                    parser.nextToken();
                    String token = parser.getText();
                    return token;
                }
            } 
        }
        return '';
    }

    // parse the response from the purchase method
    private static void checkPurchaseStatus(GE_PaymentServices.ResponseWrapper response) {
        // check the status
        System.assertEquals(201, response.statusCode, 'Purchase failed. ' + response.status);

        // check the body
        String body = response.body;
        System.debug('body = ' + body);
    }

    
}
