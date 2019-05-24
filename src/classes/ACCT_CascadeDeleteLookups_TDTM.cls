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
 * @group Cascade Delete
 * @description Cascade deletion extension for Account object.
 */
public with sharing class ACCT_CascadeDeleteLookups_TDTM extends CDL_CascadeDeleteLookups_TDTM {

    /*******************************************************************************************************
    * @description Gets the deleted Accounts CascadeDeleteLoader Object. 
    * @return CDL_CascadeDeleteLookups.CascadeDeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeDeleteLoader getCascadeDeleteLoader() {
        return new CascadeDeleteLoader();
    }

    /*******************************************************************************************************
    * @description Gets the deleted Accounts CascadeUndeleteLoader Object.
    * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeUndeleteLoader getCascadeUndeleteLoader() {
        return new FirstCascadeUndeleteLoader();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the deleted Accounts.
    ********************************************************************************************************/
    class CascadeDeleteLoader implements CDL_CascadeDeleteLookups.CascadeDeleteLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Relationships, Recurring Donations, Allocations.
        * of the deleted Accounts.
        * @param Set<Id> The Ids of the deleted Accounts.
        * @return List<SObject> Deleted Accounts' Relationships, Recurring Donations, Allocations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> accountIds) {
            List<SObject> result = new List<SObject>();

            List<Contact> relatedContacts = [
                SELECT Id
                FROM Contact 
                WHERE AccountId IN :accountIds
            ];

            List<npe4__Relationship__c> relatedRelationships = getRelatedRelationships(relatedContacts);
            result.addAll((List<SObject>) relatedRelationships);
            
            List<npe03__Recurring_Donation__c> relatedRecurringDonations = getRelatedRecurringDonations(accountIds, relatedContacts);
            result.addAll((List<SObject>) relatedRecurringDonations);

            List<Allocation__c> relatedAllocations = getRelatedAllocations(accountIds, relatedRecurringDonations);
            result.addAll((List<SObject>) relatedAllocations);
            
            return result;
        }

        /*******************************************************************************************************
        * @description Retrieves the related Relationships of the deleted Accounts.
        * @param List<Contact> The Contacts of the deleted Accounts.
        * @return List<npe4__Relationship__c> Deleted Accounts' Relationships.
        ********************************************************************************************************/
        private List<npe4__Relationship__c> getRelatedRelationships(List<Contact> relatedContacts) {
            List<npe4__Relationship__c> reciprocalRelationships = [
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
        * @description Retrieves the related Recurring Donations of the deleted Accounts.
        * @param Set<Id> The Ids of the deleted Accounts.
        * @param List<Contact> The Contacts of the deleted Accounts.
        * @return List<npe03__Recurring_Donation__c> Deleted Accounts' Recurring Donations.
        ********************************************************************************************************/
        private List<npe03__Recurring_Donation__c> getRelatedRecurringDonations(Set<Id> accountIds, List<Contact> relatedContacts) {
            return [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE npe03__Organization__c IN :accountIds
                OR npe03__Contact__c IN :relatedContacts
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the deleted Accounts.
        * @param Set<Id> The Ids of the deleted Accounts.
        * @param List<npe03__Recurring_Donation__c> The Recurring Donations of the deleted Accounts.
        * @return List<Allocation__c> Deleted Accounts' Allocations.
        ********************************************************************************************************/
        private List<Allocation__c> getRelatedAllocations(Set<Id> accountIds, List<npe03__Recurring_Donation__c> relatedRecurringDonations) {
            List<Opportunity> relatedOpportunities = [
                SELECT Id 
                FROM Opportunity 
                WHERE AccountId IN :accountIds
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
    * @description Class that retrieves the first children group of the undeleted Accounts.
    ********************************************************************************************************/
    class FirstCascadeUndeleteLoader implements CDL_CascadeDeleteLookups.CascadeUndeleteLoader {

        private List<npe03__Recurring_Donation__c> relatedRecurringDonations;

        /******************************************************************************************************
        * @description The Constructor of FirstCascadeUndeleteLoader.
        */
        FirstCascadeUndeleteLoader() {
            this.relatedRecurringDonations = new List<npe03__Recurring_Donation__c>();
        }

        /*******************************************************************************************************
        * @description Retrieves the related Recurring Donations and Relationships of the undeleted Accounts.
        * @param Set<Id> The Ids of the undeleted Accounts.
        * @return List<SObject> Deleted Accounts' Relationships, Recurring Donations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> accountIds) {
            List<SObject> result = new List<SObject>();

            List<Contact> relatedContacts = [
                SELECT Id
                FROM Contact 
                WHERE AccountId IN :accountIds
            ];

            relatedRecurringDonations = getRelatedRecurringDonations(accountIds, relatedContacts);
            result.addAll((List<SObject>) relatedRecurringDonations);

            List<npe4__Relationship__c> relatedRelationships = getRelatedRelationships(relatedContacts);
            result.addAll((List<SObject>) relatedRelationships);

            return result;
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is another
        * group of children records (Allocations) to undelete. To retrieve the Allocations, the logic needs the 
        * the Recurring Donations undeleted (from the load method).
        * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
        ********************************************************************************************************/
        public CDL_CascadeDeleteLookups.CascadeUndeleteLoader next() {
            List<npe03__Recurring_Donation__c> undeletedRecurringDonations = getUndeletedRecurringDonations(relatedRecurringDonations);
            return new SecondCascadeUndeleteLoader(undeletedRecurringDonations);

        }

        /*******************************************************************************************************
        * @description Retrieves the related Recurring Donations of the undeleted Accounts.
        * @param Set<Id> The Ids of the undeleted Accounts.
        * @param List<Contact> The Contacts of the undeleted Accounts
        * @return List<npe03__Recurring_Donation__c> Undeleted Accounts' Recurring Donations.
        ********************************************************************************************************/
        private List<npe03__Recurring_Donation__c> getRelatedRecurringDonations(Set<Id> accountIds, List<Contact> relatedContacts) {
            return [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE IsDeleted = TRUE
                AND (npe03__Organization__c IN :accountIds OR npe03__Contact__c IN :relatedContacts)
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the related Relationships of the undeleted Accounts.
        * @param List<Contact> The Contacts of the undeleted Accounts.
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
        * @description Retrieves the Undeleted Recurring Donations to be passed to the SecondCascadeUndeleteLoader.
        * This query is run to make sure the SecondCascadeUndeleteLoader gets only the Recurring Donations that were
        * successfully undeleted.
        * @param List<npe03__Recurring_Donation__c> The Recurring Donations that are supposed to be undeleted.
        * @return List<npe03__Recurring_Donation__c> The Recurring Donations that are successfully undeleted.
        ********************************************************************************************************/
        private List<npe03__Recurring_Donation__c> getUndeletedRecurringDonations(List<npe03__Recurring_Donation__c> relatedRecurringDonations) {
            return [
                SELECT Name, npe03__Organization__c, npe03__Contact__r.AccountId
                FROM npe03__Recurring_Donation__c
                WHERE Id IN :relatedRecurringDonations
            ];
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the second children group of the undeleted Accounts.
    ********************************************************************************************************/
    class SecondCascadeUndeleteLoader implements CDL_CascadeDeleteLookups.CascadeUndeleteLoader {

        private List<npe03__Recurring_Donation__c> relatedRecurringDonations;

        /*********************************************************************************************************
        * @description The Constructor of SecondCascadeUndeleteLoader.
        * @param List<npe03__Recurring_Donation__c> The Recurring Donations. 
        */
        SecondCascadeUndeleteLoader(List<npe03__Recurring_Donation__c> relatedRecurringDonations) {
            this.relatedRecurringDonations = relatedRecurringDonations;
        }

        /*******************************************************************************************************
        * @description Retrieves the Allocations of the undeleted Accounts.
        * @param Set<Id> The Ids of the undeleted Accounts.
        * @return List<Allocation__c> Undeleted Accounts' Allocations.
        ********************************************************************************************************/
        public List<Allocation__c> load(Set<Id> accountIds) {

            List<Opportunity> relatedOpportunities = [
                SELECT Id 
                FROM Opportunity 
                WHERE AccountId IN :accountIds
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
        * @description Retrieves the next children records group to be undeleted. In this case, there is no other
        * group of children records to undelete after Allocations undeletion.
        * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
        ********************************************************************************************************/
        public CDL_CascadeDeleteLookups.CascadeUndeleteLoader next() {
            return null;
        }
    }
}