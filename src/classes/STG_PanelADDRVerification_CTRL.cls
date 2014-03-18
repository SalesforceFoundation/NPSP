public with sharing class STG_PanelADDRVerification_CTRL {

    public Address_Authentication_Settings__c apiSettings { get; set; }
    public Address_Verification_Settings__c verificationSettings { get; set; }

    public String apiSettingsSaveMessage { get; private set; }
    public String verificationSettingsSaveMessage { get; private set; }

    public String apiTestEntry { get; set; }
    public String apiTestResult { get; set; }

    public Boolean skipPreviouslyVerifiedObjects { get; set; } { skipPreviouslyVerifiedObjects = true; } 
    public Boolean nowVerifying { get; private set; } { nowVerifying = false; } 
    public String bulkVerifyMessage { get; set; }


    public STG_PanelADDRVerification_CTRL() {
        apiSettings = Address_Authentication_Settings__c.getInstance();
        verificationSettings = Address_Verification_Settings__c.getInstance();
    }

    public PageReference saveApiSettings() {
        try {
            upsert apiSettings;
            apiSettingsSaveMessage = 'Saved.';
        } catch (Exception e) {
            apiSettingsSaveMessage = 'Did not save settings: ' + e.getMessage();
        }
        return null;
    }

    public PageReference saveVerificationSettings() {
        try {
            upsert verificationSettings;
            verificationSettingsSaveMessage = 'Saved.';
        } catch (Exception e) {
            verificationSettingsSaveMessage = 'Did not save settings: ' + e.getMessage();
        }
        return null;
    }

    public PageReference testApi() {
        try {
            ADDR_Zipcode_Validation_Gateway la = new ADDR_Zipcode_Validation_Gateway(apiSettings.Auth_ID__c, apiSettings.Auth_Token__c);
            ADDR_Zipcode_Validation_Gateway.Response sz = la.verifyZip( apiTestEntry );
            apiTestResult = JSON.serializePretty(sz);
        } catch (Exception e) {
            apiTestResult = e.getMessage();
        }
        return null;
    }

    public PageReference bulkVerify() {
        list<Id> apexJobIds = ADDR_Validator_Batch.verifyAllAddresses( skipPreviouslyVerifiedObjects );
        nowVerifying = true;
        bulkVerifyMessage = 'Verifying addresses. ' + JSON.serialize( apexJobIds );
        return null;
    }
}