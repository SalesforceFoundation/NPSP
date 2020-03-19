/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020 (2.x)
* @description Tests for DRS_ContactMerge_CTRL
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/
@isTest(isParallel=true)
public with sharing class DRS_ContactMerge_Test {
    //This is test on initail load of the Contact Merge Page
    static testMethod void testInitailLoadOfPage() {
        exerciseUI();
    }
    //exercise the many UI variables
    static void exerciseUI() {
        
        //set up 3 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        con3.LastName = '3Contact_forTests_Merge';

        insert new Contact[]{con, con2, con3};

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller 
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        Test.startTest();
        System.assertEquals(controller.showContactSearch, false);
        System.assertEquals(controller.showDRSButton, true);
        Test.stopTest();
    }

    //This is test to redirection to DRS_ContactMerge Page
    static testMethod void testRedirectToDRSContactMerge() {
        CON_ContactMerge_CTRL controller 
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        PageReference expectedPage = new PageReference('/apex/DRS_ContactMerge');
        PageReference actualPage = controller.redirectToShowDRSList();
        System.assertEquals(expectedPage.getUrl() , actualPage.getUrl());
        System.assertEquals(controller.hasDSRObjectReadPermission(), true);
    }
    
    //This is to test redirect to Contact Search Page
    static testMethod void testShowContactSearchPage() {
        CON_ContactMerge_CTRL controller 
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.showContactSearchPage();
        System.assertEquals(controller.showContactSearch, true);
    }

    static testMethod void testInitailLoadOfDRS() {
        
        Test.startTest();
        getDuplicateSetOfRecords(15);  
        Test.setCurrentPageReference(new PageReference('Page.DRS_ContactMerge'));
        DRS_ContactMerge_CTRL controller 
            = new DRS_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<DuplicateRecordSet>())) ;

        controller.showDuplicateRecordSets();
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

        //Asserts to check the results are correct.
        System.assertEquals(controller.showDRS, true);
        System.assertEquals(controller.totalPages, 2);
        System.assertEquals(controller.hasContactObjectDeletePermission(), true, 'Do not have delete permission on DRS');
        System.assertNotEquals(controller.listDuplicateRecordSets.size(), 0, 'List is empty');
        
        Test.stopTest();
    }

    static testMethod void testSelectDRSrecord() {
        
        Test.startTest();
        getDuplicateSetOfRecords(15);  
        
        Test.setCurrentPageReference(new PageReference('Page.DRS_ContactMerge'));
        DRS_ContactMerge_CTRL controller 
            = new DRS_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<DuplicateRecordSet>())) ;

        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.showContactRelatedToDRS(); 
        
        System.assertEquals(controller.step, 2);
        System.assertNotEquals(controller.contactResults.size(), 0 ,'Contact Not found');
        Test.stopTest();
    }

    static testMethod void testMergeContact() {

        Test.startTest();
        getDuplicateSetOfRecords(15);        
        Test.setCurrentPageReference(new PageReference('Page.DRS_ContactMerge'));
        DRS_ContactMerge_CTRL controller 
            = new DRS_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<DuplicateRecordSet>())) ;

        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.showContactRelatedToDRS(); 
        // now select  2 contacts from the contactwrapper to proceed for merge
        controller.contactResults[0].selected = true;
        controller.contactResults[1].selected = true;
        Id contactId = controller.contactResults[0].contactRecord.Id; 
        controller.nextStep();
        System.assertEquals(controller.selectedRecordsCount, 2);
        
        Apexpages.currentPage().getParameters().put('recordId', contactId);
        controller.selectDefaultRecord();
        PageReference mergedContact = controller.mergeContacts();
        PageReference expectedMergedContactPage  = new PageReference('/'+contactId);
        System.assertEquals(expectedMergedContactPage.getUrl(), mergedContact.getUrl());

        PageReference contactMergePage = controller.searchByContact();
        PageReference expectedContactMergePage  = new PageReference('/apex/CON_ContactMerge?showContactSearch=true');
        System.assertEquals(expectedContactMergePage.getUrl(), contactMergePage.getUrl());

        Test.stopTest();
    }
    
    //When one contact is selected on the page
    static testMethod void testOneContactSelectedToMerge() {
        
        Test.startTest();
        getDuplicateSetOfRecords(15);        
        Test.setCurrentPageReference(new PageReference('Page.DRS_ContactMerge'));
        DRS_ContactMerge_CTRL controller 
            = new DRS_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<DuplicateRecordSet>())) ;

        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.showContactRelatedToDRS(); 
        // now select  1 contacts from the contactwrapper to proceed for merge
        controller.contactResults[0].selected = true;
        Id contactId = controller.contactResults[0].contactRecord.Id; 
        controller.nextStep();
        apexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if( message.getSeverity() == ApexPages.Severity.Error
              && message.getDetail() == Label.npe01.Contact_Merge_Error_Too_Few_Contacts) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
        //Exception is thrown hence the selectedRecordsCount is not populated.
        System.assertEquals(controller.selectedRecordsCount, 0 );
        //Exception is thrown hence the selectedRecordsCount is not populated.
        System.assertEquals(controller.selectedRecordsCount, 0 );

        Test.stopTest();
    }
    
    //Test if more than 3 contacts are selected for merge
    static testMethod void testFourContactSelectedToMerge() {
        
        DuplicateRule dR = [
                            SELECT 
                                Id
                            FROM 
                                DuplicateRule
                            Where
                                SobjectType = 'Contact'
                            LIMIT 1
                            ];
        
        Test.startTest();
        
        //Create Original Contacts
        Contact con = UTIL_UnitTestData_TEST.getContact();
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        Contact con4 = UTIL_UnitTestData_TEST.getContact();
        
        insert new Contact[]{con, con2, con3, con4};
        
        //Create Duplicate Record Set
        List<DuplicateRecordSet> dupRSList = getDuplicateRecordSets(dR.Id , 1);
        insert dupRSList;
        
        //Create Duplicate Record Items
        List<DuplicateRecordItem> duplicateRecordItems = new List<DuplicateRecordItem>();
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con.Id));
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con2.Id));
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con3.Id));
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con4.Id));
        insert duplicateRecordItems;
               
        Test.setCurrentPageReference(new PageReference('Page.DRS_ContactMerge'));
        DRS_ContactMerge_CTRL controller 
            = new DRS_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<DuplicateRecordSet>())) ;

        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.showContactRelatedToDRS(); 
        // now select 4 contacts from the contactwrapper to proceed for merge
        controller.contactResults[0].selected = true;
        controller.contactResults[1].selected = true;
        controller.contactResults[2].selected = true;
        controller.contactResults[3].selected = true;
        Id contactId = controller.contactResults[0].contactRecord.Id; 
        controller.nextStep();
        apexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if( message.getSeverity() == ApexPages.Severity.Error
              && message.getDetail() == Label.npe01.Contact_Merge_Error_Too_Many_Contacts) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
        //Exception is thrown hence the selectedRecordsCount is not populated.
        System.assertEquals(controller.selectedRecordsCount, 0 );

        Test.stopTest();
    }
    
    //Create the duplicate data for contact
    public static void getDuplicateSetOfRecords(Integer duplicateRecordSize) {
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
        
        //Create Duplicate Record Items
        List<DuplicateRecordItem> duplicateRecordItems = new List<DuplicateRecordItem>();

        Database.DMLOptions insertDML = new Database.DMLOptions(); 
        insertDML.DuplicateRuleHeader.AllowSave = true; 
        List<Database.SaveResult> srList  = Database.insert(duplicatecontacts, insertDML);
        Integer index = 0 ;
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id , sr.getId()));
                duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id , contacts[index].Id));
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
}
