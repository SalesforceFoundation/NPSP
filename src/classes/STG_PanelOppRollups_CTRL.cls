public with sharing class STG_PanelOppRollups_CTRL extends STG_Panel {

    public override string idPanel() { return 'idPanelOppRollup'; }
    
    // verify that if Use Fiscal Years is turned on, Custom Fiscal Years are not in place - called by HealthCheck
    public static void verifyFiscalYearRollups(STG_PanelHealthCheck_CTRL ctrl) {
        string strSetting = UTIL_Describe.getFieldLabel('npo02__Households_Settings__c', 'npo02__Use_Fiscal_Year_for_Rollups__c');    	
        if (STG_Panel.stgService.stgHH.npo02__Use_Fiscal_Year_for_Rollups__c == true) {
            String fyQuery = 'select id from FiscalYearSettings';            
            List<SObject> fySettings = new List<SObject>();
            fySettings = Database.query(fyQuery);
            integer hasCustomFYRecord = fySettings.size();
                
            //if org has customFY records, disable FY settings
            if (hasCustomFYRecord > 0) {
                ctrl.createDR(strSetting, 'Error', 'Fiscal Year Rollups are not supported when the organization is using Custom Fiscal Years', 
                    'Since Salesforce does not support turning off Custom Fiscal Years, NPSP Rollups will default to Calendar Year.');
                return;
            }            
        }
        ctrl.createDR(strSetting, 'Success', null, null);            
    }        
    
}