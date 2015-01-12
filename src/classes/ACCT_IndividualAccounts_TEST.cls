/*
    Copyright (c) 2011, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2011 (1.x)
* @group Accounts
* @description Tests for ACCT_IndividualAccounts_TDTM
*/
@isTest
private class ACCT_IndividualAccounts_TEST {    
/* TESTING CONTACT AND ACCOUNT PLUMBING ------------------------------------------------*/

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    /// <name> ACCT_IndividualAccounts_TEST </name>
    /// <summary> test default constructor </summary>
    static testMethod void ACCT_IndividualAccounts_TEST() {
    	if (strTestOnly != '*' && strTestOnly != 'ACCT_IndividualAccounts_TEST') return;
        ACCT_IndividualAccounts_TDTM testIndividualAccounts = new ACCT_IndividualAccounts_TDTM();
    }

    /// <name> insertPrivate </name>
    /// <summary> Test Method for inserting a Contact that should get no account </summary>
    static testMethod void insertPrivate() {
    	if (strTestOnly != '*' && strTestOnly != 'insertPrivate') return;
        insertPrivateProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        insertPrivateProcessor(CAO_Constants.BUCKET_PROCESSOR);
        insertPrivateProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }   
    static void insertPrivateProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__Private__c=true,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
        
