public without sharing virtual class AccessData {
    
    //Service
    
    protected AccessData() {}

    @TestVisible private static AccessData instance = null;

    public static AccessData getInstance() {
        if(instance == null) {
            instance = new AccessData();
        }
        return instance;
    }

    @TestVisible
    private PS_IntegrationServiceConfig.Service configService {
        get {
            if (configService == null) {
                configService = new PS_IntegrationServiceConfig.Service();
            }
            return configService;
        }
        set;
    }
    
    public String getElevateSDKURL() {
        return configService.getElevateSDKURL();
    }

    public string getClientId(){
        return configService.getClientId();
    }

    public string getMerchantId(){
        return configService.getMerchantIds();
    }

    public string getGatewayId(){
        return configService.getGatewayIds();
    }

   public string getJwtToken(){
        return new PS_Request.Builder().getJWT(PS_Request.ElevateEndpoint.TOKENIZE);
    }

    public List<Payment_Services_Configuration__c> getPaymentInfo() {
        //need a selector class (only queries)
        return [SELECT Id, Service_Key__c, Key__c, Value__c FROM Payment_Services_Configuration__c];
    }
}
