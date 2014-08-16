/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Controller for the address verification settings page.
 */
public with sharing class STG_PanelADDRVerification_CTRL extends STG_Panel {

    public override String idPanel() { return 'idPanelAddressVerification'; }
    
    public Addr_Verification_Settings__c addrVerifSettings {
	    public get { 
	        if(addrVerifSettings == null) addrVerifSettings = UTIL_CustomSettingsFacade.getAddressValidationSettings();
	        return addrVerifSettings;
	    }
	    public set;
    }
    
    public String apiSettingsErrorMessage { get; private set; }
    public String apiSettingsSaveMessage { get; private set; }

    public String apiTestEntry { get; set; }
    public String apiTestResult { get; set; }

    public Boolean skipPreviouslyVerifiedObjects { get; set; } { skipPreviouslyVerifiedObjects = true; } 
    public Boolean nowVerifying { get; private set; } { nowVerifying = false; } 
    public String bulkVerifyMessage { get; set; }

    String[] validatorExclussions = new String[]{'ADDR_IValidator', 'ADDR_SmartyStreets_Gateway', 'ADDR_Validator'};
    
    public String validatorHelpText { public get; public set; }    
    
    public String validatorSelection; 
    
    public String getValidatorSelection() { return validatorSelection; }
    
    public void setValidatorSelection(String validatorSelection) {
		addrVerifSettings.Class__c = validatorSelection;
		if(!String.isBlank(validatorSelection)) {
			Type classType = Type.forName(validatorSelection);
			if(classType != null) { 
				Object classInstance = classType.newInstance();
				if(classInstance instanceof ADDR_IValidator) {
				  this.validatorSelection = validatorSelection;
				  validatorHelpText = ((ADDR_IValidator)classInstance).getHelpText();
				}
			}
		}
    }
    
    public List<SelectOption> validators {
    	get {
    		List<SelectOption> result = new List<SelectOption>();
    		result.add(new SelectOption('', ''));
    		ApexClass[] classes = [select Name from ApexClass where Name like 'ADDR_%' and (not Name like '%_TEST') 
    		          and (not Name like '%_CTRL') and (not Name like '%_TDTM') and (not Name like '%_Batch') 
    		          and (not Name like '%_SCHED') and (not Name IN :validatorExclussions)];
            for(ApexClass c : classes) {
            	Type classType = Type.forName(c.Name);
            	Object classInstance = classType.newInstance();
                if(classInstance instanceof ADDR_IValidator) {
                    result.add(new SelectOption(c.Name, ((ADDR_IValidator)classInstance).getServiceName()));
                }
            }
            return result;
    	}
    	
    	set;
    }
    
    public STG_PanelADDRVerification_CTRL() {
    	String validator = addrVerifSettings.Class__c;
    	setValidatorSelection(validator);
    }
    
    public override PageReference saveSettings() {
        System.debug('****Settings: ' + JSON.serializePretty(addrVerifSettings));
        try {
        	apiTestResult = null;
        	
        	if(addrVerifSettings.Class__c == 'ADDR_SmartyStreets_Validator') {
        		addrVerifSettings.Using_SmartyStreets__c = true;
        	}
        	
        	encodeTokenIfNotEncoded(addrVerifSettings);
                        
            Boolean validationError = false;
            apiSettingsErrorMessage = '';
            if(addrVerifSettings.Using_SmartyStreets__c && String.isBlank(addrVerifSettings.Auth_ID__c)) {
                apiSettingsErrorMessage = Label.Addr_Id_Error;
                apiSettingsSaveMessage = null;
                validationError = true;
            }
            
            if(addrVerifSettings.Using_SmartyStreets__c && String.isBlank(addrVerifSettings.Auth_Token__c)) {
                String validationMessage = Label.Addr_Token_Error;
                apiSettingsErrorMessage = apiSettingsErrorMessage == null ? validationMessage : apiSettingsErrorMessage + validationMessage; 
                apiSettingsSaveMessage = null;
                validationError = true;
            }
            
            if(!validationError) {
                upsert addrVerifSettings;
                apiSettingsSaveMessage = Label.Saved + '\n';
                apiSettingsErrorMessage = null;
                return super.saveSettings();
            }
        } catch (Exception e) {
            apiSettingsErrorMessage = Label.Settings_not_Saved + ': ' + e.getMessage();
        }
        return null;
    }
    
    public override PageReference cancelEdit() {
    	apiSettingsErrorMessage = null;
	    apiSettingsSaveMessage = null;
	    apiTestEntry = null;
	    apiTestResult = null;
    	return super.cancelEdit();
    }

    public PageReference testApi() {
    	if(addrVerifSettings.Class__c == 'ADDR_SmartyStreets_Validator') {
            addrVerifSettings.Using_SmartyStreets__c = true;
        }
        apiTestResult = strVerifyAddressVerificationService(addrVerifSettings, apiTestEntry);
        return null;
    }
    
    // verify the current address settings - used by Health Check.    
    public static void verifyAddressVerificationService(STG_PanelHealthCheck_CTRL ctrl) {
        Addr_Verification_Settings__c avs = UTIL_CustomSettingsFacade.getAddressValidationSettings();
        if (avs.Using_SmartyStreets__c) {
	        string strSetting = Schema.Sobjecttype.Addr_Verification_Settings__c.getLabel(); 
	        string strResult = strVerifyAddressVerificationService(avs, '98005');
	        string strStatus = strResult.contains('is valid') ? 'Success' : 'Error';
	        string strSolution = strStatus == 'Success' ? strResult : 
                string.format(system.Label.healthSolutionEditSetting, new string[]{strSetting, Label.stgNavHouseholds, Label.stgNavAddressVerification});
	        if (strStatus == 'Success') strResult = null;
	        ctrl.createDR(strSetting, strStatus, strResult, strSolution);
        } 
    }
    
    // verify the current address settings - used both by the UI panel, as well as Health Check.	
    private static string strVerifyAddressVerificationService(Addr_Verification_Settings__c addrVerifSettings, string strZip) {
        string strResult;
        Addr_Verification_Settings__c avs = UTIL_CustomSettingsFacade.getAddressValidationSettings();
        if (avs.Using_SmartyStreets__c) {
	        try {
	        	encodeTokenIfNotEncoded(addrVerifSettings);
	            ADDR_SmartyStreets_Gateway la = new ADDR_SmartyStreets_Gateway(addrVerifSettings);
	            ADDR_SmartyStreets_Gateway.ZipResponse sz = la.verifyZip(strZip);
	            strResult = Label.Addr_Valid_Key_Pair; //no exception thrown when deserializing it
	        } catch (Exception e) {
	        	if(!addrVerifSettings.Using_SmartyStreets__c || String.isBlank(addrVerifSettings.Auth_ID__c) 
	        	|| String.isBlank(addrVerifSettings.Auth_Token__c)) {
	        		strResult = Label.Addr_Verify_Settings;
	        	} else if(e.getMessage().startsWith('no protocol')) {
	        		strResult = Label.Addr_Verify_Endpoint;
	        	} else if(e.getMessage().startsWith('Unauthorized endpoint')) {
	        		strResult = Label.Addr_Unauthorized_Endpoint;
	        	} else {
	                strResult = e.getMessage();
	        	}
	        }
        }
        return strResult;
    }
    
    private static void encodeTokenIfNotEncoded(Addr_Verification_Settings__c addrVerifSettings) {
    	//SmartyStreets' unencoded token is always 88 chars long
        if(addrVerifSettings.Using_SmartyStreets__c && !String.isBlank(addrVerifSettings.Auth_Token__c) 
        && addrVerifSettings.Auth_Token__c.length() == 88)
            addrVerifSettings.Auth_Token__c = EncodingUtil.urlEncode(addrVerifSettings.Auth_Token__c, 'UTF-8');
    }

    public PageReference bulkVerify() {
    	String classToRunName = String.valueOf(addrVerifSettings.get('Class__c'));
        if(!String.isBlank(classToRunName)) {
	        Type classType = Type.forName(classToRunName);
	        if(classType != null) {     
	            Object classInstance = classType.newInstance();
	            if(classInstance instanceof ADDR_IValidator) {
	                ADDR_IValidator validator = (ADDR_IValidator)classInstance;
	                if(validator.supportsBatch()) {
	                    ADDR_Validator_Batch b = new ADDR_Validator_Batch(skipPreviouslyVerifiedObjects);
				        Database.executeBatch(b); 
				        nowVerifying = true;
				        bulkVerifyMessage = Label.Addr_Verifying;	
	                } else {
	                    bulkVerifyMessage = Label.Addr_No_Batch;	
	                }
	            }
	        } else {
	        	bulkVerifyMessage = Label.Addr_No_Batch;
	        }
        } else {
            bulkVerifyMessage = Label.Addr_No_Batch;
        }
        return null;
    }
}