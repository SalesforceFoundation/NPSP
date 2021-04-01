public with sharing class ElevateTokenizedGift {
    public Decimal amount;
    public String firstName;
    public String paymentMethodToken;
    public String merchantId;
    public String gatewayId;
    public String lastName;
    public String currencyCode;
    public PS_IntegrationServiceConfig.Service configService;

    public ElevateTokenizedGift() {
        this.currencyCode = UserInfo.getDefaultCurrency();
        setConfigServiceInstance();
        setGatewayId();
        setMerchantId();
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

    public String token() {
        return paymentMethodToken;
    }
}