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
 * @description Cascade deletion extension for Account object.
 */
public with sharing class ACCT_CascadeDeleteLookups_TDTM extends CascadeDeleteLookups_TDTM {

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenLoader getDeletionChildrenLoader() {
        return new AccountDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the ChildrenLoader Object of the running Trigger. 
    * @return CascadeDeleteLookupsDomain.ChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.UndeleteChildrenLoader getUndeletionChildrenLoader() {
        return new UndeletionTopChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Recurring Donations being deleted
    ********************************************************************************************************/
    class AccountDeletionChildrenLoader implements CascadeDeleteLookupsDomain.DeleteChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being deleted
        * @return List<SObject> Deleted Recurring Donation's Allocations
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentIds) {
            List<SObject> result = new List<SObject>();

            List<Contact> relatedContacts = [
                SELECT Id
                FROM Contact 
                WHERE AccountId IN :parentIds
            ];
            List<Opportunity> relatedOpportunities = [
                SELECT Id 
                FROM Opportunity 
                WHERE AccountId IN :parentIds
            ];

            List<SObject> relatedRecurringDonations = [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE npe03__Organization__c IN :parentIds
                OR npe03__Contact__c IN :relatedContacts
            ];
            result.addAll(relatedRecurringDonations);

            List<SObject> relatedAllocations = [
                SELECT Name, Opportunity__r.AccountId, Recurring_Donation__r.npe03__Organization__c, 
                    Recurring_Donation__r.npe03__Contact__r.AccountId
                FROM Allocation__c
                WHERE Recurring_Donation__c IN :relatedRecurringDonations
                OR Opportunity__c IN :relatedOpportunities
            ];
            result.addAll(relatedAllocations);

            List<SObject> contactsReciprocalRelatedRelationship = [
                SELECT Id
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN :relatedContacts
            ];

            List<SObject> relatedRelationship = [
                SELECT Name
                FROM npe4__Relationship__c
                WHERE npe4__ReciprocalRelationship__c IN :contactsReciprocalRelatedRelationship
            ];
            result.addAll(relatedRelationship);
            
            return (new Map<Id, SObject>(result)).values();
        }
    }

    /*******************************************************************************************************
    * @description Retrieves the children of the Recurring Donations being undeleted
    ********************************************************************************************************/
    class UndeletionTopChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        private List<SObject> relatedRecurringDonations;

        UndeletionTopChildrenLoader() {
            this.relatedRecurringDonations = new List<SObject>();
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<SObject> Undeleted Recurring Donations's Allocations
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentIds) {
            List<SObject> result = new List<SObject>();

            List<Contact> relatedContacts = [
                SELECT Id
                FROM Contact 
                WHERE AccountId IN :parentIds
            ];

            relatedRecurringDonations = [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE IsDeleted = TRUE
                AND (npe03__Organization__c IN :parentIds
                    OR npe03__Contact__c IN :relatedContacts
                )
                ALL ROWS
            ];

            result.addAll(relatedRecurringDonations);

            List<SObject> contactsReciprocalRelatedRelationship = [
                SELECT Id
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN :relatedContacts
            ];

            List<SObject> relatedRelationship = [
                SELECT Name
                FROM npe4__Relationship__c
                WHERE npe4__ReciprocalRelationship__c IN :contactsReciprocalRelatedRelationship
                AND IsDeleted = TRUE
                ALL ROWS
            ];
            result.addAll(relatedRelationship);

            return (new Map<Id, SObject>(result)).values();
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<SObject> Undeleted Recurring Donations's Allocations
        ********************************************************************************************************/
        public CascadeDeleteLookupsDomain.UndeleteChildrenLoader next() {
            return new UndeletionSecondChildrenLoader(relatedRecurringDonations);

        }
    }

    /*******************************************************************************************************
    * @description Retrieves the children of the Recurring Donations being undeleted
    ********************************************************************************************************/
    class UndeletionSecondChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        private List<SObject> relatedRecurringDonations;

        UndeletionSecondChildrenLoader(List<SObject> relatedRecurringDonations) {
            this.relatedRecurringDonations = relatedRecurringDonations;
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<SObject> Undeleted Recurring Donations's Allocations
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentIds) {

            List<Opportunity> relatedOpportunities = [
                SELECT Id 
                FROM Opportunity 
                WHERE AccountId IN :parentIds
            ];

            return [
                SELECT Name, Opportunity__r.AccountId, Recurring_Donation__r.npe03__Organization__c, 
                    Recurring_Donation__r.npe03__Contact__r.AccountId
                FROM Allocation__c
                WHERE IsDeleted = TRUE
                AND (Recurring_Donation__c IN :relatedRecurringDonations
                    OR Opportunity__c IN :relatedOpportunities
                )
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted
        * @return List<SObject> Undeleted Recurring Donations's Allocations
        ********************************************************************************************************/
        public CascadeDeleteLookupsDomain.UndeleteChildrenLoader next() {
            return null;
        }
    }
}