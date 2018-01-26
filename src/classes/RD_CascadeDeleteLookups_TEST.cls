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
        List<Account> testAccounts = CDL_CascadeDeleteLookups_TEST.createAccounts(1);
        insert testAccounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        List<Opportunity> testRDOpportunities = new List<Opportunity>();
        testRDOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.createRDOpportunities(testRecurringDonations, UTIL_UnitTestData_TEST.getClosedLostStage()));
        insert testRDOpportunities;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;

        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createRDAllocations(testGAU, testRecurringDonations));
        insert testAllocations;

        TDTM_TriggerHandler.disableTDTM = false;

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
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies
    * exception is thrown.
    */
    static testMethod void testRDDeleteException(){
        List<Account> testAccounts = CDL_CascadeDeleteLookups_TEST.createAccounts(1);
        insert testAccounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        List<Opportunity> testRDOpportunities = new List<Opportunity>();
        testRDOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.createRDOpportunities(testRecurringDonations, UTIL_UnitTestData_TEST.getClosedWonStage()));
        insert testRDOpportunities;

        Exception caughException;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);

        TDTM_TriggerHandler.disableTDTM = false;

        Test.startTest();
        try{
            delete testRecurringDonations;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete 2 Recurring Donations, 1 with Closed Won Opportunity and the other one
    * with Closed Lost Opportunity. The first one should have an error, and its Closed Won Opportunity should 
    * not be deleted. The other one should be deleted, and its Closed Lost Opportunity deleted.
    */
    static testMethod void testRDDeleteWithMixExceptionAndSuccess(){
        List<Account> testAccounts = CDL_CascadeDeleteLookups_TEST.createAccounts(2);
        insert testAccounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        List<Opportunity> testRDOpportunities = new List<Opportunity>();
        
        //Create a Closed Won Opportunity for the first Recurring Donation.
        testRDOpportunities.add(
            CDL_CascadeDeleteLookups_TEST.createRDOpportunities(
                new List<npe03__Recurring_Donation__c>{testRecurringDonations[0]}, 
                UTIL_UnitTestData_TEST.getClosedWonStage()
            )[0]
        );
        //Create a Closed Lost Opportunity for the first Recurring Donation.
        testRDOpportunities.add(
            CDL_CascadeDeleteLookups_TEST.createRDOpportunities(
                new List<npe03__Recurring_Donation__c>{testRecurringDonations[1]}, 
                UTIL_UnitTestData_TEST.getClosedLostStage()
            )[0]
        );
        insert testRDOpportunities;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(CDL_CascadeDeleteLookups_TEST.createRDAllocations(testGAU, testRecurringDonations));
        insert testAllocations;

        TDTM_TriggerHandler.disableTDTM = false;

        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);

        Test.startTest();
        List<Database.DeleteResult> deleteResults = Database.delete(testRecurringDonations, false);
        Test.stopTest();

        Set<String> errorMessages = new Set<String>();
        for (Database.DeleteResult deleteResult :deleteResults) {
            if (deleteResult.isSuccess()) {
                continue;
            }
            for (Database.Error deleteError : deleteResult.getErrors()) {
                errorMessages.add(deleteError.getMessage());
            }
        }
        System.assert(errorMessages.isEmpty() == false, 'An exception should be caught.');
        System.assert(errorMessages.contains(expectedError.getMessage()), 'Exception message is not the one expected');

        List<npe03__Recurring_Donation__c> nonDeletedRecurringDonations = [
            SELECT Id
            FROM npe03__Recurring_Donation__c
            WHERE IsDeleted = false
            AND Id = :testRecurringDonations[0].Id
        ];
        List<Opportunity> nonDeletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = false
            AND npe03__Recurring_Donation__c = :testRecurringDonations[0].Id
        ];
        List<Allocation__c> nonDeletedAllocations = [
            SELECT Id 
            FROM Allocation__c
            WHERE IsDeleted = false
            AND Recurring_Donation__c = :testRecurringDonations[0].Id
        ];
        System.assertEquals(1, nonDeletedRecurringDonations.size(), 'The RD testRecurringDonation[0] should not be deleted.');
        System.assertEquals(1, nonDeletedRDOpportunities.size(), 'The testRecurringDonation[0] Opportunity should not be deleted.');
        System.assertEquals(1, nonDeletedAllocations.size(), 'The testRecurringDonation[0] Allocation should not be deleted.');

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = [
            SELECT Id
            FROM npe03__Recurring_Donation__c
            WHERE IsDeleted = true
            AND Id = :testRecurringDonations[1].Id
            ALL ROWS
        ];
        List<Opportunity> deletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = true
            ALL ROWS
        ];
        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c
            WHERE IsDeleted = true
            ALL ROWS
        ];
        System.assertEquals(1, deletedRecurringDonations.size(), 'The RD testRecurringDonation[1] should be deleted.');
        System.assertEquals(1, deletedRDOpportunities.size(), 'The testRecurringDonation[1] Opportunity should be deleted.');
        System.assertEquals(1, deletedAllocations.size(), 'The testRecurringDonation[1] Allocation should be deleted.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies correct Lightning 
    * exception is thrown.
    */
    static testMethod void testRDDeleteException_LightningThemeContext(){
        List<Account> testAccounts = CDL_CascadeDeleteLookups_TEST.createAccounts(1);
        insert testAccounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        List<Opportunity> testRDOpportunities = new List<Opportunity>();
        testRDOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.createRDOpportunities(testRecurringDonations, UTIL_UnitTestData_TEST.getClosedWonStage()));
        insert testRDOpportunities;

        TDTM_TriggerHandler.disableTDTM = false;

        Exception caughException;
        CDL_CascadeDeleteLookups.LIGHTNING_CONTEXT = true;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);


        Test.startTest();
        try{
            delete testRecurringDonations;
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
        List<Account> testAccounts = CDL_CascadeDeleteLookups_TEST.createAccounts(1);
        insert testAccounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> testRecurringDonations = new List<npe03__Recurring_Donation__c>();
        testRecurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.createOrganizationalRDs(testAccounts));
        insert testRecurringDonations;

        List<Opportunity> testRDOpportunities = new List<Opportunity>();
        testRDOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.createRDOpportunities(testRecurringDonations, UTIL_UnitTestData_TEST.getClosedWonStage()));
        insert testRDOpportunities;

        TDTM_TriggerHandler.disableTDTM = false;

        Exception caughException;
        CDL_CascadeDeleteLookups.LIGHTNING_CONTEXT = false;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(testRecurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, testRDOpportunities[0].Id, testRDOpportunities[0].Name);

        Test.startTest();
        try{
            delete testRecurringDonations;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(testRDOpportunities[0].Id), 'Exception message should contain the closed won opportunity Id.');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }
}