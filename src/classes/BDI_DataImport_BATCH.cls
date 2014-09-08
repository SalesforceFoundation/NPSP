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
        strSoql += ' FROM DataImport__c ';
        strSoql += ' WHERE Status__c <> \'Imported\' ';         
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strSoql);
    }

    // maps to keep track of the objects we will create.
    // all are indexed by the DataImport ID
    private map<Id, Contact> mapC1 = new map<Id, Contact>();
    private map<Id, Contact> mapC2 = new map<Id, Contact>();
    private map<Id, Account> mapA1 = new map<Id, Account>();
    private map<Id, Account> mapA2 = new map<Id, Account>();
    private map<Id, Address__c> mapAddr = new map<Id, Address__c>();
    private map<Id, Opportunity> mapOpp = new map<Id, Opportunity>();

    // holds the list of DataImport records we are currently processing
    private list<DataImport__c> listDI;

    public void execute(Database.BatchableContext bc, List<DataImport__c> listDI) {

	    SavePoint sp = Database.setSavepoint();
	    
	    try {
            this.listDI = listDI;
            
            importContactsAndHouseholds();
            
            importAccounts();
            
            importAddresses();

            importOpportunities();
            
            // update final status for each DI
            for (DataImport__c di: listDI) {
                di.Status__c = 'Imported';
                di.ImportedDate__c = system.now();
            }
            
            update listDI;
	
	    } catch (Exception e) {
            // rollback the entire transaction on any failure, DML or otherwise
	        Database.rollback(sp);
	        ERR_Handler.processError(e, ERR_Handler.Context.BDI);
	        // UNDONE: need to write errors into DI's and not have that commit rolled back.
	        throw new BDIException(e.getMessage());
	    }
    }

    public class BDIException extends Exception {}
            
    public void finish(Database.BatchableContext bc) { }

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
        	list<string> strParts = strF.split('_', 3);
        	string strField;
        	if (strParts.size() == 3 && strParts[0] == strObj && strParts[1] != '' && strParts[2] != '') {
        		if (strParts[1] == 'std')
                    strField = strParts[2].replace('__c', '');
                else if (strParts[1] == 'npsp' && !UTIL_Namespace.InManagedPackage)
                    strField = strParts[2];
                else
                    strField = strParts[1] + '__' + strParts[2];
                
                mapDIFieldToObjField.put(strF, strField);
        	}
        }
        return mapDIFieldToObjField;
    }

    // looks for existing contacts that match C1 or C2, and if found,
    // updates their Id's in the Di's.
    private void matchExistingContacts() {
    
        //UNDONE: read preference for fields to match against.
        set<string> setFname = new set<string>();
        set<string> setLname = new set<string>();
        set<string> setEmail = new set<string>();
        
        for (DataImport__c di : listDI) {
            // c1
            if (di.Contact1_std_Firstname__c != null)
                setFname.add(di.Contact1_std_Firstname__c);
            if (di.Contact1_std_Lastname__c != null)
                setLname.add(di.Contact1_std_Lastname__c);
            if (di.Contact1_npe01_HomeEmail__c != null)
                setEmail.add(di.Contact1_npe01_HomeEmail__c);            

            // c2
            if (di.Contact2_std_Firstname__c != null)
                setFname.add(di.Contact2_std_Firstname__c);
            if (di.Contact2_std_Lastname__c != null)
                setLname.add(di.Contact2_std_Lastname__c);
            if (di.Contact2_npe01_HomeEmail__c != null)
                setEmail.add(di.Contact2_npe01_HomeEmail__c);            
        }
        
        string strSoql = 'Select Id, Firstname, Lastname, Email from Contact where ';
        strSoql += 'Firstname in :setFname and Lastname in :setLname and Email in :setEmail';
        list<Contact> listCon = database.query(strSoql);
        
        map<string, Id> mapKeyToContactId = new map<string, Id>();
        for (Contact con : listCon) {
            string key = con.Firstname + '|' + con.Lastname + '|' + con.Email;
            mapKeyToContactId.put(key, con.Id);
        }        
        
        for (DataImport__c di : listDI) {
            ID id = mapKeyToContactId.get(di.Contact1_std_Firstname__c + '|' + di.Contact1_std_Lastname__c + '|' + di.Contact1_npe01_HomeEmail__c);
            if (id != null) {
                di.Contact1Imported__c = id;
                di.Contact1ImportStatus__c = 'Matched';
            }
            id = mapKeyToContactId.get(di.Contact2_std_Firstname__c + '|' + di.Contact2_std_Lastname__c + '|' + di.Contact2_npe01_HomeEmail__c);
            if (id != null) {
                di.Contact2Imported__c = id;
                di.Contact2ImportStatus__c = 'Matched';
            }
        }
    }

    // method to handle importing or updating Contact1 and Contact2,
    // creating their Household if none exists.
    private void importContactsAndHouseholds() {        

        // first, try to match our existing contacts
        matchExistingContacts();            
            
        // create/update our c1's
        map<string, string> mapDIFieldToC1Field = mapFieldsForDIObject('Contact1', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            Contact con = new Contact();
            if (di.Contact1Imported__c != null)
                con.Id = di.Contact1Imported__c; 
            for (string strDIField : mapDIFieldToC1Field.keySet()) {
                if (di.get(strDIField) != null)
                    con.put(mapDIFieldToC1Field.get(strDIField), di.get(strDIField));
            }
            mapC1.put(di.Id, con);
        }
        upsert mapC1.values();
            
        // update each DI with its new contact1 ID
        // also get all our C1 Id's in a set for further use
        set<Id> setC1Id = new set<Id>();
        for (DataImport__c di: listDI) {
            if (di.Contact1Imported__c == null) {
            	Contact con = mapC1.get(di.Id);
            	if (con != null) {
	                di.Contact1Imported__c = con.Id;
                    di.Contact1ImportStatus__c = 'Created';
            	}
            }
            setC1Id.add(di.Contact1Imported__c);
        }
            
        // get the Household Accounts that were created for C1's
        map<Id, Id> mapC1IdToHHId = new map<Id, Id>();
        for (Contact con : [select Id, AccountId from Contact where Id in :setC1Id]) {
            mapC1IdToHHId.put(con.Id, con.AccountId);
        }
        // store it back in C1 for later use
        for (DataImport__c di : listDI) {
            if (di.Contact1Imported__c != null) {
                Id HHId = mapC1IdToHHId.get(di.Contact1Imported__c);
                if (HHId != null) {
                    Contact con = mapC1.get(di.Id);
                    con.AccountId = HHId;
                }
            }
        }

        // now create our c2's
        map<string, string> mapDIFieldToC2Field = mapFieldsForDIObject('Contact2', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            Contact con = new Contact();
            boolean isEmpty = true;
            if (di.Contact2Imported__c != null)
                con.Id = di.Contact2Imported__c; 
            con.AccountId = mapC1IdToHHId.get(di.Contact1Imported__c);
            for (string strDIField : mapDIFieldToC2Field.keySet()) {
                if (di.get(strDIField) != null) {
                    con.put(mapDIFieldToC2Field.get(strDIField), di.get(strDIField));
                    isEmpty = false;
                }
            }
            if (!isEmpty)
                mapC2.put(di.Id, con);
        }
        upsert mapC2.values();
            
        // update each DI with its new contact2 ID
        for (DataImport__c di: listDI) {
            if (di.Contact2Imported__c == null) {
            	Contact con = mapC2.get(di.Id);
            	if (con != null) {
	                di.Contact2Imported__c = con.Id;
                    di.Contact2ImportStatus__c = 'Created';
            	}
            }
        }
    }
            
    // method to handle importing or updating Account1 and Account2,
    // and setting the contacts' Primary Affiliation.
    private void importAccounts() {        

        // first, try to match our existing Accounts
        matchExistingAccounts();            
            
        // create/update our A1's
        map<string, string> mapDIFieldToA1Field = mapFieldsForDIObject('Account1', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            Account acc = new Account();
            boolean isEmpty = true;
            if (di.Account1Imported__c != null)
                acc.Id = di.Account1Imported__c; 
            for (string strDIField : mapDIFieldToA1Field.keySet()) {
                if (di.get(strDIField) != null) {
                    acc.put(mapDIFieldToA1Field.get(strDIField), di.get(strDIField));
                    isEmpty = false;
                }
            }
            if (!isEmpty)
                mapA1.put(di.Id, acc);
        }
        upsert mapA1.values();
            
        // update each DI with its new Account1 ID
        // and set contact's primary affiliations
        list<Contact> listConToUpdate = new list<Contact>();
        for (DataImport__c di: listDI) {
            if (di.Account1Imported__c == null) {
            	Account acc = mapA1.get(di.Id);
            	if (acc != null) {
	                di.Account1Imported__c = acc.Id;
	                di.Account1ImportStatus__c = 'Created';
            	}
            }
            // set c1's primary affilation
            if (di.Account1Imported__c != null) {
                Contact c1 = mapC1.get(di.Id);
                if (c1 != null) {
	                c1.Primary_Affiliation__c = di.Account1Imported__c;
	                listConToUpdate.add(c1);
                }
            }            
        }
            
        // create/update our A2's
        map<string, string> mapDIFieldToA2Field = mapFieldsForDIObject('Account2', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            Account acc = new Account();
            boolean isEmpty = true;
            if (di.Account2Imported__c != null)
                acc.Id = di.Account2Imported__c; 
            for (string strDIField : mapDIFieldToA2Field.keySet()) {
                if (di.get(strDIField) != null) {
                    acc.put(mapDIFieldToA2Field.get(strDIField), di.get(strDIField));
                    isEmpty = false;
                }
            }
            if (!isEmpty)
                mapA2.put(di.Id, acc);
        }
        upsert mapA2.values();
            
        // update each DI with its new Account1 ID
        // and set contact's primary affiliations
        for (DataImport__c di: listDI) {
            if (di.Account2Imported__c == null) {
            	Account acc = mapA2.get(di.Id);
            	if (acc != null) {
                    di.Account2Imported__c = acc.Id;
                    di.Account2ImportStatus__c = 'Created';
            	}
            }
            // set c2's primary affilation
            if (di.Account2Imported__c != null) {
                Contact c2 = mapC2.get(di.Id);
                if (c2 != null) {
	                c2.Primary_Affiliation__c = di.Account2Imported__c;
	                listConToUpdate.add(c2);
                }
            }            
        }
        
        // now update the Contacts to create their Affiliations
	    // unfortunately, we must manually clear these static flags since we are doing 
	    // a bunch of stuff in the same context.
	    AFFL_Affiliations_TDTM.hasRunForContacts = false;
	    AFFL_Affiliations_TDTM.hasRunForAffiliations = false;       
        update listConToUpdate;
    }

    // looks for existing Accounts that match A1 or A2, and if found,
    // updates their Id's in the Di's.
    private void matchExistingAccounts() {
    
        //UNDONE: read preference for fields to match against.
        set<string> setName = new set<string>();
        
        for (DataImport__c di : listDI) {
            // a1
            if (di.Account1_std_Name__c != null)
                setName.add(di.Account1_std_Name__c);

            // a2
            if (di.Account2_std_Name__c != null)
                setName.add(di.Account2_std_Name__c);
        }
        
        string strSoql = 'Select Id, Name from Account where ';
        strSoql += 'Name in :setName';
        list<Account> listAcc = database.query(strSoql);
        
        map<string, Id> mapKeyToAccountId = new map<string, Id>();
        for (Account acc : listAcc) {
            string key = acc.Name;
            mapKeyToAccountId.put(key, acc.Id);
        }        
        
        for (DataImport__c di : listDI) {
            ID id = mapKeyToAccountId.get(di.Account1_std_Name__c);
            if (id != null) {
                di.Account1Imported__c = id;
                di.Account1ImportStatus__c = 'Matched';
            }
            id = mapKeyToAccountId.get(di.Account2_std_Name__c);
            if (id != null) {
                di.Account2Imported__c = id;
                di.Account2ImportStatus__c = 'Matched';
            }
        }
    }
    
    // method to create the default Household Address for each household.
    // must ensure the address doesn't already exist for the case of updating existing contacts and accounts.
    private void importAddresses() {
    	
    	// only create Home Address if it doesn't already exist on the Household.
    	// so we need to get all the households, and then get all their addresses.
        set<Id> setHHId = new set<Id>();
        for (DataImport__c di : listDI) {
            Contact con = mapC1.get(di.Id);
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
        
        map<string, string> mapDIFieldToAddrField = mapFieldsForDIObject('Home', listStrDataImportFields);
        for (DataImport__c di : listDI) {
 
            // only create Home Address if we have a household
            Contact con = mapC1.get(di.Id);
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
                    mapAddr.put(di.Id, addr);
            	}
            }
        }
        insert mapAddr.values();   

        // update each DI with its new home address
        for (DataImport__c di: listDI) {
            if (di.HomeAddressImported__c == null) {
                Address__c addr = mapAddr.get(di.Id);
                if (addr != null) {
                    di.HomeAddressImported__c = addr.Id;
                    di.HomeAddressImportStatus__c = 'Created';
                }
            }
        }
    }

    // method to create an new Opportunity for the specified Contact or Account
    private void importOpportunities() {
    
        // get the fields we will auto-copy
        map<string, string> mapDIFieldToOppField = mapFieldsForDIObject('Donation', listStrDataImportFields);

        // need to find all the Campaigns that we might need
        set<string> setStrCampaign = new set<string>();
        for (DataImport__c di : listDI) {
            if (di.DonationCampaignName__c != null)
                setStrCampaign.add(di.DonationCampaignName__c);
        }
        map<string, Id> mapStrCampaignToId = new map<string, Id>();
        for (Campaign cmp : [select Id, Name from Campaign where Name in :setStrCampaign]) {
            mapStrCampaignToId.put(cmp.Name, cmp.Id);
        }

        for (DataImport__c di : listDI) {
            integer cPropSet = 0;
            Opportunity opp = new Opportunity();
            string strOppName;
            
            // ignore this row if we've already imported an opp 
            if (di.DonationImported__c != null)
                continue;

            if (di.DonationDonor__c == 'Contact1' || di.DonationDonor__c == null) {
                Contact con = mapC1.get(di.Id);
                if (con == null)
                    throw new BDIException('Invalid Donation Donor');                
                opp.npe01__Contact_Id_for_Role__c = con.Id;
                opp.AccountId = con.AccountId;
                strOppName = con.Firstname + ' ' + con.Lastname;
            } else if (di.DonationDonor__c == 'Account1') {
                Account acc = mapA1.get(di.Id);
                if (acc == null)
                    throw new BDIException('Invalid Donation Donor');
                opp.accountId = acc.Id;    
                strOppName = acc.Name;            
            } else {
                throw new BDIException('Invalid Donation Donor');
            }
                
            if (di.DonationRecordTypeName__c != null) {
                Id idRt = UTIL_RecordTypes.GetRecordTypeId('Opportunity', di.DonationRecordTypeName__c);
                if (idRt == null)
                    throw new BDIException('Invalid Donation Record Type Name');
                opp.RecordTypeId = idRt;
                strOppName += ' ' + di.DonationRecordTypeName__c;
            } else {
                strOppName += ' Donation';
            }
            
            if (di.DonationCampaignName__c != null) {
                Id idCmp = mapStrCampaignToId.get(di.DonationCampaignName__c);
                if (idCmp == null)
                    throw new BDIException('Invalid Donation Campaign Name');
                opp.CampaignId = idCmp;
            }
            
            if (di.Donation_std_CloseDate__c == null) {
                di.Donation_std_CloseDate__c = system.today();
                cPropSet--;
            }
            
            if (di.Donation_std_Name__c == null) {
                di.Donation_std_Name__c = strOppName + ' ' + di.Donation_std_CloseDate__c.format();
                cPropSet--;
            } 
                
            if (di.Donation_std_StageName__c == null) {
                di.Donation_std_StageName__c = UTIL_UnitTestData_TEST.getClosedWonStage();
                cPropSet--;
            }

            for (string strDIField : mapDIFieldToOppField.keySet()) {
                if (di.get(strDIField) != null) {
                    opp.put(mapDIFieldToOppField.get(strDIField), di.get(strDIField));
                    cPropSet++;
                }
            }
            if (cPropSet > 0)
                mapOpp.put(di.Id, opp);
        }
        insert mapOpp.values();
        
        // update each DI with its new opp
        for (DataImport__c di: listDI) {
            if (di.DonationImported__c == null) {
                Opportunity opp = mapOpp.get(di.Id);
                if (opp != null) {
                    di.DonationImported__c = opp.Id;
                    di.DonationImportStatus__c = 'Created';
                }
            }
        }
    }
}