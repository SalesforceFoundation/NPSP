/*
    Copyright (c) 2011, Salesforce.org
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
* @date 2011 (2.1)
* @group Settings
* @description Controller for the payment mapping wizard
*/
public with sharing class STG_PanelPaymentMapping_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description Returns the string Id of the Payment Mapping panel.
    */
    public override string idPanel() { return 'idPanelPaymentMapping'; }

    /*********************************************************************************************************
    * @description Map of Field names to DisplayTypes
    */
    map<string, Schema.Displaytype> mapFieldTypes = new map<string, Schema.Displaytype>();

    /*********************************************************************************************************
    * @description List of SelectOptions of Source object Fields
    */
    public list<SelectOption> sourcefields = new list<SelectOption>();

    /*********************************************************************************************************
    * @description List of SelectOptions of Target object Fields
    */
    public list<SelectOption> targetfields = new list<SelectOption>();

    /*********************************************************************************************************
    * @description Action Method to cancel Edit mode without saving
    * @return null
    */
    public pageReference cancelPfmEdit() {
        this.sourcefields.clear();
        this.mapFieldTypes.clear();
        this.targetfields.clear();
        pfmNew = null;
        isEditMode = false;
        return null;
    }

    /*********************************************************************************************************
    * @description Check if the running user has full access to the npe4__Relationship_Auto_Create__c sObject
    * @return Boolean
    */
    public Boolean getHasAccess() {
        String autoCreateObjectName = Schema.SObjectType.npe01__Payment_Field_Mapping_Settings__c.getName();

        return UTIL_Permissions.canRead(autoCreateObjectName, false) &&
                UTIL_Permissions.canCreate(autoCreateObjectName, false) &&
                UTIL_Permissions.canUpdate(autoCreateObjectName, false) &&
                UTIL_Permissions.canDelete(autoCreateObjectName, false);
    }

    /*********************************************************************************************************
    * @description Initializes the targetFields SelectOption list for the selected object
    * @return List of SelectOption with available fields for mapping.
    */
    public List<SelectOption> getTargetFields() {
        targetFields.clear();

        String paymentObjectName = Schema.SObjectType.npe01__OppPayment__c.getName();
        Set<String> paymentsFieldsToExclude = new Set<String> {
            'npe01__Opportunity__c', 'npe01__Paid__c', 'npe01__Payment_Amount__c', 'npe01__Payment_Date__c',
            'npe01__Written_Off__c'};
        Map<String, Schema.SObjectField> targetTokenMap = Schema.SObjectType.npe01__OppPayment__c.fields.getMap().clone();

        //pop out the known fields
        for (String fieldName : paymentsFieldsToExclude) {
            fieldName = fieldName.toLowerCase();
            targetTokenMap.remove(fieldName);
        }

        // remove fields that are already used in a mapping
        for (npe01__Payment_Field_Mapping_Settings__c pfm : STG_Panel.stgService.listPMTFieldMapping) {
            String paymentFieldName = pfm.npe01__Payment_Field__c;
            paymentFieldName = paymentFieldName.toLowerCase();
            targetTokenMap.remove(paymentFieldName);
        }

        if (!targettokenMap.isEmpty()) {

            Schema.DisplayType oppType = mapFieldTypes.get(pfmNew.npe01__Opportunity_Field__c);
            for (String fieldName : targetTokenMap.keyset()) {
                if (fieldName.contains('__c') && UTIL_Describe.isValidField(paymentObjectName, fieldName)) {
                    Schema.DescribeFieldResult field = UTIL_Describe.getFieldDescribe(paymentObjectName, fieldName);

                    // disallow formula fields and autonums
                    if (field.isCalculated() || field.isAutoNumber()) {
                        continue;
                    }
                    // check for compatible displaytypes
                    Schema.DisplayType payType = field.getType();
                    if (UTIL_Describe.canDisplaytypesCopy(oppType, payType)) {
                        targetFields.add(new SelectOption(field.getName(), field.getLabel()));
                    }
                }
            }

            targetFields.sort();
        }

        if (targetFields.isEmpty()) {
            targetFields.add(new SelectOption(strNoValidField, strNoValidField));
        }
        return targetFields;
    }

    /*********************************************************************************************************
    * @description A localized string to use if there is no valid field
    */
    private static string strNoValidField = System.Label.stgLabelPaymentMapNoValidFields;

    /*********************************************************************************************************
    * @description Initializes the sourcefields SelectOption list for Opportunities
    */
    public list<SelectOption> getSourceFields() {

        if (sourcefields.isEmpty()) {

            // sets of strings are case sensitive, so use lower case in our set for the contains() against knownopptyFields.
            set<string> knownOpptyFields = new set<string>{'amount', 'closedate', 'expectedrevenue',
                'probability', 'totalopportunityquantity', 'npe01__membership_start_date__c', 'npe01__membership_end_date__c'};

            map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap();

            //loop through the map, only get the describe information for fields we don't
            //already recognize, including our own and non-custom fields, we'll add those in a moment
            for (string fieldName : oppFieldTokenList.keyset()) {
                if ((fieldname.contains('__c') || knownopptyFields.contains(fieldName)) && UTIL_Describe.isValidField('Opportunity', fieldname)) {
                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('Opportunity', fieldname);
                    Schema.Displaytype dt = f.getType();
                    sourcefields.add(new SelectOption(f.getName(), f.getLabel()));
                    mapFieldTypes.put(f.getName(), dt);
                }
           }
           sourcefields.sort();
        }
        return sourceFields;
    }

    /*********************************************************************************************************
    * @description Checks that existing user defined rollups are valid - called by Health Check
    * @return void
    */
    public static void verifyPaymentMappings(STG_PanelHealthCheck_CTRL ctrl) {

        map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappings = UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings();
        string strSetting = Schema.Sobjecttype.npe01__Payment_Field_Mapping_Settings__c.getLabel();
        boolean isValid = true;
        boolean isValidAll = true;

        for (string s : paymentMappings.keySet()){
            npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
            SobjectField paymentField;
            SobjectField opportunityField;
            isValid = true;

            //check source field
            opportunityField = Schema.sObjectType.Opportunity.fields.getMap().get(pfms.npe01__Opportunity_Field__c);
            if (opportunityField == null) {
                isValid = false;
                ctrl.createDR(strSetting, STG_PanelHealthCheck_CTRL.statusError,
                    string.format(label.healthDetailsInvalidOppField, new string[]{pfms.npe01__Opportunity_Field__c}),
                    string.format(label.healthSolutionInvalidOppField, new string[]{label.stgNavDonations, label.stgNavPaymentMappings}));
            }

            //check target fields
            paymentField = Schema.sObjectType.npe01__OppPayment__c.fields.getMap().get(pfms.npe01__Payment_Field__c);
            if (paymentField == null) {
                isValid = false;
                ctrl.createDR(strSetting, STG_PanelHealthCheck_CTRL.statusError,
                    string.format(label.healthDetailsInvalidPaymentField, new string[]{pfms.npe01__Payment_Field__c}),
                    string.format(label.healthSolutionInvalidPaymentField, new string[]{label.stgNavDonations, label.stgNavPaymentMappings}));
            }

            //only if the other checks succeed, get the describe type
            if (isValid == true){
                //check Field Types
                Schema.Displaytype dtPmt = UTIL_Describe.getFieldDisplaytype('npe01__OppPayment__c', pfms.npe01__Payment_Field__c);
                Schema.Displaytype dtOpp = UTIL_Describe.getFieldDisplaytype('Opportunity', pfms.npe01__Opportunity_Field__c);
                if (!UTIL_Describe.canDisplaytypesCopy(dtOpp, dtPmt)) {
                    isValid = false;
                    ctrl.createDR(strSetting, STG_PanelHealthCheck_CTRL.statusError,
                        string.format(label.healthDetailsPaymentMappingBadDataTypes, new string[]{pfms.npe01__Payment_Field__c, pfms.npe01__Opportunity_Field__c}),
                        string.format(label.healthSolutionPaymentMappingBadDataTypes, new string[]{label.stgNavDonations, label.stgNavPaymentMappings}));
                }
            }

            if (!isValid)
                isValidAll = false;
        }

        if (isValidAll) {
            ctrl.createDR(strSetting, STG_PanelHealthCheck_CTRL.statusSuccess, null, label.healthLabelPaymentMappingsValid);
        }
    }

    /*********************************************************************************************************
    * @description Adds an error message to the visualforce page
    * @return null
    */
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }

    /*********************************************************************************************************
    * @description Holds the Id of a Payment Mapping record to delete
    */
    public string pfmIdDelete { get; set; }

    /*********************************************************************************************************
    * @description Action Method to delete a Payment Mapping record
    * @return null
    */
    public PageReference deletePfm() {
        if (!isRunningUserIsAdmin) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.stgDeletePermissionError));
            return null;
        }

        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        if (pfmIdDelete != null) {
           npe01__Payment_Field_Mapping_Settings__c pfm = new npe01__Payment_Field_Mapping_Settings__c(Id = pfmIdDelete);
           delete pfm;
           // force reload.
           resetFieldMappingSettings();
        }
        return null;
    }

    /*********************************************************************************************************
    * @description The Payment Field Mapping Settings object
    */
    public npe01__Payment_Field_Mapping_Settings__c pfmNew {
        get {
            if (pfmNew == null) pfmNew = new npe01__Payment_Field_Mapping_Settings__c();
            return pfmNew;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description Whether all required fields are set in order to create a new Payment Mapping
    */
    public boolean isPfmNewValid {
        get {
            return pfmNew != null &&
               pfmNew.npe01__Opportunity_Field__c != null &&
               pfmNew.npe01__Payment_Field__c != null &&
               pfmNew.npe01__Payment_Field__c != strNoValidField;
        } private set;
    }

    /*********************************************************************************************************
    * @description Action Method to enter Edit mode in order to create a new Payment Mapping
    * @return null
    */
    public PageReference newPfm() {
        isEditMode = true;
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to save a new Payment Mapping
    * @return null
    */
    public PageReference savePfm() {
        if (!isPfmNewValid) {
            showMsg('No valid Payment field was found for the chosen Opportunity field.', ApexPages.Severity.FATAL);
            return null;
        }

        Try {
            isEditMode = false;
            map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappings = UTIL_ListCustomSettingsFacade.getMapPaymentFieldMappingSettings();

            // make sure we have a unique name
            integer nameNumber;
            for (nameNumber = paymentMappings.size(); ; nameNumber++) {
                if (paymentMappings.get('CustomMapping' + nameNumber) == null)
                  break;
            }
            pfmNew.Name = 'CustomMapping' + nameNumber;

            insert pfmNew;
            pfmNew = null;
            resetFieldMappingSettings();
        } catch(Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            showMsg('An unhandled exception has occurred. Please try again.',ApexPages.Severity.FATAL);
            showMsg('Exception type' + e, ApexPages.Severity.INFO);
        }
        return null;
    }

    /*********************************************************************************************************
    * @description Resets payment field mappings so that they are reloaded and the cached version isn't used.
    */
    public void resetFieldMappingSettings() {
        UTIL_ListCustomSettingsFacade.mapPaymentFieldMappingSettings = null;
        STG_Panel.stgService.listPMTFieldMapping = null;
        listPMTFieldMapping = null;
    }

    /*********************************************************************************************************
    * @description Action Method to update target fields after the source field has been chosen
    * @return null
    */
    public PageReference onSelectSourceField() {
        // refresh target fields
        targetfields.clear();
        return null;
    }

    /*********************************************************************************************************
    * @description The list of current Payment Field Mappings with labels substituted for developer names
    * @return list<npe01__Payment_Field_Mapping_Settings__c>
    */
    public list<npe01__Payment_Field_Mapping_Settings__c> listPMTFieldMapping {
        get {
            if (listPMTFieldMapping == null) {
                listPMTFieldMapping = new list<npe01__Payment_Field_Mapping_Settings__c>();
                for (npe01__Payment_Field_Mapping_Settings__c pfm : STG_Panel.stgService.listPMTFieldMapping) {
                    string strOppField = UTIL_Describe.getFieldLabelSafe('Opportunity', pfm.npe01__Opportunity_Field__c);
                    string strPmtField = UTIL_Describe.getFieldLabelSafe('npe01__OppPayment__c', pfm.npe01__Payment_Field__c);
                    npe01__Payment_Field_Mapping_Settings__c pfm2 = new npe01__Payment_Field_Mapping_Settings__c();
                    pfm2.Id = pfm.Id;
                    pfm2.npe01__Opportunity_Field__c = strOppField;
                    pfm2.npe01__Payment_Field__c = strPmtField;
                    listPMTFieldMapping.add(pfm2);
                }
            }
            return listPMTFieldMapping;
        }
        private set;
    }

}