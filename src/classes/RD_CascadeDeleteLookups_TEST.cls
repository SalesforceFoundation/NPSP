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
* @description Tests for cascade delete of Recurring Donations
*/
@isTest
private class RD_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Deletes recurring donation, which deletes opportunities and allocations. Verifies results.
    * Then undeletes recurring donation, which undeletes opportunities and allocation. Verifies results.
    */
    static testMethod void testRDCascade(){
        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(1);
        insert accounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        List<Opportunity> rdOpportunities = new List<Opportunity>();
        rdOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.buildRDOpportunities(recurringDonations, UTIL_UnitTestData_TEST.getClosedLostStage()));
        insert rdOpportunities;

        General_Accounting_Unit__c generalAccountingUnit = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert generalAccountingUnit;

        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildRDAllocations(generalAccountingUnit, recurringDonations));
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildOpportunityAllocations(generalAccountingUnit, rdOpportunities));
        insert allocations;

        TDTM_TriggerHandler.disableTDTM = false;

        Test.startTest();
        delete recurringDonations;
        Test.stopTest();

        List<Error__c> errors = CDL_CascadeDeleteLookups_TEST.getErrors();
        System.assertEquals(0, errors.size(), errors);

        List<Opportunity> deletedRDOpportunities = CDL_CascadeDeleteLookups_TEST.getDeletedOpportunities();
        System.assertEquals(rdOpportunities.size(), deletedRDOpportunities.size(), 'The Opportunities should be cascade deleted with the recurring donations.');

        List<Allocation__c> deletedAllocations = CDL_CascadeDeleteLookups_TEST.getDeletedAllocations();
        System.assertEquals(allocations.size(), deletedAllocations.size(), 'Allocation should be cascade deleted when recurring donation is deleted.');

        undelete recurringDonations;

        List<Opportunity> undeletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedRDOpportunities.size(), undeletedRDOpportunities.size(), 'The deleted Recurring Donation Opportunities should be cascade undeleted.');

        List<Allocation__c> undeletedAllocations = CDL_CascadeDeleteLookups_TEST.getNonDeletedAllocations();
        System.assertEquals(deletedAllocations.size(), undeletedAllocations.size(), 'The Recurring Donation Allocations should be cascade undeleted.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies
    * exception is thrown.
    */
    static testMethod void testRDDeleteException(){
        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(1);
        insert accounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        List<Opportunity> rdOpportunities = new List<Opportunity>();
        rdOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.buildRDOpportunities(recurringDonations, UTIL_UnitTestData_TEST.getClosedWonStage()));
        insert rdOpportunities;

        Exception caughException;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(recurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, rdOpportunities[0].Id, rdOpportunities[0].Name);

        TDTM_TriggerHandler.disableTDTM = false;

        Test.startTest();
        try{
            delete recurringDonations;
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
        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(2);
        insert accounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        List<Opportunity> rdOpportunities = new List<Opportunity>();
        
        //Create a Closed Won Opportunity for the first Recurring Donation.
        rdOpportunities.add(
            CDL_CascadeDeleteLookups_TEST.buildRDOpportunities(
                new List<npe03__Recurring_Donation__c>{recurringDonations[0]}, 
                UTIL_UnitTestData_TEST.getClosedWonStage()
            )[0]
        );
        //Create a Closed Lost Opportunity for the first Recurring Donation.
        rdOpportunities.add(
            CDL_CascadeDeleteLookups_TEST.buildRDOpportunities(
                new List<npe03__Recurring_Donation__c>{recurringDonations[1]}, 
                UTIL_UnitTestData_TEST.getClosedLostStage()
            )[0]
        );
        insert rdOpportunities;

        General_Accounting_Unit__c generalAccountingUnit = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert generalAccountingUnit;
        List<Allocation__c> allocations = new List<Allocation__c>();
        allocations.addAll(CDL_CascadeDeleteLookups_TEST.buildRDAllocations(generalAccountingUnit, recurringDonations));
        insert allocations;

        TDTM_TriggerHandler.disableTDTM = false;

        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(recurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, rdOpportunities[0].Id, rdOpportunities[0].Name);

        Test.startTest();
        List<Database.DeleteResult> deleteResults = Database.delete(recurringDonations, false);
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

        List<npe03__Recurring_Donation__c> nonDeletedRecurringDonations = CDL_CascadeDeleteLookups_TEST.getNonDeletedRecurringDonations();
        List<Opportunity> nonDeletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = false
            AND npe03__Recurring_Donation__c = :recurringDonations[0].Id
        ];
        List<Allocation__c> nonDeletedAllocations = CDL_CascadeDeleteLookups_TEST.getNonDeletedAllocations();
        System.assertEquals(1, nonDeletedRecurringDonations.size(), 'The RD testRecurringDonation[0] should not be deleted.');
        System.assertEquals(1, nonDeletedRDOpportunities.size(), 'The testRecurringDonation[0] Opportunity should not be deleted.');
        System.assertEquals(1, nonDeletedAllocations.size(), 'The testRecurringDonation[0] Allocation should not be deleted.');

        List<npe03__Recurring_Donation__c> deletedRecurringDonations = [
            SELECT Id
            FROM npe03__Recurring_Donation__c
            WHERE IsDeleted = true
            AND Id = :recurringDonations[1].Id
            ALL ROWS
        ];
        List<Opportunity> deletedRDOpportunities = [
            SELECT Id 
            FROM Opportunity 
            WHERE IsDeleted = true
            ALL ROWS
        ];
        List<Allocation__c> deletedAllocations = CDL_CascadeDeleteLookups_TEST.getDeletedAllocations();
        System.assertEquals(1, deletedRecurringDonations.size(), 'The RD testRecurringDonation[1] should be deleted.');
        System.assertEquals(1, deletedRDOpportunities.size(), 'The testRecurringDonation[1] Opportunity should be deleted.');
        System.assertEquals(1, deletedAllocations.size(), 'The testRecurringDonation[1] Allocation should be deleted.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies correct Lightning 
    * exception is thrown.
    */
    static testMethod void testRDDeleteException_LightningThemeContext(){
        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(1);
        insert accounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        List<Opportunity> rdOpportunities = new List<Opportunity>();
        rdOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.buildRDOpportunities(recurringDonations, UTIL_UnitTestData_TEST.getClosedWonStage()));
        insert rdOpportunities;

        TDTM_TriggerHandler.disableTDTM = false;

        Exception caughException;
        CDL_CascadeDeleteLookups.isLightningContext = true;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(recurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, rdOpportunities[0].Id, rdOpportunities[0].Name);


        Test.startTest();
        try{
            delete recurringDonations;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(rdOpportunities[0].Id) == false, 'Exception message should not contain the closed won opportunity Id.');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }

    /*********************************************************************************************************
    * @description Attempts to delete recurring donation with closed/won and org opps, verifies correct Classic Theme
    * exception is thrown.
    */
    static testMethod void testRDDeleteException_ClassicThemeContext(){
        List<Account> accounts = CDL_CascadeDeleteLookups_TEST.buildAccounts(1);
        insert accounts;

        TDTM_TriggerHandler.disableTDTM = true;

        List<npe03__Recurring_Donation__c> recurringDonations = new List<npe03__Recurring_Donation__c>();
        recurringDonations.addAll(CDL_CascadeDeleteLookups_TEST.buildOrganizationalRDs(accounts));
        insert recurringDonations;

        List<Opportunity> rdOpportunities = new List<Opportunity>();
        rdOpportunities.addAll(CDL_CascadeDeleteLookups_TEST.buildRDOpportunities(recurringDonations, UTIL_UnitTestData_TEST.getClosedWonStage()));
        insert rdOpportunities;

        TDTM_TriggerHandler.disableTDTM = false;

        Exception caughException;
        CDL_CascadeDeleteLookups.isLightningContext = false;
        CDL_CascadeDeleteLookups.Error expectedError = new CDL_CascadeDeleteLookups.Error(recurringDonations[0].Name);
        expectedError.addChildError(Label.ClosedWonOpportunities, rdOpportunities[0].Id, rdOpportunities[0].Name);

        Test.startTest();
        try{
            delete recurringDonations;
        } catch (Exception ex) {
            caughException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughException, 'An exception should be caught.');
        System.assert(caughException.getMessage().contains(expectedError.getMessage()), 'Exception message is not the one expected');
        System.assert(caughException.getMessage().contains(rdOpportunities[0].Id), 'Exception message should contain the closed won opportunity Id.');
        System.assert(caughException.getMessage().contains(Label.ClosedWonOpportunities), 'Exception message should mention Closed Won Opportunities.');
    }
}