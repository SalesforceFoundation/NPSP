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
 * @group Utilities
 * @description Cascade deletion extension for Recurring Donation object.
 */
public with sharing class RD_CascadeDeleteLookups_TDTM extends CascadeDeleteLookups_TDTM {

    /*******************************************************************************************************
    * @description Gets the deleted Recurring Donations ChildrenLoader Object. 
    * @return CascadeDeleteLookupsDomain.DeleteChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenLoader getDeletionChildrenLoader() {
        return new RDDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the undeleted Recurring Donations ChildrenLoader Object.
    * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader.
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.UndeleteChildrenLoader getUndeletionChildrenLoader() {
        return new RDUndeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenValidator Object.
    * @return CascadeDeleteLookupsDomain.DeleteChildrenValidator.
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenValidator getDeletionChildrenValidator() {
        return new RDChildrenValidator();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Recurring Donations being deleted.
    ********************************************************************************************************/
    class RDDeletionChildrenLoader implements CascadeDeleteLookupsDomain.DeleteChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Opportunities and Allocations of the Recurring Donations being deleted.
        * @param Set<Id> The Ids of the deleted Recurring Donations.
        * @return List<SObject> Deleted Recurring Donations' Opportunities and Allocations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentsIds) {
            List<SObject> result = new List<SObject>();

            List<SObject> relatedOpportunities = [
                SELECT Name, npe03__Recurring_Donation__c, IsWon, IsClosed
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :parentsIds
            ];
            result.addAll(relatedOpportunities);

            List<SObject> relatedAllocations = [
                SELECT Recurring_Donation__c, Opportunity__c
                FROM Allocation__c
                WHERE Recurring_Donation__c IN :parentsIds
                OR Opportunity__c IN :relatedOpportunities
            ];
            result.addAll(relatedAllocations);

            return (new Map<Id, SObject>(result)).values();
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Recurring Donations being undeleted.
    ********************************************************************************************************/
    class RDUndeletionChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        /*******************************************************************************************************
        * @description Retrieves the related Opportunities and Allocations of the Recurring Donations being undeleted.
        * @param Set<Id> The Ids of the undeleted Recurring Donations.
        * @return List<SObject> Undeleted Recurring Donations's Opportunities and Allocations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentsIds) {
            List<SObject> result = new List<SObject>();

            List<SObject> relatedOpportunities = [
                SELECT Name
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :parentsIds
                AND IsDeleted = TRUE
                ALL ROWS
            ];
            result.addAll(relatedOpportunities);

            List<SObject> relatedAllocations = [
                SELECT Id
                FROM Allocation__c
                WHERE (Recurring_Donation__c IN :parentsIds OR Opportunity__c IN :relatedOpportunities)
                AND IsDeleted = TRUE
                ALL ROWS
            ];
            result.addAll(relatedAllocations);

            return (new Map<Id, SObject>(result)).values();
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is no other
        * group of children records to undelete after Opportunities and Allocations undeletion.
        * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader
        ********************************************************************************************************/
        public CascadeDeleteLookupsDomain.UndeleteChildrenLoader next() {
            return null;
        }
    }

    /*******************************************************************************************************
    * @description Class that validates the children of the Recurring Donations being deleted
    ********************************************************************************************************/
    class RDChildrenValidator implements CascadeDeleteLookupsDomain.DeleteChildrenValidator {

        /*******************************************************************************************************
        * @description validates the children of the Account.
        * @param List<Account> The Accounts to delete.
        * @param List<SObject> The children to validate.
        * @return List<Object> Valid children records that can be deleted
        ********************************************************************************************************/
        public List<SObject> validateDeletion(List<npe03__Recurring_Donation__c> parents, List<SObject> children) {
            List<SObject> validChildren = new List<SObject>();

            for(npe03__Recurring_Donation__c parent : parents) {
                CascadeDeleteLookupsDomain.DeleteError error = new CascadeDeleteLookupsDomain.DeleteError(parent.Name);
                for (SObject child : children) {
                    if (isClosedWonOpportunity(child, parent.Id)) {
                        Opportunity closedWonOpportunity = (Opportunity) child;
                        error.addChildError(Label.ClosedWonOpportunities, closedWonOpportunity.Id, closedWonOpportunity.Name);
                    }
                    else {
                        validChildren.add(child);
                    }
                }

                String errorMessage = error.getMessage();
                if (String.isNotBlank(errorMessage)) {
                    parent.addError(errorMessage, false);
                }
            }

            return validChildren;
        }

        /*******************************************************************************************************
        * @description Checks if the record is a Closed Won Opportunity.
        * @param SObject The child record.
        * @param Id The Id of the parent record.
        * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader.
        ********************************************************************************************************/
        private Boolean isClosedWonOpportunity(SObject record, Id parentId) {
            return (
                record instanceof Opportunity && 
                ((Opportunity) record).npe03__Recurring_Donation__c == parentId &&
                ((Opportunity) record).IsClosed && ((Opportunity) record).IsWon
            );
        }
    }
}