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
* @description Domain Classes for the deletion of duplicate primary OCRs. 
*/

public with sharing class OPP_PrimaryContactRoleMerge {

    @TestVisible private static final String ERROR_MESSAGE = Label.OCRRemovePrimaryDuplicateBatchErrorText;
    @TestVisible private static final String ERROR_CONTEXT = 'Remove Duplicate Primary OCRs';
    @TestVisible private static final String ERROR_SOBJECT = 'Opportunity';
    /*******************************************************************************************************
    * @description The Duplicate Primary Opportunity Contact Roles Wrapper. It contains the logic that loads  
    * and manages the duplicate Primary OCRs and the related Opportunities.
    ********************************************************************************************************/
    public class DuplicatePrimaryOCRs {
        private Map<Id, Opportunity> opportunityRecords;
        private Map<Id, OpportunityContactRole> ocrRecords;

        private Map<Id, Opportunity> opportunityRecordsToUpdate;
        private Map<Id, OpportunityContactRole> ocrRecordsToUpdate;
        private Map<Id, OpportunityContactRole> ocrRecordsToDelete;

        /*********************************************************************************************************
        * @description The Constructor of DuplicatePrimaryOCRs.
        * @param List<AggregateResult> The duplicate primary OCRs Aggregate Result. 
        */
        public DuplicatePrimaryOCRs(List<AggregateResult> primaryOCRsAggregateResult) {
            opportunityRecords = new Map<Id, Opportunity>(loadOpportunities(primaryOCRsAggregateResult));
            ocrRecords = new Map<Id, OpportunityContactRole>(loadOpportunityContactRoles(opportunityRecords.values()));
            opportunityRecordsToUpdate = new Map<Id, Opportunity>();
            ocrRecordsToUpdate = new Map<Id, OpportunityContactRole>();
            ocrRecordsToDelete = new Map<Id, OpportunityContactRole>();
        }

        /*******************************************************************************************************
        * @description Gets the Opportunities of the duplicate primary OCRs. 
        * @return List<Opportunity> The Opportunities of the duplicate primary OCRs.
        ********************************************************************************************************/
        public List<Opportunity> getOpportunities() {
            return opportunityRecords.values();
        }

        /*******************************************************************************************************
        * @description Sets the OCR in paramater as Primary OCR.
        * @param OpportunityContactRole the OCR to set as primary.
        * @return void.
        ********************************************************************************************************/
        public void makePrimary(OpportunityContactRole inputOCR) {
            OpportunityContactRole ocrToUpdate = ocrRecords.get(inputOCR.Id);
            ocrToUpdate.IsPrimary = true;
            ocrRecordsToUpdate.put(ocrToUpdate.Id, ocrToUpdate);

            Opportunity opportunityToUpdate = opportunityRecords.get(inputOCR.OpportunityId);
            if (opportunityToUpdate.Primary_Contact__c != inputOCR.ContactId) {
                opportunityToUpdate.Primary_Contact__c = inputOCR.ContactId;
                opportunityRecordsToUpdate.put(opportunityToUpdate.Id, opportunityToUpdate);
            } 
        }

        /*******************************************************************************************************
        * @description Deletes the OCRs in paramater.
        * @param List<OpportunityContactRole> The OCRs to delete.
        * @return void.
        ********************************************************************************************************/
        public void deleteRecords(List<OpportunityContactRole> ocrsToDelete) {
            ocrRecordsToDelete.putAll(ocrsToDelete);
        }

        /*******************************************************************************************************
        * @description Commits the DMLs (delete/Update OCRs, update Opportunities)
        * @return void.
        ********************************************************************************************************/
        public void processDML() {
            delete ocrRecordsToDelete.values();
            update ocrRecordsToUpdate.values();
            update opportunityRecordsToUpdate.values();
        }

        /*******************************************************************************************************
        * @description Gets the Opportunities with their related primary OCRs.
        * @param List<AggregateResult> The duplicate primary OCRs Aggregate Result.
        * @return List<Opportunity> 
        ********************************************************************************************************/
        private List<Opportunity> loadOpportunities(List<AggregateResult> primaryOCRsAggregateResult) {
            Set<Id> opportunityIds = new Set<Id>();
            for (AggregateResult aggregateResult : primaryOCRsAggregateResult) {
                opportunityIds.add((Id) aggregateResult.get('OpportunityId'));
            }
            return [
                SELECT Name, Primary_Contact__c, (
                    SELECT OpportunityId, ContactId, Role, IsPrimary
                    FROM OpportunityContactRoles
                    WHERE IsPrimary = true
                )
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];
        }

        /*******************************************************************************************************
        * @description Gets the OCRs of the given Opportunities.
        * @param List<Opportunity> The Opportunities with the related Primary OCRs.
        * @return List<OpportunityContactRole>.
        ********************************************************************************************************/
        private List<OpportunityContactRole> loadOpportunityContactRoles(List<Opportunity> opportunityRecords) {
            List<OpportunityContactRole> result = new List<OpportunityContactRole>();
            for (Opportunity currentOpportunity : opportunityRecords) {
                result.addAll(currentOpportunity.OpportunityContactRoles);
            }
            return result;
        }
    }


    /*******************************************************************************************************
    * @description It encapsulates an Opportunity and its related duplicate Primary OCRs.
    ********************************************************************************************************/
    public class OpportunityPrimaryOCRs {
        private Opportunity record;

        /*********************************************************************************************************
        * @description The Constructor of OpportunityPrimaryOCRs.
        * @param Opportunity Opportunity with the related primary OCRs.
        */
        public OpportunityPrimaryOCRs(Opportunity currentOpportunity) {
            record = currentOpportunity;
        }

        /*******************************************************************************************************
        * @description Checks if the Opportunity has an OCR Role equals to the Role in the parameter.
        * @param String OCR Role.
        * @return Boolean.
        ********************************************************************************************************/
        public Boolean containsRole(String ocrRole) {
            for (OpportunityContactRole ocr : record.OpportunityContactRoles) {
                if (ocr.Role == ocrRole) {
                    return true;
                }
            }
            return false;
        }

        /*******************************************************************************************************
        * @description Gets the OCRs with role equals blank.
        * @return List<OpportunityContactRole> The OCRs with role role = blank.
        ********************************************************************************************************/
        public List<OpportunityContactRole> getBlankRole() {
            List<OpportunityContactRole> result = new List<OpportunityContactRole>();
            for (OpportunityContactRole ocr : record.OpportunityContactRoles) {
                if (String.isBlank(ocr.Role)) {
                    result.add(ocr);
                }
            }
            return result;
        }

        /*******************************************************************************************************
        * @description Gets the OCRs with Role equals to the Role in the parameter.
        * @param String OCR Role.
        * @return List<OpportunityContactRole> The OCRs with Role equals to the Role in the parameter.
        ********************************************************************************************************/
        public List<OpportunityContactRole> getRoleEquals(String ocrRole) {
            List<OpportunityContactRole> result = new List<OpportunityContactRole>();
            for (OpportunityContactRole ocr : record.OpportunityContactRoles) {
                if (ocr.Role == ocrRole) {
                    result.add(ocr);
                }
            }
            return result;
        }

        /*******************************************************************************************************
        * @description Gets the OCRs with Role not equals to the Role in the parameter.
        * @param String OCR Role.
        * @return List<OpportunityContactRole> The OCRs with Role not equals to the Role in the parameter.
        ********************************************************************************************************/
        public List<OpportunityContactRole> getRoleNotEquals(String ocrRole) {
            List<OpportunityContactRole> result = new List<OpportunityContactRole>();
            for (OpportunityContactRole ocr : record.OpportunityContactRoles) {
                if (ocr.Role != ocrRole) {
                    result.add(ocr);
                }
            }
            return result;
        }
    }


    /*******************************************************************************************************
    * @description Error Log. This class contains the logic that creates the error logs.
    ********************************************************************************************************/
    public class Errors {
        private List<Error__c> errors;

        /*********************************************************************************************************
        * @description The Constructor of Errors
        */
        public Errors() {
            errors = new List<Error__c>();
        }

        /*******************************************************************************************************
        * @description Adds an error log for the Opportunity in the parameter.
        * @param Opportunity.
        * @return void.
        ********************************************************************************************************/
        public void add(Opportunity opportunityRecord) {
            errors.add(new Error__c(
                Datetime__c = System.now(),
                Full_Message__c = String.format(ERROR_MESSAGE, new List<String>{opportunityRecord.Name}),
                Record_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + opportunityRecord.Id,
                Context_Type__c = ERROR_CONTEXT,
                Object_Type__c = ERROR_SOBJECT
            ));
        }

        /*******************************************************************************************************
        * @description Commits the DMLs (insert Error__c records)
        * @return void.
        ********************************************************************************************************/
        public void processDML() {
            insert errors;
        }
    }
}