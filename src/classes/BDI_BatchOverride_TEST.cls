/*
    Copyright (c) 2017 Salesforce.org
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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Import Batch Edit Override user interface
*/

@isTest
public with sharing class BDI_BatchOverride_TEST {

    /*********************************************************************************************************
    * @description returns a new initialized DataImportBatch object
    * @returns DataImportBatch__c
    */
    public static DataImportBatch__c newDIBatch() {

        return new DataImportBatch__c(
            Name = 'testBatch',
            Batch_Process_Size__c = 100,
            Donation_Matching_Behavior__c = BDI_DataImport_API.DoNotMatch,
            Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c'),
            Contact_Matching_Rule__c = 'Firstname',
            Donation_Date_Range__c = 0
        );
    }

    /*********************************************************************************************************
    * @description operation:
    *    test controller against a new Batch
    */
    static testMethod void saveNewBatch() {

        DataImportBatch__c diBatch = newDIBatch();
        BDI_BatchOverride_CTRL ctrl = new BDI_BatchOverride_CTRL(new ApexPages.StandardController(diBatch));

        Test.startTest();
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        Test.stopTest();

        System.assert(ctrl.redirect, 'The page should save successfully and set redirect to true.');
        System.assertEquals(1, [select count() from DataImportBatch__c]);
    }

    /*********************************************************************************************************
    * @description operation:
    *    test controller against an existing Batch
    */
    static testMethod void saveExistingBatch() {

        DataImportBatch__c diBatch = newDIBatch();
        insert diBatch;

        BDI_BatchOverride_CTRL ctrl = new BDI_BatchOverride_CTRL(new ApexPages.StandardController(diBatch));

        Test.startTest();
        ctrl.diBatch.Name = 'testBatchModified';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        Test.stopTest();

        System.assert(ctrl.redirect, 'The page should save successfully and set redirect to true.');
        System.assertEquals(1, [select count() from DataImportBatch__c where Name = 'testBatchModified']);
    }

    /*********************************************************************************************************
    * @description operation:
    *    test controller against cloning an existing Batch
    */
    static testMethod void saveClonedBatch() {

        DataImportBatch__c diBatch = newDIBatch();
        insert diBatch;

        PageReference pageRef = Page.BDI_BatchOverride;
        pageRef.getParameters().put('id', diBatch.Id);
        pageRef.getParameters().put('clone', '1');
        Test.setCurrentPage(pageRef);
        BDI_BatchOverride_CTRL ctrl = new BDI_BatchOverride_CTRL(new ApexPages.StandardController(diBatch));

        Test.startTest();
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        Test.stopTest();

        System.assert(ctrl.redirect, 'The page should save successfully and set redirect to true.');
        System.assertEquals(2, [select count() from DataImportBatch__c]);
        System.assertEquals(1, [select count() from DataImportBatch__c where Name = 'testBatch - Cloned']);
    }

    /*********************************************************************************************************
    * @description operation:
    *    test validation of save method
    * verify:
    *    errors detected
    */
    static testMethod void testBDIBatchUISaveValidation() {

        // start with a valid diBatch
        DataImportBatch__c diBatch = newDIBatch();

        // instantiate the controller
        BDI_BatchOverride_CTRL ctrl = new BDI_BatchOverride_CTRL(new ApexPages.StandardController(diBatch));

        Test.startTest();

        diBatch.Name = null;
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save without a name and redirect should remain false.');

        diBatch = newDIBatch();
        diBatch.Batch_Process_Size__c = -1;
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with a negative batch size and redirect should remain false.');

        diBatch.Donation_Matching_Behavior__c = 'bogus value';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with an invalid matching behavior and redirect should remain false.');

        diBatch = newDIBatch();
        diBatch.Donation_Matching_Rule__c = 'Donation_Date__c';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with an invalid matching rule and redirect should remain false.');

        diBatch = newDIBatch();
        diBatch.Donation_Date_Range__c = -1;
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with a negative date range and redirect should remain false.');

        diBatch = newDIBatch();
        diBatch.Donation_Matching_Implementing_Class__c = 'foo';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with an invalid matching implementation class and redirect should remain false.');


        diBatch = newDIBatch();
        diBatch.Post_Process_Implementing_Class__c = 'bar';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with an invalid process implementation class and redirect should remain false.');

        diBatch = newDIBatch();
        diBatch.Contact_Custom_Unique_ID__c = 'bogus field';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with an invalid contact unique id field and redirect should remain false.');

        diBatch = newDIBatch();
        diBatch.Account_Custom_Unique_ID__c = 'bogus field';
        System.assertEquals(null, ctrl.save(), 'The page should always return null on save and use redirect flag for javascript navigation on page');
        System.assert(!ctrl.redirect, 'The page should fail to save with an invalid account unique id field and redirect should remain false.');

        Test.stopTest();
    }

}