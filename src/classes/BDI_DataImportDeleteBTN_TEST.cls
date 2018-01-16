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
 * @description Tests specific to the Delete Data Import Records buttons' user interface and error handling
 */

@isTest
class BDI_DataImportDeleteBTN_TEST {

    /**
     * @description Specify '*' to run all tests, 
     * otherwise, specify a test name to execute the specified test only
     */
    static String strTestOnly = '*';

    /** @description Error message returned when user does not have Delete permission on the SObject */
    static String INSUFFICIENT_ACCESS_ERROR_MSG = 'INSUFFICIENT_ACCESS_OR_READONLY';

    /** @description Static method executed before each test method is run */
    static {
        Test.setCurrentPage(Page.BDI_DataImportDeleteBTN); 
    }
    
    /**
     * @description operation: 
     *    Test an error message is displayed when a button is clicked and
     *    the action type page parameter is not provided or is empty
     * verify: 
     *    - the error is displayed on the page
     *    - no record is deleted
     */
    @isTest
    static void TestErrorMessageDisplayWhenPageActionParameterIsNotProvided() {
        if (isNotRunnable('TestErrorMessageDisplayWhenPageActionParameterIsNotProvided')) return;
        
        PageReference returnPage;
        DataImport__c[] records = setUpData();
        
        Test.startTest();
        
        for (String actionType : new String[] { null, '', ' ' }) {
            returnPage = clickButton(actionType);
            
            System.assertEquals(null, returnPage);
            
            UTIL_UnitTestData_TEST.assertPageHasError('Please specify an action type');
            
            assertExpectedRecordSize(records.size());
        }
        
        Test.stopTest();
    }
    
    /**
     * @description operation: 
     *    Test an error message is displayed when a button is clicked and
     *    the action type page parameter is not valid
     * verify: 
     *    - the error is displayed on the page
     *    - no record is deleted
     */
    @isTest
    static void TestErrorMessageDisplayWhenPageActionParameterIsInvalid() {
        if (isNotRunnable('TestErrorMessageDisplayWhenPageActionParameterIsInvalid')) return;
        
        String actionType = 'TestInvalidAction';
        DataImport__c[] records = setUpData();
        
        Test.startTest();
        PageReference returnPage = clickButton(actionType);
        Test.stopTest();

        System.assertEquals(null, returnPage);

        UTIL_UnitTestData_TEST.assertPageHasError(actionType + ' is not a valid action type');

        assertExpectedRecordSize(records.size());
    }

    /**
     * @description operation: 
     *    Test Delete All Data Import Records button 
     * verify: 
     *    All records are deleted
     */
    @isTest
    static void TestDeleteAllDataImportRecordsBtn() {
        if (isNotRunnable('TestDeleteAllDataImportRecordsBtn')) return;
            
        DataImport__c[] records = setUpData();
        
        Test.startTest();
        PageReference returnPage = clickButton(BDI_DataImportDeleteBTN_CTRL.ACTION_DELETE_ALL);
        Test.stopTest();

        System.assertNotEquals(null, returnPage);

        assertExpectedRecordSize(0);
    }

    /**
     * @description operation: 
     *    Test Delete All Data Import Records button action
     *    adds an error message to the page when an exception is raised.
     * verify: 
     *    - the error is displayed on the page
     *    - no record is deleted
     */
    @isTest
    static void TestDeleteAllDataImportRecordsBtnExceptionMessageDisplay() {
        testPageErrorMessageDisplayOnDeleteActionException(
            'TestDeleteAllDataImportRecordsBtnExceptionMessageDisplay',
            BDI_DataImportDeleteBTN_CTRL.ACTION_DELETE_ALL,
            INSUFFICIENT_ACCESS_ERROR_MSG
        );
    }

   /**
    * @description operation: 
    *    Test Delete Imported Data Import Records button 
    * verify: 
    *    All imported records are deleted
    */
    @isTest
    static void TestDeleteImportedDataImportRecordsBtn() {
        if (isNotRunnable('TestDeleteImportedDataImportRecordsBtn')) return;
            
        DataImport__c[] records = setUpData();
        records[3].Status__c = BDI_DataImport_API.bdiImported;
        update records;
        
        Test.startTest();
        PageReference returnPage = clickButton(BDI_DataImportDeleteBTN_CTRL.ACTION_DELETE_IMPORTED);
        Test.stopTest();

        System.assertNotEquals(null, returnPage);

        records = [SELECT Id, Status__c FROM DataImport__c ORDER BY Status__c];
        System.assertEquals(2, records.size());
        System.assertEquals(null, records[0].Status__c);
        System.assertEquals(BDI_DataImport_API.bdiFailed, records[1].Status__c);
    }

