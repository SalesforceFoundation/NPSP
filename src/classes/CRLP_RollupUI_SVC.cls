/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Lightning Component Server Controller for the Rollups UI page CRLP_Setup.
*/

public with sharing class CRLP_RollupUI_SVC {

    /*******************************************************************************************************
    * @description a class to hold only the required information from the rollup__mdt records for the rollup UI.
    */
    public class RollupTableItem {
        @AuraEnabled public String active;
        @AuraEnabled public String activeIcon;
        @AuraEnabled public String creditType;
        @AuraEnabled public String description;
        @AuraEnabled public String detailField;
        @AuraEnabled public String detailObject;
        @AuraEnabled public String filterGroupName;
        @AuraEnabled public String operation;
        @AuraEnabled public String rollupName;
        @AuraEnabled public String summaryObject;
        @AuraEnabled public String summaryObjectApiName;
        @AuraEnabled public Id id;

    }
    /*******************************************************************************************************
    * @description a class to hold only the required information from the filter_group__mdt records for the filter group UI.
    */
    public class FilterGroupTableItem{
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public Integer countFilterRules;
        @AuraEnabled public Integer countRollups;
        @AuraEnabled public String name;
        @AuraEnabled public Id id;
    }

    /*******************************************************************************************************
    * @description a class to hold only the required information from the filter_rule__mdt records for the filter group detail.
    */
    public class FilterRulesTableItem{
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String operator;
        @AuraEnabled public String constant;
        @AuraEnabled public Id id;
    }

    /*******************************************************************************************************
    * @description Creates a model to collect both the RollupTableItems and the labels used on the page to minimize server trips.
    * Retrieving labels in Apex instead of lightning components avoids namespace complications.
    */
    public class RollupGridModel {
        @AuraEnabled public List<RollupTableItem> items;
        @AuraEnabled public Map<String, String> labels;
        @AuraEnabled public List<FilterGroupTableItem> filterGroups;

    }

    /*******************************************************************************************************
    * @description Creates a model to collect both the RollupTableItems and the labels used on the page to minimize server trips.
    * Retrieving labels in Apex instead of lightning components avoids namespace complications.
    */
    public class RollupDetailModel {
        @AuraEnabled public Rollup__mdt rollup;
        @AuraEnabled public Map<String,List<Map<String,String>>> fieldsByDataType;
        @AuraEnabled public Map<String, String> timeBoundOperations;
        @AuraEnabled public Map<String, String> operations;

    }

    /*******************************************************************************************************
    * @description Creates a model to collect both the Filter Group and Filter Rules used on the page to minimize server trips.
    * Filter rules need to be flattened for use within the lightning:datatable.
    */
    public class FilterGroupModel {
        @AuraEnabled public Filter_Group__mdt filterGroup;
        @AuraEnabled public List<FilterRulesTableItem> filterRuleList;

    }

    /*******************************************************************************************************
    * @description Retrieves rollup definitions and creates the rollup model.
    * @return rollup grid model
    */
    @AuraEnabled
    public static String setupRollupGrid() {
        RollupGridModel model = new RollupGridModel();

        model.items = getRollupDefinitions();
        model.labels = getRollupLabels();
        model.filterGroups = getFilterGroupDefinitions();

        //serialize to avoid passing inner classes, which is technically unsupported
        String modelString = JSON.serialize(model);
        return modelString;
    }

    /*******************************************************************************************************
    * @description Retrieves rollup definitions and creates the rollup model.
    * @param targetObjectNames list of target objects used in rollups
    * @param detailObjectNames list of detail objects used in rollups
    * @return model with optional rollup and fields with data types
    */
    @AuraEnabled
    public static String setupRollupDetail(String rollupId, List<String> targetObjectNames, List<String> detailObjectNames) {
        RollupDetailModel model = new RollupDetailModel();
        String summaryField = '';

        if(rollupId != ''){
            Id id = Id.valueOf(rollupId);
            model.rollup = getRollupById(id);
            summaryField = model.rollup.Summary_Field__r.QualifiedApiName;
        }
        model.fieldsByDataType = getFieldsByDataType(summaryField, targetObjectNames, detailObjectNames);
        model.timeBoundOperations = getTimeBoundOperations();
        model.operations = getRollupOperations();

        //serialize to avoid passing inner classes, which is technically unsupported
        String modelString = JSON.serialize(model);
        return modelString;
    }

    /*******************************************************************************************************
    * @description Queries from the rollup selector to fetch all rollup__mdt records. Parses so that only the relevant
    * information is returned, and a custom RollupTableItem class is created with this information.
    * @return a list of all rollup definitions
    */
    @AuraEnabled
    public static List<RollupTableItem> getRollupDefinitions() {
        List<RollupTableItem> mdtTableList = new List<RollupTableItem>();

        List<Rollup__mdt> mdtList = CRLP_Rollup_SEL.getRollupDefinitions();
        Map<CRLP_Operation.RollupType, String> operationTypes = CRLP_Operation.getRollupOperationTypes();

        for(Integer i=0; i<mdtList.size(); i++){
            RollupTableItem item = new RollupTableItem();

            if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Account'
                    && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Opportunity') {
                item.creditType = Label.CRLP_HardCredit;
            } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Account'
                    && mdtList[i].Detail_Object__r.QualifiedAPIName == 'npe01__OppPayment__c') {
                item.creditType = Label.CRLP_HardCredit;
            } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Account'
                    && mdtList[i].Detail_Object__r.QualifiedAPIName == UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')) {
                item.creditType = Label.CRLP_SoftCredit;
            } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Contact'
                    && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Opportunity') {
                item.creditType = Label.CRLP_HardCredit;
            } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Contact'
                    && mdtList[i].Detail_Object__r.QualifiedAPIName == UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')) {
                item.creditType = Label.CRLP_SoftCredit;
            } else {
                item.creditType = Label.stgNotApplicable;
            }
            item.detailObject = mdtList[i].Detail_Object__r.Label;
            item.summaryObject = mdtList[i].Summary_Object__r.Label;
            item.summaryObjectApiName = mdtList[i].Summary_Object__r.QualifiedApiName;
            item.rollupName = mdtList[i].MasterLabel;
            item.detailField = mdtList[i].Detail_Field__r.Label;
            item.description = mdtList[i].Description__c;
            item.filterGroupName = mdtList[i].Filter_Group__r.MasterLabel;
            item.operation = mdtList[i].Operation__c.replace('_', ' ');
            if(mdtList[i].Active__c){
                item.activeIcon = 'utility:check';
            } else {
                item.activeIcon = 'utility:close';
            }
            item.id = mdtList[i].Id;

            mdtTableList.add(item);
        }

        return mdtTableList;

    }

    /*******************************************************************************************************
    * @description Queries from the Filter Rule selector to fetch all Filter_Group__mdt records. Parses so that only the relevant
    * information is returned, and a custom FilterGroupTableItem class is created with this information.
    * @return a list of all filter group definitions
    */
    @AuraEnabled
    public static List<FilterGroupTableItem> getFilterGroupDefinitions() {

        List<FilterGroupTableItem> mdtTableList = new List<FilterGroupTableItem>();
        List<Filter_Group__mdt> mdtList = CMT_FilterRule_SEL.getFilterGroups();
        Map<Id, List<Rollup__mdt>> rollupsByFilterGroup = CRLP_Rollup_SEL.getRollupsByFilterGroup();

        for(Integer i=0; i<mdtList.size(); i++) {
            FilterGroupTableItem item = new FilterGroupTableItem();

            item.label = mdtList[i].MasterLabel;
            item.name = mdtList[i].DeveloperName;
            item.description = mdtList[i].Description__c;
            item.countFilterRules = mdtList[i].Filter_Rules__r.size();
            item.countRollups = rollupsByFilterGroup.get(mdtList[i].Id).size();
            item.id = mdtList[i].Id;

            mdtTableList.add(item);
        }

        return mdtTableList;

    }

    /*******************************************************************************************************
    * @description Queries from the Filter Rule metadata to fetch all operation values.
    * @return a map of picklist options api values to labels
    */
    @AuraEnabled
    public static Map<String,String> getFilterRuleOperations() {

        Map<String,String> filterRuleOperations = new Map<String,String>();

        Schema.DescribeFieldResult field = Filter_Rule__mdt.Operator__c.getDescribe();

        for (Schema.PicklistEntry f : field.getPicklistValues()) {
            filterRuleOperations.put(f.getValue(), f.getLabel());
        }
        return filterRuleOperations;
    }

    /*******************************************************************************************************
    * @description Fetches a single FilterGroup__mdt record by Id and associated FilterRule__mdt records.
    * @param id the filter group ID
    * @return a FilterGroup__mdt record and related FilterRule__mdt records.
    */

    @AuraEnabled
    public static FilterGroupModel getFilterGroupById(Id id) {

        List<FilterRulesTableItem> mdtTableList = new List<FilterRulesTableItem>();
        Map<String,String> operators = getfilterRuleOperations();

        Filter_Group__mdt filterGroup = [SELECT Id
                , DeveloperName
                , MasterLabel
                , Description__c
        FROM Filter_Group__mdt
        WHERE Id = :id];

        List<Filter_Rule__mdt> mdtList = [SELECT Id, Operator__c, Constant__c, Field__r.MasterLabel, Object__r.MasterLabel FROM Filter_Rule__mdt WHERE Filter_Group__c = :id];

        for(Integer i=0; i<mdtList.size(); i++) {
            FilterRulesTableItem item = new FilterRulesTableItem();

            String c = mdtList[i].Constant__c;
            item.constant = c.replace(';', '\n');
            item.operator = operators.get(mdtList[i].Operator__c);
            item.fieldLabel = mdtList[i].Field__r.MasterLabel;
            item.objectLabel = mdtList[i].Object__r.MasterLabel;
            item.id = mdtList[i].id;

            mdtTableList.add(item);
        }

        FilterGroupModel model = new FilterGroupModel();

        model.filterGroup = filterGroup;
        model.filterRuleList = mdtTableList;

        return model;
    }


    /*******************************************************************************************************
    * @description Queries from the Rollup operations to fetch all rollup operation values.
    * @return a map of picklist options api values to labels
    */
    @AuraEnabled
    public static Map<String,String> getRollupOperations() {

        Map<String,String> rollupOperations = new Map<String,String>();

        Schema.DescribeFieldResult field = Rollup__mdt.Operation__c.getDescribe();

        for (Schema.PicklistEntry f : field.getPicklistValues()) {
            rollupOperations.put(f.getValue(), f.getLabel());
        }
        return rollupOperations;
    }

    /*******************************************************************************************************
    * @description Queries from the Rollup yearly operation types to fetch all yearly operation values.
    * @return a map of picklist yearly operations api values to labels
    */
    @AuraEnabled
    public static Map<String,String> getTimeBoundOperations() {

        Map<String,String> timeBoundOperations = new Map<String,String>();

        Schema.DescribeFieldResult field = Rollup__mdt.Time_Bound_Operation_Type__c.getDescribe();

        for (Schema.PicklistEntry f : field.getPicklistValues()) {
            timeBoundOperations.put(f.getValue(), f.getLabel());
        }
        return timeBoundOperations;
    }

    /*******************************************************************************************************
    @description Fetches a single Rollup__mdt record by Id.
    * @return a Rollup__mdt record.
    */

    @AuraEnabled
    public static Rollup__mdt getRollupById(Id id) {

        Rollup__mdt rollup = CRLP_Rollup_SEL.getRollupsById(Id);

        return rollup;
    }

    /*******************************************************************************************************
    @description Fetches all field labels, mapped to their data types, for a list of objects.
    * @param summaryField a summary field already being used to include in the type list
    * @param targetObjectNames list of target or summary objects to query
    * @param detailObjectNames list of detail or objects to rollup to query
    * @return a map of strings to string-string maps. Map<String,Map<String,String>>
    */

    @AuraEnabled
    public static Map<String,List<Map<String,String>>> getFieldsByDataType(String summaryField, List<String> targetObjectNames, List<String> detailObjectNames) {

        Map<String,List<Map<String,String>>> objNameToFieldTypeMap = new Map<String,List<Map<String,String>>>();

        for(String detailObj : detailObjectNames){
            List<Map<String, String>> detailNameToFieldTypeObj = UTIL_Describe.getAllFieldsWithType(detailObj);
            objNameToFieldTypeMap.put(detailObj, detailNameToFieldTypeObj);
        }
        for(String targetObj : targetObjectNames){
            List<Map<String, String>> summaryNameToFieldTypeObj = getTargetFieldsWithType(targetObj, summaryField);
            objNameToFieldTypeMap.put(targetObj, summaryNameToFieldTypeObj);
        }

        return objNameToFieldTypeMap;
    }


    /*******************************************************************************************************
    @description Fetches a list of labels for the rollups UI to avoid namespace issues within lightning components.
    * If any additional labels are required, they should be added here.
    * @return a list of all labels used in the rollups UI.
    */
    //TODO: should the labels live in an enum or elsewhere to be easily accessible for other pages?
    public static Map<String, String> getRollupLabels() {

            Map<String, String> labels = new Map<String,String>
            {
                'action' => Label.stgLabelActionColumn,
                'active' => Schema.Rollup__mdt.Active__c.getDescribe().getLabel(),
                'advancedCustomizationHeader' => Label.CRLP_AdvancedCustomizationHeader,
                'advancedCustomizationText' => Label.CRLP_AdvancedCustomizationText,
                'amountField' => Schema.Rollup__mdt.Amount_Field__c.getDescribe().getLabel(),
                'amountObject' => Schema.Rollup__mdt.Amount_Object__c.getDescribe().getLabel(),
                'availableRollupTypes' => Label.CRLP_AvailableRollupType,
                'cancel' => Label.stgBtnCancel,
                'checkboxTrue' => Label.stgCheckboxTrue,
                'checkboxFalse' => Label.stgCheckboxFalse,
                'clone' => Label.stgBtnClone,
                'constant' => Schema.Filter_Rule__mdt.Constant__c.getDescribe().getLabel(),
                'countOf' => Label.stgCountOf,
                'create' => Label.stgCreate,
                'createIntroHelp' => Label.CRLP_CreateRollupIntroHelpText,
                'createTargetObjectHelp' => Label.CRLP_CreateRollupTargetObjectHelpText,
                'createTargetFieldHelp' => Label.CRLP_CreateRollupTargetFieldHelpText,
                'createActiveHelp' => Label.CRLP_CreateRollupActiveHelpText,
                'createDescriptionHelp' => Label.CRLP_CreateRollupDescriptionHelpText,
                'createRollupTypeHelp' => Label.CRLP_CreateRollupTypeHelpText,
                'createFilterGroupHelp' => Label.CRLP_CreateRollupFilterGroupHelpText,
                'createOperationHelp' => Label.CRLP_CreateRollupOperationHelpText,
                'createFiscalYearHelp' => Label.CRLP_CreateRollupFiscalYearHelpText,
                'createTimeBoundHelp' => Label.CRLP_CreateRollupTimeBoundOperationHelpText,
                'createYearsHelp' => Label.CRLP_CreateRollupYearsAgoHelpText,
                'createDaysHelp' => Label.CRLP_CreateRollupDaysBackHelpText,
                'createDetailFieldHelp' => Label.CRLP_CreateRollupDetailFieldHelpText,
                'createDateFieldHelp' => Label.CRLP_CreateRollupDateFieldHelpText,
                'createAmountFieldHelp' => Label.CRLP_CreateRollupAmountFieldHelpText,
                'creditType' => Label.CRLP_CreditType,
                'dateField' => Schema.Rollup__mdt.Date_Field__c.getDescribe().getLabel(),
                'dateObject' => Schema.Rollup__mdt.Date_Object__c.getDescribe().getLabel(),
                'delete' => Label.alloDeleteRow,
                'detailField' => Schema.Rollup__mdt.Detail_Field__c.getDescribe().getLabel(),
                'detailObject' => Schema.Rollup__mdt.Detail_Object__c.getDescribe().getLabel(),
                'description' => Schema.Rollup__mdt.Description__c.getDescribe().getLabel(),
                'edit' => Label.stgBtnEdit,
                'field' => Schema.Filter_Rule__mdt.Field__c.getDescribe().getLabel(),
                'filterGroupDescription' => Schema.Filter_Group__mdt.Description__c.getDescribe().getLabel(),
                'filterGroupLabel' => Schema.SObjectType.Filter_Group__mdt.getLabel(),
                'filterGroupLabelPlural' => Schema.SObjectType.Filter_Group__mdt.getLabelPlural(),
                'filterGroupNew' => Label.CMT_FilterNew,
                'filterRuleLabel' => Schema.SObjectType.Filter_Rule__mdt.getLabel(),
                'filterRuleLabelPlural' => Schema.SObjectType.Filter_Rule__mdt.getLabelPlural(),
                'hardCredit' => Label.CRLP_HardCredit,
                'integer' => Schema.Rollup__mdt.Integer__c.getDescribe().getLabel(),
                'integerError' => String.format(Label.bdiPositiveNumber, new List<String>{Schema.Rollup__mdt.Integer__c.getDescribe().getLabel()}),
                'labelAccount' => Schema.SObjectType.Account.getLabel(),
                'labelAllocation' => Schema.SObjectType.Allocation__c.getLabel(),
                'labelContact' => Schema.SObjectType.Contact.getLabel(),
                'labelGAU' => Schema.SObjectType.General_Accounting_Unit__c.getLabel(),
                'labelPayment' => Schema.SObjectType.npe01__OppPayment__c.getLabel(),
                'labelOpportunity' => Schema.SObjectType.Opportunity.getLabel(),
                'labelPartialSoftCredit' => Schema.SObjectType.Partial_Soft_Credit__c.getLabel(),
                'labelRD' => Schema.SObjectType.npe03__Recurring_Donation__c.getLabel(),
                'name' => Label.stgLabelName,
                'na' => Label.stgNotApplicable,
                'next' => Label.labelListViewNext,
                'noFields' => Label.stgLabelPaymentMapNoValidFields,
                'noObjects' => String.format(Label.stgNoObjectsFound, new List<String>{Schema.Filter_Rule__mdt.Object__c.getDescribe().getLabel().toLowerCase()}),
                'noFilterGroups' => String.format(Label.stgNoObjectsFound, new List<String>{Schema.SObjectType.Filter_Group__mdt.getLabelPlural()}),
                'noFilterRules' => String.format(Label.stgNoObjectsFound, new List<String>{Schema.SObjectType.Filter_Rule__mdt.getLabelPlural()}),
                'noRollupType' => Label.CRLP_NoRollupType,
                'noRollups' => String.format(Label.stgNoObjectsFound, new List<String>{Schema.SObjectType.Rollup__mdt.getLabelPlural()}),
                'object' => Schema.Filter_Rule__mdt.Object__c.getDescribe().getLabel(),
                'objectAccount' => Schema.SObjectType.Account.getName(),
                'objectAllocation' => Schema.SObjectType.Allocation__c.getName(),
                'objectContact' => Schema.SObjectType.Contact.getName(),
                'objectGAU' => Schema.SObjectType.General_Accounting_Unit__c.getName(),
                'objectPayment' => Schema.SObjectType.npe01__OppPayment__c.getName(),
                'objectOpportunity' => Schema.SObjectType.Opportunity.getName(),
                'objectPartialSoftCredit' => Schema.SObjectType.Partial_Soft_Credit__c.getName(),
                'objectRD' => Schema.SObjectType.npe03__Recurring_Donation__c.getName(),
                'operation' => Schema.Rollup__mdt.Operation__c.getDescribe().getLabel(),
                'operator' => Schema.Filter_Rule__mdt.Operator__c.getDescribe().getLabel(),
                'picklistLabelLastYear' => Label.stgLabelYearPicklistLastYear,
                'picklistLabelThisYear' => Label.stgLabelYearPicklistThisYear,
                'returnNPSP' => String.format(Label.CRLP_Return, new List<String>{Label.lblNPSPSettings}),
                'returnFilterGroup' => String.format(Label.CRLP_Return, new List<String>{Schema.SObjectType.Filter_Group__mdt.getLabel()}),
                'rollupLabel' => Schema.SObjectType.Rollup__mdt.getLabel(),
                'rollupLabelPlural' => Schema.SObjectType.Rollup__mdt.getLabelPlural(),
                'rollupNew' => Label.CRLP_RollupNew,
                'rollupsByFilterGroup' => Label.CRLP_RollupsByFilterGroup,
                'rollupSummaryTitle' => Label.CRLP_RollupSummary,
                'rollupType' => Label.CRLP_RollupType,
                'save' => Label.stgBtnSave,
                'saveAndNew' => Label.lvlBtnSaveAndNew,
                'selectOne' => Label.stgSelectOne,
                'selectAll' => Label.conMergeSelectAll,
                'softCredit' => Label.CRLP_SoftCredit,
                'summaryField' => Schema.Rollup__mdt.Summary_Field__c.getDescribe().getLabel(),
                'summaryObject' => Schema.Rollup__mdt.Summary_Object__c.getDescribe().getLabel(),
                'useFiscalYear' => Schema.Rollup__mdt.Use_Fiscal_Year__c.getDescribe().getLabel(),
                'view' => Label.stgLabelView,
                'timeBoundOperationType' => Schema.Rollup__mdt.Time_Bound_Operation_Type__c.getDescribe().getLabel()
            };

        for (Integer i = 2; i < 21; i++) {
            String key = 'picklistLabelYearsAgo' + i;
            String value = String.format(Label.stgLabelYearPicklistYearsAgo, new List<String>{String.valueOf(i)});
            labels.put(key, value);
        }

        return labels;
    }

    /*******************************************************************************************************
    * @description Finds writable, custom, unused target fields of specific types to provide field lists for Rollup definitions.
    *              Includes an exception for a set summary field on the rollup detail.
    * @param objectName the name of the object to look up
    * @param selectedField the name of a summary field already in use
    * @return List<Map<String, String>> an object with field api names, labels and data type.
    */
    public static List<Map<String, String>> getTargetFieldsWithType(String objectName, String selectedField) {

        List<Map<String, String>> fieldObjectList = new List<Map<String, String>>();

        Map<String, Schema.DescribeFieldResult> objectFields = UTIL_Describe.getAllFieldsDescribe(objectName);
        Schema.SObjectType sobjType = UTIL_Describe.getSObjectType(objectName);
        List<Schema.DescribeFieldResult> referencedFields = CRLP_Rollup_SEL.getReferencedFieldsByObject(sobjType);
        Set<Schema.DescribeFieldResult> referencedFieldSet = new Set<Schema.DescribeFieldResult>(referencedFields);

        for (Schema.DescribeFieldResult dfr : objectFields.values()) {
            //valid types are taken from the DisplayType Enum and only include values that make sense to roll up
            String type = dfr.getType().Name();
            Set<String> validTypeSet = new Set<String>{'CURRENCY', 'DATE', 'DATETIME', 'DOUBLE', 'INTEGER', 'MULTIPICKLIST', 'PICKLIST', 'REFERENCE', 'STRING', 'TEXTAREA'};
            Boolean isValidType = validTypeSet.contains(type);

            //check that summary field isn't being used on another rollup
            Boolean isRolledUp = referencedFieldSet.contains(dfr);

            if((dfr.isUpdateable() && dfr.isCustom() && !dfr.name.toLowerCase().contains('__system') && isValidType && !isRolledUp)
                    || selectedField.equals(dfr.name)){
                Map<String, String> fieldObject = new Map<String, String>();
                fieldObject.put('name', dfr.name);
                fieldObject.put('label', dfr.label);
                fieldObject.put('type', type);

                fieldObjectList.add(fieldObject);
            }
        }

        return fieldObjectList;
    }

}