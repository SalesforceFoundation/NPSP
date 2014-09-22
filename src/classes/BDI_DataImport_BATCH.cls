/*
    Copyright (c) 2014 Salesforce.com Foundation
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
* @date 2014
* @description Batch class for the Batch Data Importer.
*
* Batch process looks for all DataImport records that need to be processed
*
*/
public with sharing class BDI_DataImport_BATCH implements Database.Batchable<sObject> { 

    private String strSoql;
    
    // constructor, which sets up our initial soql
    public BDI_DataImport_BATCH() {

        strSoql = 'SELECT ';
        string strComma = '';
        for (string strF : listStrDataImportFields) {
            strSoql += strComma + strF;
            strComma = ', ';
        }
        strSoql += ' FROM ' + UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        strSoql += ' WHERE Status__c <> \'Imported\' ';        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strSoql);
    }
    
    // maps to keep track of the objects we will create.
    // all are indexed by the object's matching key or the di.Id
    private map<string, Contact> mapDIKeyToContact = new map<string, Contact>();
    private map<string, Account> mapDIKeyToAccount = new map<string, Account>();
    private map<Id, Address__c> mapDIIdToAddr = new map<Id, Address__c>();
    private map<Id, Opportunity> mapDIIdToOpp = new map<Id, Opportunity>();
    private map<Id, npe01__OppPayment__c> mapDIIdPmt = new map<Id, npe01__OppPayment__c>();
    private map<string, Id> mapStrNameToCampaignId = new map<string, Id>();

    // holds the list of DataImport records we are currently processing
    private list<DataImport__c> listDI;

    public void execute(Database.BatchableContext bc, List<DataImport__c> listDI) {

	    SavePoint sp = Database.setSavepoint();
	    
	    try {
            this.listDI = listDI;
            
            // first set a clean state for each DI
            for (DataImport__c di: listDI) {
                di.Status__c = null;
                di.ImportedDate__c = null;
                di.ApexJobId__c = null;
                di.FailureInformation__c = null;
            }

            importContactsAndHouseholds();
            
            importAccounts();
            
            importAddresses();
            
            importCampaigns();

            importOpportunities();

            // update final status for each DI
            for (DataImport__c di: listDI) {
            	if (di.Status__c == null)
                    di.Status__c = 'Imported';
                di.ImportedDate__c = system.now();
                di.ApexJobId__c = bc.getJobId();
            }
            
            update listDI;
	
	    } catch (Exception e) {
            // rollback the entire transaction on any failure, DML or otherwise
	        Database.rollback(sp);
	        
	        // log the unexpected error
	        ERR_Handler.processError(e, ERR_Handler.Context.BDI);
	        
            // update all the di's with errors with the error state.
            // those di's without specific errors will get the exception's error
            list<DataImport__c> listDIError = new list<DataImport__c>();
            for (DataImport__c di : listDI) {
            		listDIError.add(new DataImport__c(
            		  Id = di.Id, 
            		  Status__c = 'Failed', 
            		  FailureInformation__c = di.Status__c == 'Failed' ? di.FailureInformation__c : e.getMessage(),
            		  ApexJobId__c = bc.getJobId()
            		  ));
            }
            
            update listDIError;
            
            // unfortunately, we can't let the system think the batch failed, or
            // then it would rollback our setting of failure state in the DI records.
            // so we just return, and rely on our Data Import ui to notify the user.
	    }
    }

    // utility to copy the specific error into the provide di.
    private void LogBDIError(DataImport__c di, string strError) {
    	di.Status__c = 'Failed';
        di.FailureInformation__c = strError;
    }
            
    // required method for Batchable.  Nothing we need to do though!
    public void finish(Database.BatchableContext bc) {}

    // utility to return all fields from the Data Import object
    private static list<string> listStrDataImportFields { 
        get {
            if (listStrDataImportFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.DataImport__c.fields.getMap();
                listStrDataImportFields = new list<string>();
                listStrDataImportFields.addAll(mapS.keySet());                         
            }
            return listStrDataImportFields;
        }
        set;
    }    
    
    // utility to return a map of fields from the DataImport to fields for the given 'object',
    // from the list of DataImport Fields, which have the form DIObject_namespace_field 
    private static map<string, string> mapFieldsForDIObject(string strObj, list<string> listStrDIFields) {
        map<string, string> mapDIFieldToObjField = new map<string, string>();
        for (string strF : listStrDIFields) {
        	DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), strF);
        	string strHelpText = dfr.getInlineHelpText();
        	if (strHelpText != null && strHelpText != '') {
	        	list<string> strParts = strHelpText.split('\\.', 2);
	        	if (strParts.size() == 2 && strParts[0] == strObj && strParts[1] != '') {
	        		string strField = strParts[1];
	        		if (!UTIL_Namespace.InManagedPackage)
	        		     strField = UTIL_Namespace.StrTokenRemoveNSPrefix(strField);
	                mapDIFieldToObjField.put(strF, strField);
	        	}
        	} 
        }
        return mapDIFieldToObjField;
    }

    //********************************************* CONTACTS & HOUSEHOLDS ************************************************
    // method to handle importing or updating Contact1 and Contact2,
    // creating their Household if none exists.
    private void importContactsAndHouseholds() {        

        // first, try to match our existing contacts
        matchExistingContacts();            

        // handle multiple di's referring to the same existing contact
        set<string> setDIKeyUpsert = new set<string>();
        list<Contact> listConUpsert = new list<Contact>();
                    
        // create/update our c1's
        map<string, string> mapDIFieldToC1Field = mapFieldsForDIObject('Contact1', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
               
            string diKey = diKeyC1(di);
            if (diKey == null)
                continue;                
            Contact con = mapDIKeyToContact.get(diKey);
            
            boolean isModified = false;                 
            for (string strDIField : mapDIFieldToC1Field.keySet()) {
                if (di.get(strDIField) != null) {
                    con.put(mapDIFieldToC1Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            
            if (isModified) {
                if (setDIKeyUpsert.add(diKey))
                    listConUpsert.add(con);
            }
        }
        upsert listConUpsert;
            
        // update each DI with its new contact1 ID
        // also get all our C1 Id's in a set for further use
        set<Id> setC1Id = new set<Id>();
        for (DataImport__c di: listDI) {
            if (di.Contact1Imported__c == null) {
                string diKey = diKeyC1(di);
                Contact con = mapDIKeyToContact.get(diKey);
                if (con != null) 
                    di.Contact1Imported__c = con.Id;
            }
            setC1Id.add(di.Contact1Imported__c);
        }
            
        // get the Household Accounts that were created for C1's
        map<Id, Id> mapC1IdToHHId = new map<Id, Id>();
        for (Contact con : [select Id, AccountId from Contact where Id in :listConUpsert]) {
            mapC1IdToHHId.put(con.Id, con.AccountId);
        }
        // store it back in C1 for later use
        for (DataImport__c di : listDI) {
            if (di.Contact1Imported__c != null) {
                Id HHId = mapC1IdToHHId.get(di.Contact1Imported__c);
                if (HHId != null) {
                    string diKey = diKeyC1(di);
                    Contact con = mapDIKeyToContact.get(diKey);
                    con.AccountId = HHId;
                }
            }
        }

        // now create our c2's
        map<string, string> mapDIFieldToC2Field = mapFieldsForDIObject('Contact2', listStrDataImportFields);
        setDIKeyUpsert.clear();
        listConUpsert.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
               
            string diKey = diKeyC2(di);
            if (diKey == null)
                continue;                
            Contact con = mapDIKeyToContact.get(diKey);
            // set c2's household to match c1
            con.AccountId = mapC1IdToHHId.get(di.Contact1Imported__c);
            
            boolean isModified = false;                 
            for (string strDIField : mapDIFieldToC2Field.keySet()) {
                if (di.get(strDIField) != null) {
                    con.put(mapDIFieldToC2Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            if (isModified) {
                if (setDIKeyUpsert.add(diKey))
                   listConUpsert.add(con);
            }
        }
        upsert listConUpsert;
            
        // update each DI with its new contact2 ID
        for (DataImport__c di: listDI) {
            if (di.Contact2Imported__c == null) {
                string diKey = diKeyC2(di);
                Contact con = mapDIKeyToContact.get(diKey);
                if (con != null) 
                    di.Contact2Imported__c = con.Id;
            }
        }
    }

    // looks for existing contacts that match C1 or C2, and if found,
    // updates their Id's in the Di's.  if not found, creates a new
    // contact object for that di.
    private void matchExistingContacts() {
    
        //UNDONE: read preference for fields to match against.
        set<string> setFname = new set<string>();
        set<string> setLname = new set<string>();
        set<string> setEmail = new set<string>();
        
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
        	if (di.Status__c == 'Failed')
        	   continue;
            // c1
            if (di.Contact1_Firstname__c != null)
                setFname.add(di.Contact1_Firstname__c);
            if (di.Contact1_Lastname__c != null)
                setLname.add(di.Contact1_Lastname__c);
            if (di.Contact1_Personal_Email__c != null)
                setEmail.add(di.Contact1_Personal_Email__c);            

            // c2
            if (di.Contact2_Firstname__c != null)
                setFname.add(di.Contact2_Firstname__c);
            if (di.Contact2_Lastname__c != null)
                setLname.add(di.Contact2_Lastname__c);
            if (di.Contact2_Personal_Email__c != null)
                setEmail.add(di.Contact2_Personal_Email__c);            
        }
        
        string strSoql = 'Select Id, Firstname, Lastname, Email from Contact where ';
        strSoql += 'Firstname in :setFname and Lastname in :setLname and Email in :setEmail';
        list<Contact> listCon = database.query(strSoql);
        
        // put all potential contacts into a map
        map<string, Contact> mapDIKeyToContactAll = new map<string, Contact>();        
        for (Contact con : listCon) {
            string diKey = diKeyContact(con);
            mapDIKeyToContactAll.put(diKey, con);
        }
        
        for (DataImport__c di : listDI) {
        	string diKey = diKeyC1(di);
            Contact con = mapDIKeyToContactAll.get(diKey);
            if (con != null) {
                di.Contact1Imported__c = con.id;
                di.Contact1ImportStatus__c = 'Matched';
            } else if (diKey != null) {
                con = new Contact();
                di.Contact1ImportStatus__c = 'Created';
            }
            mapDIKeyToContactAll.put(diKey, con);
            mapDIKeyToContact.put(diKey, con);
            
            diKey = diKeyC2(di);
            con = mapDIKeyToContactAll.get(diKey);
            if (con != null) {
                di.Contact2Imported__c = con.id;
                di.Contact2ImportStatus__c = 'Matched';
            } else if (diKey != null) {
                con = new Contact();
                di.Contact2ImportStatus__c = 'Created';
            }
            mapDIKeyToContactAll.put(diKey, con);
            mapDIKeyToContact.put(diKey, con);
        }
    }

    // utility to return the search key for a given contact.
    private string diKeyContact(Contact con) {
    	if (con == null)
    	   return null;
        return con.Firstname + '|' + con.Lastname + '|' + con.Email;
    }

    // utility to return the search key for contact1 in the given di.
    private string diKeyC1(DataImport__c di) {
    	if (di.Contact1_Firstname__c == null && di.Contact1_Lastname__c == null && di.Contact1_Personal_Email__c == null)
    	   return null;
        return di.Contact1_Firstname__c + '|' + di.Contact1_Lastname__c + '|' + di.Contact1_Personal_Email__c;
    }
    
    // utility to return the search key for contact2 in the given di.
    private string diKeyC2(DataImport__c di) {
        if (di.Contact2_Firstname__c == null && di.Contact2_Lastname__c == null && di.Contact2_Personal_Email__c == null)
            return null;
        return di.Contact2_Firstname__c + '|' + di.Contact2_Lastname__c + '|' + di.Contact2_Personal_Email__c;
    }

    //********************************************* ACCOUNTS ************************************************
    // method to handle importing or updating Account1 and Account2,
    // and setting the contacts' Primary Affiliation.
    private void importAccounts() {        

        // first, try to match our existing Accounts
        matchExistingAccounts();            
            
        // handle multiple di's referring to the same existing account
        set<string> setDIKeyUpsert = new set<string>();
        list<Account> listAccUpsert = new list<Account>();

        // create/update our A1's
        map<string, string> mapDIFieldToA1Field = mapFieldsForDIObject('Account1', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
               
            string diKey = diKeyA1(di);
            if (diKey == null)
                continue;
            Account acc = mapDIKeyToAccount.get(diKey);

            boolean isModified = false;             
            for (string strDIField : mapDIFieldToA1Field.keySet()) {
                if (di.get(strDIField) != null) {
                    acc.put(mapDIFieldToA1Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            if (isModified) {
                if (setDIKeyUpsert.add(diKey)) 
                    listAccUpsert.add(acc);
            }
        }
        upsert listAccUpsert;
            
        // update each DI with its new Account1 ID
        // and set contact's primary affiliations
        map<Id, Contact> mapConIdToConUpdate = new map<Id, Contact>();
        for (DataImport__c di: listDI) {
            if (di.Account1Imported__c == null) {
            	Account acc = mapDIKeyToAccount.get(diKeyA1(di));
            	if (acc != null) 
	                di.Account1Imported__c = acc.Id;
            }
            // set c1's primary affilation
            if (di.Account1Imported__c != null) {
            	Contact c1 = mapDIKeyToContact.get(diKeyC1(di));
                if (c1 != null) {
	                c1.Primary_Affiliation__c = di.Account1Imported__c;
	                if (mapConIdToConUpdate.get(c1.Id) == null)
	                   mapConIdToConUpdate.put(c1.Id, c1);
                }
            }            
        }
            
        // create/update our A2's
        map<string, string> mapDIFieldToA2Field = mapFieldsForDIObject('Account2', listStrDataImportFields);
        listAccUpsert.clear();
        setDIKeyUpsert.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
            
            string diKey = diKeyA2(di);
            if (diKey == null)
                continue;
            Account acc = mapDIKeyToAccount.get(diKey);

            boolean isModified = false;             
            for (string strDIField : mapDIFieldToA2Field.keySet()) {
                if (di.get(strDIField) != null) {
                    acc.put(mapDIFieldToA2Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            if (isModified) {
                if (setDIKeyUpsert.add(diKey)) 
                    listAccUpsert.add(acc);
            }
        }
        upsert listAccUpsert;

        // update each DI with its new Account2 ID
        // and set contact's primary affiliations
        for (DataImport__c di: listDI) {
            if (di.Account2Imported__c == null) {
            	Account acc = mapDIKeyToAccount.get(diKeyA2(di));
            	if (acc != null) 
                    di.Account2Imported__c = acc.Id;
            }
            // set c2's primary affilation
            if (di.Account2Imported__c != null) {
                Contact c2 = mapDIKeyToContact.get(diKeyC2(di));
                if (c2 != null) {
	                c2.Primary_Affiliation__c = di.Account2Imported__c;
	                if (mapConIdToConUpdate.get(c2.Id) == null)
	                   mapConIdToConUpdate.put(c2.Id, c2);
                }
            }            
        }
        
        // now update the Contacts to create their Affiliations
	    // unfortunately, we must manually clear these static flags since we are doing 
	    // a bunch of stuff in the same context.
	    AFFL_Affiliations_TDTM.hasRunForContacts = false;
	    AFFL_Affiliations_TDTM.hasRunForAffiliations = false;       
        update mapConIdToConUpdate.values();
    }

    // utility to return the search key for a given account.
    private string diKeyAccount(Account acc) {
    	if (acc == null)
    	   return null;
        return acc.Name;
    }

    // utility to return the search key for Account1 in the given di.
    private string diKeyA1(DataImport__c di) {
        return di.Account1_Name__c;
    }
    
    // utility to return the search key for Account2 in the given di.
    private string diKeyA2(DataImport__c di) {
        return di.Account2_Name__c;
    }

    // looks for existing Accounts that match A1 or A2, and if found,
    // updates their Id's in the Di's.
    private void matchExistingAccounts() {
    
        //UNDONE: read preference for fields to match against.
        set<string> setName = new set<string>();
        
        for (DataImport__c di : listDI) {
            // a1
            if (di.Account1_Name__c != null)
                setName.add(di.Account1_Name__c);

            // a2
            if (di.Account2_Name__c != null)
                setName.add(di.Account2_Name__c);
        }
        
        string strSoql = 'Select Id, Name from Account where ';
        strSoql += 'Name in :setName';
        list<Account> listAcc = database.query(strSoql);
        
        // put all Accounts into our map
        for (Account acc : listAcc) {
            string diKey = diKeyAccount(acc);
            mapDIKeyToAccount.put(dikey, acc);
        }        
        
        for (DataImport__c di : listDI) {
        	string diKey = diKeyA1(di);
            Account acc = mapDIKeyToAccount.get(diKey);
            if (acc != null) {
                di.Account1Imported__c = acc.id;
                di.Account1ImportStatus__c = 'Matched';
            } else if (diKey != null) {
                acc = new Account();
                di.Account1ImportStatus__c = 'Created';                
            }
            mapDIKeyToAccount.put(diKey, acc);

            diKey = diKeyA2(di);
            acc = mapDIKeyToAccount.get(diKey);
            if (acc != null) {
                di.Account2Imported__c = acc.id;
                di.Account2ImportStatus__c = 'Matched';
            } else if (diKey != null) {
                acc = new Account();
                di.Account2ImportStatus__c = 'Created';                
            }
            mapDIKeyToAccount.put(diKey, acc);
        }
    }

    //********************************************* ADDRESSES ************************************************    
    // method to create the default Household Address for each household.
    // must ensure the address doesn't already exist for the case of updating existing contacts and accounts.
    private void importAddresses() {
    	
    	// only create Home Address if it doesn't already exist on the Household.
    	// so we need to get all the households, and then get all their addresses.
        set<Id> setHHId = new set<Id>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
            Contact con = mapDIKeyToContact.get(diKeyC1(di));
            if (con != null && con.AccountId != null)
                setHHId.add(con.AccountId);
        }
        list<Address__c> listAddrExisting = [select Id, Household_Account__c, MailingStreet__c, MailingCity__c, MailingState__c,
            MailingPostalCode__c from Address__c where Household_Account__c in :setHHId];
        map<String, Id> mapHHAddrKeyToId = new map<String, Id>();
        for (Address__c addr : listAddrExisting) {
            mapHHAddrKeyToId.put(addr.Household_Account__c + addr.MailingStreet__c + addr.MailingCity__c + 
                addr.MailingState__c + addr.MailingPostalCode__c, addr.Id);
        }        
        
        map<string, string> mapDIFieldToAddrField = mapFieldsForDIObject('Address', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
 
            // only create Home Address if we have a household
            Contact con = mapDIKeyToContact.get(diKeyC1(di));
            if (con == null || con.AccountId == null)
                continue;
 
            Address__c addr = new Address__c();
            addr.Address_Type__c = 'Home';
            addr.Default_Address__c = true;
            addr.Household_Account__c = con.AccountId;
            boolean isEmpty = true;
            for (string strDIField : mapDIFieldToAddrField.keySet()) {
                if (di.get(strDIField) != null) {
                    addr.put(mapDIFieldToAddrField.get(strDIField), di.get(strDIField));
                    isEmpty = false;
                }
            }
            if (!isEmpty) {
            	// check to see if we already have this address in this hh.
            	ID idAddr = mapHHAddrKeyToId.get(addr.Household_Account__c + addr.MailingStreet__c + addr.MailingCity__c + addr.MailingState__c + addr.MailingPostalCode__c);
            	if (idAddr != null) {
            	   di.HomeAddressImported__c = idAddr;
            	   di.HomeAddressImportStatus__c = 'Matched';
            	} else {
                    mapDIIdToAddr.put(di.Id, addr);
            	}
            }
        }
        // because we have inserted contacts and accounts it the same context,
        // the address trigger flag will have been set to true.  we need to
        // reset it back to false, or else the newly inserted addresses won't
        // propogate to the hh account and contacts.
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;        
        insert mapDIIdToAddr.values();   

        // update each DI with its new home address
        for (DataImport__c di: listDI) {
            if (di.HomeAddressImported__c == null) {
                Address__c addr = mapDIIdToAddr.get(di.Id);
                if (addr != null) {
                    di.HomeAddressImported__c = addr.Id;
                    di.HomeAddressImportStatus__c = 'Created';
                }
            }
        }
    }

    //********************************************* OPPORTUNITIES ************************************************
    // method to create an new Opportunity for the specified Contact or Account
    private void importOpportunities() {
    
        // get the fields we will auto-copy
        map<string, string> mapDIFieldToOppField = mapFieldsForDIObject('Opportunity', listStrDataImportFields);

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
            integer cPropSet = 0;
            Opportunity opp = new Opportunity();
            string strOppName;
            
            // ignore this row if we've already imported an opp 
            if (di.DonationImported__c != null)
                continue;

            if (di.Donation_Donor__c == 'Contact1' || di.Donation_Donor__c == null) {
                Contact con = mapDIKeyToContact.get(diKeyC1(di));
                if (con == null) {
                    LogBDIError(di, 'Invalid Donation Donor');
                    continue;
                }                
                opp.npe01__Contact_Id_for_Role__c = con.Id;
                opp.AccountId = con.AccountId;
                strOppName = con.Firstname + ' ' + con.Lastname;
            } else if (di.Donation_Donor__c == 'Account1') {
                Account acc = mapDIKeyToAccount.get(diKeyA1(di));
                if (acc == null) {
                    LogBDIError(di, 'Invalid Donation Donor');
                    continue;
                }
                opp.accountId = acc.Id;    
                strOppName = acc.Name;            
            } else {
                LogBDIError(di, 'Invalid Donation Donor');
                continue;
            }
                
            if (di.Donation_Record_Type_Name__c != null) {
                Id idRt = UTIL_RecordTypes.GetRecordTypeId('Opportunity', di.Donation_Record_Type_Name__c);
                if (idRt == null) {
                    LogBDIError(di, 'Invalid Donation Record Type Name');
                    continue;
                }
                opp.RecordTypeId = idRt;
                strOppName += ' ' + di.Donation_Record_Type_Name__c;
            } else {
                strOppName += ' Donation';
            }
            
            if (di.Donation_Campaign_Name__c != null) {
                Id idCmp = mapStrNameToCampaignId.get(di.Donation_Campaign_Name__c);
                if (idCmp == null) {
                    LogBDIError(di, 'Invalid Donation Campaign Name');
                    continue;
                }
                opp.CampaignId = idCmp;
            }
            
            if (di.Donation_Date__c == null) {
                di.Donation_Date__c = system.today();
                cPropSet--;
            }
            
            if (di.Donation_Name__c == null) {
                di.Donation_Name__c = strOppName + ' ' + di.Donation_Date__c.format();
                cPropSet--;
            } 
                
            if (di.Donation_Stage__c == null) {
                di.Donation_Stage__c = UTIL_UnitTestData_TEST.getClosedWonStage();
                cPropSet--;
            }

            for (string strDIField : mapDIFieldToOppField.keySet()) {
                if (di.get(strDIField) != null) {
                    opp.put(mapDIFieldToOppField.get(strDIField), di.get(strDIField));
                    cPropSet++;
                }
            }
            if (cPropSet > 0)
                mapDIIdToOpp.put(di.Id, opp);
        }
        insert mapDIIdToOpp.values();
        
        // update each DI with its new opp
        for (DataImport__c di: listDI) {
            if (di.DonationImported__c == null) {
                Opportunity opp = mapDIIdToOpp.get(di.Id);
                if (opp != null) {
                    di.DonationImported__c = opp.Id;
                    di.DonationImportStatus__c = 'Created';
                }
            }
        }  
        
        // now deal with any payment child records
        updatePayments();      
    }
    
    // method to update any fields on payment objects created for the Data Import opportunities.
    private void updatePayments() {

        // need to find payment records, to add any additional info.
        map<Id, npe01__OppPayment__c> mapOppIdToPayment = new map<Id, npe01__OppPayment__c>();
        for (npe01__OppPayment__c pmt : [select Id, npe01__Opportunity__c from npe01__OppPayment__c where npe01__Opportunity__c in :mapDIIdToOpp.values()]) {
            mapOppIdToPayment.put(pmt.npe01__Opportunity__c, pmt);
        }

        // get the payment fields we will auto-copy
        map<string, string> mapDIFieldToPmtField = mapFieldsForDIObject('Payment', listStrDataImportFields);

        // update payments
        for (DataImport__c di: listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;        	
            if (di.DonationImported__c != null) {
                npe01__OppPayment__c pmt = mapOppIdToPayment.get(di.DonationImported__c);
                if (pmt != null) {
                    integer cPropSet = 0;
                    for (string strDIField : mapDIFieldToPmtField.keySet()) {
                        if (di.get(strDIField) != null) {
                            pmt.put(mapDIFieldToPmtField.get(strDIField), di.get(strDIField));
                            cPropSet++;
                        }
                    }                    
                    if (cPropSet > 0)
                        mapDIIdPmt.put(di.Id, pmt);
                }
            }
        }
        
        upsert mapDIIdPmt.values();
    }    

    //********************************************* CAMPAIGNS ************************************************
    // utility to match to existing campaigns, and create new campaigns, as needed.
    private void importCampaigns() {

        // need to find all the Campaigns that we might need
        set<string> setStrCampaign = new set<string>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;
            if (di.Donation_Campaign_Name__c != null)
                setStrCampaign.add(di.Donation_Campaign_Name__c);
        }

        // add the existing campaigns to our map
        for (Campaign cmp : [select Id, Name from Campaign where Name in :setStrCampaign]) {
            mapStrNameToCampaignId.put(cmp.Name, cmp.Id);
        }
        
        // create any new campaigns
        list<Campaign> listCmpNew = new list<Campaign>();
        for (string strName : setStrCampaign) {
            if (mapStrNameToCampaignId.get(strName) == null)
            	listCmpNew.add(new Campaign(Name=strName));
        }
        insert listCmpNew;
        
        // add the new campaigns to our map
        for (Campaign cmp : listCmpNew) {
            mapStrNameToCampaignId.put(cmp.Name, cmp.Id);
        }
            
    }

}