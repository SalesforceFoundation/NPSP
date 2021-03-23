public with sharing class ElevateTokenizedGift {
    public Decimal amount;
    public String firstName;
    public String lastName;
    public String currencyCode;
    public String gatewayId;
    public String merchantId;
    public String token;
    public PS_IntegrationServiceConfig.Service configService;

    public ElevateTokenizedGift() {
        getConfigServiceInstance();
        getGatewayId();
        getMerchantId();
    }

    private void getMerchantId() {
        if (String.isBlank(merchantId)) {
            merchantId = configService.getMerchantIds();
        }
    }

    private void getGatewayId() {
        if (String.isBlank(gatewayId)) {
            gatewayId = configService.getGatewayIds();
        }
    }

    private void getConfigServiceInstance() {
        if (configService == null) {
            configService = new PS_IntegrationServiceConfig.Service();
        }
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
        return token;
    }
}