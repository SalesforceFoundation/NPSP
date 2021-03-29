public with sharing class ElevateTokenizedGift {
    private Decimal amount;
    private String merchantId;
    private String gatewayId;
    private String firstName;
    private String lastName;
    private String currencyCode;
    private String paymentMethodToken;
    /*********************************
        * Optional properties
        */
    // May be any key:value pairs. i.e. campaignCode: 123
    private Metadata metadata;
    private String phone;
    private String city;
    private String state;
    private String postalCode;
    // The ISO 3166-1 alpha-2 country code. E.g. US
    private String country;
    private AchData achData;
    private String paymentMethodType;
    private String accountName;
    private PS_IntegrationServiceConfig.Service configService;

    public ElevateTokenizedGift() {
        this.currencyCode = UserInfo.getDefaultCurrency();
        setConfigServiceInstance();
        setGatewayId();
        setMerchantId();
    }

    public ElevateTokenizedGift(PS_IntegrationServiceConfig.Service configService) {
        this.configService = configService;
    }

    private void setMerchantId() {
        if (String.isBlank(merchantId)) {
            merchantId = configService.getMerchantIds();
        }
    }

    private void setGatewayId() {
        if (String.isBlank(gatewayId)) {
            gatewayId = configService.getGatewayIds();
        }
    }

    private void setConfigServiceInstance() {
        configService = new PS_IntegrationServiceConfig.Service();
    }

    @TestVisible
    private ElevateTokenizedGift withAmount(Decimal amount) {
        this.amount = amount;
        return this;
    }

    @TestVisible
    private ElevateTokenizedGift withToken(String token) {
        paymentMethodToken = token;
        return this;
    }

    public String phone() {
        return phone;
    }

    public String city() {
        return city;
    }

    public String state() {
        return state;
    }

    public String postalCode() {
        return postalCode;
    }

    public String country() {
        return country;
    }

    public AchData achData() {
        return achData;
    }

    public String paymentMethodType() {
        return paymentMethodType;
    }

    public String accountName() {
        return accountName;
    }

    public Decimal amount() {
        return amount;
    }

    public String firstName() {
        return firstName;
    }

    public String lastName() {
        return lastName;
    }

    public String currencyCode() {
        return currencyCode;
    }

    public String gatewayId() {
        return gatewayId;
    }

    public String merchantId() {
        return merchantId;
    }

    public String token() {
        return paymentMethodToken;
    }

    /**
     * @description Inner class for constructing ACH specific data for the purchase request body
     */
    public with sharing class AchData {
        public String achCode;
        public String consent;
        public String type;
        public String bankType;
    }

    /***
    * @description Inner class of PurchaseCallBody to assist in constructing the metadata property.
    * This could/should probably just be a map.
    */
    public with sharing class Metadata {
        public String campaignCode;
    }
}