        //contact should have no AccountId
        system.assertEquals(null,insertedContacts[0].AccountId);
    }
    
    static testMethod void changeFromOneToOneToHouseholdAccount() {
    	if (strTestOnly != '*' && strTestOnly != 'changeFromOneToOneToHouseholdAccount') return;
    	
    	UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR));
            
    	//Set Individual (Bucket) settings
    	npe01__Contacts_And_Orgs_Settings__c contactsSettings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
    	contactsSettings.npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR;
        update contactsSettings;
        
    	//Create a contact
    	Contact contact1 = new Contact(FirstName = 'Test', LastName = 'Testerson');
        insert contact1;
        
    	//Verify it's using Individual
    	contact1 = [select Account.Name from Contact Where ID = :contact1.ID];
    	System.assertEquals(CAO_Constants.BUCKET_PROCESSOR, contact1.Account.Name);
    	
    	//Verify we are still using Individual (Bucket) settings
    	contactsSettings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
    	System.assertEquals(CAO_Constants.BUCKET_PROCESSOR, contactsSettings.npe01__Account_Processor__c);
    	
    	//Change to Household Account
    	contactsSettings.npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR;
        update contactsSettings;
            
    	//Create a Contact
    	Contact contact2 = new Contact(FirstName = 'Test2', LastName = 'Testerson2');
        insert contact2;
        
    	//Verify it's using Household Account - a new Account should have been created for it
    	Integer numOfAccs = [select count() from Account];
    	System.assertEquals(2, numOfAccs);
    }
    
    static testMethod void insertOneToOneChangeToPrivate() {
    	if (strTestOnly != '*' && strTestOnly != 'insertOneToOneChangeToPrivate') return;
    	
        insertOneToOneChangeToPrivateProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);	
        insertOneToOneChangeToPrivateProcessor(CAO_Constants.BUCKET_PROCESSOR); 
        insertOneToOneChangeToPrivateProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR); 
    }
    
    static void insertOneToOneChangeToPrivateProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
        ID accountId = insertedContacts[0].AccountId;
        
        insertedContacts[0].npe01__Private__c = true;
        update insertedContacts;
        insertedContacts = [Select FirstName, LastName, AccountId,npe01__Private__c  from Contact where id=:con.id];
        //contact should have no AccountId
        system.assertEquals(null,insertedContacts[0].AccountId);
        system.assert(insertedContacts[0].npe01__Private__c);
        
        // account should NOT get deleted
        Account[] acts = [Select Id from Account where Id = :accountId];
        system.assertEquals(1, acts.size());
    }
    
    static testMethod void insertOneToOneTriggerOff() {
    	if (strTestOnly != '*' && strTestOnly != 'insertOneToOneTriggerOff') return;
        insertOneToOneTriggerOffProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        insertOneToOneTriggerOffProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);    
    }
    
    static void insertOneToOneTriggerOffProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor,npe01__Disable_Account_Model_Trigger__c=true));
        
        // turn off all TDTM triggers for this component
        List<Trigger_Handler__c> handlers = new List<Trigger_Handler__c>();
        handlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert'));
        handlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeUpdate'));
        handlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert'));
        handlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterUpdate'));                
        handlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterDelete'));
        insert handlers;
         
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];

        //contact should have no AccountId
        system.assertEquals(null,insertedContacts[0].AccountId);
    }

    /// <name> insertUpdateOneToOne </name>
    /// <summary> Test Method for inserting and updating a Contact in the One-to-One model</summary>
    static testMethod void insertUpdateOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'insertUpdateOneToOne') return;
    	insertUpdateOneToOneProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    
    /// <name> insertUpdateOneToOne </name>
    /// <summary> Test Method for inserting and updating a Contact in the One-to-One model</summary>
    static testMethod void insertUpdateOneToOneHouseholds() {
        if (strTestOnly != '*' && strTestOnly != 'insertUpdateOneToOneHouseholds') return;
        insertUpdateOneToOneProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR); 
    }
    
    static void insertUpdateOneToOneProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        String newContactMailingStreet = '123 Elm St';

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            MailingStreet = newContactMailingStreet,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,Account.BillingStreet,npe01__Organization_Type__c,Account.npe01__SYSTEMIsIndividual__c  from Contact where id=:con.id];
        UTIL_Debug.debug('****' +insertedContacts);
        UTIL_Debug.debug('****' +insertedcontacts[0].id);
        UTIL_Debug.debug('****' +insertedContacts);
        //one contact should have been created
        system.assertEquals(1,insertedContacts.size());
        //the account should have the right type
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)        
            system.assertEquals(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE,insertedcontacts[0].npe01__Organization_Type__c);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)    
            system.assertEquals(CAO_Constants.HH_ACCOUNT_TYPE,insertedcontacts[0].npe01__Organization_Type__c);
        //the account should be flagged as an individual
        system.assertEquals(true,insertedcontacts[0].Account.npe01__SYSTEMIsIndividual__c );
        //the account should have been named correctly
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)
            system.assertEquals(CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS + ' ' + CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,insertedcontacts[0].Account.Name);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + ' Household',insertedcontacts[0].Account.Name);        
        //relationship should be bi-directional
        system.assertEquals(insertedcontacts[0].id,insertedcontacts[0].Account.npe01__One2OneContact__c);
        //addresses should be sync'd
        system.assertEquals(newContactMailingStreet,insertedcontacts[0].Account.BillingStreet);
        system.assertEquals(insertedcontacts[0].MailingStreet,insertedcontacts[0].Account.BillingStreet);
        
        String updatedContactLastName = 'Contact_forTestsChange';
        String updatedOtherCity = 'Seattle';
        con.LastName=updatedContactLastName;
        con.OtherCity = updatedOtherCity;
        con.AccountId = insertedContacts[0].AccountId;
        update con;
        
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,OtherCity,Account.BillingStreet,Account.ShippingCity from Contact where id=:con.id];
        
        //the account should have been named correctly
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)        
            system.assertEquals(updatedContacts[0].firstName + ' ' + updatedContacts[0].LastName,updatedContacts[0].Account.Name);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(updatedContacts[0].LastName + ' Household',updatedContacts[0].Account.Name);        
        //relationship should be bi-directional
        system.assertEquals(updatedContacts[0].id,updatedContacts[0].Account.npe01__One2OneContact__c);
        //addresses should be sync'd
        system.assertEquals(newContactMailingStreet,updatedContacts[0].MailingStreet);
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR) {        
	        system.assertEquals(updatedOtherCity,updatedContacts[0].Account.ShippingCity);
	        system.assertEquals(updatedContacts[0].MailingStreet,updatedContacts[0].Account.BillingStreet);
	        system.assertEquals(updatedContacts[0].OtherCity,updatedContacts[0].Account.ShippingCity);
        }        
    }
    /*
    static testMethod void testDefault()
    {
       
        boolean aDefaultIsSelected = false;
        Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.Salutation;
            List<Schema.PicklistEntry> P = F.getPicklistValues();
            for(Schema.PicklistEntry pe : P){
                UTIL_Debug.debug('****' +pe.getValue() + ' : ' + pe.isDefaultValue());
                if (pe.isDefaultValue()){
                        aDefaultIsSelected = true;
                }
            }
         system.assert(aDefaultIsSelected); 
    }
    */
    
    /// <name> detachOneToOne </name>
    /// <summary> Test Method for separating a Contact from it's One-to-One account</summary>
    static testMethod void detachOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'detachOneToOne') return;
        detachOneToOneProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        detachOneToOneProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    static void detachOneToOneProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select AccountId from Contact where id=:con.id];      
        
        Id originalAccountId = insertedContacts[0].AccountId;
        
        String updatedContactLastName = 'Contact_forTestsChange';
        
        con.AccountId = null;
        con.LastName = updatedContactLastName;
        update con;
        
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId,Account.Name,Account.npe01__One2OneContact__c from Contact where id=:con.id];
        
        //Original Account should still be there
        Account[] originalAccount = [Select id from Account where Id=:originalAccountId];
        
        system.assertEquals(1,originalAccount.size());
        
        //AccountId of updated contact should match the orignial Account
        system.assertEquals(originalAccountId,updatedContacts[0].AccountId);
    }
        
    /// <name> editContactDuringDetachOneToOne </name>
    /// <summary> Test Method for editing a contact while it is being detached from it's One-to-One Account. This was a bug (#37)</summary>
    static testMethod void editContactDuringDetachOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'editContactDuringDetachOneToOne') return;
        editContactDuringDetachOneToOneProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        editContactDuringDetachOneToOneProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);	
    }
    
    static void editContactDuringDetachOneToOneProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
                
        String newContactMailingStreet = '123 Elm St';

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            MailingStreet = newContactMailingStreet,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select AccountId from Contact where id=:con.id];      
        
        Id originalAccountId = insertedContacts[0].AccountId;
        
        String updatedContactLastName = 'Contact_forTestsChange';
        String updateContactMailingStreet = '234 Oak St';
        
        con.AccountId = null;
        con.LastName = updatedContactLastName;
        con.MailingStreet = updateContactMailingStreet;
        update con;
        
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId,Account.Name,Account.npe01__One2OneContact__c,MailingStreet,npe01__Organization_Type__c,Account.BillingStreet from Contact where id=:con.id];
        
        //AccountId of updated contact should match the orignial Account
        system.assertEquals(originalAccountId,updatedContacts[0].AccountId);
        
        //org type should be set correctly
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)            
            system.assertEquals(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE,updatedContacts[0].npe01__Organization_Type__c);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)            
            system.assertEquals(CAO_Constants.HH_ACCOUNT_TYPE,updatedContacts[0].npe01__Organization_Type__c);
        
        //the account should have been named correctly
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)            
            system.assertEquals(updatedContacts[0].FirstName + ' ' + updatedContacts[0].LastName,updatedContacts[0].Account.Name);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)            
            system.assertEquals(updatedContacts[0].LastName + ' Household',updatedContacts[0].Account.Name);
        
        //addresses should be sync'd
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR) {           
	        system.assertEquals(updateContactMailingStreet,updatedContacts[0].MailingStreet);
	        system.assertEquals(updatedContacts[0].MailingStreet,updatedContacts[0].Account.BillingStreet);
        } 
    }

    /// <name> attachToIndividualAccount </name>
    /// <summary> Test Method for a new Contact in the Bucket Individual model </summary>
    static testMethod void attachToIndividualAccount() {
    	if (strTestOnly != '*' && strTestOnly != 'attachToIndividualAccount') return;
        attachToIndividualAccountProcessor(CAO_Constants.BUCKET_PROCESSOR);
        attachToIndividualAccountProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR); 
    }
    
    static void attachToIndividualAccountProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
                
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        //the contact should have the right type
        if (strProcessor == CAO_Constants.BUCKET_PROCESSOR)
            system.assertEquals(CAO_Constants.BUCKET_ORGANIZATION_TYPE,insertedcontacts[0].npe01__Organization_Type__c);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(CAO_Constants.HH_ACCOUNT_TYPE,insertedcontacts[0].npe01__Organization_Type__c);
        //the account should have been named correctly
        if (strProcessor == CAO_Constants.BUCKET_PROCESSOR)
            system.assertEquals(CAO_Constants.BUCKET_ACCOUNT_NAME,insertedcontacts[0].Account.Name);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(con.LastName + ' Household',insertedcontacts[0].Account.Name);        
    }
    
    /// <name> detachIndividualAccount </name>
    /// <summary> Test Method for detaching a Contact from the bucket individual account </summary>
    static testMethod void detachIndividualAccount() {
    	if (strTestOnly != '*' && strTestOnly != 'detachIndividualAccount') return;
    	detachIndividualAccountProcessor(CAO_Constants.BUCKET_PROCESSOR);
        detachIndividualAccountProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    static void detachIndividualAccountProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
               
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        Id AccountId = insertedContacts[0].AccountId;
             
        con.AccountId = null;
        update con;
        
        Contact[] updatedContacts = [Select Lastname,Account.Name,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        //the contact should have the right type
        if (strProcessor == CAO_Constants.BUCKET_PROCESSOR)
            system.assertEquals(CAO_Constants.BUCKET_ORGANIZATION_TYPE,updatedContacts[0].npe01__Organization_Type__c);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(CAO_Constants.HH_ACCOUNT_TYPE,updatedContacts[0].npe01__Organization_Type__c);
        //the account should have been named correctly
        if (strProcessor == CAO_Constants.BUCKET_PROCESSOR)
            system.assertEquals(CAO_Constants.BUCKET_ACCOUNT_NAME,updatedContacts[0].Account.Name);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(updatedContacts[0].Lastname + ' Household',updatedContacts[0].Account.Name);
        //the account should have the correct AccountId
        system.assertEquals(AccountId,updatedContacts[0].AccountId);        
    }

    /// <name> detachFromNormalAccountToBucket </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in the bucket account. </summary>
    static testMethod void detachFromNormalAccountToBucket() {
    	if (strTestOnly != '*' && strTestOnly != 'detachFromNormalAccountToBucket') return;
        detachFromNormalAccountToBucketProcessor(CAO_Constants.BUCKET_PROCESSOR);
    }
    
    /// <name> detachFromNormalAccountToBucket </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in the bucket account. </summary>
    static testMethod void detachFromNormalAccountToBucketAccountProcessor() {
        if (strTestOnly != '*' && strTestOnly != 'detachFromNormalAccountToBucketAccountProcessor') return;
        detachFromNormalAccountToBucketProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    static void detachFromNormalAccountToBucketProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));
               
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Account acct = new Account(Name='Test Account 876');
        insert acct;
        
        Account[] insertedAccount = [select npe01__SystemIsIndividual__c from Account where id = :acct.id];
        
        //the account should not be an individual one
        system.assert(!insertedAccount[0].npe01__SystemIsIndividual__c);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            AccountId = acct.id,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.npe01__SystemIsIndividual__c,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        //the contact should be connected to the account
        system.assertEquals(acct.id,insertedContacts[0].AccountId);
        //the account should not be an individual account
        system.assert(!insertedContacts[0].Account.npe01__SystemIsIndividual__c);
             
        con.AccountId = null;
        update con;
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.npe01__SystemIsIndividual__c,npe01__Organization_Type__c from Contact where id=:con.id];
        
        //the account should be an individual account
        system.assert(updatedContacts[0].Account.npe01__SystemIsIndividual__c);
        //the account should not be the one we started with
        system.assertNotEquals(acct.id,updatedContacts[0].AccountId);         
    }
    
    static testMethod void contactAddedToExistingOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'contactAddedToExistingOneToOne') return;
        contactAddedToExistingOneToOneProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        contactAddedToExistingOneToOneProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);   
    }
    
    static void contactAddedToExistingOneToOneProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.npe01__SystemIsIndividual__c,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        Id accountId = insertedContacts[0].AccountId;
        
        Contact con2 = new Contact(FirstName='John', LastName='Smith',AccountId=accountId);
        
        insert con2;
        
        Contact[] insertedContact = [Select Account.Name,AccountId,Account.npe01__SystemIsIndividual__c,npe01__Organization_Type__c from Contact where id=:con2.id];
        
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)
            system.assertNotEquals(accountId,insertedContact[0].AccountId);  
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(accountId,insertedContact[0].AccountId);        
    }
    
    static testMethod void contactUpdatedToExistingOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'contactUpdatedToExistingOneToOne') return;
        contactUpdatedToExistingOneToOneProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    
    static testMethod void contactUpdatedToExistingOneToOneHH() {
        if (strTestOnly != '*' && strTestOnly != 'contactUpdatedToExistingOneToOneHH') return;
        contactUpdatedToExistingOneToOneProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);   
    }
    
    static void contactUpdatedToExistingOneToOneProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.npe01__SystemIsIndividual__c,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        Id accountId = insertedContacts[0].AccountId;
        
        Contact con2 = new Contact(FirstName='John', LastName='Smith',AccountId=null);       
        insert con2;
        
        // now update the contact to the existing account from contact 1
        con2.AccountId = accountId;
        update con2;
        
        Contact[] insertedContact = [Select Account.Name,AccountId,Account.npe01__SystemIsIndividual__c,npe01__Organization_Type__c from Contact where id=:con2.id];
        
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)
            system.assertNotEquals(accountId,insertedContact[0].AccountId);  
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            system.assertEquals(accountId,insertedContact[0].AccountId);        
    }

    static testMethod void contactInNormalOrgNameChange() {
    	if (strTestOnly != '*' && strTestOnly != 'contactInNormalOrgNameChange') return;
        contactInNormalOrgNameChangeProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        contactInNormalOrgNameChangeProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    static void contactInNormalOrgNameChangeProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
                
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        String acctName = 'Test Account 876';
        Account acct = new Account(Name=acctName);
        insert acct;

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            AccountId = acct.id,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.npe01__SystemIsIndividual__c,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        //the contact should be connected to the account
        system.assertEquals(acct.id,insertedContacts[0].AccountId);
        
        system.assertEquals(acctName,insertedContacts[0].Account.Name);
        
        
        Contact con2 = new Contact(id=con.id, LastName='Smith');
        
        update con2;
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.npe01__SystemIsIndividual__c,npe01__Organization_Type__c from Contact where id=:con.id];
        
        system.assertEquals(acctName,updatedContacts[0].Account.Name);         
    }
    
    /// <name> detachFromNormalAccountToOneToOne </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in a one-to-one account. </summary>
    static testMethod void detachFromNormalAccountToOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'detachFromNormalAccountToOneToOne') return;
    	detachFromNormalAccountToOneToOneProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    
    /// <name> detachFromNormalAccountToOneToOne </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in a one-to-one account. </summary>
    static testMethod void detachFromNormalAccountToOneToOneHousehold() {
        if (strTestOnly != '*' && strTestOnly != 'detachFromNormalAccountToOneToOneHousehold') return;
        detachFromNormalAccountToOneToOneProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    static void detachFromNormalAccountToOneToOneProcessor(string strProcessor) {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Account acct = new Account(Name='Test Account 876');
        insert acct;
        
        Account[] insertedAccount = [select npe01__SystemIsIndividual__c from Account where id = :acct.id];
        
        //the account should not be an individual one
        system.assert(!insertedAccount[0].npe01__SystemIsIndividual__c);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            AccountId = acct.id,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.npe01__SystemIsIndividual__c,AccountId,npe01__Organization_Type__c from Contact where id=:con.id];
        
        //the contact should be connected to the account
        system.assertEquals(acct.id,insertedContacts[0].AccountId);
        //the account should not be an individual account
        system.assert(!insertedContacts[0].Account.npe01__SystemIsIndividual__c);
             
        con.AccountId = null;
        update con;
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.npe01__SystemIsIndividual__c,npe01__Organization_Type__c from Contact where id=:con.id];
        
        //the account should be an individual account
        system.assert(updatedContacts[0].Account.npe01__SystemIsIndividual__c);
        //the account should not be the one we started with
        system.assertNotEquals(acct.id,updatedContacts[0].AccountId);        
    }
    
     public static testMethod void deleteContactNoOpp() {
     	if (strTestOnly != '*' && strTestOnly != 'deleteContactNoOpp') return;
        deleteContactNoOppProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        deleteContactNoOppProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
     }
     
     public static void deleteContactNoOppProcessor(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        String newContactMailingStreet = '123 Elm St';

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            MailingStreet = newContactMailingStreet,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        Id contactId;
        contactId = con.id;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:contactId];
        Id createdAccountId = insertedContacts[0].AccountId;
        
        delete con;
        
        insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:contactId];
        system.assertEquals(0,insertedContacts.size());
        
        Account[] missingAccount = [select id from Account where id=:createdAccountId];
        system.assertEquals(0,missingAccount.size());
    }
    
    public static testMethod void deleteContactWithOpp() {
    	if (strTestOnly != '*' && strTestOnly != 'deleteContactWithOpp') return;
        deleteContactWithOppProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        deleteContactWithOppProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    
    public static void deleteContactWithOppProcessor(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));        
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
              
        String newContactMailingStreet = '123 Elm St';

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            MailingStreet = newContactMailingStreet,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        Id contactId;
        contactId = con.id;
        Id accountId;
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:contactId];
        
        Id createdAccountId = insertedContacts[0].AccountId;
       
       Opportunity opp = new Opportunity(
            Amount=500,
            AccountId=createdAccountId,
            Name='test',
            StageName='Closed/Won',
            CloseDate=System.today()
        );
        insert opp;
        
        delete con;
        
        Account[] missingAccount = [select id from Account where id=:createdAccountId];
        system.assertEquals(1,missingAccount.size());
    }
    
    public static testMethod void deleteContactNormalAccountOneToOne() {
    	if (strTestOnly != '*' && strTestOnly != 'deleteContactNormalAccountOneToOne') return;
        deleteContactNormalAccountProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    
    public static testMethod void deleteContactNormalAccountHouseholdAcc() {
        if (strTestOnly != '*' && strTestOnly != 'deleteContactNormalAccountHouseholdAcc') return;
        deleteContactNormalAccountProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    public static void deleteContactNormalAccountProcessor(string strProcessor) {
              
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));        

        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Account orgAccount = new Account(
            Name='Fake account'
        );
        insert orgAccount;
               
        String newContactMailingStreet = '123 Elm St';

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            MailingStreet = newContactMailingStreet,
            AccountId=orgAccount.id,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
        
        Id createdAccountId = insertedContacts[0].AccountId;
            
        delete con;
        
        Account[] missingAccount = [select id from Account where id=:createdAccountId];
        system.assertEquals(1,missingAccount.size());
    }
    
