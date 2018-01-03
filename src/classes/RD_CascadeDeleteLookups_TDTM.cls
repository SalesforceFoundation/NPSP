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
    protected override CascadeDeleteLookupsDomain.ChildrenLoader getDeletionChildrenLoader() {
        return new RDDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.ChildrenLoader getUndeletionChildrenLoader() {
        return new RDUndeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.ChildrenValidator getChildrenValidator() {
        return new RDChildrenValidator();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Recurring Donations being deleted
    ********************************************************************************************************/
    class RDDeletionChildrenLoader implements CascadeDeleteLookupsDomain.ChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being deleted
        * @return List<Allocation__c> Deleted Recurring Donation's Allocations
        ********************************************************************************************************/
        public List<SObject> loadChildren(Set<Id> parentsIds) {
            Map<Id, SObject> result = new Map<Id, SObject>();

            List<Opportunity> relatedOpportunities = [
                SELECT Name, npe03__Recurring_Donation__c, IsWon, IsClosed
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :parentsIds
            ];
            List<Allocation__c> relatedAllocations = [
                SELECT Recurring_Donation__c, Opportunity__c
                FROM Allocation__c
                WHERE Recurring_Donation__c IN :parentsIds
                OR Opportunity__c IN :relatedOpportunities
            ];

            result.putAll(relatedOpportunities);
            result.putAll(relatedAllocations);

            return result.values();
        }
    }

    /*******************************************************************************************************
    * @description Retrieves the children of the Recurring Donations being undeleted
    ********************************************************************************************************/
    class RDUndeletionChildrenLoader implements CascadeDeleteLookupsDomain.ChildrenLoader {

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<Allocation__c> Undeleted Recurring Donations's Allocations
        ********************************************************************************************************/
        public List<SObject> loadChildren(Set<Id> parentsIds) {
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
    }

    /*******************************************************************************************************
    * @description Class that validates the children of the Recurring Donations being deleted
    ********************************************************************************************************/
    class RDChildrenValidator implements CascadeDeleteLookupsDomain.ChildrenValidator {

        /*******************************************************************************************************
        * @description validates the children of the Recurring Donations being undeleted
        * @return void
        ********************************************************************************************************/
        public void validateChildrenDeletion(List<npe03__Recurring_Donation__c> parentRecords, List<SObject> childrenRecords) {
            for(npe03__Recurring_Donation__c parentRecord : parentRecords) {
                CascadeDeleteLookupsDomain.DeletionError deletionError = new CascadeDeleteLookupsDomain.DeletionError(parentRecord.Name);
                for (SObject childRecord : childrenRecords) {
                    if (childRecord instanceof Opportunity && 
                        (Id) childRecord.get('npe03__Recurring_Donation__c') == parentRecord.Id && 
                        (Boolean) childRecord.get('IsClosed') && (Boolean) childRecord.get('IsWon')
                    ) {
                        deletionError.addChildError(Label.ClosedWonOpportunities, (Id) childRecord.get('Id'), (String) childRecord.get('Name')); 
                    }
                }
                String deletionErrorMessage = deletionError.getMessage();
                if (String.isNotBlank(deletionErrorMessage)) {
                    parentRecord.addError(deletionErrorMessage, false);
                }
            }
        }
    }
}