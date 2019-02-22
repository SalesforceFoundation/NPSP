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
* @group Opportunity Contact Role.
* @description Domain Classes for the deletion of duplicate primary OCRs. 
*/

public with sharing class OPP_PrimaryContactRoleMerge {

    @TestVisible private static final String ERROR_MESSAGE = Label.OCRRemovePrimaryDuplicateBatchErrorText;
    @TestVisible private static final String ERROR_CONTEXT = 'Remove Duplicate Primary OCRs';
    @TestVisible private static final String ERROR_SOBJECT = UTIL_Describe.getObjectLabel('Opportunity');

    private List<AggregateResult> primaryOCRsAggregateResult;

    public OPP_PrimaryContactRoleMerge(List<Opportunity> opportunities) {
        primaryOCRsAggregateResult = getPrimaryOCRsAggregateResult(opportunities);
    }

    /*******************************************************************************************************
    * @description Removes the duplicate primary OCRs.
    * @return void.
    ********************************************************************************************************/
    public void run() {
        List<Error__c> errors = new List<Error__c>();
        DuplicatePrimaryOCRs duplicatePrimaryOCRs = new DuplicatePrimaryOCRs(primaryOCRsAggregateResult);

        for (Opportunity opportunityRecord : duplicatePrimaryOCRs.getOpportunities()) {
            String settingsRole = getSettingsRole(opportunityRecord.Account);
            OpportunityPrimaryOCRs opportunityPrimaryOCRs = new OpportunityPrimaryOCRs(opportunityRecord);

            if (opportunityPrimaryOCRs.containsRole(settingsRole) == false) {
                errors.add(createError(opportunityRecord));
            }
            else {
                List<OpportunityContactRole> ocrsWithSettingsRole = opportunityPrimaryOCRs.getRolesEqual(settingsRole);
                duplicatePrimaryOCRs.makePrimary(ocrsWithSettingsRole[0]);
            }
        }

        insert errors;
        duplicatePrimaryOCRs.processDML();
    }

    /*******************************************************************************************************
    * @description Gets the Opportunities with duplicate primary OCRs.
    * @param List<Opportunity>. The List of the Opportunities.
    * @return List<AggregateResult>. The Aggregate Result that contains the List of the duplicate primary OCRs.
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
    * @description Gets the NPSP Settings Role based on the Account type.
    * @param Account. The Opportunity Account.
    * @return String. The NPSP Settings Role based on the Account Type.
    ********************************************************************************************************/
    private String getSettingsRole(Account inputAccount) {
        return inputAccount.npe01__SYSTEMIsIndividual__c ? 
                UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c :
                UTIL_CustomSettingsFacade.getContactsSettings().Contact_Role_for_Organizational_Opps__c;
    }

    /*******************************************************************************************************
    * @description Creates an error log for the Opportunity in the parameter.
    * @param Opportunity. The Opportunity with the error.
    * @return Error__c.
    ********************************************************************************************************/
    private Error__c createError(Opportunity opportunity) {
        return new Error__c(
            Datetime__c = System.now(),
            Full_Message__c = String.format(ERROR_MESSAGE, new List<String>{opportunity.Name}),
            Record_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + opportunity.Id,
            Context_Type__c = ERROR_CONTEXT,
            Object_Type__c = ERROR_SOBJECT
        );
    }

    /*******************************************************************************************************
    * @description The Duplicate Primary Opportunity Contact Roles Wrapper. It contains the logic that loads  
    * and manages the duplicate Primary OCRs and the related Opportunities.
    ********************************************************************************************************/
    class DuplicatePrimaryOCRs {
        private Map<Id, Opportunity> opportunityRecords;
        private Map<Id, OpportunityContactRole> ocrRecordsToUpdate;
        private Map<Id, OpportunityContactRole> ocrRecordsToDelete;

        /*********************************************************************************************************
        * @description The Constructor of DuplicatePrimaryOCRs.
        * @param List<AggregateResult>. The duplicate primary OCRs Aggregate Result. 
        */
        public DuplicatePrimaryOCRs(List<AggregateResult> primaryOCRsAggregateResult) {
            opportunityRecords = new Map<Id, Opportunity>(loadOpportunities(primaryOCRsAggregateResult));
            ocrRecordsToUpdate = new Map<Id, OpportunityContactRole>();
            ocrRecordsToDelete = new Map<Id, OpportunityContactRole>();
        }

        /*******************************************************************************************************
        * @description Gets the duplicate primary OCRs Opportunities. 
        * @return List<Opportunity> The duplicate primary OCRs Opportunities.
        ********************************************************************************************************/
        public List<Opportunity> getOpportunities() {
            return opportunityRecords.values();
        }

        /*******************************************************************************************************
        * @description Sets the OCR in paramater as Primary OCR.
        * @param OpportunityContactRole. The OCR to set as primary.
        * @return void.
        ********************************************************************************************************/
        public void makePrimary(OpportunityContactRole inputOCR) {
            Opportunity opportunityToUpdate = opportunityRecords.get(inputOCR.OpportunityId);
            for (OpportunityContactRole ocr : opportunityToUpdate.OpportunityContactRoles) {
                // Delete the inputOCR duplicates (same Contact)
                if (ocr.Id != inputOCR.Id && ocr.ContactId == inputOCR.ContactId) {
                    ocrRecordsToDelete.put(ocr.Id, ocr);
                }
                // After a deletion of one duplicate Primary OCR, Salesforce updates all the OCRs' IsPrimary field to false.
                // So, we need to force the update of the input OCR even if the OCR is already a Primary OCR.
                if (ocr.Id == inputOCR.Id) {
                    ocr.IsPrimary = true;
                    ocrRecordsToUpdate.put(ocr.Id, ocr);
                }
            }
        }

        /*******************************************************************************************************
        * @description Commits the DMLs (delete/Update OCRs)
        * @return void.
        ********************************************************************************************************/
        public void processDML() {
            delete ocrRecordsToDelete.values();
            update ocrRecordsToUpdate.values();
        }

        /*******************************************************************************************************
        * @description Gets the Opportunities with their related primary OCRs.
        * @param List<AggregateResult>. The duplicate primary OCRs Aggregate Result.
        * @return List<Opportunity>. 
        ********************************************************************************************************/
        private List<Opportunity> loadOpportunities(List<AggregateResult> primaryOCRsAggregateResult) {
            Set<Id> opportunityIds = new Set<Id>();
            for (AggregateResult aggregateResult : primaryOCRsAggregateResult) {
                opportunityIds.add((Id) aggregateResult.get('OpportunityId'));
            }
            return [
                SELECT Name, Primary_Contact__c, Account.npe01__SYSTEMIsIndividual__c, (
                    SELECT OpportunityId, ContactId, Role, IsPrimary
                    FROM OpportunityContactRoles
                    WHERE IsPrimary = true
                )
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that wraps an Opportunity and its related duplicate Primary OCRs.
    ********************************************************************************************************/
    class OpportunityPrimaryOCRs {
        private Opportunity record;

        /*********************************************************************************************************
        * @description The Constructor of OpportunityPrimaryOCRs.
        * @param Opportunity. Opportunity with the related primary OCRs.
        */
        public OpportunityPrimaryOCRs(Opportunity currentOpportunity) {
            record = currentOpportunity;
        }

        /*******************************************************************************************************
        * @description Checks if the Opportunity has a Primary OCR Role equals to the Role in the parameter.
        * @param String OCR Role.
        * @return Boolean.
        ********************************************************************************************************/
        public Boolean containsRole(String ocrRole) {
            return getRolesEqual(ocrRole).isEmpty() == false;
        }

        /*******************************************************************************************************
        * @description Gets the primary OCRs with role equals to the role in the parameter.
        * @param String OCR Role.
        * @return List<OpportunityContactRole>. The primary OCRs with Role equals to the Role in the parameter.
        ********************************************************************************************************/
        public List<OpportunityContactRole> getRolesEqual(String ocrRole) {
            List<OpportunityContactRole> result = new List<OpportunityContactRole>();
            for (OpportunityContactRole ocr : record.OpportunityContactRoles) {
                if (ocrRole.equalsIgnoreCase(ocr.Role)) {
                    result.add(ocr);
                }
            }
            return result;
        }
    }
}