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
* @description tests out the Post Process Extensibility mechanism in BDI
*/

@isTest
public with sharing class BDI_PostProcess_TEST {


    /*********************************************************************************************************
    * @description operation
    *        import DI's with new Contact1 and Contact2 specified
    * verify:
    *       relationships created between Contact1 and Contact2
    *       duplicate relationships not created when Contact1 and Contact2 appear in multiple DI records
    */
    static testMethod void testRelCreatedForDIsWithC1AndC2() {

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'A', 'c2', 'A'));
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'A', 'c2', 'A')); // dupe contacts should not get another rel.
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'B', 'c2', 'B'));
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C', 'c2', 'C'));
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'D', null, null)); // should not get a rel
        listDI.add(BDI_DataImport_TEST.newDI(null, null, 'c2', 'E')); // should not get a rel
        insert listDI;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Post_Process_Implementing_Class__c = UTIL_Namespace.StrTokenNSPrefixDotNotation('BDI_PostProcess_TEST.MyPostProcess');

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [SELECT Id, Name, AccountId FROM Contact];
        system.assertEquals(8, listCon.size());

        List<npe4__Relationship__c> listRel = [SELECT npe4__Contact__c, npe4__RelatedContact__c, npe4__Type__c, npe4__Status__c
            FROM npe4__Relationship__c];
        system.assertEquals(6, listRel.size());
        for (integer i = 0; i < listRel.size(); i++) {
            system.assertEquals('Spouse', listRel[i].npe4__Type__c);
            system.assertEquals('Current', listRel[i].npe4__Status__c);
        }

        listDI = [select Id, Status__c from DataImport__c];
        system.assertEquals(6, listDI.size());
        for (integer i = 0; i < listDI.size(); i++) {
            system.assertEquals(BDI_DataImport_API.bdiImported, listDI[i].Status__c);
        }
    }

    /*******************************************************************************************************
    * @description a test implementation of BDI_IPostProcess, to use for testing that post process
    * extensibility works.
    */
    public with sharing class MyPostProcess implements BDI_IPostProcess {

        /*******************************************************************************************************
        * @description Perform any additional processing steps after NPSP has completed processing all Data
        * Import records in the current batch execution.  This implementation creates a "Spouse" relationship
        * between Contact1 and Contact2, if both are specified, and newly created (ie, not matched to existing).
        *
        * @param bdi The BDI instance currently running
        * @return void
        */
        public void process(BDI_DataImportService bdi) {

            List<npe4__Relationship__c> listRel = new List<npe4__Relationship__c>();

            for (DataImport__c di : bdi.listDI) {
                // create a relationship if both c1 and c2 are specified
                // and they are newly created contacts
                if (di.Contact1Imported__c != null && di.Contact2Imported__c != null &&
                    di.Contact1ImportStatus__c == label.bdiCreated && di.Contact2ImportStatus__c == label.bdiCreated) {
                    listRel.add(new npe4__Relationship__c(
                        npe4__Contact__c = di.Contact1Imported__c,
                        npe4__RelatedContact__c = di.Contact2Imported__c,
                        npe4__Type__c = 'Spouse',
                        npe4__Status__c = 'Current'));
                }
            }

            if (listRel.size() > 0) {
                database.insert(listRel);
            }

        }
    }
}