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
    
    public Addr_Verification_Settings__c addrVerifSettings { public get; public set; }
    
    public String apiSettingsErrorMessage { get; private set; }
    public String apiSettingsSaveMessage { get; private set; }

    public String apiTestEntry { get; set; }
    public String apiTestResult { get; set; }

    public Boolean skipPreviouslyVerifiedObjects { get; set; } { skipPreviouslyVerifiedObjects = true; } 
    public boolean isRunningBatch { get; set; }
    public String batchVerifyMessage { get; set; }

    String[] validatorExclussions = new String[]{'ADDR_IValidator', 'ADDR_SmartyStreets_Gateway', 'ADDR_Validator'};
    
    public String settingsHelpText { public get; public set; }    
    public String validatorBatchHelpText { public get; public set; }
    
    public Boolean batchVerifEnabled { public get; set; }
    
    public Map<String, String> servicesHelpTextMap { public get; set; }
    public Map<String, String> servicesURLMap  { public get; set; }
    
    public String validatorSelection;     
    public String getValidatorSelection() { return validatorSelection; }  
    public void setValidatorSelection(String validatorSelection) {
		addrVerifSettings.Class__c = validatorSelection;
		clearDynamicFields();
		if(!String.isBlank(validatorSelection)) {
			Type classType = Type.forName(validatorSelection);
			if(classType != null) { 
				Object classInstance = classType.newInstance();
				if(classInstance instanceof ADDR_IValidator) {
				  this.validatorSelection = validatorSelection;
				  setDynamicFields((ADDR_IValidator)classInstance);
				}
			}
		}
    }
    
    public PageReference initDynamicFields() {
    	addrVerifSettings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
    	String validator = addrVerifSettings.Class__c;
        clearDynamicFields();
        if(validator != null) {           
            Type classType = Type.forName(validator);
            if(classType != null) { 
                Object classInstance = classType.newInstance();
                if(classInstance instanceof ADDR_IValidator) {
                   setDynamicFields((ADDR_IValidator)classInstance);
                   setValidatorSelection(addrVerifSettings.Class__c);
                }
            }
        }
        return null;
    }
    
    private void clearDynamicFields() {
    	batchVerifEnabled = false;
        settingsHelpText = '';
        validatorBatchHelpText = '';
    }
    
    private void setDynamicFields(ADDR_IValidator validator) {
        settingsHelpText = validator.getHelpText();
        batchVerifEnabled = validator.supportsBatch();
        validatorBatchHelpText = validator.getBatchHelpText();	
    }
    
    public List<SelectOption> validators { public get; set; }
    
    public STG_PanelADDRVerification_CTRL() {
    	isRunningBatch = false;    
    	servicesHelpTextMap = new Map<String, String>();
        servicesURLMap = new Map<String, String>();
    
        validators = new List<SelectOption>();
        validators.add(new SelectOption('', ''));
        //We have to use these strings because the underscode is treated like a special character in a LIKE 
        //clause, and if we try to escape it with a backslash it gets double-escaped automatically.
        String addrLikeClause = 'ADDR\\_%';
        String testLikeClause = '%\\_TEST';
        String ctrlLikeClause = '%\\_CTRL';
        String tdtmLikeClause = '%\\_TDTM';
        String batchLikeClause = '%\\_Batch';
        String schedLikeClause = '%\\_SCHED'; 
        ApexClass[] classes = [select Name, NamespacePrefix from ApexClass where Name like :addrLikeClause 
                  and (not Name like :testLikeClause) and (not Name like :ctrlLikeClause) 
                  and (not Name like :tdtmLikeClause) and (not Name like :batchLikeClause) 
                  and (not Name like :schedLikeClause) and (not Name IN :validatorExclussions)];
        System.debug('****Validators: ' + JSON.serializePretty(classes));
        for(ApexClass c : classes) {
            Type classType = Type.forName(c.NamespacePrefix, c.Name);
            if(classType != null) {
	            Object classInstance = classType.newInstance();
	            if(classInstance instanceof ADDR_IValidator) {
	                validators.add(new SelectOption(c.Name, ((ADDR_IValidator)classInstance).getServiceName()));
	                servicesHelpTextMap.put(((ADDR_IValidator)classInstance).getServiceName(), ((ADDR_IValidator)classInstance).getHelpText());
	                servicesURLMap.put(((ADDR_IValidator)classInstance).getServiceName(), ((ADDR_IValidator)classInstance).getDefaultURL());
	            }
            }
        }         
    }
    
    public override PageReference saveSettings() {
        try {
        	apiTestResult = null;
        	
        	addrVerifSettings.Using_SmartyStreets__c = (addrVerifSettings.Class__c == 'ADDR_SmartyStreets_Validator');
        	
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
            	if(addrVerifSettings.Using_SmartyStreets__c && addrVerifSettings.Zipcode_Verification_Endpoint__c == null) {
            		ADDR_SmartyStreets_Validator validator = new ADDR_SmartyStreets_Validator();
            		addrVerifSettings.Zipcode_Verification_Endpoint__c = validator.getDefaultZipcodeURL();
            	}
            	if(addrVerifSettings.Address_Verification_Endpoint__c.contains('http:')) {
            	   addrVerifSettings.Address_Verification_Endpoint__c = addrVerifSettings.Address_Verification_Endpoint__c.replaceFirst('http:', 'https:');
            	} else if(!addrVerifSettings.Address_Verification_Endpoint__c.contains('http')) {
            	   addrVerifSettings.Address_Verification_Endpoint__c = 'https://' + addrVerifSettings.Address_Verification_Endpoint__c;
            	}
                upsert addrVerifSettings;
                apiSettingsSaveMessage = Label.Saved + '\n';
                apiSettingsErrorMessage = null;
                setValidatorSelection(addrVerifSettings.Class__c);
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
        Addr_Verification_Settings__c avs = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
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
        Addr_Verification_Settings__c avs = UTIL_CustomSettingsFacade.getAddressVerificationSettings();
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

    public PageReference batchVerify() {
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
				        isRunningBatch = true;
				        batchVerifyMessage = Label.Addr_Verifying;	
	                } else {
	                    batchVerifyMessage = Label.Addr_No_Batch;	
	                }
	            }
	        } else {
	        	batchVerifyMessage = Label.Addr_No_Batch;
	        }
        } else {
            batchVerifyMessage = Label.Addr_No_Batch;
        }
        return null;
    }
}