/* TESTING PHONE NUMBER WORKFLOW -------------------------------------------------------
 
    /// <name> createContactWithPhoneNoPref </name>
    /// <summary> Test Method for creating a contact with a phone number and no preferences set. </summary>
    static testMethod void createContactWithPhoneNoPref()
    {
        //with no other prefs, phone should land in npe01__workphone__c and set npe01__PreferredPhone__c to 'work'.
        String newPhone = '206-777-7777';
        String preferredPhone = null;
        String workPhoneString = 'Work';
        Contact con = new Contact(FirstName='test', LastName='contact678',phone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,npe01__workPhone__c,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
        system.assertEquals(newPhone,insertedContacts[0].npe01__WorkPhone__c);
        system.assertEquals(workPhoneString,insertedContacts[0].npe01__PreferredPhone__c);
        
    }
    
    /// <name> createContactWithPhoneNoPrefAlsoHomePhone </name>
    /// <summary> Test Method for creating a contact with a phone number and a home number. </summary>
    static testMethod void createContactWithPhoneNoPrefAlsoHomePhone()
    {
        //with pref set to Home, HomePhone should land in Phone and set npe01__PreferredPhone__c to 'home'.
        //currently HomePhone data is lost.
        String newPhone = '206-777-7777';
        String newHomePhone = '888-898-9999';
        String preferredPhone = 'Home';
        Contact con = new Contact(FirstName='test', LastName='contact678',phone=newPhone,HomePhone=newHomePhone,npe01__PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,npe01__workPhone__c,HomePhone,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
        system.assertEquals(newPhone,insertedContacts[0].HomePhone);
        system.assertEquals(null,insertedContacts[0].npe01__WorkPhone__c);
        system.assertEquals(preferredPhone,insertedContacts[0].npe01__PreferredPhone__c);
        
    }
    
    /// <name> createContactWithPhonePrefSet </name>
    /// <summary> Test Method for creating a contact with a phone number in Phone and the preferred phone set. </summary>
    static testMethod void createContactWithPhonePrefSet()
    {
        //with pref set to Home, HomePhone should land in Phone and set npe01__PreferredPhone__c to 'home'.
        //these are currently commented out because it's not supported. See #47.
        String newPhone = '206-777-7777';
        String preferredPhone = 'Home';
        Contact con = new Contact(FirstName='test', LastName='contact678',phone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,HomePhone,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
        system.assertEquals(newPhone,insertedContacts[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts[0].npe01__PreferredPhone__c);
        
        //test work phone
        preferredPhone = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',phone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con1;
        
        Contact[] insertedContacts1 = [Select phone,npe01__WorkPhone__c,npe01__PreferredPhone__c from Contact where id=:con1.id];
        
        system.assertEquals(newPhone,insertedContacts1[0].Phone);
        system.assertEquals(newPhone,insertedContacts1[0].npe01__WorkPhone__c);
        system.assertEquals(preferredPhone,insertedContacts1[0].npe01__PreferredPhone__c);
        
        //test mobile phone
        preferredPhone = 'Mobile';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',phone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con2;
        
        Contact[] insertedContacts2 = [Select phone,MobilePhone,npe01__PreferredPhone__c from Contact where id=:con2.id];
        
        system.assertEquals(newPhone,insertedContacts2[0].Phone);
        system.assertEquals(newPhone,insertedContacts2[0].MobilePhone);
        system.assertEquals(preferredPhone,insertedContacts2[0].npe01__PreferredPhone__c);
        
        //test other phone
        preferredPhone = 'Other';
        
        Contact con3 = new Contact(FirstName='test', LastName='contact678',phone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con3;
        
        Contact[] insertedContacts3 = [Select phone,OtherPhone,npe01__PreferredPhone__c from Contact where id=:con3.id];
        
        system.assertEquals(newPhone,insertedContacts3[0].Phone);
        system.assertEquals(newPhone,insertedContacts3[0].OtherPhone);
        system.assertEquals(preferredPhone,insertedContacts3[0].npe01__PreferredPhone__c);
        
    }
    
    /// <name> createContactWithNumberAndPrefSet </name>
    /// <summary> Test Method for creating a contact with a phone number in the correct field
    /// and the preferred phone set. </summary>
    static testMethod void createContactWithNumberAndPrefSet()
    {
        //with pref set to Home, HomePhone should land in Phone and set npe01__PreferredPhone__c to 'home'.
        //these are currently commented out because it's not supported. See #47.
        String newPhone = '206-777-7777';
        String preferredPhone = 'Home';
        Contact con = new Contact(FirstName='test', LastName='contact678',HomePhone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,HomePhone,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
        system.assertEquals(newPhone,insertedContacts[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts[0].npe01__PreferredPhone__c);
        
        //test work phone
        preferredPhone = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',npe01__WorkPhone__c=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con1;
        
        Contact[] insertedContacts1 = [Select phone,npe01__WorkPhone__c,npe01__PreferredPhone__c from Contact where id=:con1.id];
        
        system.assertEquals(newPhone,insertedContacts1[0].Phone);
        system.assertEquals(newPhone,insertedContacts1[0].npe01__WorkPhone__c);
        system.assertEquals(preferredPhone,insertedContacts1[0].npe01__PreferredPhone__c);
        
        //test mobile phone
        preferredPhone = 'Mobile';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',MobilePhone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con2;
        
        Contact[] insertedContacts2 = [Select phone,MobilePhone,npe01__PreferredPhone__c from Contact where id=:con2.id];
        
        system.assertEquals(newPhone,insertedContacts2[0].Phone);
        system.assertEquals(newPhone,insertedContacts2[0].MobilePhone);
        system.assertEquals(preferredPhone,insertedContacts2[0].npe01__PreferredPhone__c);
        
        //test other phone
        preferredPhone = 'Other';
        
        Contact con3 = new Contact(FirstName='test', LastName='contact678',OtherPhone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con3;
        
        Contact[] insertedContacts3 = [Select phone,OtherPhone,npe01__PreferredPhone__c from Contact where id=:con3.id];
        
        system.assertEquals(newPhone,insertedContacts3[0].Phone);
        system.assertEquals(newPhone,insertedContacts3[0].OtherPhone);
        system.assertEquals(preferredPhone,insertedContacts3[0].npe01__PreferredPhone__c);
        
    }
    
    /// <name> updateContactWithNumberAndPref </name>
    /// <summary> Test Method for updating a contact with a phone number in the correct field
    /// and the preferred phone set. </summary>
    static testMethod void updateContactWithNumberAndPref()
    {
        //with pref set to Home, HomePhone should land in Phone and set npe01__PreferredPhone__c to 'home'.
        
        String newPhone = '206-777-7777';
        String preferredPhone = 'Home';
        Contact con = new Contact(FirstName='test', LastName='contact678',HomePhone=newPhone,npe01__PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,HomePhone,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        //test work phone
        preferredPhone = 'Work';
        String workPhone = '206-888-8888';
        
        con.npe01__WorkPhone__c = workPhone;
        con.npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS;
        update con;
        
        Contact[] insertedContacts1 = [Select phone,HomePhone,npe01__WorkPhone__c,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(workPhone,insertedContacts1[0].Phone);
        system.assertEquals(workPhone,insertedContacts1[0].npe01__WorkPhone__c);
        system.assertEquals(newPhone,insertedContacts1[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts1[0].npe01__PreferredPhone__c);
        
        //test mobile phone
        preferredPhone = 'Mobile';
        String mobilePhone = '206-999-9999';
        
        con.MobilePhone = mobilePhone;
        con.npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS;
        update con;
        
        Contact[] insertedContacts2 = [Select phone,HomePhone,npe01__WorkPhone__c,MobilePhone,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(mobilePhone,insertedContacts2[0].Phone);
        system.assertEquals(mobilePhone,insertedContacts2[0].MobilePhone);
        system.assertEquals(workPhone,insertedContacts2[0].npe01__WorkPhone__c);
        system.assertEquals(newPhone,insertedContacts2[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts2[0].npe01__PreferredPhone__c);
        
        //test other phone
        preferredPhone = 'Other';
        String otherPhone = '206-666-6666';
        
        con.OtherPhone = otherPhone;
        con.npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS;
        update con;
        
        Contact[] insertedContacts3 = [Select phone,HomePhone,npe01__WorkPhone__c,MobilePhone,OtherPhone,npe01__PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(otherPhone,insertedContacts3[0].Phone);
        system.assertEquals(otherPhone,insertedContacts3[0].OtherPhone);
        system.assertEquals(mobilePhone,insertedContacts3[0].MobilePhone);
        system.assertEquals(workPhone,insertedContacts3[0].npe01__WorkPhone__c);
        system.assertEquals(newPhone,insertedContacts3[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts3[0].npe01__PreferredPhone__c);
        
    }
   */

