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
* @description Controller for the Allocations settings page.
 */

public with sharing class STG_PanelAllocations_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelAllocations'; }

    public boolean isRunningBatch { get; set; }

    public STG_PanelAllocations_CTRL() {
        isRunningBatch = false;
    }

    //generates a list of SelectOptions for all General Accounting Units to allow the user to select a default.
    static public list<SelectOption> listSOGeneralAccountingUnitIds {
        get {
            if (listSOGeneralAccountingUnitIds == null) {
                listSOGeneralAccountingUnitIds = new list<SelectOption>();
                list<General_Accounting_Unit__c> listGAU = [select Id, Name from General_Accounting_Unit__c WHERE Active__c = TRUE ORDER BY Name];
                if (listGAU.isEmpty()) {
                    listSOGeneralAccountingUnitIds.add(new SelectOption('', Label.stgLabelNone, true));
                } else for (General_Accounting_Unit__c gau : listGAU) {
                    listSOGeneralAccountingUnitIds.add(new SelectOption(gau.Id, gau.Name));
                }
            }
            return listSOGeneralAccountingUnitIds;
        }
        private set;
    }

    //pulls the name of the default General Accounting Unit based on the ID stored in the custom setting.
    static public string strDefaultGAUName {
        get {
            if (strDefaultGAUName == null) {
                ID id = STG_Panel.stgService.stgAllo.Default__c;
                if (id != null) {
                    list<General_Accounting_Unit__c> listGAU = [select Id, Name from General_Accounting_Unit__c WHERE ID=:id];
                    if (!listGAU.isEmpty())
                        strDefaultGAUName = listGAU[0].Name;
                }
            }
            if (strDefaultGAUName==null)
                strDefaultGAUName = Label.stgLabelNone;
            return strDefaultGAUName;
        }
        private set;
    }

    //this method runs each time the user selects the "Enable Allocations" checkbox
    //if no General Accounting Units exist, create one, then blank out the property
    //so that the rerender queries for the newly created GAU
    public pagereference enableDefaultAllocations() {
        if (listSOGeneralAccountingUnitIds.size() == 1 && listSOGeneralAccountingUnitIds[0].getValue()=='') {
            General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='General Fund');
            insert gau;
            listSOGeneralAccountingUnitIds = null;
        }
        return null;
    }

    public PageReference runBatch() {
        // run batch rollup
        isRunningBatch = true;
        id batchProcessId = database.executeBatch(new ALLO_MakeDefaultAllocations_BATCH());
        return null;
    }
}