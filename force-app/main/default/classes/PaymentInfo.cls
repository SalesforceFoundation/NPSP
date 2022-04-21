public with sharing class PaymentInfo {

    //Controller
    private static AccessData access = AccessData.getInstance();

    @AuraEnabled(cacheable=true)
    public static List<Payment_Services_Configuration__c> getPaymentInfo(String accountId) {
        return access.getPaymentInfo();
    }

    @AuraEnabled(cacheable=true)
    public static string getElevateSDKURL(){
        return access.getElevateSDKURL();
    }

    @AuraEnabled(cacheable=true)
    public static string getClientId(){
        return access.getClientId();
    }

    @AuraEnabled(cacheable=true)
    public static string getMerchantId(){
        return access.getMerchantId();
    }

    @AuraEnabled(cacheable=true)
    public static string getGatewayId(){
        return access.getGatewayId();
    }

    @AuraEnabled(cacheable=true)
    public static string getJwtToken(){
        return access.getJwtToken();
    }
}