/* TESTING EMAIL WORKFLOW --------------------------------------------------------------
    /// <name> createContactWithEmailNoPref </name>
    /// <summary> Test Method for creating a contact with an email and no preferences set. </summary>
    static testMethod void createContactWithEmailNoPref()
    {
        //with no other prefs, email should land in npe01__workemail__c and set npe01__Preferred_Email__c to 'work'.
        String newEmail = 'joe@testforemail.com';
        String preferredEmail = null;
        String workEmailString = 'Work';
        Contact con = new Contact(FirstName='test', LastName='contact678',email=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,npe01__workEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
        system.assertEquals(newEmail,insertedContacts[0].npe01__workEmail__c);
        system.assertEquals(workEmailString,insertedContacts[0].npe01__Preferred_Email__c);
        
    }
    
    /// <name> createContactWithEmailPersonalPrefAlsoPersonalEmail </name>
    /// <summary> Test Method for creating a contact with a email and a personal email. </summary>
    static testMethod void createContactWithEmailPersonalPrefAlsoPersonalEmail()
    {
        //with pref set to Personal, Personal email should land in email and set npe01__Preferred_Email__c to 'Personal'.
        String newEmail = 'joe@testforemail.com';
        String newPersonalEmail = 'j@testemail.net';
        String preferredEmail = 'Personal';
        Contact con = new Contact(FirstName='test', LastName='contact678',email=newEmail,npe01__HomeEmail__c=newPersonalEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,npe01__workEmail__c,npe01__HomeEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
        system.assertEquals(newEmail,insertedContacts[0].npe01__HomeEmail__c);
        system.assertEquals(null,insertedContacts[0].npe01__workEmail__c);
        system.assertEquals(preferredEmail,insertedContacts[0].npe01__Preferred_Email__c);
        
    }
    
    /// <name> createContactWithEmailPrefSet </name>
    /// <summary> Test Method for creating a contact with an email in email and the preferred email set. </summary>
    static testMethod void createContactWithEmailPrefSet()
    {
        //with pref set to Home, Personal Email should land in email and set npe01__Preferred_Email__c to 'Personal'.
        //commented out until #49 is fixed
        String newEmail = 'joe@testforemail.com';
        String preferredEmail = 'Personal';
        Contact con = new Contact(FirstName='test', LastName='contact678',email=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,npe01__HomeEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
       //   system.assertEquals(newEmail,insertedContacts[0].npe01__HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts[0].npe01__Preferred_Email__c);
        
        //test work email
        preferredEmail = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',email=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con1;
        
        Contact[] insertedContacts1 = [Select email,npe01__workEmail__c,npe01__Preferred_Email__c from Contact where id=:con1.id];
        
        system.assertEquals(newEmail,insertedContacts1[0].email);
        system.assertEquals(newEmail,insertedContacts1[0].npe01__workEmail__c);
        system.assertEquals(preferredEmail,insertedContacts1[0].npe01__Preferred_Email__c);
        
        //test alternate email
        preferredEmail = 'Alternate';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',email=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con2;
        
        Contact[] insertedContacts2 = [Select email,npe01__AlternateEmail__c,npe01__Preferred_Email__c from Contact where id=:con2.id];
        
        system.assertEquals(newEmail,insertedContacts2[0].email);
        system.assertEquals(newEmail,insertedContacts2[0].npe01__AlternateEmail__c);
        system.assertEquals(preferredEmail,insertedContacts2[0].npe01__Preferred_Email__c);
      
    }
    
    /// <name> createContactWithEmailAndPrefSet </name>
    /// <summary> Test Method for creating a contact with a email in the correct field
    /// and the preferred email set. </summary>
    static testMethod void createContactWithEmailAndPrefSet()
    {
        //with pref set to Home, Personal Email should land in email and set npe01__Preferred_Email__c to 'Personal'.
        
        String newEmail = 'joe@testforemail.com';
        String preferredEmail = 'Personal';
        Contact con = new Contact(FirstName='test', LastName='contact678',npe01__HomeEmail__c=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,npe01__HomeEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
        system.assertEquals(newEmail,insertedContacts[0].npe01__HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts[0].npe01__Preferred_Email__c);
        
        //test work email
        preferredEmail = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',npe01__workEmail__c=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con1;
        
        Contact[] insertedContacts1 = [Select email,npe01__workEmail__c,npe01__Preferred_Email__c from Contact where id=:con1.id];
        
        system.assertEquals(newEmail,insertedContacts1[0].email);
        system.assertEquals(newEmail,insertedContacts1[0].npe01__workEmail__c);
        system.assertEquals(preferredEmail,insertedContacts1[0].npe01__Preferred_Email__c);
        
        //test mobile email
        preferredEmail = 'Alternate';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',npe01__AlternateEmail__c=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con2;
        
        Contact[] insertedContacts2 = [Select email,npe01__AlternateEmail__c,npe01__Preferred_Email__c from Contact where id=:con2.id];
        
        system.assertEquals(newEmail,insertedContacts2[0].email);
        system.assertEquals(newEmail,insertedContacts2[0].npe01__AlternateEmail__c);
        system.assertEquals(preferredEmail,insertedContacts2[0].npe01__Preferred_Email__c);
       
        
    }
    
    /// <name> updateContactWithEmailAndPref </name>
    /// <summary> Test Method for updating a contact with a email in the correct field
    /// and the preferred email set. </summary>
    static testMethod void updateContactWithEmailAndPref()
    {
        //with pref set to Personal, Personal email should land in email and set npe01__Preferred_Email__c to 'Personal'.
        
        String newEmail = 'joe@testforemail.com';
        String preferredEmail = 'Personal';
        Contact con = new Contact(FirstName='test', LastName='contact678',npe01__HomeEmail__c=newEmail,npe01__Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,npe01__HomeEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        //test work email
        preferredEmail = 'Work';
        String workEmail = 'jd@email.net';
        
        con.npe01__workEmail__c = workEmail;
        con.npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS;
        update con;
        
        Contact[] insertedContacts1 = [Select email,npe01__HomeEmail__c,npe01__workEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(workEmail,insertedContacts1[0].email);
        system.assertEquals(workEmail,insertedContacts1[0].npe01__workEmail__c);
        system.assertEquals(newEmail,insertedContacts1[0].npe01__HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts1[0].npe01__Preferred_Email__c);
        
        //test mobile email
        preferredEmail = 'Alternate';
        String alternateEmail = 'jdc@testemail.net';
        
        con.npe01__alternateEmail__c = alternateEmail;
        con.npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS;
        update con;
        
        Contact[] insertedContacts2 = [Select email,npe01__HomeEmail__c,npe01__workEmail__c,npe01__alternateEmail__c,npe01__Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(alternateEmail,insertedContacts2[0].email);
        system.assertEquals(alternateEmail,insertedContacts2[0].npe01__alternateEmail__c);
        system.assertEquals(workEmail,insertedContacts2[0].npe01__workEmail__c);
        system.assertEquals(newEmail,insertedContacts2[0].npe01__HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts2[0].npe01__Preferred_Email__c);
      
        
    }
*/
/* TESTING DONATION HISTORY WEBSERVICES ------------------------------------------------*/
/************************* DEPRECATE IN CUMULUS ***********************************    

    /// <name> getContactDonationHistory </name>
    /// <summary> Test Method for getContactDonationHistory</summary>
    static testMethod void getContactDonationHistory()
    {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;

        Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed Won',CloseDate=System.today());
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
        insert ocr;

        Decimal sum = ACCT_IndividualAccounts.getContactDonationHistory(con.id);
    }

    /// <name> getContactLastDonation </name>
    /// <summary> Test Method for getContactLastDonation</summary>
    static testMethod void getContactLastDonation()
    {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        String sum = ACCT_IndividualAccounts.getContactLastDonation(con.id);
        
        system.assertEquals('',sum);

        Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed Won',CloseDate=System.today());
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
        insert ocr;

        sum = ACCT_IndividualAccounts.getContactLastDonation(con.id);
        
    }


/// <name> getContactDonationHistory </name>
    /// <summary> Test Method for getContactDonationHistory</summary>
    static testMethod void getContactDonationHistoryAmount()
    {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;

        Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed Won',CloseDate=System.today());
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
        insert ocr;
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(con);
        //pass the controller into the extension
        ContactDonationCredit_EXT ext = new ContactDonationCredit_EXT(sc);
        
        system.assertEquals(system.label.npe01.DefaultContactTransactionCurrency + '500.00',ext.getContactDonationHistory());
    }

    /// <name> getContactLastDonation </name>
    /// <summary> Test Method for getContactLastDonation</summary>
    static testMethod void getContactLastDonationDate()
    {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        Integer year = 2005;
        Integer month = 10;
        Integer day = 10;
        
        
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        String sum = ACCT_IndividualAccounts.getContactLastDonation(con.id);
        
        system.assertEquals('',sum);

        Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed Won',CloseDate=date.newInstance(year,month,day));
        insert o;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
        insert ocr;
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(con);
        //pass the controller into the extension
        ContactDonationCredit_EXT ext = new ContactDonationCredit_EXT(sc);

        system.assertEquals(String.valueOf(day) + '/' + String.valueOf(month) + '/' + String.valueOf(year),ext.getContactLastDonation());        
    }   
************************* DEPRECATE IN CUMULUS ***********************************/    
     
    static testMethod void ghIssue16a(){
    	if (strTestOnly != '*' && strTestOnly != 'ghIssue16a') return;
        ghIssue16Processor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    
    static testMethod void ghIssue16b(){
    	if (strTestOnly != '*' && strTestOnly != 'ghIssue16b') return;
        ghIssue16Processor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    
    static void ghIssue16Processor(string strProcessor){
        /* Set value of Account name to blank when first name is blank, not null */ 
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        Contact con = new Contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS,
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        con = [select AccountId from Contact where id = :con.Id];
        Account newAcc = [select id,Name from Account where id = :con.AccountId limit 1];
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)
            system.assertEquals(newAcc.Name, CAO_Constants.Contact_FIRSTNAME_FOR_TESTS + ' ' + CAO_Constants.Contact_LASTNAME_FOR_TESTS);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)            
            system.assertEquals(newAcc.Name, CAO_Constants.Contact_LASTNAME_FOR_TESTS + ' Household');
        
        //set name to null
        con.FirstName = null;
        
        Test.startTest();
        update con;
        Test.stopTest();
        
        newAcc = [select id,Name from Account where id = :con.AccountId limit 1];
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR)
            system.assertEquals(newAcc.Name, CAO_Constants.Contact_LASTNAME_FOR_TESTS);
        else if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR)            
            system.assertEquals(newAcc.Name, CAO_Constants.Contact_LASTNAME_FOR_TESTS + ' Household');
    }
}