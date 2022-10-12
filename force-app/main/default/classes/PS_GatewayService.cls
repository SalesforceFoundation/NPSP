/*
    Copyright (c) 2022, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2022
* @group Payment Services
* @description Contains methods to retrieve Elevate gateways
*/
public with sharing class PS_GatewayService {

    private UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    public HttpRequest buildGetGatewaysByMerchantRequest() {
        return new PS_Request.Builder()
                .withEndpoint(PS_Request.ElevateEndpoint.MERCHANTS)
                .withMethod(UTIL_Http.Method.GET)
                .build();
    }

    private UTIL_Http.Response getGatewaysResponse() {
        UTIL_Http.Response response;

        try {
            HttpRequest gatewaysByMerchantGetRequest = buildGetGatewaysByMerchantRequest();
            response = requestService.sendRequest(gatewaysByMerchantGetRequest);
        }

        catch(Exception e) {
            response = requestService.buildErrorResponse(e);
        }

        return response;
    }

    public String getGatewaysByMerchant() {
        UTIL_Http.Response gatewayResponse;

        gatewayResponse = getGatewaysResponse();

        if (gatewayResponse.statusCode == UTIL_Http.STATUS_CODE_OK) {
            return buildTemplateSettingsJSON((Map<String, Object>) JSON.deserializeUntyped(gatewayResponse.body));
        } else {
            String errorMessage = gatewayResponse.getErrorMessages();
            AuraHandledException e = new AuraHandledException(errorMessage);
            e.setMessage(errorMessage);
            throw e;
        }
    }

    private String buildTemplateSettingsJSON(Map<String, Object> gatewayResponse) {
        List<Object> gateways = new List<Object>();
        gateways = (List<Object>) gatewayResponse.get('gateways');

        List<GatewayTemplateSetting> gatewayTemplateSettings = new List<GatewayTemplateSetting>();
        if (!gateways.isEmpty()) {
            for (Object gatewayObject : gateways) {
                gatewayTemplateSettings.add(buildGatewayTemplateSetting(gatewayObject));
            }
        }

        return JSON.serialize(gatewayTemplateSettings);
    }

    private GatewayTemplateSetting buildGatewayTemplateSetting(Object gatewayObject) {
        GatewayTemplateSetting templateSetting = new GatewayTemplateSetting(
                (ResponseBody) JSON.deserialize(JSON.serialize(gatewayObject), ResponseBody.class));

        if (PS_GatewayManagement.getGatewayIdFromConfig().startsWith(templateSetting.id)) {
            templateSetting.isDefault = true;
        }

        return templateSetting;
    }

    public class ResponseBody {
        public String id;
        public String alias;
        public String vendorName;
        public GatewaySettings settings;
    }

    public class GatewaySettings {
        public List<String> enabledPaymentMethods;
    }

    public class GatewayTemplateSetting {
        public String id;
        public String gatewayName;
        public Boolean isCreditCardEnabled;
        public Boolean isACHEnabled;
        public Boolean isDefault;

        public GatewayTemplateSetting() {}
        public GatewayTemplateSetting(ResponseBody rb) {
            this.id = rb.id;
            this.gatewayName = rb.alias == null ? rb.vendorName : rb.alias;
            this.isDefault = false;
            this.isCreditCardEnabled = false;
            this.isACHEnabled = false;

            if (rb.settings.enabledPaymentMethods != null) {
                for (String paymentMethod : rb.settings.enabledPaymentMethods) {
                    if (paymentMethod.equalsIgnoreCase(ElevatePaymentMethod.CARD.name())) {
                        this.isCreditCardEnabled = true;
                    } else if (paymentMethod.equalsIgnoreCase(ElevatePaymentMethod.ACH.name())) {
                        this.isACHEnabled = true;
                    }
                }
            }
            else {
                this.isCreditCardEnabled = true;
                this.isACHEnabled = true;
            }
        }
    }
}