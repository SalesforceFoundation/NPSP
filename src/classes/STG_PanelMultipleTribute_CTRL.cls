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
* @group Settings
* @description Controller for the Multiple Tribute panel.
*/
public class STG_PanelMultipleTribute_CTRL extends STG_Panel {
    /*********************************************************************************************************
    * @description Returns the string Id of the Multiple Tribute panel.
    */
    public override string idPanel() { 
        return 'idPanelMultipleTribute'; 
        }

    /*********************************************************************************************************
    * @description Allows admins to pass in additional constraints to the Create Tribute Batch Job processing
    * Opportunities.
    */
    public String additionalWhereClause { public get; public set; }

    /*********************************************************************************************************
    * @description Whether we are running the Create Tribute from Opportunity Batch process.
    */
    public boolean isRunningBatch { get; set; }

    public boolean isBatchDisabled {
        public get {
            return TBU_MultipleTributesSettingsFacade.isMultipleTributesSingle();
        }
        private set;
    }

    public String getMultipleTributesSettingForDisplay() {
        return TBU_MultipleTributesSettingsFacade.getMultipleTributesSettingLocalized();
    }

    public List<SelectOption> getMultipleTributesOptions() {
        List<SelectOption> mtSettingsOptions = new List<SelectOption>();

        mtSettingsOptions.add(new SelectOption(TBU_MultipleTributesSettingsFacade.TRIBUTE_SINGLE_VAL, Label.stgMultipleTributesSingleOpp));
        mtSettingsOptions.add(new SelectOption(TBU_MultipleTributesSettingsFacade.TRIBUTE_MIXED_VAL, Label.stgMultipleTributesFlexible));
        mtSettingsOptions.add(new SelectOption(TBU_MultipleTributesSettingsFacade.TRIBUTE_MULTIPLE_VAL, Label.stgMultipleTributesLimited));

        return mtSettingsOptions;
    }

    /*********************************************************************************************************
    * @description Action Method to run Create Tribute from Opportunity Batch.
    * @return null
    */
    public PageReference runBatch() {
        //We only allow user to run the batch if user only use Tribute object
        if (!TBU_MultipleTributesSettingsFacade.isMultipleTributesLimited()) {
            isRunningBatch = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.errMultipleTributesBatchInvalid));
            return null;
        }
        isRunningBatch = true;

        Database.executeBatch(new OPP_CreateTribute_BATCH(additionalWhereClause), 200);

        return null;
    }
}