/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (2.x)
* @description Tests for CON_ContactMerge_CTRL
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/
@isTest
public class CON_ContactMerge_TEST {
    @TestSetup
    private static void createTestData() {
        createGenericTestContacts(3);
        createUniqueContact();
        createOneToOneAccountAndContacts(2);
        createPrivateContacts();

        UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);
    }

    public static void selectMasterRecord(CON_ContactMerge_CTRL cont, Id masterId) {
        for (CON_ContactMerge_CTRL.FieldRow row : cont.fieldRows) {
            if (row.showRadio) {
                row.selectedValue = String.valueOf(masterId);
            }
        }
    }

    @IsTest
    private static void shouldDisplayErrorWhenTooFewContactsSelected() {
        // given
        List<Contact> testContacts = getContacts(1);
        CON_ContactMerge_CTRL controller = getControllerForSearch();

        // when
        controller.loadMergeCandidates(getSetOfIds(testContacts));

        // then
        System.assertEquals(1, ApexPages.getMessages().size(), 'Selecting only one contact should display one ' +
                'page-level error message.');
        ApexPages.Message pageMessage = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, pageMessage.getSeverity(), 'The error thrown should be an error' +
                ' severity.');
        System.assertEquals(Label.npe01.Contact_Merge_Error_Too_Few_Contacts, pageMessage.getDetail(), 'The correct ' +
                'error message should be displayed.');
    }

    @IsTest
    private static void searchReturnsResultsWhenMatchFound() {
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.showContactSearch = true;
        controller.searchText = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        controller.mergeSelector = stubFor(new ContactMergeSelectorMock(3));

        Test.startTest();
            controller.search();
        Test.stopTest();

        System.assert(!controller.searchResults.isEmpty(), 'Search results should not be empty.');
        System.assertEquals(3, controller.searchResults.size(), 'The correct number of search results should be ' +
                'returned.');
    }

    @IsTest
    private static void searchReturnsNoResultsWhenNoMatchesFound() {
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.showContactSearch = true;
        controller.searchText = 'test';

        Test.startTest();
        controller.search();
        Test.stopTest();

        System.assert(controller.searchResults.isEmpty(), 'Search results returned from controller should be empty.');
    }

    @IsTest
    private static void shouldSelectEntireDefaultRecordWhenChoosingSelectAll() {
        // given
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> mockContactsWithIds = getMockContactsWithIds(3);
        controller.selectedRecords = getMockSelectedRecordsForMerge(mockContactsWithIds);
        controller.fieldRows = getMockFieldRows(new List<String>{
                String.valueOf(Contact.FirstName),
                String.valueOf(Contact.LastName),
                String.valueOf(Contact.npe01__Preferred_Email__c)
        }, mockContactsWithIds);

        Id defaultRecordId = controller.selectedRecords.get(mockContactsWithIds[0].Id).Id;
        ApexPages.currentPage().getParameters().put('recordId', defaultRecordId);

        //when
        Test.startTest();
            controller.selectDefaultRecord();
        Test.stopTest();

        //then
        for (CON_ContactMerge_CTRL.FieldRow row : controller.fieldRows) {
            if (row.showRadio) {
                System.assertEquals(defaultRecordId, row.selectedValue, 'The selected record should be the default ' +
                    'record.');
            }
        }
    }

    @IsTest
    static void mergeShouldReturnCorrectPageReference() {
        // given
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(2);
        setupMockDataForMerge(controller, testContacts);

        // when
        Test.startTest();
        PageReference mergedContact = controller.mergeContacts();
        Test.stopTest();

        //then
        PageReference expectedMergedContactPage  = new PageReference('/' + testContacts[0].Id);
        System.assertEquals(expectedMergedContactPage.getUrl(), mergedContact.getUrl());
    }

    @IsTest
    private static void mergeFailsWhenContactIsMissing() {
        //given
        // Contact ids are mock ids which will simulate missing contacts on the database
        CON_ContactMerge_CTRL controller = getController();
        setupMockDataForMerge(controller, getMockContactsWithIds(2));

        //when
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();

        //then
        System.assertEquals(1, ApexPages.getMessages().size(), 'Contact merge should from the controller should fail ' +
                'if a contact chosen for merge has been deleted.'); // Selecting a deleted record must throw an error
        ApexPages.Message pageMessage = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.ERROR, pageMessage.getSeverity());
        System.assertEquals(Label.npe01.Contact_Merge_Error_Lock_failed + ' ' + Label.npe01.Contact_Merge_Error_please_retry, pageMessage.getDetail());
    }

    /*******************************************************************************************************
     * @description Integration test to test full load merge candidates flow.
     */
    @IsTest
    private static void selectedMergeCandidatesShouldDisplayCorrectValues() {
        Contact differingContact = getUniqueContact();
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.search();
        selectSearchResults(controller.searchResults);

        Test.startTest();
        controller.nextStep();
        Test.stopTest();

        List<CON_ContactMerge_CTRL.FieldRow> fieldRows = controller.fieldRows;

        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.fieldName.equals(CON_ContactMerge_CTRL.MASTER_KEY)) {
                System.assert(row.showRadio);
                System.assert(row.selectedValue != null);
            }

            if (row.fieldName.equalsIgnoreCase(String.valueOf(Contact.FirstName))) {
                System.assert(!row.showRadio, 'The field should not be shown when both records have the same value.');
            }

            if (row.fieldName.equalsIgnoreCase(String.valueOf(Contact.HomePhone))) {
                System.assert(row.showRadio);
                System.assertEquals(differingContact.Id, row.selectedValue);
            }
        }
    }

    @IsTest
    private static void loadingMergePageFailsWhenTooFewContactsSelected() {
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> mockContacts = getMockContactsWithIds(1);
        setupMockDataForMerge(controller, mockContacts);

        Test.startTest();
            controller.loadMergeCandidates(getSetOfIds(mockContacts));
        Test.stopTest();

        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting only one record for merge should throw an error.
        ApexPages.Message pageMessage = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.ERROR, pageMessage.getSeverity());
        System.assertEquals(Label.npe01.Contact_Merge_Error_Too_Few_Contacts, pageMessage.getDetail());
    }

    @IsTest
    private static void loadMergePageFailsWhenTooManyContactsAreSelected() {
        // given
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> mockContacts = getMockContactsWithIds(4);
        setupMockDataForMerge(controller, mockContacts);

        Test.startTest();
        controller.loadMergeCandidates(getSetOfIds(mockContacts));
        Test.stopTest();

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size(), 'Error should be thrown if more than 3 contacts are selected ' +
                'for merge.');

        Boolean messageFound = false;
        for (ApexPages.Message message : pageMessages) {
            if ( message.getSeverity() == ApexPages.Severity.ERROR
                    && message.getDetail() == Label.npe01.Contact_Merge_Error_Too_Many_Contacts) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }

    /**
     * @description Validate that a User with delete permissions to the Contact object, but no record level acesss
       gets a pageErrorMessage doing the contact merge.
     */
    @isTest
    private static void loadMergePageFailsWithNoDeleteRecordAccess() {
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(2);
        setupMockDataForMerge(controller, testContacts);

        //given
        User readOnlyUser = getReadOnlyUser();
        assignDeletePermissionSet(readOnlyUser.Id);

        Test.startTest();
        System.runAs(readOnlyUser) {
            //when
            controller.loadMergeCandidates(getSetOfIds(testContacts));
            //then
            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.conMergeErrorNoDeleteRecAccess);
        }
        Test.stopTest();
    }

    @IsTest
    private static void loadingMergePageFailsWhenContactIsMissing() {
        //given
        // Contact ids are mock ids which will simulate missing contacts on the database
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> mockContacts = getMockContactsWithIds(2);

        // when
        Test.startTest();
            controller.loadMergeCandidates(getSetOfIds(mockContacts));
        Test.stopTest();

        //then
        System.assertEquals(1, ApexPages.getMessages().size(), 'An error should be thrown when all merge candidates ' +
                'were not successfully queried.');
        ApexPages.Message pageMessage = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.ERROR, pageMessage.getSeverity());
        System.assertEquals(Label.npe01.Contact_Merge_Error_Query_Failed + ' ' + Label.npe01.Contact_Merge_Error_please_retry, pageMessage.getDetail());

    }

    @IsTest
    private static void loadingMergePageFailsWhenTooManyContactsSelected() {
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> mockContacts = getMockContactsWithIds(4);
        setupMockDataForMerge(controller, mockContacts);

        Test.startTest();
            controller.loadMergeCandidates(getSetOfIds(mockContacts));
        Test.stopTest();

        System.assertEquals(1, ApexPages.getMessages().size(), 'An error should be thrown when more than 3 contacts ' +
                'are selected for merge.'); // Selecting too many records for merge should throw
        // an error.
        ApexPages.Message pageMessage = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.ERROR, pageMessage.getSeverity());
        System.assertEquals(Label.npe01.Contact_Merge_Error_Too_Many_Contacts, pageMessage.getDetail());
    }

    /**
     * @description Validate that a User with no delete permissions to the Contact object gets a pageMessage
     * error when navigating to Contact Merge page.
     */
    @isTest
    private static void shouldDisplayErrorWithNoDeletePermission() {
        //given
        User readOnlyUser = getReadOnlyUser();

        Test.startTest();
            System.runAs(readOnlyUser) {
                //when
                CON_ContactMerge_CTRL controller = getController();
                //then
                UTIL_UnitTestData_TEST.assertPageHasError(System.Label.conMergeErrorNoDeleteObjPermission);
            }
        Test.stopTest();
    }

    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    @IsTest
    private static void mergingTwoContactsDeletesCorrectDuplicateAndAccount() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        // given
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(2);
        setupMockDataForMerge(controller, testContacts);

        //when
        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> winningContact = getWinningContact(testContacts);
        List<Contact> losingContact = getLosingContact(testContacts);

        //then
        System.assert(!winningContact.isEmpty(), 'The winning contact should not be deleted.');
        System.assert(losingContact.isEmpty(), 'The losing contact should be deleted.');
        System.assertEquals(testContacts[0].AccountId, testContacts[0].AccountId, 'The winning contacts account ' +
                'should not have changed.');

        List<Account> winningTestAccount = getTestAccountFor(testContacts[0].AccountId);
        List<Account> losingTestAccount = getTestAccountFor(testContacts[1].AccountId);

        System.assert(!winningTestAccount.isEmpty(), 'The winning contacts account should not be deleted.');
        System.assert(losingTestAccount.isEmpty(), 'The losing contacts account should be deleted.');

    }

    //merge two contacts that are both in the one-to-one account model
    //the second contact's org shouldn't be deleted because it has open opportunities
    @IsTest
    private static void mergingTwoContactsDoesNotDeleteDuplicateAccountWithOpportunities() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(1);
        testContacts.add(getUniqueContact());
        setupMockDataForMerge(controller, testContacts);

        Contact losingContact = testContacts[0];
        Contact winningContact = testContacts[1];

        Opportunity testOpportunity = new Opportunity(AccountId =losingContact.AccountId,
                Amount=500, Name='test',StageName='Closed Won',CloseDate=System.today());
        insert testOpportunity;

        selectMasterRecord(controller, winningContact.Id);

        //merge them
        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = getContacts(new List<Contact>{winningContact});
        List<Contact> updatedLosingContact = getContacts(new List<Contact>{losingContact});

        List<Account> winningAccount = getTestAccountFor(updatedWinningContact[0].AccountId);
        List<Account> losingAccount = getTestAccountFor(losingContact.AccountId);

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');

        System.assert(!winningAccount.isEmpty(), 'The winning contact account should not be deleted');
        System.assert(losingAccount.isEmpty(), 'The losing contact account should be deleted.');

        List<Opportunity> updatedWinningOpportunity = [SELECT Id FROM Opportunity WHERE AccountId =
                :updatedWinningContact[0].AccountId];
        List<Opportunity> updatedLosingOpportunity = [SELECT Id FROM Opportunity WHERE AccountId = :losingContact
                .AccountId];

        System.assert(!updatedWinningOpportunity.isEmpty(), 'The winning account should not be deleted since it' +
                ' has opportunities associated.');
        System.assert(updatedLosingOpportunity.isEmpty(), 'The losing account opportunities should be deleted.');

        System.assertEquals(winningContact.AccountId, updatedWinningContact[0].AccountId, 'The winning contacts ' +
                'account should not have changed.');
    }

    @IsTest
    private static void mergingTwoContactsWithActiveRDSustainersChangeToActive() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(1);
        testContacts.add(getUniqueContact());
        setupMockDataForMerge(controller, testContacts);

        Contact losingContact = testContacts[0];
        Contact winningContact = testContacts[1];

        insert new List<npe03__Recurring_Donation__c> {
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusActive()
            .withContact(losingContact.Id)
            .withAmount(1)
            .build(),

            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusClosed()
            .withContact(winningContact.Id)
            .withAmount(1)
            .build()
        };

        winningContact = getContacts(new List<Contact>{winningContact})[0];
        losingContact = getContacts(new List<Contact>{losingContact})[0];

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Active.name(), losingContact.Sustainer__c,
            'The losing Contact should be mark as Active Sustainer');
        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Former.name(), winningContact.Sustainer__c,
            'The winning Contact should be mark as Former Sustainer');

        selectMasterRecord(controller, winningContact.Id);

        //merge them
        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = getContacts(new List<Contact>{winningContact});
        List<Contact> updatedLosingContact = getContacts(new List<Contact>{losingContact});

        List<Account> winningAccount = getTestAccountFor(updatedWinningContact[0].AccountId);
        List<Account> losingAccount = getTestAccountFor(losingContact.AccountId);

        List<npe03__Recurring_Donation__c> rds = [SELECT npe03__Organization__c, npe03__Contact__c FROM npe03__Recurring_Donation__c];

        System.assertEquals(updatedWinningContact[0].Id, rds[0].npe03__Contact__c,
            'The RD should be reparent to winning Contact');
        System.assertEquals(winningAccount[0].Id, rds[0].npe03__Organization__c,
            'The RD should be reparent to winning Account');

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');

        System.assert(!winningAccount.isEmpty(), 'The winning contact account should not be deleted');
        System.assert(losingAccount.isEmpty(), 'The losing contact account should be deleted.');

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Active.name(), updatedWinningContact[0].Sustainer__c,
            'The winning contact should be mark as Active Sustainer when there is an Active RD attached to it.');
            System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Active.name(), winningAccount[0].Sustainer__c,
            'The winning Account should be mark as Active Sustainer when there is an Active RD attached to it.');
    }

    @IsTest
    private static void mergingTwoContactsWithLapsedRDResultSustainerSetToLapsed() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(1);
        testContacts.add(getUniqueContact());
        setupMockDataForMerge(controller, testContacts);

        Contact losingContact = testContacts[0];
        Contact winningContact = testContacts[1];

        insert new List<npe03__Recurring_Donation__c> {
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusLapsed()
            .withContact(losingContact.Id)
            .withAmount(1)
            .build(),

            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusClosed()
            .withContact(winningContact.Id)
            .withAmount(1)
            .build()
        };

        winningContact = getContacts(new List<Contact>{winningContact})[0];
        losingContact = getContacts(new List<Contact>{losingContact})[0];

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Lapsed.name(), losingContact.Sustainer__c,
            'The losing Contact should be mark as Lapsed Sustainer');
        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Former.name(), winningContact.Sustainer__c,
            'The winning Contact should be mark as Former Sustainer');

        selectMasterRecord(controller, winningContact.Id);

        //merge them
        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = getContacts(new List<Contact>{winningContact});
        List<Contact> updatedLosingContact = getContacts(new List<Contact>{losingContact});

        List<Account> winningAccount = getTestAccountFor(updatedWinningContact[0].AccountId);
        List<Account> losingAccount = getTestAccountFor(losingContact.AccountId);

        List<npe03__Recurring_Donation__c> rds = [SELECT npe03__Organization__c, npe03__Contact__c FROM npe03__Recurring_Donation__c];

        System.assertEquals(updatedWinningContact[0].Id, rds[0].npe03__Contact__c,
            'The RD should be reparent to winning Contact');
        System.assertEquals(winningAccount[0].Id, rds[0].npe03__Organization__c,
            'The RD should be reparent to winning Account');

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');

        System.assert(!winningAccount.isEmpty(), 'The winning contact account should not be deleted');
        System.assert(losingAccount.isEmpty(), 'The losing contact account should be deleted.');

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Lapsed.name(), updatedWinningContact[0].Sustainer__c,
            'The winning contact should be mark as Lapsed Sustainer when there is an Lapsed RD attached to it.');
            System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Lapsed.name(), winningAccount[0].Sustainer__c,
            'The winning Account should be mark as Lapsed Sustainer when there is an Lapsed RD attached to it.');
    }

    @IsTest
    private static void mergingTwoContactsWithClosedRDResultSustainerSetToFormer() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        CON_ContactMerge_CTRL controller = getController();
        List<Contact> testContacts = getContacts(1);
        testContacts.add(getUniqueContact());
        setupMockDataForMerge(controller, testContacts);

        Contact losingContact = testContacts[0];
        Contact winningContact = testContacts[1];

        insert TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withStatusClosed()
            .withContact(losingContact.Id)
            .withAmount(1)
            .build();

        winningContact = getContacts(new List<Contact>{winningContact})[0];
        losingContact = getContacts(new List<Contact>{losingContact})[0];

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Former.name(), losingContact.Sustainer__c,
            'The losing Contact should be mark as Former Sustainer');
        System.assertEquals(null, winningContact.Sustainer__c,
            'The winning Contact should not be a Sustainer');

        selectMasterRecord(controller, winningContact.Id);

        //merge them
        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = getContacts(new List<Contact>{winningContact});
        List<Contact> updatedLosingContact = getContacts(new List<Contact>{losingContact});

        List<Account> winningAccount = getTestAccountFor(updatedWinningContact[0].AccountId);
        List<Account> losingAccount = getTestAccountFor(losingContact.AccountId);

        List<npe03__Recurring_Donation__c> rds = [SELECT npe03__Organization__c, npe03__Contact__c FROM npe03__Recurring_Donation__c];

        System.assertEquals(updatedWinningContact[0].Id, rds[0].npe03__Contact__c,
            'The RD should be reparent to winning Contact');
        System.assertEquals(winningAccount[0].Id, rds[0].npe03__Organization__c,
            'The RD should be reparent to winning Account');

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');

        System.assert(!winningAccount.isEmpty(), 'The winning contact account should not be deleted');
        System.assert(losingAccount.isEmpty(), 'The losing contact account should be deleted.');

        System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Former.name(), updatedWinningContact[0].Sustainer__c,
            'The winning contact should be mark as Former Sustainer when there are only Closed RDs attached to it.');
            System.assertEquals(RD2_SustainerEvaluationService.SustainerType.Former.name(), winningAccount[0].Sustainer__c,
            'The winning Account should be mark as Former Sustainer when there are only Closed RDs attached to it.');
    }


    //merge a one-to-one contact with one in a normal organzation
    //the organization shouldn't be deleted
    @IsTest
    static void merge2Organizations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        Account acc = new Account(
            Name = 'Test Account 1'
        );

        Account acc2 = new Account(
            Name = 'Test Account 2'
        );
        insert new Account[]{acc, acc2};

        Contact winningContact = UTIL_UnitTestData_TEST.getContact();
        winningContact.AccountId = acc.Id;

        Contact losingContact = UTIL_UnitTestData_TEST.getContact();
        losingContact.LastName = '2Contact_forTests_Merge';
        losingContact.AccountId = acc2.Id;

        insert new Contact[]{winningContact, losingContact};

        CON_ContactMerge_CTRL controller = getController();
        setupMockDataForMerge(controller, new List<Contact>{winningContact, losingContact});
        selectMasterRecord(controller, winningContact.Id);

        Test.startTest();
        //merge them
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = [Select Id, accountId, FirstName, LastName, MailingStreet from Contact
                                               where Id = :winningContact.Id];
        List<Contact> updatedLosingContact = [Select Id, accountId, FirstName, LastName, MailingStreet from Contact
                                              where Id = :losingContact.Id];

        List<Account> winningAccount = getTestAccountFor(updatedWinningContact[0].AccountId);
        List<Account> losingAccount = getTestAccountFor(losingContact.AccountId);

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');

        System.assert(!winningAccount.isEmpty(), 'The winning contact account should not be deleted');
        System.assert(!losingAccount.isEmpty(), 'The losing contact account should be deleted.');
        System.assertEquals(winningContact.AccountId, updatedWinningContact[0].AccountId, 'The winning contacts ' +
                'account should not have changed.');
    }

    //merge two private contacts
    //the organization shouldn't be deleted
    @IsTest
    static void merge2PrivateContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        List<Contact> privateContacts = getPrivateContacts();
        CON_ContactMerge_CTRL controller = setupControllerMock(privateContacts);

        Contact winningContact = privateContacts[0];
        Contact losingContact = privateContacts[1];

        selectMasterRecord(controller, winningContact.Id);

        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = [Select Id, accountId, FirstName, LastName, MailingStreet from Contact
            where Id = :winningContact.Id];
        List<Contact> updatedLosingContact = [Select id, accountId, FirstName, LastName, MailingStreet from Contact
            where Id = :losingContact.Id];

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');
        System.assertEquals(winningContact.AccountId, updatedWinningContact[0].AccountId, 'The winning contacts ' +
                'account should not have changed.');
    }

    //merge two contacts in the Individual Account
    //the organization shouldn't be deleted or renamed
    @IsTest
    static void merge2IndividualBucketContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        // Arrange: GIVEN two Individual Bucket Contacts exist and are to be merged on the
        // Contact Merge Visualforce page
        List<Contact> testContacts = UTIL_UnitTestData_TEST.getContacts(2);
        insertAsIndividualBucketContacts(testContacts);

        List<Contact> queriedBucketContacts = getContacts(testContacts);
        Contact winningContact = queriedBucketContacts[0];
        Contact losingContact = queriedBucketContacts[1];

        CON_ContactMerge_CTRL controller = setupControllerMock(queriedBucketContacts);

        selectMasterRecord(controller, winningContact.Id);

        Test.startTest();
            controller.mergeContacts();
        Test.stopTest();

        List<Contact> updatedWinningContact = [Select Id, accountId, Account.Name, FirstName, LastName, MailingStreet
            from Contact where Id = :winningContact.Id];

        List<Contact> updatedLosingContact = [Select Id, accountId, FirstName, LastName, MailingStreet from Contact
            where Id = :losingContact.Id];

        List<Account> winningAccount = getTestAccountFor(updatedWinningContact[0].AccountId);
        List<Account> losingAccount = getTestAccountFor(losingContact.AccountId);

        System.assert(!updatedWinningContact.isEmpty(), 'Winning contact should not be deleted.');
        System.assert(updatedLosingContact.isEmpty(), 'Losing contact should be deleted.');

        System.assert(!winningAccount.isEmpty(), 'The winning contact account should not be deleted');
        System.assert(!losingAccount.isEmpty(), 'The losing contact account should be deleted.');
        System.assertEquals(winningContact.AccountId, updatedWinningContact[0].AccountId, 'The winning contacts ' +
                'account should not have changed.');

        System.assertEquals(CAO_Constants.BUCKET_ACCOUNT_NAME, updatedWinningContact[0].Account.Name,
                'The winning Contact\'s Account\'s Name should not have changed');
    }

    @IsTest
    private static void testShowDuplicateRecordSets() {
        //Create 15 DRS records
        getDuplicateSetOfRecords(2);
        CON_ContactMerge_CTRL controller = getController();
        controller.pageSize = 1;
        controller.showDuplicateRecordSets();

        Test.startTest();
        System.assertEquals(controller.hasDSRObjectReadPermission(), true);
        
        Boolean hasNextvalue = controller.hasNext;
        Boolean hasPreviousValue = controller.hasPrevious;
        Integer pageNumberValue = controller.pageNumber;

        System.assertEquals(pageNumberValue, 1);
        System.assertEquals(hasPreviousValue, false);
        System.assertEquals(hasNextvalue, true);

        // Test pagination methods
        controller.lastPage();
        controller.firstPage();
        controller.previouspage();
        controller.nextpage();

        Test.stopTest();

        //Asserts to check the results are correct.
        System.assertEquals(controller.showDRS, true);
        System.assertEquals(controller.totalPages, 2);
        System.assertEquals(controller.hasContactObjectDeletePermission(), true, 'Do not have delete permission on DRS');
        System.assertNotEquals(controller.listDuplicateRecordSets.size(), 0, 'List is empty');
    }

    @IsTest
    private static void testSelectDRRecord() {

        Test.startTest();
        getDuplicateSetOfRecords(3);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.search();
        System.assertEquals(controller.step, 2);
        System.assertNotEquals(controller.searchResults.size(), 0 ,'Contact Not found');
        Test.stopTest();
    }

    @IsTest
    private static void shouldDisplayDuplicateRecordSetWithLeadAndTwoContacts() {
        Test.startTest();
        getDuplicateSetOfRecords(3, 2, true);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.getUnactionableDuplicateRecordSets();
        System.assertEquals(controller.unactionableDuplicateRecordSets.size(), 0,
            'All Duplicate Record Sets should be visible');
        System.assertEquals(Label.commonContactCount, Label.commonContactCount,
            'Label should be ' + Label.commonContactCount);
        System.assertEquals(Label.conMergeFirstContactLabel, Label.conMergeFirstContactLabel,
            'Label should be ' + Label.conMergeFirstContactLabel);

        Test.stopTest();
    }

    @IsTest
    static void shouldNotDisplayDuplicateRecordSetWithLeadAndOneContact() {
        Test.startTest();
        getDuplicateSetOfRecords(3, 1, true);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.getUnactionableDuplicateRecordSets();
        System.assertEquals(controller.unactionableDuplicateRecordSets.size(), 3,
            'All 3 Duplicate Record Sets should not be visible');
        Test.stopTest();
    }

    /*** Helper methods ***/
    public static void getDuplicateSetOfRecords(Integer duplicateRecordSize) {
        getDuplicateSetOfRecords(duplicateRecordSize, 2, false);
    }

    //Create the duplicate data for contact
    public static void getDuplicateSetOfRecords(Integer duplicateRecordSize,
            Integer contactsPerSet,
            Boolean createLeads) {
        DuplicateRule dR = [
                SELECT
                        Id
                FROM
                        DuplicateRule
                Where
                        SobjectType = 'Contact'
                LIMIT 1
        ];
        //Create Original Contacts
        List<Contact> contacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(duplicateRecordSize);
        insert contacts;

        //Create Duplicate Record Set
        List<DuplicateRecordSet> dupRSList = getDuplicateRecordSets(dR.Id , duplicateRecordSize);
        insert dupRSList;

        //Create Duplicate Contact Records
        List<Contact> duplicatecontacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(duplicateRecordSize);

        //Create Duplicate Leads
        List<Lead> duplicateleads;
        if (createLeads) {
            //Create Duplicate Contact Records
            duplicateleads = UTIL_UnitTestData_TEST.createMultipleTestLeads(duplicateRecordSize);
            insert duplicateleads;
        }

        //Create Duplicate Record Items
        List<DuplicateRecordItem> duplicateRecordItems = new List<DuplicateRecordItem>();

        Database.DMLOptions insertDML = new Database.DMLOptions();
        insertDML.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> srList  = Database.insert(duplicatecontacts, insertDML);
        Integer index = 0 ;
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id , sr.getId()));
                if (contactsPerSet == 2) {
                    duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id, contacts[index].Id));
                }
                if (createLeads) {
                    duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id, duplicateleads[index].Id));
                }
            }
            index = index + 1;
        }
        insert duplicateRecordItems;
    }

    //Create Duplicate Record Sets
    public static List<DuplicateRecordSet> getDuplicateRecordSets(Id duplicateRuleId, Integer count) {
        List<DuplicateRecordSet> drsList = new List<DuplicateRecordSet>();
        for (Integer i = 0; i < count; i++) {
            drsList.add(
                    new DuplicateRecordSet(DuplicateRuleId = duplicateRuleId)
            );
        }
        return drsList;
    }

    //Create Duplicate Record Items
    public static DuplicateRecordItem getDuplicateRecordItem(Id drsId, Id recordId) {
        return new DuplicateRecordItem(
                DuplicateRecordSetId = drsId,
                RecordId = recordId
        );
    }
    private static void createPrivateContacts() {
        List<Contact> contactsToMakePrivate = UTIL_UnitTestData_TEST.getContacts(2);
        for (Contact contact : contactsToMakePrivate) {
            contact.npe01__Private__c = true;
        }
        insert contactsToMakePrivate;
    }

    private static CON_ContactMerge_CTRL setupControllerMock(List<Contact> testContacts) {
        CON_ContactMerge_CTRL controller = getController();
        setupMockDataForMerge(controller, testContacts);
        return controller;
    }

    private static Map<Id, Contact> getContactsByRecordId(Set<Id> contactIds) {
        return new Map<Id, Contact>([
                Select accountId, FirstName, LastName, MailingStreet, Account.Name
                from Contact
                where Id = :contactIds
        ]);
    }

    private static List<Contact> getContacts(Integer numberOfContacts) {
        return [
                SELECT FirstName, LastName, npe01__Preferred_Email__c, AccountId, Sustainer__c
                FROM Contact
                LIMIT :numberOfContacts
        ];
    }

    private static List<Contact> getContacts(List<Contact> contacts) {
        return [
                SELECT FirstName, LastName, npe01__Preferred_Email__c, AccountId, Sustainer__c
                FROM Contact
                WHERE Id IN :contacts
        ];
    }

    private static void insertAsIndividualBucketContacts(Contact[] contacts) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c (
                        npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));

        insert contacts;
    }

    private static void createOneToOneAccountAndContacts(Integer numberToCreate) {
        List<Contact> oneToOneContacts = UTIL_UnitTestData_TEST.createAccountContactTestData(
                CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, numberToCreate, 1, 0);
    }

    private static List<Contact> getLosingContact(List<Contact> testContacts) {
        List<Contact> losingContact = [SELECT AccountId FROM Contact WHERE Id = :testContacts[1].Id];
        return losingContact;
    }

    private static List<Contact> getWinningContact(List<Contact> testContacts) {
        List<Contact> winningContact = [SELECT AccountId FROM Contact WHERE Id = :testContacts[0].Id];
        return winningContact;
    }

    private static List<Account> getTestAccountFor(Id accountId) {
        return [SELECT Id, Sustainer__c FROM Account WHERE Id = :accountId];
    }

    private static Set<Id> getSetOfIds(List<SObject> records) {
        return (new Map<Id,SObject>(records)).keySet();
    }

    private static User getReadOnlyUser() {
        return [SELECT Id FROM User WHERE Profile.Name = :UTIL_UnitTestData_TEST.PROFILE_READONLY_USER LIMIT 1];
    }

    private static void selectSearchResults(List<CON_ContactMerge_CTRL.ContactWrapper> searchResults) {
        for (CON_ContactMerge_CTRL.ContactWrapper contactWrapper : searchResults) {
            contactWrapper.selected = true;
        }
    }

    private static List<Contact> getMockContactsWithIds(Integer numberOfResults) {
        List<Contact> mockContacts = new List<Contact>();
        for (Integer i = 0; i < numberOfResults; i++) {
            Contact testContact = UTIL_UnitTestData_TEST.getContact();
            UTIL_UnitTestData_TEST.setMockId(testContact);

            mockContacts.add(testContact);
        }
        return mockContacts;
    }

    private static List<Contact> createGenericTestContacts(Integer numberOfContacts) {
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < numberOfContacts; i++) {
            Contact testContact = UTIL_UnitTestData_TEST.getContact();

            testContacts.add(testContact);
        }
        insert testContacts;
        return testContacts;
    }

    private static void createUniqueContact() {
        List<Account> testAccounts = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, CAO_Constants.HH_ACCOUNT_TYPE);
        UTIL_UnitTestData_TEST.oppsForAccountList(new List<Account> {testAccounts[0]}, null,
            UTIL_UnitTestData_TEST.getClosedWonStage(), null, Double.valueOf(10.00),
            null, null);

        Contact differingContact = UTIL_UnitTestData_TEST.getContact();
        differingContact.LastName = 'Differing';
        differingContact.HomePhone = '7771232345';
        differingContact.MailingStreet = '123 Test St';
        differingContact.AccountId = testAccounts[0].Id;
        insert differingContact;
    }

    private static List<Contact> getPrivateContacts() {
        return [
                SELECT FirstName, LastName, npe01__Preferred_Email__c, AccountId
                FROM Contact
                WHERE npe01__Private__c = TRUE
        ];
    }

    private static List<Contact> getOneToOneContacts() {
        return [
                SELECT FirstName, LastName, npe01__Preferred_Email__c, AccountId
                FROM Contact
                WHERE Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE
        ];
    }

    private static Contact getUniqueContact() {
        return [SELECT FirstName, LastName, npe01__Preferred_Email__c, AccountId
                FROM Contact
                WHERE HomePhone = '7771232345'
                LIMIT 1
        ];
    }

    private static Map<String, Contact> getMockSelectedRecordsForMerge(List<Contact> mockContactsWithIds) {
        return new Map<String, Contact>(mockContactsWithIds);
    }

    private static List<CON_ContactMerge_CTRL.FieldRow> getMockFieldRows(List<String> fieldNames,
            List<Contact> contacts) {
        List<CON_ContactMerge_CTRL.FieldRow> mockFieldRows = new List<CON_ContactMerge_CTRL.FieldRow>();
        for (Integer i=0; i < fieldNames.size(); i++) {
            CON_ContactMerge_CTRL.FieldRow mockFieldRow = new CON_ContactMerge_CTRL.FieldRow();

            if (isMasterRecordField(fieldNames[i])) {
                mockFieldRow.fieldName = CON_ContactMerge_CTRL.MASTER_KEY;
                mockFieldRow.fieldLabel = 'Master Record';
                mockFieldRow.showRadio = true;
                mockFieldRow.selectedValue = contacts[0].Id;
            } else {
                mockFieldRow.fieldLabel = 'Test Field';
                mockFieldRow.fieldName = fieldNames[i];
                mockFieldRow.showRadio = true;
                mockFieldRow.selectedValue = contacts[0].Id;
            }

            List<CON_ContactMerge_CTRL.Cell> mockCells = getMockCells(fieldNames[i], contacts);
            mockFieldRow.values = mockCells;
            mockFieldRows.add(mockFieldRow);
        }
        return mockFieldRows;
    }

    private static List<CON_ContactMerge_CTRL.Cell> getMockCells(String fieldName, List<Contact> contacts) {
        List<CON_ContactMerge_CTRL.Cell> mockCells = new List<CON_ContactMerge_CTRL.Cell>();
        for (Contact contact : contacts) {
            CON_ContactMerge_CTRL.Cell mockCell = new CON_ContactMerge_CTRL.Cell(
                contact.Id,
                getCellValue(fieldName, contact)
            );
            mockCells.add(mockCell);
        }
        return mockCells;
    }

    private static String getCellValue(String fieldName, Contact contact) {
        if (isMasterRecordField(fieldName)) {
            return String.valueOf(contact.Id);
        } else {
           return String.valueOf(contact.get(fieldName));
        }
    }

    private static Boolean isMasterRecordField(String fieldName) {
        return fieldName == CON_ContactMerge_CTRL.MASTER_KEY;
    }

    /*******************************************************************************************************
    * @description Creates and assigns the permission set with delete permission on contact object
    */
    private static void assignDeletePermissionSet(Id userId) {
        // Create a permission set with CustomizeApplication set ensuring other flags
        // on which CustomizeApplication settings depends are set as well
        PermissionSet permission = new PermissionSet(
                Name = 'PermissionTest',
                Label = 'PermissionTest'
        );

        insert permission;

        insert new ObjectPermissions (
                SObjectType = 'Contact',
                ParentId = permission.id,
                PermissionsRead = true,
                PermissionsViewAllRecords = true,
                PermissionsCreate = true,
                PermissionsDelete = true,
                PermissionsEdit = true
        );

        insert new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = permission.Id
        );

    }

    private static CON_ContactMerge_CTRL getControllerForSearch() {
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.StandardSetController(new List<Contact>()));
        controller.showContactSearch = true;
        controller.searchText = 'test';
        return controller;
    }

    private static CON_ContactMerge_CTRL getController() {
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.StandardSetController(new List<Contact>()));
        return controller;
    }

    private static void setupMockDataForMerge(CON_ContactMerge_CTRL controller, List<Contact> contactsToMerge) {
        setMockFieldRows(controller, contactsToMerge);
        setSelectedRecordsForMerge(controller, contactsToMerge);
    }

    private static void setMockFieldRows(CON_ContactMerge_CTRL controller, List<Contact> contactsToMerge) {
        controller.fieldRows = getMockFieldRows(new List<String>{
                CON_ContactMerge_CTRL.MASTER_KEY,
                String.valueOf(Contact.FirstName),
                String.valueOf(Contact.LastName),
                String.valueOf(Contact.npe01__Preferred_Email__c)
        }, contactsToMerge);
    }

    private static void setSelectedRecordsForMerge(CON_ContactMerge_CTRL controller, List<Contact> contactsToMerge) {
        controller.selectedRecords = getMockSelectedRecordsForMerge(contactsToMerge);
    }

    private static CON_ContactMerge_CTRL.FieldRow getMasterRecordRow(List<CON_ContactMerge_CTRL.FieldRow> fieldRows) {
        CON_ContactMerge_CTRL.FieldRow masterRecordRow;
        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.showRadio && isMasterRecordField(row.fieldName)) {
                masterRecordRow = row;
            }
        }
        return masterRecordRow;
    }

    private static Id setWinningContact(CON_ContactMerge_CTRL.FieldRow masterRecordRow, Id winningContactIdToSet) {
        masterRecordRow.selectedValue = winningContactIdToSet;

        return winningContactIdToSet;
    }

    private static ContactMergeSelector stubFor(StubProvider mock) {
        return  (ContactMergeSelector) Test.createStub(
                ContactMergeSelector.class,
                mock
        );
    }

    private class ContactMergeSelectorMock implements StubProvider {
        Integer numberOfResults;

        public ContactMergeSelectorMock(Integer numberOfResults) {
            this.numberOfResults = numberOfResults;
        }

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'selectContactsByName' {
                    List<Contact> contacts = UTIL_UnitTestData_TEST.getContacts(numberOfResults);
                    UTIL_UnitTestData_TEST.setMockIds(contacts);

                    return contacts;
                }
            }

            return null;
        }
    }
}
