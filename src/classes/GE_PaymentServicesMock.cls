public with sharing class GE_PaymentServicesMock implements System.StubProvider {
    private Boolean isElevateCustomer;
    private String gatewayId;
    private String merchantId;
    private final String DUMMY_GATEWAY_ID = 'def123-ghi456';
    private final String DUMMY_MERCHANT_ID = 'abc123-xyz456';

    public GE_PaymentServicesMock() {
        this.isElevateCustomer = true;
        this.gatewayId = DUMMY_GATEWAY_ID;
        this.merchantId = DUMMY_MERCHANT_ID;
    }

    public GE_PaymentServicesMock isElevateCustomer(Boolean isElevateCustomer) {
        this.isElevateCustomer = isElevateCustomer;
        return this;
    }

    public GE_PaymentServicesMock setGatewayId(String gatewayId) {
        this.gatewayId = gatewayId;
        return this;
    }

    public GE_PaymentServicesMock setMerchantId(String merchantId) {
        this.merchantId = merchantId;
        return this;
    }

    public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

        switch on stubbedMethodName {
            when 'isElevateCustomer' {
                return isElevateCustomer;
            }
            when 'getGatewayIds' {
                return gatewayId;
            }
            when 'getMerchantIds' {
                return merchantId;
            }
            when 'createCaptureGroup' {
                return new GE_PaymentServices().createCaptureGroup();
            }
        }
        return null;
    }
}