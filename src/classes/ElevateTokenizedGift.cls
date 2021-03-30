public virtual with sharing class ElevateTokenizedGift {
    protected Decimal amount;
    protected String firstName;
    protected String paymentMethodToken;
    protected String merchantId;
    protected String gatewayId;
    protected String lastName;
    protected String currencyCode;
    protected PS_IntegrationServiceConfig.Service configService;

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

    public virtual Decimal amount() {
        return amount;
    }

    public virtual String firstName() {
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

    public virtual String token() {
        return paymentMethodToken;
    }
}