/**
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
* @description Tests for visualforce page enabling a selected set of Data Import records 
* to be processed via list view button
*/
@isTest
private class BDI_ProcessSelectedDIs_TEST {

    /*********************************************************************************************************
    * @description Tests that DataImport Ids are passed in the URL to the BDI_DataImport page
    **********************************************************************************************************/
    @isTest
    static void testDIIdsPassed() {

        DataImport__c[] testDIs = diGenerator(2);

        insert testDIs;

        Test.startTest();
        Test.setCurrentPage(Page.BDI_ProcessSelectedDIs);
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(testDIs);
        setCtrl.setSelected(testDIs);

        BDI_ProcessSelectedDIs_CTRL ctrl = new BDI_ProcessSelectedDIs_CTRL(setCtrl);
        PageReference pr = ctrl.directToDataImportPage();

        Test.stopTest();
        
        // Confirm no error messages were generated
        System.assertEquals(false, ApexPages.hasMessages());

        // Confirm that the URL contains the correct Ids
        System.assert(pr.getUrl().contains(testDIs[0].Id));
        System.assert(pr.getUrl().contains(testDIs[1].Id));
    }


    /*********************************************************************************************************
    * @description Tests too many record error
    **********************************************************************************************************/
    @isTest
    static void testTooManyDIRecordError() {

        DataImport__c[] testDIs = diGenerator(6);

        insert testDIs;

        Test.startTest();
        Test.setCurrentPage(Page.BDI_ProcessSelectedDIs);
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(testDIs);
        setCtrl.setSelected(testDIs);

        BDI_ProcessSelectedDIs_CTRL ctrl = new BDI_ProcessSelectedDIs_CTRL(setCtrl);

        Test.stopTest();
        
        // Construct expected error message
        String errorMsg = String.format(System.label.bdiSelectTooManyDIRecords, 
            new String[]{String.valueOf(ctrl.maxNumOfDi)});

        // Confirm error message was generated
        System.assertEquals(true, ApexPages.hasMessages());
        System.assertEquals(errorMsg,ApexPages.getMessages()[0].getDetail());
    }

    /*********************************************************************************************************
    * @description Tests no record selected error
    **********************************************************************************************************/
    @isTest
    static void testNoRecordSelected() {

        DataImport__c[] testDIs = new DataImport__c[]{};

        Test.startTest();
        Test.setCurrentPage(Page.BDI_ProcessSelectedDIs);
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(testDIs);
        setCtrl.setSelected(testDIs);

        BDI_ProcessSelectedDIs_CTRL ctrl = new BDI_ProcessSelectedDIs_CTRL(setCtrl);

        Test.stopTest();
        
        // Confirm error message was generated
        System.assertEquals(true, ApexPages.hasMessages());
        System.assertEquals(System.label.bdiSelectNoDIRecordsSelected,ApexPages.getMessages()[0].getDetail());
    }

    /*********************************************************************************************************
    * @description Tests that an error is thrown if one of the selected DIs is already imported
    **********************************************************************************************************/
    @isTest
    static void testAlreadyImportedError() {

        DataImport__c[] testDIs = diGenerator(2);
        // Set one to imported to test error
        testDIs[0].Status__c = BDI_DataImport_API.bdiImported;

        insert testDIs;

        Test.startTest();
        
        Test.setCurrentPage(Page.BDI_ProcessSelectedDIs);
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(testDIs);
        setCtrl.setSelected(testDIs);

        BDI_ProcessSelectedDIs_CTRL ctrl = new BDI_ProcessSelectedDIs_CTRL(setCtrl);

        Test.stopTest();
        
        // Confirm error message was generated
        System.assertEquals(true, ApexPages.hasMessages());
        System.assertEquals(System.label.bdiSelectCantProcessImportedRecords,ApexPages.getMessages()[0].getDetail());

        ctrl.returnToListView();
    }

    /*********************************************************************************************************
    * @description Tests that an error is thrown if one of the selected DIs is a part of a NPSP Data Import Batch
    **********************************************************************************************************/
    @isTest
    static void testBatchDataImportRecordError() {

        DataImportBatch__c diBatch = Util_UnitTestData_TEST.createGiftBatches(200,2,1)[0];
        insert diBatch;

        DataImport__c[] testDIs = diGenerator(2);
        // Set one to be part of a batch to test error
        testDIs[0].NPSP_Data_Import_Batch__c = diBatch.Id;

        insert testDIs;

        Test.startTest();
        Test.setCurrentPage(Page.BDI_ProcessSelectedDIs);
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(testDIs);
        setCtrl.setSelected(testDIs);

        BDI_ProcessSelectedDIs_CTRL ctrl = new BDI_ProcessSelectedDIs_CTRL(setCtrl);

        Test.stopTest();
        
        // Confirm error message was generated
        System.assertEquals(true, ApexPages.hasMessages());
        System.assertEquals(System.label.bdiSelectCantProcessBatchDIRecords,ApexPages.getMessages()[0].getDetail());
    }

    /*********************************************************************************************************
    * @description Prepares Data Import test data
    **********************************************************************************************************/
    private static DataImport__c[] diGenerator (Integer numOfDIs) {
        DataImport__c[] disForImport = new DataImport__c[]{};

        for (Integer i = 0; i < numOfDis; i ++) {
            DataImport__c testDi = new DataImport__c(
                Contact1_Firstname__c = 'FirstNameA' + i,
                Contact1_Lastname__c = 'LastNameA' + i,
                Contact1_Personal_Email__c = 'testA' + i +'@fakedata.com',
                Contact1_Preferred_Email__c = 'testA' + i +'@fakedata.com',
                Donation_Donor__c = 'Contact1',
                Donation_Amount__c = 100,
                Donation_Date__c = System.Date.Today(),
                Home_City__c = 'Fakeville',
                Home_Country__c = 'United States',
                Home_State_Province__c = 'California',
                Home_Street__c = i +' FakeA Blvd',
                Home_Zip_Postal_Code__c = '94105',
                Payment_Check_Reference_Number__c = '453',
                Payment_Method__c = 'Check');
            disForImport.add(testDi);
        }

        return disForImport;
    }
}
