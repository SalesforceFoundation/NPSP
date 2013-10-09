/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @description Implements one of two account models, 1x1 or bucket - controls syncing within the model 
*/
global with sharing class CAO_IndividualAccounts{
    /// <name> IndividualAccounts </name>
    /// <summary> Default Constructor </summary>
    public CAO_IndividualAccounts(){}

    /// <name> IndividualAccounts </name>
    /// <summary> Overloads the IndividualAccounts object constructor to handle Contact processing </summary>
    /// <param name="contacts"> Contact objects that are being triggered </param>
    /// <param name="oldContacts"> Contact object values before trigger event </param>
    /// <param name="ta"> Trigger action that is occuring </param>
    private static npe01__Contacts_and_Orgs_Settings__c ContactsSettings;
    
    private static Set<String> EasternOrderLanguages = new Set<String>{
        'ja','ko','vi','hu','ro','zh_CN','zh_TW'
    };
              
    private static String OrgLanguage{get{
        if(OrgLanguage == null)
            OrgLanguage = UserInfo.getLocale();// [Select LanguageLocaleKey From Organization].LanguageLocaleKey;
        return OrgLanguage;             
    }set;}       
    
    public CAO_IndividualAccounts(Contact[] contacts, Contact[] oldContacts, CAO_Constants.triggerAction ta)
    {
            ContactsSettings = CAO_Constants.getContactsSettings();
            
            if(!ContactsSettings.npe01__Disable_Account_Model_Trigger__c){
            List<Contact> individualInserts = new List<Contact>();
            List<Contact> individualUpdates = new List<Contact>();
            List<Contact> contactDeletes = new List<Contact>();
            List<Contact> bucketContacts = new List<Contact>();
            Set<Id> contactAccountIds = new Set<Id>();
            Map<Id,Id> accountUpdates = new Map<Id,Id>();
            if(contacts!=null){
                for(Contact mycontact : contacts){
                    contactAccountIds.add(mycontact.AccountId);
                }
            }
            
            Map<Id,Account> existingAccounts = new Map<Id,Account>([select Id,npe01__One2OneContact__c from Account where Id IN :contactAccountIds]);
            
            Integer i = 0;
            //if this is after a delete
            if(ta==CAO_Constants.triggerAction.afterDelete){
                
                for(Contact c : oldContacts) {
                    contactDeletes.add(c);
                }
                    deleteContactAccounts(contactDeletes);
            } else {
                for(Contact c : contacts)
                {
                    //BEFORE INSERT
                    if ( ta==CAO_Constants.triggerAction.beforeInsert )
                    {
                        /*one-to-one account should be created if:
                            1. The account isn't set by the user
                            2. The npe01__Private__c checkbox isn't set by the user
                            3. The one-to-one model is chosen in the npe01__SystemAccountProcessor__c
                        */
                        if (((c.AccountId != null && existingAccounts.get(c.AccountId).npe01__One2OneContact__c!=null) || c.AccountId == null) && c.npe01__Private__c != true && CAO_Constants.isOneToOne())
                        {
                            if(c.AccountId != null && c.Account.npe01__One2OneContact__c != null){
                                c.AccountId = null;
                            }
                            individualInserts.add(c);
                        }
                   
                        /*contact should be connected to the bucket account if:
                            1. The account isn't set by the user
                            2. The npe01__Private__c checkbox isn't set by the user
                            3. The Individual model is chosen in the npe01__SystemAccountProcessor__c
                        */
                        if (c.AccountId == null && c.npe01__Private__c != true && !CAO_Constants.isOneToOne())
                        {        
                            bucketContacts.add(c);
                        }
                    }
        
                    //AFTER INSERT
                    if ( ta==CAO_Constants.triggerAction.afterInsert )            
                    {
                        /*grab the Accounts that need to have the newly assigned Contact Id to them if:
                            1. If the contact is connected to an Account
                            2. The Contact is flagged as an individual
                            3. The one-to-one model is chosen in the npe01__SystemAccountProcessor__c
                        */
    
                        if ( c.AccountId != null && c.npe01__Private__c != true && CAO_Constants.isOneToOne() && c.Account.npe01__SYSTEMIsIndividual__c)
                        {
                            //contacts are connected to Accounts, make the connection in the other direction
                            accountUpdates.put(c.AccountId, c.Id);
                        }
                        //there is no after insert processing for the bucket account model
                    }
        
                    //BEFORE UPDATE
                    if ( ta==CAO_Constants.triggerAction.beforeUpdate )
                    {
                        /*one-to-one account should be created if:
                            1. The account has been blanked out by the user
                            2. The npe01__Private__c checkbox isn't set by the user
                            3. The one-to-one model is chosen in the npe01__SystemAccountProcessor__c
                        */
                        if (c.AccountId == null && c.npe01__Private__c != true && CAO_Constants.isOneToOne())
                        {
                            individualInserts.add(c);
                        }          
                        /*contact should be connected to the bucket account if:
                            1. The account has been blanked out by the user
                            2. The npe01__Private__c checkbox isn't set by the user
                            3. The Individual model is chosen in the npe01__SystemAccountProcessor__c
                        */ 
                        if (c.AccountId == null && c.npe01__Private__c != true && !CAO_Constants.isOneToOne())
                        {
        
                            bucketContacts.add(c);
                        }
                        //for contacts marked private after they have been created, break the relationship to the one to one
                        if (c.AccountId != null && c.npe01__Private__c == true && CAO_Constants.isOneToOne())
                        {
                            c.AccountId = null;
                        } 
                    }
        
                    //AFTER UPDATE
                    if ( ta==CAO_Constants.triggerAction.afterUpdate )
                    {
                        /*if the contact is in the one-to-one model, changes to fields on the Contact
                        will require data changes on the Account to keep some fields in sync
                        */
                        if (CAO_Constants.isOneToOne() && c.npe01__Organization_Type__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
                        {
                            if (
                                c.FirstName != oldContacts[i].FirstName ||
                                c.LastName != oldContacts[i].LastName ||
                                c.MailingStreet != oldContacts[i].MailingStreet ||
                                c.MailingCity != oldContacts[i].MailingCity ||
                                c.MailingState != oldContacts[i].MailingState ||
                                c.MailingPostalCode != oldContacts[i].MailingPostalCode ||
                                c.MailingCountry != oldContacts[i].MailingCountry ||
                                c.OtherStreet != oldContacts[i].OtherStreet ||
                                c.OtherCity != oldContacts[i].OtherCity ||
                                c.OtherState != oldContacts[i].OtherState ||
                                c.OtherPostalCode != oldContacts[i].OtherPostalCode ||
                                c.OtherCountry != oldContacts[i].OtherCountry ||
                                c.Phone != oldContacts[i].Phone ||
                                c.Fax != oldContacts[i].Fax
                            ) {
                                individualUpdates.add(c);
                            }
                        }
                    }
                    i += 1;
                }
               
                if (individualInserts.size() > 0)
                {
                    //add the newly created or updated Contacts that need a new individual account
                    insertIndividualAccount(individualInserts);
                }
                if (bucketContacts.size() > 0)
                {
                    //add the newly created or updated Contact to the bucket account
                    attachToIndividualAccount(bucketContacts);
                }
                if (individualUpdates.size() > 0)
                {
                    //contacts in the one-to-one model that are changing for syncing with account
                    updateIndividualAccount(individualUpdates);
                }
                if (accountUpdates.size() > 0)
                {
                    //update Accounts that have newly created Contacts connected to them
                    updateAccounts(accountUpdates);
                }
            }
        }
    }

    /// <name> updateAccounts </name>
    /// <summary> Updates Accounts with the correct Individual Contact Id</summary>
    /// <param name="accounts"> Map of account Ids </param>
    public static void updateAccounts(Map<Id, Id> accounts)
    {
        List<Account> accountUpdates = new List<Account>(); 
        for (Id i : accounts.keySet())
        {
            Account a = new Account(Id=i,npe01__One2OneContact__c=accounts.get(i));
            accountUpdates.add(a);
        }
        if (accountUpdates.size() > 0)
        {
            Database.SaveResult[] lsr = Database.update(accountUpdates, false);
        }
        
    }


    /// <name> attachToIndividualAccount </name>
    /// <summary> Updates Contacts to relate to a single Individual Account</summary>
    /// <param name="contacts"> Contacts meeting the trigger criteria</param>
    public static void attachToIndividualAccount(Contact[] contacts)
    {
        //grab the first Account that is named Individual
        List<Account> individuals = [Select Id from Account where name = :CAO_Constants.BUCKET_ACCOUNT_NAME ORDER BY CreatedDate Desc Limit 1];
        
        Id individualAccountId = CAO_Constants.GetIndividualAccountId();
        
        if (individuals.size() > 0)
        {
            for(Contact c : contacts)
            {
                //connect all Contacts to the bucket Account
                c.AccountId = individualAccountId;
            }
        } else
        {
            //if there is no bucket Account, the bucket model won't function unless we create one
            Account individual = new Account();
            individual.Name = CAO_Constants.BUCKET_ACCOUNT_NAME;
            //flag the account as an individual account
            individual.npe01__SYSTEMISINDIVIDUAL__c = true;
            //individual.Type = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            individual.npe01__SYSTEM_AccountType__c = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            insert individual;

            for(Contact c : contacts)
            {
                //connect Contact to bucket Account
                c.AccountId = individual.Id;
            }
        }
    }


    /// <name> insertIndividualAccount </name>
    /// <summary> Inserts a new Individual Account for an Individual Contact</summary>
    /// <param name="contacts"> Contacts meeting the trigger criteria</param>
    public static void insertIndividualAccount(Contact[] contacts)
    {
        List<Id> contactIds = new List<Id>();
        Map<Id,Id> conAccMap = new Map<Id,Id>();       
        
        for (Contact c : contacts)
        {
            //make sure we're only working with Contacts that have already been inserted
            if (c.Id != null)
            {
                contactIds.add(c.Id);
            }
        }
        //get all the Accounts that are connected to the Contacts
        for (Account acc : [Select Id, npe01__One2OneContact__c from Account where npe01__One2OneContact__c in :contactIds])
        {
            conAccMap.put(acc.npe01__One2OneContact__c,acc.Id);
        }
        
        List<Contact> contactUpdates = new List<Contact>();
        List<Account> accountInserts = new List<Account>();

        Schema.Recordtypeinfo rtById;
        //check if recordtypes are enabled, and if it matches the existing setting
        if (ContactsSettings.npe01__One_to_One_RecordTypeID__c != null){
            Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
            Map<Id,Schema.RecordTypeInfo> rtMapById = r.getRecordTypeInfosById();
            rtById =  rtMapById.get(ContactsSettings.npe01__One_to_One_RecordTypeID__c);            
        }

        for(Contact c : contacts)
        {
            //if we found an Account already connected to this Contact, connect the Contact to that Account
            if (conAccMap.containsKey(c.Id))
            {
                //if a user has blanked out the Account for a Contact, this will put it right back
                c.AccountId = conAccMap.get(c.Id);
                
                
            } else {
                //construct the individul account for the Contact
                Account a = new Account();
                String aName = '';
                
                if (c.FirstName != null){
                    aName += c.FirstName;
                    aName += ' ' ;
                }
                
                if(EasternOrderLanguages.contains(OrgLanguage))
                    aName = c.LastName + ' ' + aName;
                else
                    aName += c.LastName;
                                         
                a.Name = aName;
                //connect the Account to the Contact
                if (c.Id != null) {
                    a.npe01__One2OneContact__c = c.Id;
                }
                a.Phone = c.Phone;
                a.Fax = c.Fax;
                a.BillingStreet = c.MailingStreet;
                a.BillingCity = c.MailingCity;
                a.BillingState = c.MailingState;
                a.BillingPostalCode = c.MailingPostalCode;
                a.BillingCountry = c.MailingCountry;
                a.ShippingStreet = c.OtherStreet;
                a.ShippingCity = c.OtherCity;
                a.ShippingState = c.OtherState;
                a.ShippingCountry = c.OtherCountry;
                //flag the account as an individual account
                //a.Type = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
                a.npe01__SYSTEM_AccountType__c = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
                if (rtById != null){                
                    a.put('RecordTypeID', rtByID.getRecordTypeID());
                }
                a.npe01__SYSTEMISINDIVIDUAL__c = true;
                accountInserts.add(a);
            }
        }
        
        if (accountInserts.size() > 0) {
            Database.SaveResult[] lsr = Database.insert(accountInserts, false);
            Integer i = 0;
            for (Contact c : contacts)
            {
                //for each success, write the new AccountId to the Contact. These 
                if (lsr[i].isSuccess() == true)
                {
                    c.AccountId = lsr[i].getId();

                } else {
                    system.debug('Error inserting Accounts');
                }
                i += 1;
            }
        }
    }


    /// <name> updateIndividualAccount </name>
    /// <summary> Updates an Individual Account for an Individual Contact</summary>
    /// <param name="contacts"> Contacts meeting the trigger criteria</param>
    public void updateIndividualAccount(Contact[] contacts)
    {
        Map<Id,Contact> accConMap = new Map<Id,Contact>();
        for (Contact c : contacts)
        {
            accConMap.put(c.AccountId,c);

        }
        //get the corresponding Accounts
        List<Account> accts = [Select a.name,a.ShippingStreet, a.ShippingState, a.ShippingPostalCode, a.ShippingCountry, 
        a.ShippingCity, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCountry, a.BillingCity
        From Account a where a.Id IN :accConMap.keyset()];
        List<Account> accountUpdates = new List<Account>();
        
        for(Account a : accts){         
            Contact c = accConMap.get(a.Id);
            //if any address data has changed on the contact, push it all to the Account
            if (
                c != null && (
                c.MailingStreet != a.BillingStreet ||
                c.MailingCity != a.BillingCity ||
                c.MailingState != a.BillingState ||
                c.MailingPostalCode != a.BillingPostalCode ||
                c.MailingCountry != a.BillingCountry ||
                c.OtherStreet != a.ShippingStreet ||
                c.OtherCity != a.ShippingCity ||
                c.OtherState != a.ShippingState ||
                c.OtherPostalCode != a.ShippingPostalCode ||
                c.OtherCountry != a.ShippingCountry ||
                EasternOrderLanguages.contains(OrgLanguage) ? c.LastName + ' ' + c.FirstName != a.Name : c.FirstName + ' ' + c.LastName != a.Name                               
                )
            ) {
                // Update Account fields
                a.BillingStreet = c.MailingStreet;
                a.BillingCity = c.MailingCity;
                a.BillingState = c.MailingState;
                a.BillingPostalCode = c.MailingPostalCode;
                a.BillingCountry = c.MailingCountry;
                a.ShippingStreet = c.OtherStreet;
                a.ShippingCity = c.OtherCity;
                a.ShippingState = c.OtherState;
                a.ShippingPostalCode = c.OtherPostalCode;
                a.ShippingCountry = c.OtherCountry;                
                String aName = '';
                if (c.FirstName != null){
                    aName += c.FirstName;
                    aName += ' ' ;
                }                
                if(EasternOrderLanguages.contains(OrgLanguage))
                    aName = c.LastName + ' ' + aName;
                else
                    aName += c.LastName;                
                a.Name = aName;                    
                accountUpdates.add(a);
            }           
        }   

        if ( accountUpdates.size() > 0){
            Database.SaveResult[] lsr = Database.update(accountUpdates, false);
        }
    }
    
    //delete the accounts for contacts that have been deleted
    public void deleteContactAccounts(Contact[] contacts){
        List<Id> accountIds = new List<Id>();
        List<Account> accountsOnContacts = new List<Account>();
        List<Account> accountsForDeletion = new List<Account>();
        
        if (contacts.size()>0){
            for (Contact thisContact : contacts){
                accountIds.add(thisContact.accountId);
            }

            accountsOnContacts = [Select Id, Type,npe01__SYSTEM_AccountType__c,(Select Id from Opportunities limit 1),(select Id from Contacts limit 1) from Account where Id IN :accountIds];
            
            for (Account thisAccount : accountsOnContacts){
                //if the legacy or current type field show it's not a one-to-one record, don't delete the account
                if ( thisAccount.Type == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || thisAccount.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE){
                    
                    //if there are no Opportunities for this Account, add it for deletion
                    if (thisAccount.Opportunities.size()==0 && thisAccount.Contacts.size()==0 )
                    {
                        accountsForDeletion.add(thisAccount);
                    }
                }   
            }        
        }
        //delete the accounts
        if(accountsForDeletion.size()>0){           
            delete accountsForDeletion;
        }
        
    }
    /// <name> getContactDonationHistory </name>
    /// <summary> Called by sControl to display total giving amount </summary>
    webservice static decimal getContactDonationHistory(Id contactId){
        Decimal sum = 0;
        for (OpportunityContactRole o : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId]) 
        {
            sum += o.Opportunity.Amount;
        }
        return sum;
    }


    /// <name> getContactLastDonation </name>
    /// <summary> Called by sControl to display last donation date </summary>
        webservice static String getContactLastDonation(Id contactId){
        Date lastDonation = null;
        List<OpportunityContactRole> ocr = [Select Opportunity.CloseDate, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId ORDER BY Opportunity.CloseDate DESC Limit 100]; 
        if ( ocr.size() > 0) {
            return String.ValueOf(ocr[0].Opportunity.CloseDate);
        } else {
            return '';
        }
    }
    
    /// <name> getContactDonationHistory </name>
    /// <summary> Called by sControl to display total giving amount </summary>
    public static string getContactDonationHistoryAmount(Id contactId){
        Decimal sum = 0;
        for (OpportunityContactRole o : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId]) 
        {
            sum += o.Opportunity.Amount;
        }
        
        String totalString = system.label.npe01.DefaultContactTransactionCurrency;
        
        totalString += String.valueOf(sum);
        if(!totalString.contains('.')){
            totalString += '.00';
        }
        return totalString;
    }


    /// <name> getContactLastDonation </name>
    /// <summary> Called by sControl to display last donation date </summary>
    public static String getContactLastDonationDate(Id contactId){
        Date lastDonation = null;
        List<OpportunityContactRole> ocr = [Select Opportunity.CloseDate, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId ORDER BY Opportunity.CloseDate DESC Limit 100]; 
        if ( ocr.size() > 0) {
            //return String.ValueOf(ocr[0].Opportunity.CloseDate);
            return ocr[0].Opportunity.CloseDate.month() + '/' + ocr[0].Opportunity.CloseDate.day() + '/' + ocr[0].Opportunity.CloseDate.year();
        } else {
            return '';
        }
    }

}