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
* @description Tests for cascade delete of Campaigns
*/
@isTest
private class CAM_CascadeDeleteLookups_TEST {

    /*********************************************************************************************************
    * @description Deletes the Campaigns which deletes the related Allocations. Verifies results.
    * Then undeletes the Campaigns, which undeletes the Allocations. Verifies results.
    */
    static testMethod void testCampaignsCascadeDelete(){
        Integer maxRecords = 200;

        List<Campaign> testCampaigns = createCampaigns(maxRecords);
        insert testCampaigns;

        General_Accounting_Unit__c testGAU = new General_Accounting_Unit__c(Name = 'TEST_GAU');
        insert testGAU;
        List<Allocation__c> testAllocations = new List<Allocation__c>();
        testAllocations.addAll(createCampaignAllocations(testGAU, testCampaigns));
        insert testAllocations;

        Test.startTest();
        delete testCampaigns;
        Test.stopTest();

        List<Error__c> errors = [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), errors);

        List<Allocation__c> deletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = true 
            ALL ROWS
        ];
        System.assertEquals(testAllocations.size(), deletedAllocations.size(), 'Allocations should be cascade deleted when campaigns are deleted.');

        undelete testCampaigns;

        errors = [
            SELECT Id, Object_Type__c, Full_Message__c, Stack_Trace__c 
            FROM Error__c
        ];
        System.assertEquals(0, errors.size(), errors);

        List<Allocation__c> undeletedAllocations = [
            SELECT Id 
            FROM Allocation__c 
            WHERE IsDeleted = false
        ];
        System.assertEquals(deletedAllocations.size(), deletedAllocations.size(), 'Allocations should be cascade undeleted.');
    }

    /*******************************************************************************************************
    * @description Create Campaigns
    * @param Integer The maximum records to create
    * @return List<Campaign> The created Campaigns
    ********************************************************************************************************/
    private static List<Campaign> createCampaigns(Integer maxRecords) {
        List<Campaign> result = new List<Campaign>();
        for (Integer i = 0; i < maxRecords; i++) {
            result.add(new Campaign(Name = 'CAMP' + i));
        }
        return result;
    }

    /*******************************************************************************************************
    * @description Create Campaign Allocations
    * @param General_Accounting_Unit__c The General Accounting Unit record that is used to create the Allocations
    * @param List<Campaign> The Campaigns records that are used to create the Allocations
    * @return List<Allocation__c> The created Allocations
    ********************************************************************************************************/
    private static List<Allocation__c> createCampaignAllocations(General_Accounting_Unit__c testGAU,  List<Campaign> testCampaigns) {
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
}