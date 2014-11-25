/*
    Written by Ryan Foster, copyright (c) 2011 Groundwire
    This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

    04/01/2012 James Melville
    Changes made throughout to support NPSP HH
    * String.escapeSingleQuotes() added (bug fix for names including ' etc.)
    * class renamed HH_ManageHousehold_EXT
    * Fields / objects updated to NPSP values / names e.g. Account (namespace prefix required?)
    * Naming methods updated to support NPSP's Name / Formal / Informal structure and npo02__SYSTEM_CUSTOM_NAMING__c setting field
    * Address object updated with viableAddress class to store household or contact addresses
    * use Mailing* instead of Other* fields for addresses
    * Set Household address based on address selected in UI
    * Use "useAddress" flag to set or not set address on contacts
    * 15/01/2012 Fixed household addressing, added tests for household addressing code
    * 16/01/2012 Fixed defect when contacts were removed and re-added
*/
/**
* @author Ryan Foster, James Melville
* @date 2012 (2.4)
* @description test class for the VF page extension for the Manage Household interface. This allows users to
* setup their household members, name, and greeting before creating the household. It will also allow the user
* to set the address on the household.  
*/
@isTest
public with sharing class HH_ManageHHAccount_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';

    // TEST METHOD
    public static testMethod void testExistingHH() { 
        if (strTestOnly != '*' && strTestOnly != 'testExistingHH') return;
        
        Account hh = new Account(
            Name = 'test_hh',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE
            );
        insert hh;
        
        Contact con = new Contact(
            FirstName = 'David',
            LastName = 'TestContactASDF',
            email = 'testemail@groundwiretest.org',
            AccountId = hh.id,
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        insert con;
        
        Test.startTest();
        
        Account tempHH = new Account(npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE);
        ApexPages.StandardController sc = new ApexPages.standardController(tempHH);
        
        // Test a bogus hhid
        ApexPages.currentPage().getParameters().put('hhid', 'sdf');
        
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);
        
        //Make sure we are creating a new HH
        system.assertEquals(null, ext.hh.id);
        
        sc = new ApexPages.standardController(tempHH);
        
        // Test a good hhid
        ApexPages.currentPage().getParameters().put('hhid', hh.Id);
        ext = new HH_ManageHousehold_EXT(sc);
        
        // Make sure we correctly got the right HH
        system.assertEquals(hh.Id, ext.hh.Id);
        system.assertEquals(true, ext.isHHAccount);
        system.assertEquals(false, ext.activeContacts.isEmpty());
        
        //test active address variables are set
        system.assertEquals(con.MailingStreet, ext.activeStreet);
        system.assertEquals(con.MailingState, ext.activeState);
        system.assertEquals(con.MailingCity, ext.activeCity);
        system.assertEquals(con.MailingPostalCode, ext.activePostalCode);
        system.assertEquals(con.MailingCountry, ext.activeCountry);
        
        //test name
        system.assertEquals('TestContactASDF Household', ext.getHHName());
        
        //test greeting
        system.assertEquals('David TestContactASDF', ext.getHHFormalName());
        
        //test greeting
        system.assertEquals('David', ext.getHHInformalName());
        
        Test.stopTest();
    }
    
    
    public static testMethod void testHHAddrToContact() {
        if (strTestOnly != '*' && strTestOnly != 'testHHAddrToContact') return;

        //tests writing the household address to the contact if the flag is ticked
        Account hh = new Account(
            Name = 'test_hh',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE,
            BillingStreet = '1234 Testing Drive Suite 1000',
            BillingCity = 'Seattle',
            BillingState = 'Washington',
            BillingPostalCode = '98101',
            BillingCountry = 'United States'
            
            );
        insert hh;
        
        Contact con = new Contact(
            FirstName = 'David',
            LastName = 'TestContactASDF',
            email = 'testemail@groundwiretest.org',
            AccountId = hh.id
            );
        insert con;
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(hh);
              
        Test.setCurrentPageReference(new PageReference('Page.HH_ManageHHAccount'));              
        // Test a good hhid
        ApexPages.currentPage().getParameters().put('hhid', hh.Id);
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);
        
        // Make sure we correctly got the right HH
        system.assertEquals(hh.Id, ext.hh.Id);
        
        system.assertEquals(false, ext.activeContacts.isEmpty());
        
        //set the flag that writes the address from household to contact
        ext.useAddress = true;
        
        //test that it also works on new contacts
        ext.insertContacts.add(new Contact(Firstname = 'John', LastName ='Jones', npo02__Naming_Exclusions__c = 'Household__c.Name;Household__c.Formal_Greeting__c;Household__c.Informal_Greeting__c;'));
        
        ext.saveHH();
        Test.stopTest();
        Contact con1 = [select MailingStreet,MailingState,MailingCity,MailingPostalCode,MailingCountry from contact where id = :con.id][0];
        //test household address written to contact
        system.assertEquals(con1.MailingStreet, ext.hhA.BillingStreet);
        system.assertEquals(con1.MailingState, ext.hhA.BillingState);
        system.assertEquals(con1.MailingCity, ext.hhA.BillingCity);
        system.assertEquals(con1.MailingPostalCode, ext.hhA.BillingPostalCode);
        system.assertEquals(con1.MailingCountry, ext.hhA.BillingCountry);

        Contact con2 = [select MailingStreet,MailingState,MailingCity,MailingPostalCode,MailingCountry from contact where name = 'John Jones'][0];
        //test household address written to contact
        system.assertEquals(con2.MailingStreet, ext.hhA.BillingStreet);
        system.assertEquals(con2.MailingState, ext.hhA.BillingState);
        system.assertEquals(con2.MailingCity, ext.hhA.BillingCity);
        system.assertEquals(con2.MailingPostalCode, ext.hhA.BillingPostalCode);
        system.assertEquals(con2.MailingCountry, ext.hhA.BillingCountry);   
    }
    
    public static testMethod void testRemoveContactActiveAddress() {
        if (strTestOnly != '*' && strTestOnly != 'testRemoveContactActiveAddress') return;

        //tests that removing the contact who is the only owner of the active address changes the active address to another appropriate one
        
        Account hh = new Account(
            Name = 'test_hh',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE
            );
        insert hh;
        
        Contact con1 = new Contact(
            FirstName = 'David',
            LastName = 'TestContactASDF',
            email = 'testemail@groundwiretest.org',
            AccountId = hh.id,
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        insert con1;
        
        Contact con2 = new Contact(
            FirstName = 'David',
            LastName = 'TestContactASDF',
            email = 'testemail@groundwiretest.org',
            AccountId = hh.id,
            MailingStreet = '5678 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        insert con2;
        
        Test.startTest();
        
        Account tempHH = new Account();
        ApexPages.StandardController sc = new ApexPages.standardController(tempHH);
        
        // Test a good hhid
        ApexPages.currentPage().getParameters().put('hhid', hh.Id);
        
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);
                
        // Make sure we correctly got the right HH
        system.assertEquals(hh.Id, ext.hh.Id);
        
        system.assertEquals(false, ext.activeContacts.isEmpty());
        
        //check two distinct addresses
        system.assertEquals(2, ext.viableAddresses.size());

        string oldactiveaddr = ext.activeAddressKey;
        
        //remove the appropriate active address contact
        if(ext.activeAddressKey.startsWith('1234'))
        {
            String jsSt = JSON.serialize(ext);
            String nwSt = HH_ManageHousehold_EXT.remoteRemoveMember(con1.id, jsSt);
            ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        }
        else if(ext.activeAddressKey.startsWith('5678'))
        {
            String jsSt = JSON.serialize(ext);
            String nwSt = HH_ManageHousehold_EXT.remoteRemoveMember(con2.id, jsSt);
            ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        }
        
        // since contacts create HH Default addresses on contact insert, this is no longer valid
        //ensure that the active address has changed
        //system.assertNotEquals(oldactiveaddr, ext.activeAddressKey);
        
        // since contacts create HH defaults addresses on contact insert, there will still be 2 viable addresses
        //check single address left
        system.assertEquals(2, ext.viableAddresses.size());
                
        Test.stopTest();
    }
    
    public static testMethod void testNewHH() {
        if (strTestOnly != '*' && strTestOnly != 'testNewHH') return;
        
        Account hh = new Account(
            Name = 'test_hh',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE
            );
        
        Contact con = new Contact(
            LastName = 'TestContactASDF',
            email = 'testemail@groundwiretest.org',
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        insert con;
        
        Contact con2 = new Contact(
            LastName = 'TestContact2 ',
            email = 'testemail2@groundwiretest.org',
            MailingStreet = 'Drastically Different',
            MailingCity = 's',
            MailingState = 'Delaware',
            MailingPostalCode = '1',
            MailingCountry = 'United States'
            );
        insert con2;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.standardController(hh);
        
        ApexPages.currentPage().getParameters().put('cid', con.id);
        
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);
        
        //make sure we got the contact
        system.assertEquals(con.id, ext.conId);
        
        system.assertEquals(null, ext.hh.id);
       
        // verify that we receive false when we attempt to add a bad contact
        system.assertEquals(false, ext.addContact('01pU0000000h6LK'));
        system.assertEquals(false, ext.addContactWithHousehold('01pU0000000h6LK'));
        
        //save
        ext.saveHH();
        
        // verify that we have a household id
        system.assertNotEquals(null, ext.hh.id);
        
        sc = new ApexPages.standardController(hh);
        ApexPages.currentPage().getParameters().put('id', hh.id);
        ext = new HH_ManageHousehold_EXT(sc);
        
        system.assertEquals(1, ext.activeContacts.size());
        
        // Get contacts in household
        //list<Contact> householdMembers = [SELECT Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Account FROM Contact WHERE Account = :ext.hh.id];
        
        //test household address is set
        system.assertEquals(con.MailingStreet, ext.hhA.BillingStreet);
        system.assertEquals(con.MailingState, ext.hhA.BillingState);
        system.assertEquals(con.MailingCity, ext.hhA.BillingCity);
        system.assertEquals(con.MailingPostalCode, ext.hhA.BillingPostalCode);
        system.assertEquals(con.MailingCountry, ext.hhA.BillingCountry);
        
        Test.stopTest();
    }
    
    public static testMethod void testFindAndAddPart1() {
        if (strTestOnly != '*' && strTestOnly != 'testFindAndAddPart1') return;
        
        Account hh = new Account(            
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE            
        );
        
        Account existingHH = new Account (
            Name = 'existing hh',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE            
            );
        insert existingHH;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'TEST abc Monkey',
            email = 'testemail@groundwiretest.org',
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        
        Contact con2 = new Contact(
            FirstName = 'Mike',
            LastName = 'TEST Monkey abc',
            email = 'testemail@groundwiretest.org',
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        
        Contact con3 = new Contact(
            FirstName = 'Cheryl',
            LastName = 'ABC TEST Monkey',
            email = 'testemail@groundwiretest.org',
            MailingStreet = '54321 Anderson',
            MailingCity = 'Kirkland',
            MailingState = 'Washington',
            MailingPostalCode = '98034',
            MailingCountry = 'United States'
            );
        
        Contact con4 = new Contact(
            FirstName = 'Toivo',
            LastName = 'abc TEST Monkey',
            email = 'testemail@groundwiretest.org'
            );
        
        Contact con5 = new Contact(
            FirstName = 'Kelley',
            LastName = 'adc TEST Monkey',
            email = 'testemail@groundwiretest.org'
            );
        
        Contact conWithHH = new Contact (
            FirstName = 'Andy',
            LastName = 'David WithHousehold',
            email = 'testEmail@groundwiretest2.org',
            AccountId = existingHH.id
            );
        
        Contact conWithHH2 = new Contact (
            FirstName = 'Cheryl',
            LastName = 'WithHousehold',
            email = 'testEmail@groundwiretest3.org',
            AccountId = existingHH.id
            );
        insert new Contact[] {con, con2, con3, con4, con5, conWithHH, conWithHH2};
        
        Test.startTest();        
        ApexPages.StandardController sc = new ApexPages.standardController(new Account(npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE));
        
        ApexPages.currentPage().getParameters().put('cid', con2.id);
        ApexPages.currentPage().getParameters().put('hhid', hh.id);
        
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);
        
        list<Contact> cQ = HH_ManageHousehold_EXT.findContacts('abc', ext.jsonState);
                
        // make sure we only got three
        system.assertEquals(3, cQ.size());
        
        // select one and add it
        ext.addContact(cQ[1].Id);
        
        string hhName = ext.getHHName();
        string hhGreeting = ext.getHHFormalName();
              
        // verify that the contact was added
        system.assertEquals(2, ext.activeContacts.size());
                
        cQ = HH_ManageHousehold_EXT.findContacts('zzzzzz', ext.jsonState);
        
        system.assertEquals(0, cQ.size());
        
        // add more contacts with different addresses
        ext.addContact(con.id);
        ext.addContact(con2.id);
        ext.addContact(con3.id);
        
        system.assertEquals(3, ext.activeContacts.size());
        
        // find viable addresses
        list<HH_ManageHousehold_EXT.viableAddress> adds = ext.getViableAddresses();
        
        //verify that we found two valid addresses even though the matches aren't exactly the same
        system.AssertEquals(2, ext.viableAddresses.size());
                
        String jsSt = JSON.serialize(ext);
        
        // now test adding a contact with its existing household members
        String nwSt = HH_ManageHousehold_EXT.remoteAddMember(conWithHH.id, true, jsSt);
        
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        // We should now have 5 total hh members displayed
        system.assertEquals(5, ext.activeContacts.size());
        
        // We should also check that the correct contact got added
        system.assertEquals(true, ext.activeContacts.containsKey(conWithHH2.id));
        system.assertEquals(conWithHH2.id, ext.activeContacts.get(conWithHH2.id).id);
        
        // now add a contact without a hh
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteAddMember(con5.id, false, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        // Add another for good measure (will use later)
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteAddMember(con4.id, false, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        // Check that the contacts got added
        system.assertEquals(true, ext.activeContacts.containsKey(con5.id));
        system.assertEquals(true, ext.activeContacts.containsKey(con4.id));
        
        // Now let us remove a contact
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteRemoveMember(con5.id, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        // Test that it was removed
        system.assertEquals(false, ext.activeContacts.containsKey(con5.id));
        
        Test.stopTest();
    }

    public static testMethod void testFindAndAddPart2() {
        if (strTestOnly != '*' && strTestOnly != 'testFindAndAddPart2') return;
        
        Account hh = new Account(            
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE            
        );
        
        Account existingHH = new Account (
            Name = 'existing hh',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE            
            );
        insert existingHH;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'TEST abc Monkey',
            email = 'testemail@groundwiretest.org',
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        insert con1;
        
        Contact con2 = new Contact(
            FirstName = 'Mike',
            LastName = 'TEST Monkey abc',
            email = 'testemail@groundwiretest.org',
            MailingStreet = '1234 Testing Drive Suite 1000',
            MailingCity = 'Seattle ',
            MailingState = 'Washington',
            MailingPostalCode = '98101',
            MailingCountry = 'United States'
            );
        insert con2;
                        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.standardController(new Account());
        
        ApexPages.currentPage().getParameters().put('cid', con1.id);
        ApexPages.currentPage().getParameters().put('hhid', hh.id);
        
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);

        // Add another existing contact
        string jsSt = JSON.serialize(ext);
        string nwSt = HH_ManageHousehold_EXT.remoteAddMember(con2.id, false, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);

        // Check that the contacts got added
        system.assertEquals(true, ext.activeContacts.containsKey(con1.id));
        system.assertEquals(true, ext.activeContacts.containsKey(con2.id));
        
        // Test changing name
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteSetNaming(false, 'The Test123Awesomes', false, 'TestZZ1234', false, 'blah', jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        // Verify that name and greeting were set
        system.assertEquals('The Test123Awesomes', ext.hhName);
        system.assertEquals('TestZZ1234', ext.hhFormalGreeting);
        
        // Save
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteSave(jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        // query for a contact and make sure it got the correct fields set
        Contact con2q = [SELECT Id, AccountId, MailingStreet FROM Contact WHERE Id = :con2.id];
        
        system.assertEquals(ext.hh.id, con2q.AccountId);
        
        // Set the address to the new contact
        ext.setActiveAddress(con2.id);
        
        // Now remove another member, save, and make sure the lookup field is set to null
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteRemoveMember(con1.id, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        // Save
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteSave(jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        Contact con1q = [SELECT Id, AccountId, MailingStreet FROM Contact WHERE Id = :con1.id];
        
        system.assertNotEquals(ext.hh.id, con1q.AccountId);
        
        // Cover the "standard" save
        ext.save();
        
        // Now, test delete
        ext.deleteHH();
        
        Test.stopTest();        
    }
    
        
    public static testMethod void testRemoveReAdd() {
        if (strTestOnly != '*' && strTestOnly != 'testRemoveReAdd') return;
        
        Account hh = new Account (
            Name = 'Household',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE
            );
        insert hh;
        
        Contact con1 = new Contact(
            FirstName = 'Joe',
            LastName = 'Test',
            AccountId = hh.id
            );
        insert con1;
        
        Contact con2 = new Contact(
            FirstName = 'Jim',
            LastName = 'Test',
            AccountId = hh.id
            );
        insert con2;
              
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.standardController(hh);
                
        HH_ManageHousehold_EXT ext = new HH_ManageHousehold_EXT(sc);
        
        String jsSt;
        String nwSt;        
        
        system.assertEquals(2, ext.activeContacts.size());
        system.assertEquals(0,ext.removeContacts.size());
        
        // Now let us remove a contact
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteRemoveMember(con2.id, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        system.assertEquals(1, ext.activeContacts.size());
        system.assertEquals(1,ext.removeContacts.size());
        
        // re add it
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteAddMember(con2.id, false, jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);
        
        system.assertEquals(2, ext.activeContacts.size());
        system.assertEquals(0,ext.removeContacts.size());
        
        // Save
        jsSt = JSON.serialize(ext);
        nwSt = HH_ManageHousehold_EXT.remoteSave(jsSt);
        ext = HH_ManageHousehold_EXT.unpackState(nwSt);

        ext.save();


        system.assertEquals(2,[SELECT Id, AccountId FROM Contact WHERE AccountId = :hh.id].size());       
        Test.stopTest();        
    }

}