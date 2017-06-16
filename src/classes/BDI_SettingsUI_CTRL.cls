/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description controller for the NPSP Data Importer Settings UI visualforce component page 
*/
public with sharing class BDI_SettingsUI_CTRL {
    
    /*********************************************************************************************************
    * @description The Data Import settings object to work upon
    */
    public Data_Import_Settings__c diSettings { get; set; }
    

    /*******************************************************************************************************
    * @description is the panel in Edit Mode
    */ 
    public boolean isEditMode { 
        get {
            if (isEditMode == null) {
                isEditMode = false;
            }
            return isEditMode;
        }
        set; 
    }
    
    /*******************************************************************************************************
    * @description is the panel in Read Only Mode
    */ 
    public boolean isReadOnlyMode {
        get {
            return !isEditMode;
        }
    }
    
    /*********************************************************************************************************
    * @description The list of SelectOptions of Donation fields from the BDI object 
    */
    public list<SelectOption> listSODonationFields {
        get {
        
            if (listSODonationFields == null) {
                listSODonationFields = new list<SelectOption>();
                
                set<String> setFields = new set<String>();
                setFields.addAll(BDI_Donations.mapDIFieldToOppField.keySet());
                setFields.addAll(BDI_Donations.mapDIFieldToPmtField.keySet());
                
                for (String diField : setFields) {
                    String strLabel = UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), diField); 
                    listSODonationFields.add(new SelectOption(diField, strLabel));
                }

                listSODonationFields.sort();
            }         
            return listSODonationFields;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions of Contact Unique ID fields 
    */
    public list<SelectOption> listSOContactUniqueID {
        get {
            if (listSOContactUniqueID == null) {
                listSOContactUniqueID = new list<SelectOption>();
                //add a default option
                listSOContactUniqueID.add(new SelectOption('', Label.stgLabelNone));
                            
                Map<String, Schema.DescribeFieldResult> mapNameToDfr = UTIL_Describe.getAllFieldsDescribe('Contact');               
                for (Schema.DescribeFieldResult dfr : mapNameToDfr.values()) {
                    //only allow custom fields that have no namespace
                    if (dfr.isCustom() && dfr.getName().countMatches('__') == 1) {
                        Schema.Displaytype dt = dfr.getType();
                        // only strings and numbers
                        if (dt == Schema.DisplayType.String ||
                           dt == Schema.DisplayType.Integer ||
                           dt == Schema.DisplayType.Double) {
                           listSOContactUniqueID.add(new SelectOption(dfr.getName(), dfr.getLabel()));
                        } 
                    }               
                }
            }               
            return listSOContactUniqueID;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions of Account Unique ID fields 
    */
    public list<SelectOption> listSOAccountUniqueID {
        get {
            if (listSOAccountUniqueID == null) {
                listSOAccountUniqueID = new list<SelectOption>();
                //add a default option
                listSOAccountUniqueID.add(new SelectOption('', Label.stgLabelNone));
                                           
                Map<String, Schema.DescribeFieldResult> mapNameToDfr = UTIL_Describe.getAllFieldsDescribe('Account');               
                for (Schema.DescribeFieldResult dfr : mapNameToDfr.values()) {
                    //only allow custom fields that have no namespace
                    if (dfr.isCustom() && dfr.getName().countMatches('__') == 1) {
                        Schema.Displaytype dt = dfr.getType();
                        // only strings and numbers
                        if (dt == Schema.DisplayType.String ||
                           dt == Schema.DisplayType.Integer ||
                           dt == Schema.DisplayType.Double) {
                           listSOAccountUniqueID.add(new SelectOption(dfr.getName(), dfr.getLabel()));
                        } 
                    }               
                }
            }               
            return listSOAccountUniqueID;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description saves the provided Settings.  since we want this operation controlled by the containing
    * page, it is static to be callable by the controlling page.  it must pass the settings instance however.
    * @param diSettings The BDI settings to save
    * @return True if success, False if error.
    */
    public static boolean saveBDISettings(Data_Import_Settings__c diSettings) {

        // validate matching rules
        if (diSettings.Donation_Matching_Behavior__c != null &&
            diSettings.Donation_Matching_Behavior__c != BDI_DataImport_API.DoNotMatch &&
            String.isBlank(diSettings.Donation_Matching_Rule__c)) {

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.bdiDonationMatchingRuleEmpty));
            return false;
        }

        // validate Donation Date Range
        if (diSettings.Donation_Date_Range__c < 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.bdiPositiveNumber));
            return false;
        }

        // validate donation implementing class
        string strClass = diSettings.Donation_Matching_Implementing_Class__c;
        if (String.isNotBlank(strClass)) {
            BDI_IMatchDonations iMatchDonations = null;
            Type classType = Type.forName(strClass);
            if (classType != null) {
                Object classInstance = classType.newInstance();
                if (classInstance instanceof BDI_IMatchDonations) {
                    iMatchDonations = (BDI_IMatchDonations) classInstance;
                }
            }
            if (iMatchDonations == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
                    String.format(Label.bdiErrorInvalidIMatchDonations, new list<String>{strClass})));
                return false;
            }
        }

        upsert diSettings;
        return true;
    }

}