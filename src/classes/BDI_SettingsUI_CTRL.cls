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
* @description controller for the NPSP Data Importer Batch/Settings UI visualforce component page
* since a DataImportBatch is a superset of DataImportSettings, this component page binds to a
* batch object, and optionally just hides the batch specific fields.
*/
public with sharing class BDI_SettingsUI_CTRL {
    
    /*********************************************************************************************************
    * @description The Data Import batch/settings object to work upon
    */
    public DataImportBatch__c diBatch { get; set; }

    /*********************************************************************************************************
    * @description getter's to provide the page our API behaviors (which the page can't refer to directly)
    */
    public string getDoNotMatch() { return BDI_DataImport_API.DoNotMatch; }
    public string getRequireNoMatch() { return BDI_DataImport_API.RequireNoMatch; }
    public string getRequireExactMatch() { return BDI_DataImport_API.RequireExactMatch; }
    public string getExactMatchOrCreate() { return BDI_DataImport_API.ExactMatchOrCreate; }
    public string getRequireBestMatch() { return BDI_DataImport_API.RequireBestMatch; }
    public string getBestMatchOrCreate() { return BDI_DataImport_API.BestMatchOrCreate; }

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

    /*******************************************************************************************************
    * @description should we display fields that are only in DataImportBatch, but not in DataImportSettings
    */
    public boolean isShowBatchOnlyFields { get; set; }

    /*********************************************************************************************************
    * @description The list of SelectOptions of Donation fields from the BDI object. note that the option
    * keys are stored in lowercase.
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
                listSOContactUniqueID = listSOForObject('Contact');
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
                listSOAccountUniqueID = listSOForObject('Account');
            }
            return listSOAccountUniqueID;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description creates a list of SelectOptions of potential Unique ID fields from the specified object
    * @param strObject the object to query fields on
    * @return list<SelectOption>
    */
    private list<SelectOption> listSOForObject(String strObject) {
        list<SelectOption> listSO = new list<SelectOption>();
        // add a default option
        listSO.add(new SelectOption('', Label.stgLabelNone));

        Map<String, Schema.DescribeFieldResult> mapNameToDfr = UTIL_Describe.getAllFieldsDescribe(strObject);
        for (Schema.DescribeFieldResult dfr : mapNameToDfr.values()) {
            // only allow unique fields and externalId fields
            if (dfr.isUnique() || dfr.isExternalId()) {
                listSO.add(new SelectOption(dfr.getName(), dfr.getLabel()));
            }
        }
        return listSO;
    }
}