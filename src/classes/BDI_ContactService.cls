/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @description Service class to manage Contact matching for the Batch Data Importer.
*/
public with sharing class BDI_ContactService {

    private Map<Id, Contact> mapDIIdToC1;
    private Map<Id, Contact> mapDIIdToC2;
    private Map<String, Contact> mapDIKeyToContact;
    private BDI_DataImportService bdi;

    public BDI_ContactService(BDI_DataImportService bdi) {
        this.bdi = bdi;
        mapDIIdToC1 = new Map<Id, Contact>();
        mapDIIdToC2 = new Map<Id, Contact>();
        mapDIKeyToContact = new Map<String, Contact>();
    }

    /*******************************************************************************************************
    * @description looks for existing contacts that match C1 or C2, and if found, updates their Id's in
    * the DI's.  if not found, creates a new contact object for that DI.
    * @return void
    */
    public void matchExistingContacts() {

        loadCandidateContacts();

        Set<Id> setHHId = new Set<Id>();


        // first we process c1's
        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            list<string> listDiKey = listDIKeyC1(di);
            Contact con = ContactFromDiKeys(listDiKey);
            if (con != null) {
                if (con.Id != null && con.AccountId != null && con.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                    bdi.LogBDIError(di, label.bdiErrorNonHHAccountContact, 'Contact1ImportStatus__c');
                    continue;
                }
                di.Contact1Imported__c = con.id;
                di.Contact1ImportStatus__c = label.bdiMatched;
                // remember all the existing household accounts, so we can query for and add "looser" keys for c2
                if (con.AccountId != null) {
                    setHHId.add(con.AccountId);
                    if (di.HouseholdAccountImported__c == null)
                        di.HouseholdAccountImported__c = con.AccountId;
                }
            } else if (listDiKey.size() > 0) {
                con = new Contact();
                di.Contact1ImportStatus__c = label.bdiCreated;
                di.Contact1_Preferred_Email__c = strPreferredEmail(di, 1);
                di.Contact1_Preferred_Phone__c = strPreferredPhone(di, 1);
            }

            // associate the Contact and its dikeys with the di
            setContactForDi(con, di, listDiKey, 1);
        }

        // before we process c2's, we want to add some "looser" keys
        // for any c2's to match against existing household members just by firstname
        list<Contact> listHHContacts = [select Id, Firstname, Lastname, AccountId, Account.npe01__SYSTEM_AccountType__c
        from Contact where AccountId in :setHHId];
        for (Contact con : listHHContacts) {
            mapDIKeyToContact.put(con.Firstname + '|' + con.AccountId, con);
        }

        // now process c2's
        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            list<string> listDiKey = listDiKeyC2(di);
            Contact con = ContactFromDiKeys(listDiKey);
            if (con != null) {
                if (con.Id != null && con.AccountId != null && con.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                    bdi.LogBDIError(di, label.bdiErrorNonHHAccountContact, 'Contact2ImportStatus__c');
                    continue;
                }
                di.Contact2Imported__c = con.id;
                di.Contact2ImportStatus__c = label.bdiMatched;
            } else if (listDiKey.size() > 0) {
                con = new Contact();
                di.Contact2ImportStatus__c = label.bdiCreated;
                di.Contact2_Preferred_Email__c = strPreferredEmail(di, 2);
                di.Contact2_Preferred_Phone__c = strPreferredPhone(di, 2);
                // if no lastname specified, we need to get it from c1 (which may only be implicit via Contact1_Imported)
                if (di.Contact2_Lastname__c == null) {
                    Contact con1 = ContactFromDi(di, 1);
                    di.Contact2_Lastname__c = con1.Lastname;
                }
            }
            // associate the Contact and its dikeys with the di
            setContactForDi(con, di, listDiKey, 2);
        }
    }

    /*******************************************************************************************************
    * @description queries for existing Contacts that might be a match for the DI records, and populates
    * them in contactsByDIKey.  The DIKey's can be either a Salesforce ID, Unique ID, or Name.
    * @return void
    */
    private void loadCandidateContacts() {
        List<Contact> listCon = queryCandidateContacts();

        // put all candidate contacts into our map by each dikey
        for (Contact con : listCon) {
            for (string diKey : listDiKeyContact(con)) {
                mapDIKeyToContact.put(diKey, con);
            }
        }
    }

    /*******************************************************************************************************
    * @description queries for existing Contacts that might be a match for the DI records
    * @return List<Contact> the list of candidate Contacts
    */
    private List<Contact> queryCandidateContacts() {
        Set<String> setFname = new Set<String>();
        Set<String> setLname = new Set<String>();
        Set<String> setName = new Set<String>();
        Set<String> setEmail = new Set<String>();
        Set<String> setPhone = new Set<String>();
        Set<String> setCustomIDString = new Set<String>();
        Set<Double> setCustomIDNumber = new Set<Double>();
        Set<Id> setSFId = new Set<Id>();
        Set<Id> setHHId = new Set<Id>();
        String c1CustomIDField = BDI_DataImportService.strDIContactCustomIDField('Contact1', bdi.diSettings);
        String c2CustomIDField = BDI_DataImportService.strDIContactCustomIDField('Contact2', bdi.diSettings);

        // since the npsp email fields and phone fields are not indexed, we optimize our query to just
        // filter on Name (plus Id and UniqueId) if both First and Last are included in the criteria.
        Boolean filterOnlyByName = isFirstnameInContactMatchRules && isLastnameInContactMatchRules;

        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;

            // SF Id's
            addIdToSet(di.Contact1Imported__c, setSFId);
            addIdToSet(di.Contact2Imported__c, setSFId);

            // UniqueId's
            if (isCustomIDInContactMatchRules) {
                if (isCustomIdInContactDatatypeString) {
                    addStringToSet((String)di.get(c1CustomIDField), setCustomIDString);
                    addStringToSet((String)di.get(c2CustomIDField), setCustomIDString);
                } else {
                    addDoubleToSet((Double)di.get(c1CustomIDField), setCustomIDNumber);
                    addDoubleToSet((Double)di.get(c2CustomIDField), setCustomIDNumber);
                }
            }

            if (filterOnlyByName) {
                // Names
                addStringToSet(getContactNameFromDi(di, 1), setName);
                addStringToSet(getContactNameFromDi(di, 2), setName);
            } else {
                // c1 Names, Emails, Phones
                addStringToSet(di.Contact1_Firstname__c, setFname);
                addStringToSet(di.Contact1_Lastname__c, setLname);
                addStringToSet(di.Contact1_Personal_Email__c, setEmail);
                addStringToSet(di.Contact1_Work_Email__c, setEmail);
                addStringToSet(di.Contact1_Alternate_Email__c, setEmail);
                addStringToSet(di.Contact1_Home_Phone__c, setPhone);
                addStringToSet(di.Contact1_Mobile_Phone__c, setPhone);
                addStringToSet(di.Contact1_Other_Phone__c, setPhone);
                addStringToSet(di.Contact1_Work_Phone__c, setPhone);

                // c2 Names, Emails, Phones
                addStringToSet(di.Contact2_Firstname__c, setFname);
                addStringToSet(di.Contact2_Lastname__c, setLname);
                addStringToSet(di.Contact2_Personal_Email__c, setEmail);
                addStringToSet(di.Contact2_Work_Email__c, setEmail);
                addStringToSet(di.Contact2_Alternate_Email__c, setEmail);
                addStringToSet(di.Contact2_Home_Phone__c, setPhone);
                addStringToSet(di.Contact2_Mobile_Phone__c, setPhone);
                addStringToSet(di.Contact2_Other_Phone__c, setPhone);
                addStringToSet(di.Contact2_Work_Phone__c, setPhone);
            }
        }

        String strSoql = 'SELECT Id, Firstname, Lastname, AccountId, Account.npe01__SYSTEM_AccountType__c, ';
        if (isCustomIDInContactMatchRules) {
            strSoql += bdi.diSettings.Contact_Custom_Unique_ID__c + ', ';
        }
        strSoql += ' Email, npe01__AlternateEmail__c, npe01__HomeEmail__c, npe01__WorkEmail__c, ';
        strSoql += ' Phone, HomePhone, MobilePhone, OtherPhone, npo02__Formula_HouseholdPhone__c, npe01__WorkPhone__c ';
        strSoql += ' FROM Contact WHERE ';

        if (setSFId.size() > 0) {
            strSoql += '(Id IN :setSFId) OR ';
        }

        if (isCustomIDInContactMatchRules && isCustomIdInContactDatatypeString) {
            strSoql += '(' + bdi.diSettings.Contact_Custom_Unique_ID__c + ' IN :setCustomIDString) OR ';
        } else if (isCustomIDInContactMatchRules && !isCustomIdInContactDatatypeString) {
            strSoql += '(' + bdi.diSettings.Contact_Custom_Unique_ID__c + ' IN :setCustomIDNumber) OR ';
        }

        if (filterOnlyByName) {
            strSoql += '(Name IN :setName) ';
        } else {
            string strAnd = '(';
            if (isFirstnameInContactMatchRules) {
                strSoql += strAnd + 'Firstname IN :setFName ';
                strAnd = ' AND ';
            }
            if (isLastnameInContactMatchRules) {
                strSoql += strAnd + 'Lastname IN :setLName ';
                strAnd = ' AND ';
            }
            if (isEmailInContactMatchRules) {
                strSoql += strAnd + '(' +
                    'Email IN :setEmail OR ' +
                    'npe01__AlternateEmail__c IN :setEmail OR ' +
                    'npe01__HomeEmail__c IN :setEmail OR ' +
                    'npe01__WorkEmail__c IN :setEmail) ';
                strAnd = ' AND ';
            }
            if (isPhoneInContactMatchRules) {
                strSoql += strAnd + '(' +
                    'Phone IN :setPhone OR ' +
                    'HomePhone IN :setPhone OR ' +
                    'MobilePhone IN :setPhone OR ' +
                    'OtherPhone IN :setPhone OR ' +
                    'npo02__Formula_HouseholdPhone__c IN :setPhone OR ' +
                    'npe01__WorkPhone__c IN :setPhone)';
            }
            strSoql += ')';
        }

        //system.debug('****DJH about to soql contacts: ' + strSoql);
        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('SOQL existing Contacts', BDI_PerfLogger.QUERY);
        list<Contact> listCon = database.query(strSoql);
        pl.stop();
        //system.debug('****DJH potential existing contacts: ' + listCon);
        return listCon;
    }

    /*******************************************************************************************************
    * @description return the dikeys for specified contact in the given di.
    * @param di the Data Import record
    * @param iCon 1 or 2 to specif which contact, eg Contact1 or Contact2
    * @return String the Contact's full name or null
    */
    private String getContactNameFromDi(DataImport__c di, Integer iCon) {
        String strCx = UTIL_Namespace.StrTokenNSPrefix('Contact' + string.valueOf(iCon));
        String strFname = (String)di.get(strCx + '_Firstname__c');
        String strLname = (String)di.get(strCx + '_Lastname__c');
        return (strFname != null ? strFname + ' ' + strLname : strLname);
    }

    /*******************************************************************************************************
    * @description adds a non-null string to the provided set
    * @param str the string value
    * @param setStr the set to add to
    * @return void
    */
    private void addStringToSet(String str, Set<String> setStr) {
        if (str != null) {
            setStr.add(str);
        }
    }

    /*******************************************************************************************************
    * @description adds a non-null Id to the provided set
    * @param Id the Id value
    * @param setId the set to add to
    * @return void
    */
    private void addIdToSet(Id id, Set<Id> setId) {
        if (id != null) {
            setId.add(id);
        }
    }

    /*******************************************************************************************************
    * @description adds a non-null Double to the provided set
    * @param dbl the Double value
    * @param setDbl the set to add to
    * @return void
    */
    private void addDoubleToSet(Double dbl, Set<Double> setDbl) {
        if (dbl != null) {
            setDbl.add(dbl);
        }
    }

    /*******************************************************************************************************
    Key Matching Explained

    First, we create a key which is the Salesforce Id of the Contact.
    Second, if Contact Unique Id is specified, we create a key with that unique id.
    Then we use a compound key of Contact Firstname, Lastname, Email, and Phone (with a | between each) to
    match against existing Contacts,
    and also those Contacts we are creating. We call this compound key a diKey. Our mapDIKeyToContact
    is used to lookup a given Contact from a diKey. In order to support settings that tell us which fields
    to use in the match, a given Contact can have multiple keys. Eg., if the setting is Email Only, and
    we have an existing Contact of Fred Smith fred@smith.com, then we need to support matching the following
    diKeys:
        Fred|Smith|fred@smith.com
        Fred||fred@smith.com
        |Smith|fred@smith.com
        ||fred@smith.com

    In this same example, if our DI record is John Doe john@doe.com, then its diKeys would be:
        John|Doe|john@doe.com
        John||john@doe.com
        |Doe|john@doe.com
        ||john@doe.com

    But if another DI record is just Bob Dole (no email), then we know it can't match an existing Contact
    since it has no email, but we still need to create a unique diKey for this record so that we can track
    its Contact, as well as map other DI records with the same name to the same contact.  Thus we'll create
    the diKey:
        Bob|Dole|

    So the rules can be explained as:
        Existing contacts only add the specific keys the rules can match against.
        Di's add the specific keys the rules can match against, and if none created, a single unique key

    ************/

    /*******************************************************************************************************
    * @description return all the diKeys for a given contact
    * @param con the Contact
    * @return List<string> a list of diKeys
    */
    public list<string> listDiKeyContact(Contact con) {
        if (con == null)
            return null;

        list<string> listDiKey = new list<string>();

        // we need any Contact SFId key to always be checked first when matching
        if (con.Id != null) {
            listDiKey.add(con.Id);
        }

        // we need the Contact CustomId key to always be checked second when matching
        string strUniqueId = '';
        if (isCustomIDInContactMatchRules && (strUniqueId = bdi.strNull(con.get(bdi.diSettings.Contact_Custom_Unique_ID__c))) != '') {
            if (!isCustomIdInContactDatatypeString) {
                strUniqueId = string.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        list<string> listFName = new list<string>();
        list<string> listLName = new list<string>();
        list<string> listEmail = new list<string>();
        list<string> listPhone = new list<string>();

        boolean addedToken = false;
        if (con.Firstname != null) {
            listFName.add(con.Firstname);
            addedToken = true;
        }
        if (!addedToken || !isFirstnameInContactMatchRules)
            listFName.add('');

        addedToken = false;
        if (con.Lastname != null) {
            listLName.add(con.Lastname);
            addedToken = true;
        }
        if (!addedToken || !isLastnameInContactMatchRules)
            listLName.add('');

        addedToken = false;
        if (con.Email != null) {
            listEmail.add(con.Email);
            addedToken = true;
        }
        if (con.npe01__HomeEmail__c != null) {
            listEmail.add(con.npe01__HomeEmail__c);
            addedToken = true;
        }
        if (con.npe01__WorkEmail__c != null) {
            listEmail.add(con.npe01__WorkEmail__c);
            addedToken = true;
        }
        if (con.npe01__AlternateEmail__c != null) {
            listEmail.add(con.npe01__AlternateEmail__c);
            addedToken = true;
        }
        if (!addedToken || !isEmailInContactMatchRules)
            listEmail.add('');

        addedToken = false;
        if (con.Phone != null) {
            listPhone.add(con.Phone);
            addedToken = true;
        }
        if (con.HomePhone != null) {
            listPhone.add(con.HomePhone);
            addedToken = true;
        }
        if (con.MobilePhone != null) {
            listPhone.add(con.MobilePhone);
            addedToken = true;
        }
        if (con.OtherPhone != null) {
            listPhone.add(con.OtherPhone);
            addedToken = true;
        }
        if (con.npo02__Formula_HouseholdPhone__c != null) {
            listPhone.add(con.OtherPhone);
            addedToken = true;
        }
        if (con.npe01__WorkPhone__c != null) {
            listPhone.add(con.npe01__WorkPhone__c);
            addedToken = true;
        }
        if (!addedToken || !isPhoneInContactMatchRules)
            listPhone.add('');

        Set<String> setDiKey = new Set<String>();
        addDiKeyPermutations(setDiKey, listFName, listLName, ListEmail, listPhone, strUniqueId);
        listDiKey.addAll(setDiKey);

        //system.debug('****DJH listDiKeyContact con: ' + con + ' listDIKey: ' + listDIKey);
        return listDiKey;
    }

    /*******************************************************************************************************
    * @description creates all the diKey permutations given firstname, lastname, emails, phones, unique Id's
    * and populates the passed in set of diKeys.
    * @param setDiKey the set to hold the diKeys
    * @param listFName a list of firstnames for the contact
    * @param listLName a list of lastnames for the contact
    * @param listEmail a list of Emails for the contact
    * @param listPhone a list of Phones for the contact
    * @param strUniqueId an option UniqueId value for the contact
    * @return void
    */
    private void addDiKeyPermutations(Set<String> setDiKey, list<string> listFname, list<string> listLName,
        list<string> listEmail, list<string> listPhone, string strUniqueId) {
        for (string strFName : listFName) {
            for (string strLName : listLName) {
                for (string strEmail : listEmail) {
                    for (string strPhone : listPhone) {
                        setDiKey.add(strFName + '|' + strLName + '|' + strEmail + '|' + strPhone + '|' + strUniqueId);
                    }
                }
            }
        }
        setDiKey.remove('||||');
    }

    /*******************************************************************************************************
    * @description return the dikeys for contact1 in the given di.
    * @param di the Data Import record
    * @return list<string> the diKeys for the contact
    */
    private list<string> listDiKeyC1(DataImport__c di) {
        return listDiKeyCx(di, 'Contact1');
    }

    /*******************************************************************************************************
    * @description return the dikeys for contact2 in the given di.
    * @param di the Data Import record
    * @return list<string> the diKeys for the contact
    */
    private list<string> listDiKeyC2(DataImport__c di) {
        return listDIKeyCx(di, 'Contact2');
    }

    /*******************************************************************************************************
    * @description return the dikeys for specified contact in the given di.
    * @param di the Data Import record
    * @param strCx specifies which contact, eg Contact1 or Contact2
    * @return list<string> the diKeys for the contact
    */
    private list<string> listDiKeyCx(DataImport__c di, string strCx) {
        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('listDiKeyCx');

        list<string> listDiKey = new list<string>();

        // we need the Contact Lookup key to always be checked first when matching
        string strUniqueId = '';
        if ((strUniqueId = bdi.strNull(di.get(strCx + 'Imported__c'))) != '') {
            listDiKey.add(strUniqueId);
            strUniqueId = '';
        }

        // we need the Contact CustomId key to always be checked second when matching
        if (isCustomIDInContactMatchRules && (strUniqueId = bdi.strNull(di.get(BDI_DataImportService.strDIContactCustomIDField(strCx, bdi.diSettings)))) != '') {
            if (!isCustomIdInContactDatatypeString) {
                strUniqueId = string.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        list<string> listFName = new list<string>();
        list<string> listLName = new list<string>();
        list<string> listEmail = new list<string>();
        list<string> listPhone = new list<string>();
        boolean addedToken = false;

        if (di.get(strCx + '_Firstname__c') != null) {
            listFName.add(string.valueOf(di.get(strCx + '_Firstname__c')));
            addedToken = true;
        }
        if (!isFirstnameInContactMatchRules || !addedToken)
            listFName.add('');

        addedToken = false;
        if (di.get(strCx + '_Lastname__c') != null) {
            listLName.add(string.valueOf(di.get(strCx + '_Lastname__c')));
            addedToken = true;
        }
        if (!isLastnameInContactMatchRules || !addedToken)
            listLName.add('');

        addedToken = false;
        if (di.get(strCx + '_Personal_Email__c') != null) {
            listEmail.add(string.valueOf(di.get(strCx + '_Personal_Email__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Work_Email__c') != null) {
            listEmail.add(string.valueOf(di.get(strCx + '_Work_Email__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Alternate_Email__c') != null) {
            listEmail.add(string.valueOf(di.get(strCx + '_Alternate_Email__c')));
            addedToken = true;
        }
        if (!isEmailInContactMatchRules || !addedToken)
            listEmail.add('');

        addedToken = false;
        if (di.get(strCx + '_Home_Phone__c') != null) {
            listPhone.add(string.valueOf(di.get(strCx + '_Home_Phone__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Mobile_Phone__c') != null) {
            listPhone.add(string.valueOf(di.get(strCx + '_Mobile_Phone__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Other_Phone__c') != null) {
            listPhone.add(string.valueOf(di.get(strCx + '_Other_Phone__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Work_Phone__c') != null) {
            listPhone.add(string.valueOf(di.get(strCx + '_Work_Phone__c')));
            addedToken = true;
        }
        if (!isPhoneInContactMatchRules || !addedToken)
            listPhone.add('');

        Set<String> setDiKey = new Set<String>();
        addDiKeyPermutations(setDiKey, listFName, listLName, ListEmail, listPhone, strUniqueId);
        listDiKey.addAll(setDiKey);

        // if we didn't create any dikey's for this di due to it not matching all constraints,
        // we have to still add a single key that this di can use to find the new contact to be created.
        if (listDiKey.size() == 0) {
            string diKey =  bdi.strNull(di.get(strCx + '_Firstname__c')) + '|' + bdi.strNull(di.get(strCx + '_Lastname__c')) + '|';

            // email
            if (di.get(strCx + '_Personal_Email__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Personal_Email__c'));
            else if (di.get(strCx + '_Work_Email__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Work_Email__c'));
            else if (di.get(strCx + '_Alternate_Email__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Alternate_Email__c'));
            diKey += '|';

            // phone
            if (di.get(strCx + '_Home_Phone__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Home_Phone__c'));
            else if (di.get(strCx + '_Mobile_Phone__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Mobile_Phone__c'));
            else if (di.get(strCx + '_Other_Phone__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Other_Phone__c'));
            else if (di.get(strCx + '_Work_Phone__c') != null)
                diKey += string.valueOf(di.get(strCx + '_Work_Phone__c'));

            diKey += '|' + strUniqueId;

            if (diKey != '||||')
                listDiKey.add(diKey);
        }

        // for c2's that we know their household, we want to add a "looser" key to match by as well.
        if (strCx == 'Contact2' && di.HouseholdAccountImported__c != null && di.get('Contact2_Firstname__c') != null) {
            listDiKey.add(di.get('Contact2_Firstname__c') + '|' + di.HouseholdAccountImported__c);
        }
        //system.debug('****DJH: listDiKeyCx returns: ' + listDiKey);
        pl.stop();
        return listDiKey;
    }

    /*******************************************************************************************************
    * @description finds a contact in our map, by matching against all the contact dikeys
    * @param listDiKey list of dikey's to try to match against
    * @return Contact the found Contact
    */
    private Contact ContactFromDiKeys(List<String> listDiKey) {
        for (string diKey : listDiKey) {
            Contact con = mapDIKeyToContact.get(diKey);
            if (con != null)
                return con;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description returns a contact from our cached map (so lookup is efficient)
    * @param di the Data Import record
    * @param iCon 1 specifies Contact1 otherwise use Contact2
    * @return Contact the found Contact
    */
    public Contact ContactFromDi(DataImport__c di, integer iCon) {
        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('ContactFromDi');
        Contact con;
        if (iCon == 1) {
            con = mapDIIdToC1.get(di.Id);
        } else {
            con = mapDIIdToC2.get(di.Id);
        }
        pl.stop();
        return con;
    }

    /*******************************************************************************************************
    * @description associates the Contact for Contact1 or Contact2 with the DataImport record
    * @param con the Contact
    * @param di the Data Import record
    * @param listDiKey list of dikey's for this di
    * @param iCon 1 specifies Contact1 otherwise use Contact2
    * @return void
    */
    private void setContactForDi(Contact con, DataImport__c di, List<String> listDiKey, integer iCon) {

        // put the Contact in our caching map
        if (iCon == 1) {
            mapDIIdToC1.put(di.Id, con);
        } else {
            mapDIIdToC2.put(di.Id, con);
        }

        // make sure all dikeys for that contact are in the dikey map
        for (string diKey : listDiKey) {
            mapDIKeyToContact.put(diKey, con);
        }

    }

    /*******************************************************************************************************
    * @description returns the type of Preferred Email if only one email is set in the di.
    * @param di the Data Import record
    * @param iCon 1 or 2, for specifying Contact1 or Contact2
    * @return string the type of Preferred Email (Personal, Work, Alternate). null if ambiguous.
    */
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

    /*******************************************************************************************************
    * @description returns the type of Preferred Phone if only one phone is set in the di.
    * @param di the Data Import record
    * @param iCon 1 or 2, for specifying Contact1 or Contact2
    * @return string the type of Preferred Phone (Personal, Work, Alternate). null if ambiguous.
    */
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

    /*******************************************************************************************************
    * @description whether the firstname field is in our contact matching rules
    */
    private boolean isFirstnameInContactMatchRules {
        get {
            string str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Firstname');
        }
    }

    /*******************************************************************************************************
    * @description whether the lastname field is in our contact matching rules
    */
    private boolean isLastnameInContactMatchRules {
        get {
            string str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Lastname');
        }
    }

    /*******************************************************************************************************
    * @description whether the email field is in our contact matching rules
    */
    private boolean isEmailInContactMatchRules {
        get {
            string str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Email');
        }
    }

    /*******************************************************************************************************
    * @description whether the phone field is in our contact matching rules
    */
    private boolean isPhoneInContactMatchRules {
        get {
            string str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Phone');
        }
    }

    /*******************************************************************************************************
    * @description whether the Contact Custom Unique ID field is in our contact matching rules
    */
    private boolean isCustomIdInContactMatchRules {
        get {
            string str = bdi.diSettings.Contact_Custom_Unique_ID__c;
            if (str == null || str == '')
                return false;
            return true;
        }
    }

    /*******************************************************************************************************
    * @description whether the Contact Custom Uniue ID field is a string datatype
    */
    private boolean isCustomIdInContactDatatypeString {
        get {
            if (isCustomIdInContactDatatypeString == null) {
                isCustomIdInContactDatatypeString = false;
                if (isCustomIdInContactMatchRules) {
                    Schema.Displaytype dt = UTIL_Describe.getFieldDisplaytype('Contact', bdi.diSettings.Contact_Custom_Unique_ID__c);
                    if (dt == Schema.Displaytype.String ||
                        dt == Schema.Displaytype.TextArea ||
                        dt == Schema.Displaytype.Id ||
                        dt == Schema.Displaytype.URL ||
                        dt == Schema.Displaytype.Reference)
                        isCustomIdInContactDatatypeString = true;
                }
            }
            return isCustomIdInContactDatatypeString;
        }
        set;
    }

}