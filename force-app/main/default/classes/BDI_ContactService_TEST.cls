/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Tests specific to the BDI_ContactService class.
*/
@isTest
private with sharing class BDI_ContactService_TEST {

    @TestSetup
    static void createContactsForMatch(){
        Contact cont1 = new Contact(FirstName = 'match1', LastName = 'match1');
        Contact cont2 = new Contact(FirstName = 'match2', LastName = 'match2');

        insert new Contact[]{cont1, cont2};
    }

    /** 
    * @description This tests how the Contact Service handles match results and updates the DI by mocking 
    * match results from UTIL_DuplicateMgmt when the Contact Matching mode is using the Contact Duplicate
    * Rules.
    */
    @isTest
    static void dupeMgmtShouldMatchAndUpdateDIs() {
        
        // Configure Data Import Settings so that the Duplicate Management logic will be used.
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c = 
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        dis.Contact_Matching_Rule__c = System.Label.bdiContactMatchDupeMgmt;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        // Retrieve the contacts we inserted for test reference.
        Contact matchCont1;
        Contact matchCont2;

        for (Contact cont : [SELECT Id, LastName FROM Contact LIMIT 10]) {
            if (cont.LastName == 'match1') {
                matchCont1 = cont;
            } else if (cont.LastName == 'match2') {
                matchCont2 = cont;
            }
        }

        // Prepare mocked match results for testing so we can check that Imported / ImportStatus fields are updated.
        UTIL_DuplicateMgmt.MatchDetail match1a = new UTIL_DuplicateMgmt.MatchDetail();
        match1a.recordId = matchCont1.Id;
        match1a.confidenceScore = 50;
        match1a.matchingRuleName = 'MatchingRule1a';
        match1a.duplicateRuleName = 'DupeRule1a';

        UTIL_DuplicateMgmt.MatchDetail match1b = new UTIL_DuplicateMgmt.MatchDetail();
        match1b.recordId = '00Q000000000000'; // Simulated Lead Id which should be excluded from matching
        match1b.confidenceScore = 100;
        match1b.matchingRuleName = 'MatchingRule1b';
        match1b.duplicateRuleName = 'DupeRule1b';

        UTIL_DuplicateMgmt.MatchDetail match1c = new UTIL_DuplicateMgmt.MatchDetail();
        match1c.recordId = matchCont1.Id;
        match1c.confidenceScore = 100;
        match1c.matchingRuleName = 'MatchingRule1c';
        match1c.duplicateRuleName = 'DupeRule1c';

        UTIL_DuplicateMgmt.MatchDetail match2 = new UTIL_DuplicateMgmt.MatchDetail();
        match2.recordId = matchCont2.Id;
        match2.confidenceScore = 100;
        match2.matchingRuleName = 'MatchingRule2';
        match2.duplicateRuleName = 'DupeRule2';

        // Prepare data imports that will be updated by the the new duplicate management logic after running match.
        DataImport__c testDi1 = new DataImport__c(
            Contact1_Firstname__c = 'match1',
            Contact1_Lastname__c = 'match1',
            Contact2_Firstname__c = 'match2',
            Contact2_Lastname__c = 'match2',
            Home_City__c = 'Fakeville',
            Home_Country__c = 'United States',
            Home_State_Province__c = 'California',
            Home_Street__c = '100 Fake Blvd',
            Home_Zip_Postal_Code__c = '94105');

        DataImport__c testDi2 = new DataImport__c(
            Contact1_Firstname__c = 'match1',
            Contact1_Lastname__c = 'match1',
            Contact2_Firstname__c = 'NotAMatch1',
            Contact2_Lastname__c = 'NotAMatch1',
            Home_City__c = 'Fakeville',
            Home_Country__c = 'United States',
            Home_State_Province__c = 'California',
            Home_Street__c = '100 Fake Blvd',
            Home_Zip_Postal_Code__c = '94105');
        
        DataImport__c testDi3 = new DataImport__c(
            Contact1_Firstname__c = 'noMatch3',
            Contact1_Lastname__c = 'noMatch3',
            Contact2_Firstname__c = 'noMatch4',
            Contact2_Lastname__c = 'noMatch4',
            Home_City__c = 'Fakeville',
            Home_Country__c = 'United States',
            Home_State_Province__c = 'California',
            Home_Street__c = '300 Fake Blvd',
            Home_Zip_Postal_Code__c = '94105');

        DataImport__c[] diList = new DataImport__c[]{testDi1,testDi2,testDi3};
        insert diList;

        // Instantiate the Data Import and Contact services so we can test the Contact Service in isolation
        // without needing to run all of Data Import.
        BDI_MappingService mapService = BDI_DataImportService.getDefaultMappingService();
        BDI_DataImportService diService = new BDI_DataImportService(true,mapService);
        diService.listDI = diList;
        diService.injectDataImportSettings(dis);

        BDI_DataImportService.injectPerfLogger(new BDI_PerfLogger(null,3));
        
        BDI_ContactService contService = new BDI_ContactService(diService);

        // Prepare contact sobjs that should match
        Sobject di1c1 = contService.mapContactFromDIToSobj(testDi1,1);
        Sobject di1c2 = contService.mapContactFromDIToSobj(testDi1,2);
        Sobject di2c1 = contService.mapContactFromDIToSobj(testDi2,1);
        Sobject di2c2 = contService.mapContactFromDIToSobj(testDi2,2);
        Sobject di3c1 = contService.mapContactFromDIToSobj(testDi3,1);
        Sobject di3c2 = contService.mapContactFromDIToSobj(testDi3,2);

        // Construct the mock results. We don't need a d2c1 since it will generate the same contact sObj as d1c1.
        Map<Sobject,UTIL_DuplicateMgmt.MatchDetail[]> mockResults = new Map<Sobject,UTIL_DuplicateMgmt.MatchDetail[]>{
            di1c1 => new UTIL_DuplicateMgmt.MatchDetail[]{match1a, match1b, match1c},
            di1c2 => new UTIL_DuplicateMgmt.MatchDetail[]{match2},
            di2c2 => null,
            di3c1 => null,
            di3c2 => null};

        UTILDuplicateMgmtMock dupeMock = new UTILDuplicateMgmtMock(mockResults);
        UTIL_DuplicateMgmt dupeMgmt = (UTIL_DuplicateMgmt)Test.createStub(UTIL_DuplicateMgmt.class, dupeMock);
        contService.dupeMgmtUtil = dupeMgmt;

        Test.startTest();
        contService.importContactsAndHouseholds();
        Test.stopTest();

        // Confirm that the Import Status and Imported Fields for each DI are updated appropriately.
        System.assertEquals(matchCont1.Id, testDi1.Contact1Imported__c);
        System.assert(testDi1.Contact1ImportStatus__c.contains(match1c.duplicateRuleName));

        System.assertEquals(matchCont2.Id, testDi1.Contact2Imported__c);
        System.assert(testDi1.Contact2ImportStatus__c.contains(match2.duplicateRuleName));

        System.assertEquals(matchCont1.Id, testDi2.Contact1Imported__c);
        System.assert(testDi2.Contact1ImportStatus__c.contains(match1c.duplicateRuleName));

        System.assertEquals(null, testDi2.Contact2Imported__c);
        System.assertEquals(diService.statusMatchedNew(), testDi2.Contact2ImportStatus__c);

        System.assertEquals(null, testDi3.Contact1Imported__c);
        System.assertEquals(diService.statusMatchedNew(), testDi3.Contact1ImportStatus__c);

        System.assertEquals(null, testDi3.Contact2Imported__c);
        System.assertEquals(diService.statusMatchedNew(), testDi3.Contact2ImportStatus__c);
        
    }

    /**
     * @description StubProvider implementation used to create match results from duplicate management in unit tests.
     */
    
    private class UTILDuplicateMgmtMock implements StubProvider {
        private Map<SObject, UTIL_DuplicateMgmt.MatchDetail[]> sObjToMatchDetails = new
                Map<SObject, UTIL_DuplicateMgmt.MatchDetail[]>();

        public UTILDuplicateMgmtMock (Map<SObject, UTIL_DuplicateMgmt.MatchDetail[]> sObjToMatchDetails) {
            this.sObjToMatchDetails = sObjToMatchDetails;
        }

        public Object handleMethodCall(
                Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'findDuplicatesBulk' {
                    return sObjToMatchDetails;
                }
            }
            return null;
        }
    }
}
