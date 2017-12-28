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

    public class RollupModel{
        @AuraEnabled public List<TableItem> items;
        //TODO: should the labels live in an enum or elsewhere to be easily accessible for other pages?
        @AuraEnabled public Map<String, String> labels = new Map<String,String>{
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

    }

    @AuraEnabled
    public static RollupModel setupRollups() {
        RollupModel model = new RollupModel();

        model.items = getRollupDefinitions();

        return model;
    }

    @AuraEnabled
    public static List<TableItem> getRollupDefinitions(){
        List<TableItem> mdtTableList = new List<TableItem>();

        try{
            List<Rollup__mdt> mdtList = CRLP_Rollup_SEL.getRollupDefinitions();

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
        }

        catch(exception e){
            throw new AuraHandledException('Unable to load rollup information at this time. Error: '
            + e.getMessage());
        }

        return mdtTableList;

    }

}