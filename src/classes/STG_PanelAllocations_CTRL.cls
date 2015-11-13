/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Settings
* @description Controller for the Allocations settings page.
*/

public with sharing class STG_PanelAllocations_CTRL extends STG_Panel { 

    /*********************************************************************************************************
    * @description Returns the string Id of the Allocations panel. 
    */
    public override string idPanel() { return 'idPanelAllocations'; }

    /*********************************************************************************************************
    * @description Whether we are currently running the batch process 
    */
    public boolean isRunningBatch { get; set; }

    /*********************************************************************************************************
    * @description The panel's constructor.
    */
    public STG_PanelAllocations_CTRL() {
        isRunningBatch = false;
    }

    /*********************************************************************************************************
    * @description An allocation, used to present a GAU lookup in the page to allow selecting a default GAU.
    */
    public static Allocation__c allo {
        get{
            if (allo == null) {
                allo = new Allocation__c();
                if (STG_Panel.stgService.stgAllo.Default__c!=null)
                    allo.General_Accounting_Unit__c = STG_Panel.stgService.stgAllo.Default__c;
            }
            return allo;

        }
        set;
    }

    /*********************************************************************************************************
    * @description The name of the default General Accounting Unit based on the ID stored in the custom setting.
    */
    static public string strDefaultGAUName {
        get {
            if (strDefaultGAUName == null) {
                if (!string.isBlank(STG_Panel.stgService.stgAllo.Default__c)) {
                    list<General_Accounting_Unit__c> listGAU = [select Id, Name from General_Accounting_Unit__c WHERE ID=:STG_Panel.stgService.stgAllo.Default__c];
                    if (!listGAU.isEmpty())
                        strDefaultGAUName = listGAU[0].Name;
                }
            }
            if (strDefaultGAUName == null)
                strDefaultGAUName = Label.stgLabelNone;
            return strDefaultGAUName;
        }
        private set;
    }
    
    /*********************************************************************************************************
    * @description Action Method to save the current settings
    * If default allocations are enabled, ensure a default GAU is selected.
    * @return STG_Panel saveSettings method. 
    */
    public override PageReference saveSettings() {
        
        if (STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.alloDefaultGAUMissing));
            return null;
        }

        STG_Panel.stgService.stgAllo.Default__c = allo.General_Accounting_Unit__c;
        strDefaultGAUName = null;

        return super.saveSettings();
    }

    /*********************************************************************************************************
    * @description Action Method to run the Batch Opp Rollups  
    * @return null
    */
    public PageReference runBatch() {
        // run batch rollup
        isRunningBatch = true;
        id batchProcessId = database.executeBatch(new ALLO_MakeDefaultAllocations_BATCH());
        return null;
    }
}