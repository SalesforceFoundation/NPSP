/**
 * Created by randi.wilson on 12/27/17.
 */

public with sharing class CRLP_RollupsUI_SVC {

    public class TableItem{
        @AuraEnabled public String rollupType;
        @AuraEnabled public String rollupName;
        @AuraEnabled public String targetField;
        @AuraEnabled public String operation;
        @AuraEnabled public String filterGroupName;
        @AuraEnabled public String active;
    }

    @AuraEnabled
    public static List<TableItem> getRollupDefinitions(){
        List<Rollup__mdt> mdtList = CRLP_Rollup_SEL.getRollupDefinitions();
        List<TableItem> mdtTableList = new List<TableItem>();

        for(Integer i=0; i<mdtList.size(); i++){
            TableItem item = new TableItem();

            item.rollupType = 'TBD';
            item.rollupName = mdtList[i].MasterLabel;
            item.targetField = mdtList[i].Summary_Field__r.Label;
            item.filterGroupName = mdtList[i].Filter_Group__r.MasterLabel;
            item.operation = mdtList[i].Operation__c.replace('_', ' ');
            item.active = String.valueOf(mdtList[i].Active__c).capitalize();

            mdtTableList.add(item);
        }
        System.debug(mdtTableList.size());
        System.debug(mdtTableList);
        return mdtTableList;
    }
}