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
    * @description Gets the deleted Accounts ChildrenLoader Object. 
    * @return CascadeDeleteLookupsDomain.DeleteChildrenLoader
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.DeleteChildrenLoader getDeletionChildrenLoader() {
        return new AccountDeletionChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Gets the undeleted Accounts ChildrenLoader Object.
    * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader.
    ********************************************************************************************************/
    protected override CascadeDeleteLookupsDomain.UndeleteChildrenLoader getUndeletionChildrenLoader() {
        return new UndeletionFirstChildrenLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the Accounts being deleted.
    ********************************************************************************************************/
    class AccountDeletionChildrenLoader implements CascadeDeleteLookupsDomain.DeleteChildrenLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Relationships, Recurring Donations, Allocations.
        * of the Accounts being deleted.
        * @param Set<Id> The Ids of the deleted Accounts
        * @return List<SObject> Deleted Accounts' Relationships, Recurring Donations, Allocations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentIds) {
            List<SObject> result = new List<SObject>();

            List<Contact> relatedContacts = [
                SELECT Id
                FROM Contact 
                WHERE AccountId IN :parentIds
            ];

            List<npe4__Relationship__c> relatedRelationships = getRelatedRelationships(relatedContacts);
            result.addAll((List<SObject>) relatedRelationships);
            
            List<npe03__Recurring_Donation__c> relatedRecurringDonations = getRelatedRecurringDonations(parentIds, relatedContacts);
            result.addAll((List<SObject>) relatedRecurringDonations);

            List<Allocation__c> relatedAllocations = getRelatedAllocations(parentIds, relatedRecurringDonations);
            result.addAll((List<SObject>) relatedAllocations);
            
            return (new Map<Id, SObject>(result)).values();
        }

        /*******************************************************************************************************
        * @description Retrieves the related Relationships of the Accounts being deleted.
        * @param List<Contact> The Contacts of the deleted Accounts.
        * @return List<npe4__Relationship__c> Deleted Accounts' Relationships.
        ********************************************************************************************************/
        private List<npe4__Relationship__c> getRelatedRelationships(List<Contact> relatedContacts) {
            List<SObject> reciprocalRelationships = [
                SELECT Id
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN :relatedContacts
            ];
            return [
                SELECT Name
                FROM npe4__Relationship__c
                WHERE npe4__ReciprocalRelationship__c IN :reciprocalRelationships
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the related Recurring Donations of the Accounts being deleted.
        * @param Set<Id> The Ids of the deleted Accounts.
        * @param List<Contact> The Contacts of the deleted Accounts.
        * @return List<npe03__Recurring_Donation__c> Deleted Accounts' Recurring Donations.
        ********************************************************************************************************/
        private List<npe03__Recurring_Donation__c> getRelatedRecurringDonations(Set<Id> parentIds, List<Contact> relatedContacts) {
            return [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE npe03__Organization__c IN :parentIds
                OR npe03__Contact__c IN :relatedContacts
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the Accounts being deleted.
        * @param Set<Id> The Ids of the deleted Accounts.
        * @param List<npe03__Recurring_Donation__c> The Recurring Donations of the deleted Accounts.
        * @return List<Allocation__c> Deleted Accounts' Allocations.
        ********************************************************************************************************/
        private List<Allocation__c> getRelatedAllocations(Set<Id> parentIds, List<npe03__Recurring_Donation__c> relatedRecurringDonations) {
            List<Opportunity> relatedOpportunities = [
                SELECT Id 
                FROM Opportunity 
                WHERE AccountId IN :parentIds
            ];
            return [
                SELECT Name, Opportunity__r.AccountId, Recurring_Donation__r.npe03__Organization__c, 
                    Recurring_Donation__r.npe03__Contact__r.AccountId
                FROM Allocation__c
                WHERE Recurring_Donation__c IN :relatedRecurringDonations
                OR Opportunity__c IN :relatedOpportunities
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the first children group of the Accounts being undeleted.
    ********************************************************************************************************/
    class UndeletionFirstChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        private List<npe03__Recurring_Donation__c> relatedRecurringDonations;

        /******************************************************************************************************
        * @description The Constructor of UndeletionFirstChildrenLoader
        */
        UndeletionFirstChildrenLoader() {
            this.relatedRecurringDonations = new List<npe03__Recurring_Donation__c>();
        }

        /*******************************************************************************************************
        * @description Retrieves the related Relationships and Recurring Donations of the Accounts being deleted.
        * @param Set<Id> The Ids of the undeleted Accounts
        * @return List<SObject> Deleted Accounts' Relationships, Recurring Donations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> parentIds) {
            List<SObject> result = new List<SObject>();

            List<Contact> relatedContacts = [
                SELECT Id
                FROM Contact 
                WHERE AccountId IN :parentIds
            ];

            relatedRecurringDonations = getRelatedRecurringDonations(parentIds, relatedContacts);
            result.addAll((List<SObject>) relatedRecurringDonations);

            List<npe4__Relationship__c> relatedRelationships = getRelatedRelationships(relatedContacts);
            result.addAll((List<SObject>) relatedRelationships);

            return (new Map<Id, SObject>(result)).values();
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is another
        * group of children records to undelete.
        * @return CascadeDeleteLookupsDomain.UndeleteChildrenLoader 
        ********************************************************************************************************/
        public CascadeDeleteLookupsDomain.UndeleteChildrenLoader next() {
            return new UndeletionSecondChildrenLoader(relatedRecurringDonations);

        }

        /*******************************************************************************************************
        * @description Retrieves the related Relationships of the Accounts being undeleted.
        * @param List<Contact> The Contacts of the undeleted Accounts
        * @return List<npe4__Relationship__c> Undeleted Accounts' Relationships.
        ********************************************************************************************************/
        private List<npe4__Relationship__c> getRelatedRelationships(List<Contact> relatedContacts) {
            List<SObject> contactsReciprocalRelationships = [
                SELECT Id
                FROM npe4__Relationship__c
                WHERE npe4__Contact__c IN :relatedContacts
            ];
            return [
                SELECT Name
                FROM npe4__Relationship__c
                WHERE npe4__ReciprocalRelationship__c IN :contactsReciprocalRelationships
                AND IsDeleted = TRUE
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the related Recurring Donations of the Accounts being undeleted.
        * @param Set<Id> The Ids of the undeleted Accounts
        * @param List<Contact> The Contacts of the undeleted Accounts
        * @return List<npe03__Recurring_Donation__c> Undeleted Accounts' Recurring Donations.
        ********************************************************************************************************/
        private List<npe03__Recurring_Donation__c> getRelatedRecurringDonations(Set<Id> parentIds, List<Contact> relatedContacts) {
            return [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE IsDeleted = TRUE
                AND (npe03__Organization__c IN :parentIds OR npe03__Contact__c IN :relatedContacts)
                ALL ROWS
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the second children group of the Accounts being undeleted
    ********************************************************************************************************/
    class UndeletionSecondChildrenLoader implements CascadeDeleteLookupsDomain.UndeleteChildrenLoader {

        private List<npe03__Recurring_Donation__c> relatedRecurringDonations;

        /*********************************************************************************************************
        * @description The Constructor of UndeletionSecondChildrenLoader
        * @param List<npe03__Recurring_Donation__c> The Recurring Donations. 
        */
        UndeletionSecondChildrenLoader(List<npe03__Recurring_Donation__c> relatedRecurringDonations) {
            this.relatedRecurringDonations = relatedRecurringDonations;
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Accounts being undeleted.
        * @param Set<Id> The Ids of the undeleted Accounts.
        * @return List<Allocation__c> Undeleted Accounts' Allocations.
        ********************************************************************************************************/
        public List<Allocation__c> load(Set<Id> parentIds) {

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
                AND (Recurring_Donation__c IN :relatedRecurringDonations OR Opportunity__c IN :relatedOpportunities)
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the children of the Recurring Donations being undeleted.
        * @return List<SObject> Undeleted Recurring Donations's Allocations.
        ********************************************************************************************************/
        public CascadeDeleteLookupsDomain.UndeleteChildrenLoader next() {
            return null;
        }
    }
}