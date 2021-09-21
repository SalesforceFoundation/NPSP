/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @group Contact Merge, Regression
* @description Test method for testing unique fields merge on contact
*/
@isTest
public class REG_ContactMergeUniqueField_TEST {
    @isTest
    public static  void shouldSuccessfullyMergeContactsWithLosingUniqueFieldSelected() {
        String WINNING_UNIQUE_VALUE = 'Winning Unique Value';
        String LOSING_UNIQUE_VALUE = 'Losing Unique Value';
        String LOSING_LAST_NAME = '2Contact_forTests_Merge';

        Contact winningContact = UTIL_UnitTestData_TEST.getContact();
        winningContact.ContactMergeUniqueField__c = WINNING_UNIQUE_VALUE;

        Contact losingContact = UTIL_UnitTestData_TEST.getContact();
        losingContact.ContactMergeUniqueField__c = LOSING_UNIQUE_VALUE;
        losingContact.LastName = LOSING_LAST_NAME;
        
        insert new Contact[] {winningContact, losingContact};

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        controller.showContactSearchPage();
        controller.searchText = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        
        List<Id> fixedSearchResults=new List<Id> {
            winningContact.Id,
            losingContact.Id
        }; 

        Test.setFixedSearchResults(fixedSearchResults); 

        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        
        controller.nextStep();
        
        CON_ContactMerge_TEST.selectMasterRecord(controller, winningContact.id);

        List<CON_ContactMerge_CTRL.FieldRow> fieldRows = controller.fieldRows;  
        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if(row.fieldName == 'ContactMergeUniqueField__c') {
                row.selectedValue = String.valueOf(losingContact.Id);
            }
            if(row.fieldName == 'LastName') {
                row.selectedValue = String.valueOf(losingContact.Id);
            }
        }
        
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();
        
        Contact mergedContact = [SELECT ContactMergeUniqueField__c, LastName 
          FROM Contact WHERE Id=:winningContact.Id];
        System.assertEquals(LOSING_UNIQUE_VALUE, mergedContact.ContactMergeUniqueField__c,
            'Contact Merge Unique Field should be updated to losing contact value');
        System.assertEquals(LOSING_LAST_NAME, mergedContact.LastName,
            'Contact Merge Last Name should be updated to losing contact value');
        System.assertEquals(0, ApexPages.getMessages().size(), 'There should be no error thrown onto the Contact Merge Page');
    }
}