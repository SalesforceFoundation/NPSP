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
    
    private Data_Import_Settings__c diSettings {
        get {
            if (diSettings == null) {
                diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
            }
            return diSettings;
        }
        private set;
    }    

    private boolean isFirstnameInContactMatchRules {
    	get {
    		string str = diSettings.Contact_Matching_Rule__c;
    		if (str == null || str == '')
                return false;
    		return str.contains('Firstname');
    	}
    }

    private boolean isLastnameInContactMatchRules {
        get {
            string str = diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Lastname');
        }
    }

    private boolean isEmailInContactMatchRules {
        get {
            string str = diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Email');
        }
    }

    private boolean isCustomIdInContactMatchRules {
        get {
            string str = diSettings.Contact_Custom_Unique_ID__c;
            if (str == null || str == '')
                return false;
            return true;
        }
    }

    private boolean isCustomIdInAccountMatchRules {
        get {
            string str = diSettings.Account_Custom_Unique_ID__c;
            if (str == null || str == '')
                return false;
            return true;
        }
    }

    // the real work gets done here!
    // given a batch of di records, process them.
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
    // from the list of DataImport Fields, which have the form DIObject.developerfieldname in the field's help text property. 
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
            Contact con = ContactFromDi(di, 1);
            if (con == null)
                continue;
            
            boolean isModified = false;                 
            for (string strDIField : mapDIFieldToC1Field.keySet()) {
                if (di.get(strDIField) != null) {
                    con.put(mapDIFieldToC1Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            
            if (isModified) {
            	boolean isAlreadyAdded = false;
            	// add all dikeys for the contact to make sure we don't try to upsert the contact twice
            	for (string dikey : listDiKeyC1(di)) {
	                if (!setDIKeyUpsert.add(diKey))
	                   isAlreadyAdded = true; 
            	}
            	if (!isAlreadyAdded)
                    listConUpsert.add(con);
            }
        }
        upsert listConUpsert;
            
        // update each DI with its new contact1 ID
        // also get all our C1 Id's in a set for further use
        set<Id> setC1Id = new set<Id>();
        for (DataImport__c di : listDI) {
            if (di.Contact1Imported__c == null) {
                Contact con = ContactFromDi(di, 1);
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
                    Contact con = ContactFromDi(di, 1);
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
            Contact con = ContactFromDi(di, 2);
            if (con == null)
                continue;
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
                boolean isAlreadyAdded = false;
                // add all dikeys for the contact to make sure we don't try to upsert the contact twice
                for (string dikey : listDiKeyC2(di)) {
                    if (!setDIKeyUpsert.add(diKey))
                       isAlreadyAdded = true; 
                }
                if (!isAlreadyAdded)
                    listConUpsert.add(con);
            }
        }
        upsert listConUpsert;
            
        // update each DI with its new contact2 ID
        for (DataImport__c di: listDI) {
            if (di.Contact2Imported__c == null) {
                Contact con = ContactFromDi(di, 2);
                if (con != null) 
                    di.Contact2Imported__c = con.Id;
            }
        }
    }

    // looks for existing contacts that match C1 or C2, and if found,
    // updates their Id's in the Di's.  if not found, creates a new
    // contact object for that di.
    private void matchExistingContacts() {
    
        set<string> setFname = new set<string>();
        set<string> setLname = new set<string>();
        set<string> setEmail = new set<string>();
        set<string> setCustomID = new set<string>();
        
        string strTestContactUniqueIdSuffix = test.isRunningTest() ? '__c' : '';
        
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
            if (di.Contact1_Work_Email__c != null)
                setEmail.add(di.Contact1_Work_Email__c);            
            if (di.Contact1_Alternate_Email__c != null)
                setEmail.add(di.Contact1_Alternate_Email__c);            
            if (isCustomIDInContactMatchRules && di.get('Contact1_' + diSettings.Contact_Custom_Unique_ID__c + strTestContactUniqueIdSuffix) != null)
                setCustomID.add(string.valueOf(di.get('Contact1_' + diSettings.Contact_Custom_Unique_ID__c + strTestContactUniqueIdSuffix)));
                
            // c2
            if (di.Contact2_Firstname__c != null)
                setFname.add(di.Contact2_Firstname__c);
            if (di.Contact2_Lastname__c != null)
                setLname.add(di.Contact2_Lastname__c);
            if (di.Contact2_Personal_Email__c != null)
                setEmail.add(di.Contact2_Personal_Email__c);            
            if (di.Contact2_Work_Email__c != null)
                setEmail.add(di.Contact1_Work_Email__c);            
            if (di.Contact2_Alternate_Email__c != null)
                setEmail.add(di.Contact1_Alternate_Email__c);            
            if (isCustomIDInContactMatchRules && di.get('Contact2_' + diSettings.Contact_Custom_Unique_ID__c + strTestContactUniqueIdSuffix) != null)
                setCustomID.add(string.valueOf(di.get('Contact2_' + diSettings.Contact_Custom_Unique_ID__c + strTestContactUniqueIdSuffix)));
        }
        
        string strSoql = 'Select Id, Firstname, Lastname, ';
        if (isCustomIDInContactMatchRules)
            strSoql += diSettings.Contact_Custom_Unique_ID__c + ', ';        
        strSoql += ' Email, npe01__AlternateEmail__c, npe01__HomeEmail__c, npe01__WorkEmail__c ';
        strSoql += ' from Contact where ';
        string strAnd = '(';
        if (isFirstnameInContactMatchRules) {
            strSoql += strAnd + ' Firstname in :setFName ';
            strAnd = ' and ';
        }
        if (isLastnameInContactMatchRules) {
            strSoql += strAnd + ' Lastname in :setLName ';
            strAnd = ' and ';
        }
        if (isEmailInContactMatchRules) {
            strSoql += strAnd + '(Email in :setEmail or npe01__AlternateEmail__c in :setEmail or npe01__HomeEmail__c in :setEmail or npe01__WorkEmail__c in :setEmail)';
            strAnd = ' and ';
        }
        if (isCustomIDInContactMatchRules) {
            strSoql += ') or (' + diSettings.Contact_Custom_Unique_ID__c + ' in :setCustomID'; 
        }
        strSoql += ')';
        
        list<Contact> listCon = database.query(strSoql);
        
        // put all potential contacts into our map
        for (Contact con : listCon) {
            for (string diKey : listDiKeyContact(con))
                mapDIKeyToContact.put(diKey, con);
        }
        
        for (DataImport__c di : listDI) {
            Contact con = ContactFromDi(di, 1);
            list<string> listDiKey = listDIKeyC1(di);
            if (con != null) {
                di.Contact1Imported__c = con.id;
                di.Contact1ImportStatus__c = 'Matched';
            } else if (listDiKey.size() > 0) {
                con = new Contact();
                di.Contact1ImportStatus__c = 'Created';
                di.Contact1_Preferred_Email__c = strPreferredEmail(di, 1);
                di.Contact1_Preferred_Phone__c = strPreferredPhone(di, 1);
            }
            // make sure all dikeys for that contact are in the map
            for (string diKey : listDiKey) 
                mapDIKeyToContact.put(diKey, con);
            
            con = ContactFromDi(di, 2);
            listDiKey = listDiKeyC2(di);
            if (con != null) {
                di.Contact2Imported__c = con.id;
                di.Contact2ImportStatus__c = 'Matched';
            } else if (listDiKey.size() > 0) {
                con = new Contact();
                di.Contact2ImportStatus__c = 'Created';
                di.Contact2_Preferred_Email__c = strPreferredEmail(di, 2);
                di.Contact2_Preferred_Phone__c = strPreferredPhone(di, 2);
            }
            // make sure all dikeys for that contact are in the map
            for (string diKey : listDiKey) 
                mapDIKeyToContact.put(diKey, con);
        }
    }

    // utility to return the Preferred Email if only one email is set in the di.
    private string strPreferredEmail(DataImport__c di, integer iCon) {
    	string strPreferred = null;
    	string strCx = UTIL_Namespace.StrTokenNSPrefix('Contact' + string.valueOf(iCon));
    	
        if (di.get(strCx + '_Preferred_Email__c') != null) {
            return string.valueOf(di.get(strCx + '_Preferred_Email__c'));
        }    
    	if (di.get(strCx + '_Personal_Email__c') != null) {
            strPreferred = 'Personal';
    	}
        if (di.get(strCx + '_Work_Email__c') != null) {
            if (strPreferred != null)
                return null;
            strPreferred = 'Work';
        }
        if (di.get(strCx + '_Alternate_Email__c') != null) {
            if (strPreferred != null)
                return null;
            strPreferred = 'Alternate';
        }
        return strPreferred;
    }
    
    // utility to return the Preferred Phone if only one phone is set in the di.
    private string strPreferredPhone(DataImport__c di, integer iCon) {
        string strPreferred = null;
        string strCx = UTIL_Namespace.StrTokenNSPrefix('Contact' + string.valueOf(iCon));
        
        if (di.get(strCx + '_Preferred_Phone__c') != null) {
            return string.valueOf(di.get(strCx + '_Preferred_Phone__c'));
        }    
        if (di.get(strCx + '_Home_Phone__c') != null) {
            strPreferred = 'Home';
        }
        if (di.get(strCx + '_Work_Phone__c') != null) {
            if (strPreferred != null)
                return null;
            strPreferred = 'Work';
        }
        if (di.get(strCx + '_Mobile_Phone__c') != null) {
            if (strPreferred != null)
                return null;
            strPreferred = 'Mobile';
        }
        if (di.get(strCx + '_Other_Phone__c') != null) {
            if (strPreferred != null)
                return null;
            strPreferred = 'Other';
        }
        return strPreferred;
    }
    
    // utility to return the dikeys for a given contact.
    private list<string> listDiKeyContact(Contact con) {
        if (con == null)
            return null;
        list<string> listDiKey = new list<string>();
        string strPrefix = '';
        if (isFirstnameInContactMatchRules) {
            strPrefix += con.Firstname;
        }
        strPrefix += '|';
        if (isLastnameInContactMatchRules) {
            strPrefix += con.Lastname;
        }
        strPrefix += '|';
        if (isEmailInContactMatchRules) {
            if (con.Email != null)
                listDiKey.add(strPrefix + con.Email);
            if (con.npe01__HomeEmail__c != null)
                listDiKey.add(strPrefix + con.npe01__HomeEmail__c);
            if (con.npe01__WorkEmail__c != null)
                listDiKey.add(strPrefix + con.npe01__WorkEmail__c);
            if (con.npe01__AlternateEmail__c != null)
                listDiKey.add(strPrefix + con.npe01__AlternateEmail__c);
        } else {
            listDiKey.add(strPrefix);
        }
        if (isCustomIDInContactMatchRules && con.get(diSettings.Contact_Custom_Unique_ID__c) != null) {
            listDiKey.add(string.valueOf(con.get(diSettings.Contact_Custom_Unique_ID__c)));
        }
        return listDiKey;
    }

    // utility to return the dikeys for contact1 in the given di.
    private list<string> listDiKeyC1(DataImport__c di) {
    	return listDiKeyCx(di, 'Contact1');
    }
    private list<string> listDiKeyC2(DataImport__c di) {
    	return listDIKeyCx(di, 'Contact2');
    }
    private list<string> listDiKeyCx(DataImport__c di, string strCx) {
        set<string> setDiKey = new set<string>(); // use set to avoid duplicate keys

        // we nee the Contact CustomId key to always be checked first when matching
        string strUnique; 
        string strTestContactUniqueIdSuffix = test.isRunningTest() ? '__c' : '';
        if (isCustomIDInContactMatchRules && (strUnique = string.valueOf(di.get(strCx + '_' + diSettings.Contact_Custom_Unique_ID__c + strTestContactUniqueIdSuffix))) != null) {
            setDiKey.add(strUnique);
        }

        // now create any other dikeys
        string strPrefix = '';
        if (isFirstnameInContactMatchRules) {
            strPrefix += di.get(strCx + '_Firstname__c');
        }
        strPrefix += '|';
        if (isLastnameInContactMatchRules) {
            strPrefix += di.get(strCx + '_Lastname__c');
        }
        strPrefix += '|';
        if (isEmailInContactMatchRules) {
        	string strEmail;
            if ((strEmail = string.valueOf(di.get(strCx + '_Personal_Email__c'))) != null)
                setDiKey.add(strPrefix + strEmail);
            if ((strEmail = string.valueOf(di.get(strCx + '_Work_Email__c'))) != null)
                setDiKey.add(strPrefix + strEmail);
            if ((strEmail = string.valueOf(di.get(strCx + '_Alternate_Email__c'))) != null)
                setDiKey.add(strPrefix + strEmail);
        } else if (strPrefix != '||') {
            setDiKey.add(strPrefix);
        }
        return new list<string>(setDiKey);        
    }
    
    // utility that finds a contact in our map, by matching against all the contact dikeys
    private Contact ContactFromDi(DataImport__c di, integer iCon) {
        for (string diKey : listDiKeyCx(di, iCon == 1 ? 'Contact1' : 'Contact2')) {
            Contact con = mapDIKeyToContact.get(diKey);
            if (con != null)
                return con;
        }
        return null;
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
               
            Account acc = AccountFromDi(di, 1);
            if (acc == null)
                continue;

            boolean isModified = false;             
            for (string strDIField : mapDIFieldToA1Field.keySet()) {
                if (di.get(strDIField) != null) {
                    acc.put(mapDIFieldToA1Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            if (isModified) {
            	boolean isAlreadyAdded = false;
            	for (string diKey : listDiKeyA1(di)) {
	                if (!setDIKeyUpsert.add(diKey))
	                   isAlreadyAdded = true;
            	}
            	if (!isAlreadyAdded) 
                    listAccUpsert.add(acc);
            }
        }
        upsert listAccUpsert;
            
        // update each DI with its new Account1 ID
        // and set contact's primary affiliations
        map<Id, Contact> mapConIdToConUpdate = new map<Id, Contact>();
        for (DataImport__c di: listDI) {
            if (di.Account1Imported__c == null) {
            	Account acc = AccountFromDi(di, 1);
            	if (acc != null) 
	                di.Account1Imported__c = acc.Id;
            }
            // set c1's primary affilation
            if (di.Account1Imported__c != null) {
            	Contact c1 = ContactFromDi(di, 1);
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
            
            Account acc = AccountFromDi(di, 2);
            if (acc == null)
                continue;

            boolean isModified = false;             
            for (string strDIField : mapDIFieldToA2Field.keySet()) {
                if (di.get(strDIField) != null) {
                    acc.put(mapDIFieldToA2Field.get(strDIField), di.get(strDIField));
                    isModified = true;
                }
            }
            if (isModified) {
                boolean isAlreadyAdded = false;
                for (string diKey : listDiKeyA2(di)) {
                    if (!setDIKeyUpsert.add(diKey))
                       isAlreadyAdded = true;
                }
                if (!isAlreadyAdded) 
                    listAccUpsert.add(acc);
            }
        }
        upsert listAccUpsert;

        // update each DI with its new Account2 ID
        // and set contact's primary affiliations
        for (DataImport__c di: listDI) {
            if (di.Account2Imported__c == null) {
            	Account acc = AccountFromDi(di, 2);
            	if (acc != null) 
                    di.Account2Imported__c = acc.Id;
            }
            // set c2's primary affilation
            if (di.Account2Imported__c != null) {
                Contact c2 = ContactFromDi(di, 2);
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

    // utility to return the dikeys for a given account.
    private list<string> listDiKeyAccount(Account acc) {
        if (acc == null)
            return null;

        list<string> listDiKey = new list<string>();
        if (isCustomIDInAccountMatchRules && acc.get(diSettings.Account_Custom_Unique_ID__c) != null) {
            listDiKey.add(string.valueOf(acc.get(diSettings.Account_Custom_Unique_ID__c)));
        }

        if (acc.Name != null)
            listDiKey.add(acc.Name);        
        return listDiKey;
    }

    // utility to return the dikeys for account1 in the given di.
    private list<string> listDiKeyA1(DataImport__c di) {
        return listDiKeyAx(di, 'Account1');
    }
    private list<string> listDiKeyA2(DataImport__c di) {
        return listDIKeyAx(di, 'Account2');
    }
    private list<string> listDiKeyAx(DataImport__c di, string strAx) {
        list<string> listDiKey = new list<string>();

        // we nee the Account CustomId key to always be checked first when matching
        string strUnique; 
        string strTestAccountUniqueIdSuffix = test.isRunningTest() ? '__c' : '';
        if (isCustomIDInAccountMatchRules && (strUnique = string.valueOf(di.get(strAx + '_' + diSettings.Account_Custom_Unique_ID__c + strTestAccountUniqueIdSuffix))) != null) {
            listDiKey.add(strUnique);
        }

        // now create any other dikeys
        string strName;
        if ((strName = string.valueOf(di.get(strAx + '_Name__c'))) != null)
            listDiKey.add(strName); 
        return listDiKey;        
    }
    
    // utility that finds an account in our map, by matching against all the account dikeys
    private Account AccountFromDi(DataImport__c di, integer iAcc) {
        for (string diKey : listDiKeyAx(di, iAcc == 1 ? 'Account1' : 'Account2')) {
            Account acc = mapDIKeyToAccount.get(diKey);
            if (acc != null)
                return acc;
        }
        return null;
    }

    // looks for existing Accounts that match A1 or A2, and if found,
    // updates their Id's in the Di's. if not found, creates a new
    // account object for that di.
    private void matchExistingAccounts() {
    
        set<string> setName = new set<string>();
        set<string> setCustomID = new set<string>();
        
        string strTestAccountUniqueIdSuffix = test.isRunningTest() ? '__c' : '';
        
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == 'Failed')
               continue;

            // a1
            if (di.Account1_Name__c != null)
                setName.add(di.Account1_Name__c);
            if (isCustomIDInAccountMatchRules && di.get('Account1_' + diSettings.Account_Custom_Unique_ID__c + strTestAccountUniqueIdSuffix) != null)
                setCustomID.add(string.valueOf(di.get('Account1_' + diSettings.Account_Custom_Unique_ID__c + strTestAccountUniqueIdSuffix)));

            // a2
            if (di.Account2_Name__c != null)
                setName.add(di.Account2_Name__c);
            if (isCustomIDInAccountMatchRules && di.get('Account2_' + diSettings.Account_Custom_Unique_ID__c + strTestAccountUniqueIdSuffix) != null)
                setCustomID.add(string.valueOf(di.get('Account2_' + diSettings.Account_Custom_Unique_ID__c + strTestAccountUniqueIdSuffix)));
        }
        
        string strSoql = 'Select Id, ';
        if (isCustomIDInAccountMatchRules)
            strSoql += diSettings.Account_Custom_Unique_ID__c + ', ';                
        strSoql += 'Name from Account where ';
        strSoql += 'Name in :setName';
        if (isCustomIDInAccountMatchRules) 
            strSoql += ' or ' + diSettings.Account_Custom_Unique_ID__c + ' in :setCustomID';     
        list<Account> listAcc = database.query(strSoql);
        
        // put all Accounts into our map
        for (Account acc : listAcc) {
            for (string diKey : listDiKeyAccount(acc))
                mapDIKeyToAccount.put(dikey, acc);
        }        
        
        for (DataImport__c di : listDI) {
            Account acc = AccountFromDi(di, 1);
            list<string> listDiKey = listDiKeyA1(di);
            if (acc != null) {
                di.Account1Imported__c = acc.id;
                di.Account1ImportStatus__c = 'Matched';
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                di.Account1ImportStatus__c = 'Created';                
            }
            // make sure all dikeys for that account are in the map
            for (string diKey : listDiKey) 
                mapDIKeyToAccount.put(diKey, acc);

            acc = AccountFromDi(di, 2);
            listDiKey = listDiKeyA2(di);
            if (acc != null) {
                di.Account2Imported__c = acc.id;
                di.Account2ImportStatus__c = 'Matched';
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                di.Account2ImportStatus__c = 'Created';                
            }
            // make sure all dikeys for that account are in the map
            for (string diKey : listDiKey) 
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
            Contact con = ContactFromDi(di, 1);
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
            Contact con = ContactFromDi(di, 1);
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

            if (di.Donation_Donor__c == 'Contact1' || (di.Donation_Donor__c == null && di.Donation_Amount__c != null)) {
                Contact con = ContactFromDi(di, 1);
                if (con == null) {
                    LogBDIError(di, 'Invalid Donation Donor');
                    continue;
                }                
                opp.npe01__Contact_Id_for_Role__c = con.Id;
                opp.AccountId = con.AccountId;
                strOppName = con.Firstname + ' ' + con.Lastname;
            } else if (di.Donation_Donor__c == 'Account1') {
                Account acc = AccountFromDi(di, 1);
                if (acc == null) {
                    LogBDIError(di, 'Invalid Donation Donor');
                    continue;
                }
                opp.accountId = acc.Id;    
                strOppName = acc.Name;            
            } else if (di.Donation_Donor__c != null) {
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
            else {
            	// clear out fields we autoset since we didn't actually create an opp.
            	di.Donation_Date__c = null;
            	di.Donation_Name__c = null;
            	di.Donation_Stage__c = null;
            }
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