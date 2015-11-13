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
    * Neither the name of the Salesforce.org nor the names of
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
* @date 2011 (1.x)
* @description Tests for OpportunityContactRoles
*/
@isTest
private class OPP_OpportunityContactRoles_TEST {
 
    /// <name> createOrUpdateCR </name>
    /// <summary> test creation or upate of contact role  </summary>
    static testMethod void createOrUpdateCR() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, 
                npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
        
        Account acc = new Account(Name='test77');
        insert acc;
        
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            AccountId = acc.Id,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;

        //Simulate user interface creation of opp from button on contact screen, 
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = acc.Id,
            CloseDate = date.today(), StageName = 'Closed Won'
        );
        insert opp1;
        
        //Make sure that we haven't created a contact role yet.
        OpportunityContactRole[] result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        system.assertEquals(0, result.size());
        
        //Insert the contact role with a blank Role field.
        OpportunityContactRole cr = new OpportunityContactRole (OpportunityId = opp1.Id, ContactId = con.Id, IsPrimary = true);
        insert cr;
        
        result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        system.assertEquals(con.Id, result[0].ContactId);
        //system.assertEquals(null, result[0].Role); there might be a default set
        
        //Now simulate import of an opp record with a contact ID.
        Opportunity opp2 = new Opportunity(
            Name = 'Apex Test Opp2',
            AccountId = acc.Id,
            Primary_Contact__c = con.Id,
            CloseDate = date.today(), StageName = 'Closed Won'
        );
        insert opp2;

        result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp2.Id];
        system.assertEquals(con.Id, result[0].ContactId);
        system.assertEquals(donorRoleforTest, result[0].Role);
    }
    
    static testMethod void oppCRTriggerTurnedOff() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR, 
                npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));

        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Trigger_Handler__c triggerHandler = [select Active__c from Trigger_Handler__c where Class__c = 'OPP_OpportunityContactRoles_TDTM'];
        triggerHandler.Active__c = false;
        update triggerHandler;
        TDTM_ObjectDataGateway.ClearCachedTriggerHandlersForTest();
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be a contact role
        system.assertEquals(0, result.size());
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should have the contact's one to one account
       system.assertEquals(null, oppResult[0].AccountId);
    }
    
    static testMethod void oppRolesForOneToOneContact() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
                
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Primary_Contact__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be a contact role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should have the contact's one to one account
       system.assertEquals(createdContacts[0].AccountId, oppResult[0].AccountId);
    }
    
    static testMethod void oppRolesForIndividualContact() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR,npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
              
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Primary_Contact__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary,Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be one role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should be null account
       system.assertEquals(null, oppResult[0].AccountId);

    }
    
    static testMethod void oppRolesForOneToOneAccount() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
                
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = createdContacts[0].AccountId,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be a contact role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
    }
    
    static testMethod void oppRolesForIndividualAccount() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR,npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
              
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary,Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be one role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should be null account
       system.assertEquals(null, oppResult[0].AccountId);

    }
    
    static testMethod void oppRolesForBadId() {
        String donorRoleforTest = 'Donor';
        npe01__Contacts_and_Orgs_Settings__c testSettings = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,npe01__Enable_Opportunity_Contact_Role_Trigger__c = true, npe01__Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
        
        Account acc = new Account(Name='test77');
        insert acc;
        
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        //Simulate user interface creation of opp from button on contact screen, 
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            npe01__Contact_Id_for_Role__c = 'junk',
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        try {
            insert opp1;            
            
            OpportunityContactRole[] result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
            //shouldn't be a contact role
            system.assertEquals(0, result.size());
            
            Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
            //shouldn't be an account
            system.assertEquals(null, oppResult[0].AccountId);
        } catch (exception e) {
            system.assert(e.getMessage().contains(Label.npe01.Opportunity_Contact_Role_Error_Bad_Contact_Id));
        }
        Test.stopTest();
    }
}
