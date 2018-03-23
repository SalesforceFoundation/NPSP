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
* @group Opportunity Contact Role
* @group-content ../../ApexDocContent/Rollups.htm
* @description Batch Class for the deletion of the duplicate primary OCRs.
*/
public class OPP_PrimaryContactRoleMerge_BATCH  implements Database.Batchable<sObject> {

    /******************************************************************************************************
    * @description Batch start method. Run through all the Opportunities in the org.
    */
    public Database.QueryLocator start(Database.batchableContext info) {
        return Database.getQueryLocator('SELECT Id FROM Opportunity');
    }

    /*******************************************************************************************************
    * @description Batch execute method. It gets the Opportunities with duplicate primary OCRs and runs 
    * the logic that remove the Primary OCR duplicates.
    * @return void.
    ********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<AggregateResult> primaryOCRsAggregateResult = getPrimaryOCRsAggregateResult(scope);
        OPP_PrimaryContactRoleMerge.DuplicatePrimaryOCRs duplicatePrimaryOCRs  = new OPP_PrimaryContactRoleMerge.DuplicatePrimaryOCRs(primaryOCRsAggregateResult);

        String settingsRole = UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c;
        OPP_PrimaryContactRoleMerge.Errors errors = validateOpportunityOCRs(duplicatePrimaryOCRs, settingsRole);
        mergeDuplicatePrimaryOCRs(duplicatePrimaryOCRs, settingsRole);
    }

    /******************************************************************************************************
    * @description Batch finish method.
    */
    public void finish(Database.batchableContext info) {
        
    }

    /*******************************************************************************************************
    * @description Gets the Opportunities with duplicate primary OCRs.
    * @param List<Opportunity> The List of the Opportunities.
    * @return List<AggregateResult> The Aggegate Result that contains the List of the duplicate primary OCRs.
    ********************************************************************************************************/
    private List<AggregateResult> getPrimaryOCRsAggregateResult(List<Opportunity> opportunities) {
        return [
            SELECT OpportunityId 
            FROM OpportunityContactRole 
            WHERE IsPrimary = true 
            AND OpportunityId IN :opportunities
            GROUP BY OpportunityId 
            HAVING COUNT(Id) > 1
        ];
    }

    /*******************************************************************************************************
    * @description Validates if the Opportunity primary OCRs contains at least the Role defined
    * in the NPSP Settings. If there is no OCR with NPSP Settings Role, then log an error.
    * @param DuplicatePrimaryOCRs The Duplicate Primary OCRs object.
    * @param String The Role defined in NPSP Settings.
    * @return Errors The errors object.
    ********************************************************************************************************/
    private OPP_PrimaryContactRoleMerge.Errors validateOpportunityOCRs(OPP_PrimaryContactRoleMerge.DuplicatePrimaryOCRs duplicatePrimaryOCRs, String settingsRole) {
        OPP_PrimaryContactRoleMerge.Errors errors = new OPP_PrimaryContactRoleMerge.Errors();
        for (Opportunity opportunityRecord : duplicatePrimaryOCRs.getOpportunities()) {
            OPP_PrimaryContactRoleMerge.OpportunityPrimaryOCRs opportunityPrimaryOCRs = new OPP_PrimaryContactRoleMerge.OpportunityPrimaryOCRs(opportunityRecord);

            if (opportunityPrimaryOCRs.containsRole(settingsRole) == false) {
                errors.add(opportunityRecord);
            }
        }
        errors.processDML();
        return errors;
    }

    /*******************************************************************************************************
    * @description Merges the Opportunity primary OCRs, by deleting the OCRs with blank roles and
    * roles different than the one defined in the NPSP Settings. 
    * @param DuplicatePrimaryOCRs The Duplicate Primary OCRs object.
    * @param String The Role defined in NPSP Settings.
    * @return void.
    ********************************************************************************************************/
    private void mergeDuplicatePrimaryOCRs(OPP_PrimaryContactRoleMerge.DuplicatePrimaryOCRs duplicatePrimaryOCRs, String settingsRole) {
        for (Opportunity opportunityRecord : duplicatePrimaryOCRs.getOpportunities()) {
            OPP_PrimaryContactRoleMerge.OpportunityPrimaryOCRs opportunityPrimaryOCRs = new OPP_PrimaryContactRoleMerge.OpportunityPrimaryOCRs(opportunityRecord);
            if (opportunityPrimaryOCRs.containsRole(settingsRole)) {
                duplicatePrimaryOCRs.deleteRecords(opportunityPrimaryOCRs.getBlankRole());
                duplicatePrimaryOCRs.deleteRecords(opportunityPrimaryOCRs.getRoleNotEquals(settingsRole));
                List<OpportunityContactRole> settingsRoleOCRs = opportunityPrimaryOCRs.getRoleEquals(settingsRole);
                duplicatePrimaryOCRs.makePrimary(settingsRoleOCRs[0]);
                settingsRoleOCRs.remove(0);
                duplicatePrimaryOCRs.deleteRecords(settingsRoleOCRs);
            }
        }
        duplicatePrimaryOCRs.processDML();
    }
}