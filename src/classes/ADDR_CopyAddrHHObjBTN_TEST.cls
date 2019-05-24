/*
    Copyright (c) 2011, Salesforce.org
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
* @date 2011 (2.3)
* @group Address Management
* @description test class for the Copy Address button controller
*/
@isTest(isParallel=true)
private with sharing class ADDR_CopyAddrHHObjBTN_TEST {
    private static Contact contactRecord;
    private static npo02__Household__c householdRecord;
    private static ADDR_CopyAddrHHObjBTN_CTRL copyAddressCtrl;
    private static PermissionsMock mockPerms = new PermissionsMock();

    /*******************************************************************************************************************
    * @description Create records common to test methods
    * @return void
    */
    @TestSetup
    private static void createRecordData() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR));

        npo02__Household__c householdRecord = new npo02__Household__c(
            npo02__MailingStreet__c = '123 Main St.',
            npo02__MailingState__c = 'Pennsylvania',
            npo02__MailingPostalCode__c = '18940',
            npo02__MailingCity__c = 'Newtown',
            npo02__MailingCountry__c = 'United States'
        );
        insert householdRecord;

        Contact contactRecord = new Contact(
            npo02__Household__c = householdRecord.Id,
            LastName = 'Copy Address Last Name',
            MailingStreet = '1 Oak Lane',
            MailingState = 'British Columbia',
            MailingPostalCode = '98122',
            MailingCity = 'Vancouver',
            MailingCountry = 'Canada'
        );
        insert contactRecord;
    }

    /*******************************************************************************************************************
    * @description Verify the the Contact address is copied to the Household
    * @return void
    */
    @isTest
    private static void shouldCopyAddressFromContact() {
        getRecordData();
        createCopyAddressBtnCtrl(contactRecord.Id);

        System.assertNotEquals(contactRecord.MailingStreet, householdRecord.npo02__MailingStreet__c, 'The original addresses should not match.');

        copyAddressCtrl.copy();

        householdRecord = getHouseholdRecordData();
        System.assertEquals(contactRecord.MailingStreet, householdRecord.npo02__MailingStreet__c, 'The household address should be updated to match the contact.');
        verifyNoteRecordCount(householdRecord.Id);
    }

    /*******************************************************************************************************************
    * @description Verify the the Household address is copied to the Contact
    * @return void
    */
    @isTest
    private static void shouldCopyAddressFromHousehold() {
        getRecordData();
        createCopyAddressBtnCtrl(householdRecord.Id);
        System.assertNotEquals(householdRecord.npo02__MailingStreet__c, contactRecord.MailingStreet, 'The original addresses should not match.');

        copyAddressCtrl.copy();

        contactRecord = getContactRecordData();
        System.assertEquals(householdRecord.npo02__MailingStreet__c, contactRecord.MailingStreet, 'The contact address should be updated to match the contact.');
        verifyNoteRecordCount(contactRecord.Id);
    }

    /*******************************************************************************************************************
    * @description Verify an error will display when an Account Id is provided
    * @return void
    */
    @isTest
    private static void shouldErrorWhenCopyAddressFromAccount() {
        Account accountRecord = new Account(Name = 'Copy Address Error Org');
        insert accountRecord;
        createCopyAddressBtnCtrl(accountRecord.Id);

        copyAddressCtrl.copy();

        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.npo02.AddressCopyUnknownObject);
    }

    /*******************************************************************************************************************
    * @description Verifies a confirmation message is displayed when button clicked
    * @return void
    */
    @isTest
    private static void shouldDisplayConfirmationMessageWhenBtnClicked() {
        getRecordData();
        createCopyAddressBtnCtrl(contactRecord.Id);

        copyAddressCtrl.buttonClick();
        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.addrCopyConAddBtnConfirm, ApexPages.Severity.INFO);
    }

    /*******************************************************************************************************************
    * @description Verifies an error message is displayed when a user does not have contact read permissions
    * @return void
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutContactReadPerms() {
        getRecordData();
        mockPerms.hasRead = false;
        createCopyAddressBtnCtrl(contactRecord.Id);

        copyAddressCtrl.buttonClick();
        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(Contact.SObjectType, mockPerms.readSObjType);
        System.assert(mockPerms.readSObjFields.contains(Contact.MailingStreet));
    }

    /*******************************************************************************************************************
    * @description Verifies an error message is displayed when a user does not have household read permissions
    * @return void
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutHHReadPerms() {
        getRecordData();
        mockPerms.hasRead = false;
        createCopyAddressBtnCtrl(householdRecord.Id);

        copyAddressCtrl.buttonClick();
        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(npo02__Household__c.SObjectType, mockPerms.readSObjType);
        System.assert(mockPerms.readSObjFields.contains(npo02__Household__c.npo02__MailingStreet__c));
    }

    /*******************************************************************************************************************
    * @description Verifies an error message is displayed when a user does not have contact update permissions
    * @return void
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutContactUpdatePerms() {
        getRecordData();
        mockPerms.hasUpdate = false;
        createCopyAddressBtnCtrl(householdRecord.Id);

        copyAddressCtrl.buttonClick();
        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(Contact.SObjectType, mockPerms.updateSObjType);
        System.assert(mockPerms.updateSObjFields.contains(Contact.MailingStreet));
    }

    /*******************************************************************************************************************
    * @description Verifies an error message is displayed when a user does not have household update permissions
    * @return void
    */
    @isTest
    private static void shouldErrorWhenBtnClickedWithoutHHUpdatePerms() {
        getRecordData();
        mockPerms.hasUpdate = false;
        createCopyAddressBtnCtrl(contactRecord.Id);

        copyAddressCtrl.buttonClick();
        UTIL_UnitTestData_TEST.assertPageHasError(System.Label.addrCopyConAddBtnFls);
        System.assertEquals(npo02__Household__c.SObjectType, mockPerms.updateSObjType);
        System.assert(mockPerms.updateSObjFields.contains(npo02__Household__c.npo02__MailingStreet__c));
    }

    /*******************************************************************************************************************
    * @description The page reference returned contains the record Id passed to the controller
    * @return void
    */
    @isTest
    private static void shouldReturnPageReferenceWithRecordId() {
        getRecordData();
        createCopyAddressBtnCtrl(contactRecord.Id);

        System.assert(String.valueOf(copyAddressCtrl.close()).contains(contactRecord.Id), 'The page ref should contain the record Id.' );
    }

    /*******************************************************************************************************************
    * @description The page reference returned should be the user home page when the id is not supported
    * @return void
    */
    @isTest
    private static void shouldReturnHomePageWhenUnsupportedRecordId() {
        Account accountRecord = new Account(Name = 'Copy Address Unsupported Org');
        insert accountRecord;
        createCopyAddressBtnCtrl(accountRecord.Id);

        System.assert(String.valueOf(copyAddressCtrl.close()).contains('home'), 'The page ref should be the user home page.' );
    }

    // Helpers
    ////////////////

    /*******************************************************************************************************************
    * @description Populates the record variables with the records generated in test setup
    * @return void
    */
    private static void getRecordData() {
        householdRecord = getHouseholdRecordData();
        contactRecord = getContactRecordData();
    }

    /*******************************************************************************************************************
    * @description Queries the household record created in test setup
    * @return npo02__Household__c
    */
    private static npo02__Household__c getHouseholdRecordData() {
        return [
            SELECT Id, npo02__MailingStreet__c, npo02__MailingState__c,
                npo02__MailingPostalCode__c, npo02__MailingCity__c, npo02__MailingCountry__c
            FROM npo02__Household__c
            LIMIT 1
        ];
    }

    /*******************************************************************************************************************
    * @description Queries the contact record created in test setup
    * @return Contact
    */
    private static Contact getContactRecordData() {
        return [
            SELECT Id, MailingStreet, MailingState, MailingPostalCode, MailingCity, MailingCountry
            FROM Contact
            LIMIT 1
        ];
    }

    /*******************************************************************************************************************
    * @description Sets the current page to page controller from the button click of provided record Id
    * with user having permissions by default.
    * @param recordId - the record Id to pass to the controller
    */
    private static void createCopyAddressBtnCtrl(Id recordId) {
        Test.setCurrentPageReference(new PageReference('Page.ADDR_CopyAddrHHObjBTN'));
        System.currentPageReference().getParameters().put('id', recordId);
        copyAddressCtrl = new ADDR_CopyAddrHHObjBTN_CTRL();
        copyAddressCtrl.perms = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class, mockPerms);

        copyAddressCtrl.buttonClick();
    }

    /*******************************************************************************************************************
    * @description Verify a note was created for the provided record Id
    * @param parentId - the id of the record the note belongs to
    * @return void
    */
    private static void verifyNoteRecordCount(Id parentId) {
        System.assertEquals(1, [SELECT count() FROM Note where ParentID = :parentId]);
    }

    /*******************************************************************************************************************
    * @description Stub for UTIL_Permissions instance
    */
    private class PermissionsMock implements System.StubProvider {
        private Boolean hasRead = true;
        private Boolean hasUpdate = true;
        private SObjectType readSObjType;
        private SObjectType updateSObjType;
        private Set<SObjectField> readSObjFields;
        private Set<SObjectField> updateSObjFields;

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            switch on stubbedMethodName {
                when 'canRead' {
                    readSObjType = (SObjectType) listOfArgs[0];
                    readSObjFields = (Set<SObjectField>) listOfArgs[1];

                    return hasRead;

                } when 'canUpdate' {
                    updateSObjType = (SObjectType) listOfArgs[0];
                    updateSObjFields = (Set<SObjectField>) listOfArgs[1];

                    return hasUpdate;

                } when else {
                    return null;
                }
            }
        }
    }

}