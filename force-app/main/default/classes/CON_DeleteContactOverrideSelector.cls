/*
    Copyright (c) 2021, Salesforce.org
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
* @date 2021
* @group Contacts
* @group-content ../../ApexDocContent/Contacts.htm
* @description Selects records for the Contact Delete button override.
*/
public with sharing class CON_DeleteContactOverrideSelector {

    public Contact queryContact(Id contactId) {
        Contact contactDetails = [
            SELECT Id, Name, FirstName, LastName,
                AccountId, Account.Name, Account.npe01__SYSTEMIsIndividual__c
            FROM Contact
            WHERE Id = :contactId
        ];
        return contactDetails;
    }

    public Boolean isAccountWithSingleContact(Id accountId) {
        List<AggregateResult> contactsInAccount = [
            SELECT COUNT(id) ct
            FROM Contact
            WHERE AccountId = :accountId
            GROUP BY AccountId
            HAVING COUNT(id) = 1
        ];

        if (contactsInAccount.size() != 1 || !(contactsInAccount[0].get('ct') == 1)) {
            return false;
        }
        return true;
    }

    /*********************************************************************************************************
    * @description Query UserRecordAccess for record Id and user
    * @return UserRecordAccess
    */
    public UserRecordAccess queryDeleteRecordAccess(Id recordId) {
        return [
            SELECT RecordId, HasDeleteAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId()
            AND RecordId = :recordId
        ];
    }

    public Account getAccountRecord(Id accountId) {
        return  [SELECT Id, Name FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];
    }

    public List<Case> getCasesRelatedToContact(Id contactId) {
        return [
            SELECT CaseNumber, ContactId
            FROM Case
            WHERE ContactId = :contactId
            WITH SECURITY_ENFORCED
        ];
    }

    public List<Case> getCasesRelatedToAccount(Id accountId) {
        return [
            SELECT CaseNumber, AccountId
            FROM Case
            WHERE AccountId = :accountId
            WITH SECURITY_ENFORCED
        ];
    }

    public List<Opportunity> getOpportunitiesRelatedToContact(Id contactId) {
        return [
            SELECT Name, AccountId, Primary_Contact__c, Primary_Contact__r.AccountId, IsWon, IsClosed
            FROM Opportunity
            WHERE Primary_Contact__c = :contactId
            WITH SECURITY_ENFORCED
        ];
    }

    public List<Opportunity> getOpportunitiesRelatedToAccount(Id accountId) {
        return [
            SELECT Name, AccountId, IsWon, IsClosed
            FROM Opportunity
            WHERE AccountId = :accountId
            WITH SECURITY_ENFORCED
        ];
    }

    public List<npe03__Recurring_Donation__c> getRelatedRecurringDonations(Id contactId) {
        return [
            SELECT Name, npe03__Contact__c
            FROM npe03__Recurring_Donation__c
            WHERE npe03__Contact__c = :contactId
            WITH SECURITY_ENFORCED
        ];
    }
}