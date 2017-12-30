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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Lightning Component Server Controller for the Rollups UI page CRLP_Setup.
*/

public with sharing class CRLP_RollupsUI_SVC {

    /*******************************************************************************************************
    * @description a class to hold only the required information from the rollup__mdt records for the rollup UI.
    */
    public class TableItem{
        @AuraEnabled public String rollupType;
        @AuraEnabled public String rollupName;
        @AuraEnabled public String targetField;
        @AuraEnabled public String operation;
        @AuraEnabled public String filterGroupName;
        @AuraEnabled public String active;
    }

    /*******************************************************************************************************
    * @description Creates a model to collect both the TableItems and the labels used on the page to minimize server trips.
    * Retrieving labels in Apex instead of lightning components avoids namespace complications.
    */
    public class RollupModel{
        @AuraEnabled public List<TableItem> items;
        @AuraEnabled public Map<String, String> labels;

    }
    /*******************************************************************************************************
    * @description Retrieves rollup definitions and creates the rollup model.
    * @return
    */
    @AuraEnabled
    public static RollupModel setupRollups() {
        RollupModel model = new RollupModel();

        model.items = getRollupDefinitions();
        model.labels = getRollupLabels();

        return model;
    }

    /*******************************************************************************************************
    * @description Queries from the rollup selector to fetch all rollup__mdt records. Parses so that only the relevant
    * information is returned, and a custom TableItem class is created with this information.
    * @return a list of all rollup definitions
    */
    @AuraEnabled
    public static List<TableItem> getRollupDefinitions(){
        List<TableItem> mdtTableList = new List<TableItem>();

        try{
            List<Rollup__mdt> mdtList = CRLP_Rollup_SEL.getRollupDefinitions();

            for(Integer i=0; i<mdtList.size(); i++){
                TableItem item = new TableItem();

                //item.rollupType = mdtList[i].Summary_Object__r.QualifiedAPIName;

                if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Account' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Opportunity') {
                    //item.rollupType = 'Opportunity to Account Hard Credit';
                    item.rollupType = mdtList[i].Summary_Object__r.Label+' to '+mdtList[i].Detail_Object__r.Label+' '+Label.CRLP_HardCredit;
                } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Account' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'npe01__OppPayment__c') {
                    item.rollupType = 'Payment to Account Hard Credit';
                } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Account' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Partial_Soft_Credit__c') {
                    item.rollupType = 'Opportunity to Account Soft Credit';
                } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Contact' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Opportunity') {
                    item.rollupType = 'Opportunity to Contact Hard Credit';
                } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Contact' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Partial_Soft_Credit__c') {
                    item.rollupType = 'Opportunity to Contact Soft Credit';
                } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'Contact' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'npe01__OppPayment__c') {
                    item.rollupType = 'Payment to Contact Hard Credit';
                } else if(mdtList[i].Summary_Object__r.QualifiedAPIName == 'General_Accounting_Unit__c' && mdtList[i].Detail_Object__r.QualifiedAPIName == 'Allocation__c') {
                    item.rollupType = 'Allocation to GAU';
                } else {
                    item.rollupType = Label.stgLabelOther;
                }
                System.debug(mdtList[i].Summary_Object__c);
                item.rollupName = mdtList[i].MasterLabel;
                item.targetField = mdtList[i].Summary_Field__r.Label;
                item.filterGroupName = mdtList[i].Filter_Group__r.MasterLabel;
                item.operation = mdtList[i].Operation__c.replace('_', ' ');
                item.active = String.valueOf(mdtList[i].Active__c).capitalize();

                mdtTableList.add(item);
            }
        }

        catch(exception e){
            throw new AuraHandledException('Unable to load rollup information at this time. Error: '
            + e.getMessage());
        }

        return mdtTableList;

    }

    /*******************************************************************************************************
    @description Fetches a list of labels for the rollups UI to avoid namespace issues within lightning components.
    * If any additional labels are required, they should be added here.
    * @return a list of all labels used in the rollups UI.
    */
    //TODO: should the labels live in an enum or elsewhere to be easily accessible for other pages?
    public static Map<String, String> getRollupLabels(){

        Map<String, String> labels = new Map<String,String>{
            'active' => Label.CRLP_Active,
            'cancel' => Label.stgBtnCancel,
            'clone' => Label.stgBtnClone,
            'delete' => Label.alloDeleteRow,
            'edit' => Label.stgBtnEdit,
            'filterCreate' => Label.CRLP_FilterCreate,
            'filterGroupName' => Label.CRLP_FilterGroupName,
            'filterGroupsTitle' => Label.CRLP_FilterGroups,
            'filterGroupsView' => Label.CRLP_FilterView,
            'filterNew' => Label.CRLP_FilterNew,
            'name' => Label.CRLP_Name,
            'operation' => Label.CRLP_Operation,
            'return' => Label.CRLP_Return,
            'rollupCreate' => Label.CRLP_RollupCreate,
            'rollupNew' => Label.CRLP_RollupNew,
            'rollupSummaryTitle' => Label.CRLP_RollupSummary,
            'rollupType' => Label.CRLP_RollupType,
            'save' => Label.stgBtnSave,
            'saveAndNew' => Label.lvlBtnSaveAndNew,
            'targetField' => Label.CRLP_TargetField
        };

        return labels;
    }

}