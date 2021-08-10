/**
 * Created by kenneth.lewis on 8/9/21.
 */

@IsTest
private class HouseholdTests_TEST {

    @IsTest
    private static void ContactRepository_getContactsShouldReturnEmptyListWhenAccountHasNoContacts() {
        Account account = new Account(Name = 'AccountWithoutContacts');
        insert account;

        Households households = new Households(new Set<Id>{
                account.Id
        });


        Contacts members = households.membersOf(new HouseholdId(account.Id));
        Contact[] contacts = members.getRecords();

        System.assertEquals(0, contacts.size());
    }

    /*********************************************************************************************************
    @description
        Execute ContactRepository.getContacts() for Acconts having Contacts
    verify:
        Method returns expected Contact list for each Account
    **********************************************************************************************************/
    @IsTest
    //todo: rename and move to HH Tests
    private static void ContactRepository_getContactsShouldReturnContactsWhenAccountHasContacts() {
        Integer hhSize = 2;
        Integer contactSize = 2;
        ADDR_Addresses_TEST.createTestData(hhSize, contactSize);

        Households testHouseholds = new Households(
                UTIL_SObject.extractIds(ADDR_Addresses_TEST.testAccounts)
        );

        testAndAssertContactRepositoryGetContacts(testHouseholds, ADDR_Addresses_TEST.testAccounts, ADDR_Addresses_TEST.testContacts);
    }

    /*********************************************************************************************************
    @description
        Execute ContactRepository.getContacts() for each Account in the input argument Account list
    verify:
        Method returns expected Contact list for each Account
    **********************************************************************************************************/
    static void testAndAssertContactRepositoryGetContacts(Households households, List<Account> accounts, List<Contact> contacts) {
        Map<Id, Contact[]> contactsByAccountId = new Map<Id, Contact[]>();
        for (Contact c : contacts) {
            if (!contactsByAccountId.containsKey(c.AccountId)) {
                contactsByAccountId.put(c.AccountId, new Contact[0]);
            }
            contactsByAccountId.get(c.AccountId).add(c);
        }

        for (Account account : accounts) {
            Contact[] expectedContacts = contactsByAccountId.get(account.Id);
            Contacts actualMembers = households.membersOf(new HouseholdId(account.Id));
            Contact[] actualContacts = actualMembers.getRecords();

            System.assertEquals(UTIL_SObject.extractIds(expectedContacts), UTIL_SObject.extractIds(actualContacts));
        }
    }

}