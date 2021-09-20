@isTest
public class REG_ContactMergeUniqueField_TEST {
    @isTest
    public static  void shouldSuccessfullyMergeContactsWithLosingUniqueFieldSelected() {
        String WINNING_UNIQUE_VALUE = 'Winning Unique Value';
        String LOSING_UNIQUE_VALUE = 'Losing Unique Value';

        Contact winningContact = UTIL_UnitTestData_TEST.getContact();
        winningContact.ContactMergeUniqueField__c = WINNING_UNIQUE_VALUE;

        Contact losingContact = UTIL_UnitTestData_TEST.getContact();
        losingContact.ContactMergeUniqueField__c = LOSING_UNIQUE_VALUE;
        losingContact.LastName = '2Contact_forTests_Merge';
        
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
                break;
            }
        }
        
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();
        
        Contact mergedContact = [SELECT ContactMergeUniqueField__c FROM Contact WHERE Id=:winningContact.Id];
        System.assertEquals(LOSING_UNIQUE_VALUE, mergedContact.ContactMergeUniqueField__c,
            'Contact Merge Unique Field should be updated to losing contact value');
    }
}