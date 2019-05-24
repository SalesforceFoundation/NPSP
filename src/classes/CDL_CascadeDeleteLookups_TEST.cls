/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Cascade Delete
* @description Cascade Delete test data factory.
*/
@isTest
public class CDL_CascadeDeleteLookups_TEST {

    /*******************************************************************************************************
    * @description Creates Accounts.
    * @param Integer The maximum records to create.
    * @return List<Account> The created Accounts.
    ********************************************************************************************************/
    public static List<Account> buildAccounts(Integer maxRecords) {
        List<Account> result = new List<Account>();
        for (Integer i = 0; i < maxRecords; i++) {
            result.add(new Account(Name = 'Account' + i));
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Contacts.
    * @param Integer The maximum records to create.
    * @return List<Contact> The created Contacts.
    ********************************************************************************************************/
    public static List<Contact> buildContacts(Integer maxRecords) {
        List<Contact> result = new List<Contact>();
        for (Integer i = 0; i < maxRecords; i++) {
            result.add(new Contact(LastName = 'CONTACT' + i));
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Contact Recurring Donations.
    * @param List<Contact> The Contacts records that are used to create the Recurring Donations.
    * @return List<npe03__Recurring_Donation__c> The created Contact Recurring Donations.
    ********************************************************************************************************/
    public static List<npe03__Recurring_Donation__c> buildContactRDs(List<Contact> testContacts) {
        List<npe03__Recurring_Donation__c> result = new List<npe03__Recurring_Donation__c>();
        for (Contact testContact : testContacts) {
            result.add(
                new npe03__Recurring_Donation__c(
                    Name = 'CON_RD',
                    npe03__Installments__c = 2,
                    npe03__Amount__c = 1,
                    npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                    npe03__Date_Established__c = Date.newinstance(1970,6,12),
                    npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                    npe03__Contact__c = testContact.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Organizational Recurring Donations.
    * @param List<Account> The Accounts records that are used to create the Recurring Donations.
    * @return List<npe03__Recurring_Donation__c> The created Organizational Recurring Donations.
    ********************************************************************************************************/
    public static List<npe03__Recurring_Donation__c> buildOrganizationalRDs(List<Account> testAccounts) {
        List<npe03__Recurring_Donation__c> result = new List<npe03__Recurring_Donation__c>();
        for (Account testAccount : testAccounts) {
            result.add(
                new npe03__Recurring_Donation__c(
                    Name = 'ORG_RD' + testAccount.Name,
                    npe03__Installments__c = 2,
                    npe03__Amount__c = 1,
                    npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                    npe03__Date_Established__c = Date.newinstance(1970,6,12),
                    npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                    npe03__Organization__c = testAccount.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Opportunities.
    * @param List<Account> The Accounts records that are used to create the Opportunities.
    * @return List<Opportunity> The created Opportunities.
    ********************************************************************************************************/
    public static List<Opportunity> buildOpportunities(List<Account> testAccounts) {
        List<Opportunity> result = new List<Opportunity>();
        for (Account testAccount : testAccounts) {
            result.add(
                new Opportunity(
                    Name = 'OPP_' + testAccount.Name,
                    Amount = 8,
                    AccountId = testAccount.Id,
                    StageName = UTIL_UnitTestData_TEST.getClosedLostStage(),
                    CloseDate = System.today()
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Recurring Donation Opportunities.
    * @param List<npe03__Recurring_Donation__c> The Recurring Donations that are used to create the Opportunities.
    * @return List<Opportunity> The created Opportunities.
    ********************************************************************************************************/
    public static List<Opportunity> buildRDOpportunities(List<npe03__Recurring_Donation__c> testRecurringDonations, String stageName) {
        List<Opportunity> result = new List<Opportunity>();
        for (npe03__Recurring_Donation__c testRecurringDonation : testRecurringDonations) {
            result.add(
                new Opportunity(
                    Name = 'OPP_' + testRecurringDonation.Name,
                    Amount = 8,
                    AccountId = testRecurringDonation.npe03__Organization__c,
                    StageName = stageName,
                    CloseDate = System.today(),
                    npe03__Recurring_Donation__c = testRecurringDonation.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Recurring Donation Allocations.
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations.
    * @param List<npe03__Recurring_Donation__c> The Recurring Donations records that are used to create the Allocations.
    * @return List<Allocation__c> The created Allocations.
    ********************************************************************************************************/
    public static List<Allocation__c> buildRDAllocations(General_Accounting_Unit__c testGAU,  List<npe03__Recurring_Donation__c> testRecurringDonations) {
        List<Allocation__c> result = new List<Allocation__c>();
        for (npe03__Recurring_Donation__c testRecurringDonation : testRecurringDonations) {
            result.add(
                new Allocation__c(
                    Amount__c = 4, 
                    Recurring_Donation__c = testRecurringDonation.Id,
                    General_Accounting_Unit__c = testGAU.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Opportunity Allocations.
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations.
    * @param List<Opportunity> The Opportunities records that are used to create the Allocations.
    * @return List<Allocation__c> The created Allocations.
    ********************************************************************************************************/
    public static List<Allocation__c> buildOpportunityAllocations(General_Accounting_Unit__c testGAU,  List<Opportunity> testOpportunities) {
        List<Allocation__c> result = new List<Allocation__c>();
        for (Opportunity testOpportunity : testOpportunities) {
            result.add(
                new Allocation__c(
                    Amount__c = 4, 
                    Opportunity__c = testOpportunity.Id,
                    General_Accounting_Unit__c = testGAU.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Relationships.
    * @param List<Contact> The Contacts records that are used to create the Relationships.
    * @return List<npe4__Relationship__c> The created Relationships.
    ********************************************************************************************************/
    public static List<npe4__Relationship__c> buildRelationships(List<Contact> testContacts) {
        List<npe4__Relationship__c> result = new List<npe4__Relationship__c>();

        Map<Id, Contact> testContactsWithFriends = new Map<Id, Contact>();
        for (Contact testContact : testContacts) {
            testContactsWithFriends.put(testContact.Id, new Contact(LastName = 'FRIEND_OF_' + testContact.LastName));
        }
        insert testContactsWithFriends.values();

        for (Contact testContact : testContacts) {
            result.add(
                new npe4__Relationship__c(
                    npe4__contact__c = testContact.Id, 
                    npe4__relatedcontact__c = testContactsWithFriends.get(testContact.Id).Id, 
                    npe4__Type__c = 'Friend',
                    npe4__Status__c = 'Active'
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Campaigns.
    * @param Integer The maximum records to create.
    * @return List<Campaign> The created Campaigns.
    ********************************************************************************************************/
    public static List<Campaign> buildCampaigns(Integer maxRecords) {
        List<Campaign> result = new List<Campaign>();
        for (Integer i = 0; i < maxRecords; i++) {
            result.add(new Campaign(Name = 'CAMP' + i));
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Creates Campaign Allocations.
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations.
    * @param List<Campaign> The Campaigns records that are used to create the Allocations.
    * @return List<Allocation__c> The created Allocations.
    ********************************************************************************************************/
    public static List<Allocation__c> buildCampaignAllocations(General_Accounting_Unit__c testGAU,  List<Campaign> testCampaigns) {
        List<Allocation__c> result = new List<Allocation__c>();
        for (Campaign testCampaign : testCampaigns) {
            result.add(
                new Allocation__c(
                    Amount__c = 4, 
                    Campaign__c = testCampaign.Id,
                    General_Accounting_Unit__c = testGAU.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Gets the deleted Recurring Donations.
    * @return List<npe03__Recurring_Donation__c> The List of deleted Recurring Donations.
    ********************************************************************************************************/
    public static List<npe03__Recurring_Donation__c> getDeletedRecurringDonations() {
        return [
            SELECT Id 
            FROM npe03__Recurring_Donation__c
            WHERE IsDeleted = true 
            ALL ROWS
        ];
    }

    /*******************************************************************************************************
    * @description Gets the non deleted Recurring Donations.
    * @return List<npe03__Recurring_Donation__c> The List of non deleted Recurring Donations.
    ********************************************************************************************************/
    public static List<npe03__Recurring_Donation__c> getNonDeletedRecurringDonations() {
        return [
            SELECT Id 
            FROM npe03__Recurring_Donation__c 
            WHERE IsDeleted = false
        ];
    }

    /*******************************************************************************************************
    * @description Gets the deleted Allocations.
    * @return List<Allocation__c> The List of deleted Allocations.
    ********************************************************************************************************/
    public static List<Allocation__c> getDeletedAllocations() {
        return [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
    }

    /*******************************************************************************************************
    * @description Gets the non deleted Allocations.
    * @return List<Allocation__c> The List of non deleted Allocations.
    ********************************************************************************************************/
    public static List<Allocation__c> getNonDeletedAllocations() {
        return [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = false
        ];
    }

    /*******************************************************************************************************
    * @description Gets the deleted Relationships.
    * @return List<npe4__Relationship__c> The List of deleted Relationships.
    ********************************************************************************************************/
    public static List<npe4__Relationship__c> getDeletedRelationships() {
        return [
            SELECT Id 
            FROM npe4__Relationship__c
            WHERE IsDeleted = true 
            ALL ROWS 
        ];
    }

    /*******************************************************************************************************
    * @description Gets the non deleted Relationships.
    * @return List<npe4__Relationship__c> The List of deleted Relationships.
    ********************************************************************************************************/
    public static List<npe4__Relationship__c> getNonDeletedRelationships() {
        return [
            SELECT Id 
            FROM npe4__Relationship__c
            WHERE IsDeleted = false
        ];
    }

    /*******************************************************************************************************
    * @description Gets the deleted Opportunities.
    * @return List<Opportunity> The List of deleted Opportunities.
    ********************************************************************************************************/
    public static List<Opportunity> getDeletedOpportunities() {
        return [
            SELECT Id 
            FROM Opportunity
            WHERE IsDeleted = true 
            ALL ROWS 
        ];
    }

    /*******************************************************************************************************
    * @description Gets the non deleted Opportunities.
    * @return List<Opportunity> The List of deleted Opportunities.
    ********************************************************************************************************/
    public static List<Opportunity> getNonDeletedOpportunities() {
        return [
            SELECT Id 
            FROM Opportunity
            WHERE IsDeleted = false
        ];
    }

    /*******************************************************************************************************
    * @description Gets the errors.
    * @return List<Error__c> The List of errors.
    ********************************************************************************************************/
    public static List<Error__c> getErrors() {
        return [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
    }
}