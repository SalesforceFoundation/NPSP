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
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenLoader getDeletionChildrenLoader() {
        return new RDDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.UndeleteChildrenLoader getUndeletionChildrenLoader() {
        return new RDUndeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenValidator getDeletionChildrenValidator() {
        return new RDChildrenValidator();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Recurring Donations being deleted
    ********************************************************************************************************/
    class RDDeletionChildrenLoader implements CascadeDeleteLookupsDomain.DeleteChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being deleted
        * @return List<SObject> Deleted Recurring Donation's Allocations
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentsIds) {
            List<SObject> result = new List<SObject>();

            List<SObject> relatedOpportunities = [
                SELECT Name, npe03__Recurring_Donation__c, IsWon, IsClosed
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :parentsIds
            ];
            List<SObject> relatedAllocations = [
                SELECT Recurring_Donation__c, Opportunity__c
                FROM Allocation__c
                WHERE Recurring_Donation__c IN :parentsIds
                OR Opportunity__c IN :relatedOpportunities
            ];

            result.addAll(relatedOpportunities);
            result.addAll(relatedAllocations);

            return (new Map<Id, SObject>(result)).values();
        }
    }

    /*******************************************************************************************************
    * @description Retrieves the children of the Recurring Donations being undeleted
    ********************************************************************************************************/
    class RDUndeletionChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<SObject> Undeleted Recurring Donations's Allocations
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentsIds) {
            Map<Id, SObject> result = new Map<Id, SObject>();

            Map<Id, Opportunity> relatedOpportunities = new Map<Id, Opportunity>([
                SELECT Name
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :parentsIds
                AND IsDeleted = TRUE
                ALL ROWS
            ]);
            List<Allocation__c> relatedAllocations = [
                SELECT Id
                FROM Allocation__c
                WHERE (Recurring_Donation__c IN :parentsIds OR Opportunity__c IN :relatedOpportunities.keySet())
                AND IsDeleted = TRUE
                ALL ROWS
            ];

            result.putAll(relatedOpportunities);
            result.putAll(relatedAllocations);

            return result.values();
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<SObject> Undeleted Recurring Donations's Allocations
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
        * @description validates the children of the Recurring Donations being undeleted
        * @return void
        ********************************************************************************************************/
        public List<SObject> validateDeletion(List<npe03__Recurring_Donation__c> parents, List<SObject> children) {
            List<SObject> validChildren = new List<SObject>();

            for(npe03__Recurring_Donation__c parent : parents) {
                CascadeDeleteLookupsDomain.DeleteError error = new CascadeDeleteLookupsDomain.DeleteError(parent.Name);

                for (SObject child : children) {
                    if (isDeletableOpportunity(child, parent)) {
                        Opportunity nonDeletableOpportunity = (Opportunity) child;
                        error.addChildError(Label.ClosedWonOpportunities, nonDeletableOpportunity.Id, nonDeletableOpportunity.Name);
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

        private Boolean isDeletableOpportunity(SObject record, npe03__Recurring_Donation__c parent) {
            if ((record instanceof Opportunity) == false) {
                return false;
            }
            Opportunity opportunityRecord = (Opportunity) record;
            
            return opportunityRecord.npe03__Recurring_Donation__c == parent.Id && opportunityRecord.IsClosed && opportunityRecord.IsWon;
        }
    }
}