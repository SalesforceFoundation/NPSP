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
* @group Utilities
* @description Tests for cascade delete of Recurring Donations
*/
@isTest
private class RD_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Deletes recurring donation, which deletes opportunities and allocations. Verifies results.
    * Then undeletes recurring donation, which undeletes opportunities and allocation. Verifies results.
    */
    static testMethod void testRDCascade(){
        Integer maxRecords = 1;

        List<Contact> testContacts = createContacts(maxRecords);
        insert testContacts;

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(createContactRDs(testContacts));
        insert testRecurringDonations;

        List<Opportunity> testRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c = :testRecurringDonations
        ];
        System.assertEquals(testRecurringDonations.size() * 2, testRDOpportunities.size(), 'Two opportunities should be auto created by recurring donations');

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;

        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(createRDAllocations(testGAU, testRecurringDonations));
        insert testAllocations;

        Test.startTest();
        delete testRecurringDonations;
        Test.stopTest();

        List<Error__c> errors = [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), errors);

        List<Opportunity> deletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testRDOpportunities.size(), deletedRDOpportunities.size(), 'The Opportunities should be cascade deleted with the recurring donations.');

        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testAllocations.size(), deletedAllocations.size(), 'Allocation should be cascade deleted when recurring donation is deleted.');

        undelete testRecurringDonations;

        List<Opportunity> undeletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedRDOpportunities.size(), undeletedRDOpportunities.size(), 'The deleted Recurring Donation Opportunities should be cascade undeleted.');

        List<Allocation__c> undeletedAllocations = [
            SELECT Id 
            FROM Allocation__c
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'The Recurring Donation Allocations should be cascade undeleted.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies correct Classic Theme
    * exception is thrown.
    */
    static testMethod void testRDDeleteException(){
        Contact testContact = new Contact(LastName='CONTACT');
        insert testContact;

        npe03__Recurring_Donation__c testRecurringDonation = new npe03__Recurring_Donation__c(
            Name = 'TEST_RD',
            npe03__Installments__c = 2,
            npe03__Amount__c = 1,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
            npe03__Date_Established__c = date.newinstance(1970, 6, 12),
            npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
            npe03__Contact__c = testContact.Id
        );
        insert testRecurringDonation;

        List<Opportunity> testRDOpportunities = [
            SELECT Name 
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c = :testRecurringDonation.Id
        ];
        System.assertEquals(2, testRDOpportunities.size(), 'Two opps should be auto created by recurring donation.');

        testRDOpportunities[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update testRDOpportunities[0];

        Exception caughException;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonation.Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);

        Test.startTest();
        try{
            delete testRecurringDonation;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies correct Lightning 
    * exception is thrown.
    */
    static testMethod void testRDDeleteException_LightningThemeContext(){
        Contact testContact = new Contact(LastName='CONTACT');
        insert testContact;

        npe03__Recurring_Donation__c testRecurringDonation = new npe03__Recurring_Donation__c(
            Name = 'TEST_RD',
            npe03__Installments__c = 2,
            npe03__Amount__c = 1,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
            npe03__Date_Established__c = date.newinstance(1970, 6, 12),
            npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
            npe03__Contact__c = testContact.Id
        );
        insert testRecurringDonation;

        List<Opportunity> testRDOpportunities = [
            SELECT Name 
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c = :testRecurringDonation.Id
        ];
        System.assertEquals(2, testRDOpportunities.size(), 'Two opps should be auto created by recurring donation.');

        testRDOpportunities[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update testRDOpportunities[0];

        Exception caughException;
        CDL_CascadeDeleteLookups.LIGHTNING_CONTEXT = true;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonation.Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);

        Test.startTest();
        try{
            delete testRecurringDonation;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(testRDOpportunities[0].Id) == false, 'Exception message should not contain the closed won opportunity Id.');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies correct Classic Theme
    * exception is thrown.
    */
    static testMethod void testRDDeleteException_ClassicThemeContext(){
        Contact testContact = new Contact(LastName='CONTACT');
        insert testContact;

        npe03__Recurring_Donation__c testRecurringDonation = new npe03__Recurring_Donation__c(
            Name = 'TEST_RD',
            npe03__Installments__c = 2,
            npe03__Amount__c = 1,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
            npe03__Date_Established__c = date.newinstance(1970, 6, 12),
            npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
            npe03__Contact__c = testContact.Id
        );
        insert testRecurringDonation;

        List<Opportunity> testRDOpportunities = [
            SELECT Name 
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c = :testRecurringDonation.Id
        ];
        System.assertEquals(2, testRDOpportunities.size(), 'Two opps should be auto created by recurring donation.');

        testRDOpportunities[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update testRDOpportunities[0];

        Exception caughException;
        CDL_CascadeDeleteLookups.LIGHTNING_CONTEXT = false;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonation.Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);

        Test.startTest();
        try{
            delete testRecurringDonation;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(testRDOpportunities[0].Id), 'Exception message should contain the closed won opportunity Id.');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }

    /*******************************************************************************************************
    * @description Create Contacts
    * @param Integer The maximum records to create
    * @return List<Contact> The created Contacts
    ********************************************************************************************************/
    private static List<Contact> createContacts(Integer maxRecords) {
        List<Contact> result = new List<Contact>();
        for (Integer i = 0; i < maxRecords; i++) {
            result.add(new Contact(LastName = 'CONTACT' + i));
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Contact Recurring Donations
    * @param List<Contact> The Contacts records that are used to create the Recurring Donations
    * @return List<npe03__Recurring_Donation__c> The created Contact Recurring Donations
    ********************************************************************************************************/
    private static List<npe03__Recurring_Donation__c> createContactRDs(List<Contact> testContacts) {
        List<npe03__Recurring_Donation__c> result = new List<npe03__Recurring_Donation__c>();
        for (Contact testContact : testContacts) {
            result.add(
                new npe03__Recurring_Donation__c(
                    Name = 'CON_RD',
                    npe03__Installments__c = 2,
                    npe03__Amount__c = 1,
                    npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                    npe03__Date_Established__c = Date.newinstance(1970, 6, 12),
                    npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                    npe03__Contact__c = testContact.Id
                )
            );
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Recurring Donation Allocations
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations
    * @param List<npe03__Recurring_Donation__c> The Recurring Donations records that are used to create the Allocations
    * @return List<Allocation__c> The created Allocations
    ********************************************************************************************************/
    private static List<Allocation__c> createRDAllocations(General_Accounting_Unit__c testGAU,  List<npe03__Recurring_Donation__c> testRecurringDonations) {
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
}