    /**
     * @description operation: 
     *    Test Delete Imported Data Import Records button action
     *    adds an error message to the page when an exception is raised.
     * verify: 
     *    - the error is displayed on the page
     *    - no record is deleted
     */
    @isTest
    static void TestDeleteImportedDataImportRecordsBtnExceptionMessageDisplay() {
        testPageErrorMessageDisplayOnDeleteActionException(
            'TestDeleteImportedDataImportRecordsBtnExceptionMessageDisplay',
            BDI_DataImportDeleteBTN_CTRL.ACTION_DELETE_IMPORTED,
            INSUFFICIENT_ACCESS_ERROR_MSG
        );
    }

    /**
     * @description operation: 
     *    Test close() method when page parameter retURL is blank
     * verify: 
     *    Home page is returned
     */
    @isTest
    static void TestCloseWhenRetUrlIsBlank() {
        if (isNotRunnable('TestCloseWhenRetUrlIsBlank')) return;

        for (String retURL : new String[] { null, '', ' ' }) {
            ApexPages.currentPage().getParameters().put('retURL', retURL);

            assertHomePage(new BDI_DataImportDeleteBTN_CTRL().close());
        }
    }

    /**
     * @description operation: 
     *    Test close() method when page parameter retURL is not provided
     * verify: 
     *    Home page is returned
     */
    @isTest
    static void TestCloseWhenRetUrlIsNotProvided() {
        if (isNotRunnable('TestCloseWhenRetUrlIsNotProvided')) return;

        assertHomePage(new BDI_DataImportDeleteBTN_CTRL().close());
    }

    /**
     * @description operation: 
     *    Test close() method when page parameter retURL is provided
     * verify: 
     *    retURL page is returned
     */
    @isTest
    static void TestCloseWhenRetUrlIsProvided() {
        if (isNotRunnable('TestCloseWhenRetUrlIsProvided')) return;

        String retURL = '/testpage.jsp';
        ApexPages.currentPage().getParameters().put('retURL', retURL);

        assertPage(retURL, new BDI_DataImportDeleteBTN_CTRL().close());
    }

    // Helpers
    ////////////

    /**
     * @description Create Data Import records with various status values
     * @return DataImport__c[] Data Import records
     */
    static DataImport__c[] setUpData() {
        DataImport__c[] records = new DataImport__c[] {
            BDI_DataImport_TEST.newDI('c1', 'C1', 'c2', 'C2'),
            BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4'),
            BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4'),
            BDI_DataImport_TEST.newDI('c3', 'C3', 'c4', 'C4')
        };
        records[0].Status__c = BDI_DataImport_API.bdiImported;
        records[1].Status__c = BDI_DataImport_API.bdiFailed;

        insert records;
        return records;
    }

    /**
     * @description Check if the specified test should not be executed
     * @param testMethodName Name of the test method
     * @return Boolean true if the test should not be executed, otherwise false
     */
    static Boolean isNotRunnable(String testMethodName) {
        return strTestOnly != '*' && strTestOnly != testMethodName;
    }

    /**
     * @description Assert that actual and expected number of Data Import records is the same
     * @param expectedSize Expected number of Data Import records
     * @return void
     */
    static void assertExpectedRecordSize(Integer expectedSize) {
        System.assertEquals(expectedSize, [SELECT COUNT() FROM DataImport__c]);
    }

    /**
     * @description Set up page and test specified delete action type
     * @param actionType Specific action type to delete all or imported Data Import records
     * @return PageReference
     */
    static PageReference clickButton(String actionType) {
        ApexPages.currentPage().getParameters().put('action', actionType);

        BDI_DataImportDeleteBTN_CTRL ctrl = new BDI_DataImportDeleteBTN_CTRL();

        return ctrl.buttonClick();
    }

    /**
     * @description Apply delete action as a user with Standard User profile.
     * Assert the exception message is displayed on the Visualforce page.
     * @return void
     */
    static void testPageErrorMessageDisplayOnDeleteActionException(
        String testMethodName,
        String actionType,
        String expectedMsg
    ) {
        if (isNotRunnable(testMethodName)) return;

        PageReference returnPage;
        DataImport__c[] records = setUpData();
        
        Test.startTest();

        System.runAs(UTIL_UnitTestData_TEST.createStandardProfileUser()) {
            returnPage = clickButton(actionType);
        }

        Test.stopTest();

        System.assertEquals(null, returnPage);

        UTIL_UnitTestData_TEST.assertPageHasError(expectedMsg);

        assertExpectedRecordSize(records.size());
    }

    /**
     * @description Assert Home page URL and redirect values
     * @param actual Page to verify
     * @return void
     */
    static void assertHomePage(PageReference actual) {
        assertPage('/home/home.jsp', actual);
    }

    /**
     * @description Assert page URL and redirect values
     * @param expectedUrl Expected URL
     * @param actual Page to verify
     * @return void
     */
    static void assertPage(String expectedUrl, PageReference actual) {
        System.assertNotEquals(null, actual);
        System.assert(actual.getRedirect());
        System.assertEquals(expectedUrl, actual.getUrl());
    }
	
}