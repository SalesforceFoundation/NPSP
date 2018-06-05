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

    /*******************************************************************************************************
    * @description Constructor, that initializes various maps
    * @param bdi The data import service instance that invokes us
    */
    public BDI_ContactService(BDI_DataImportService bdi) {
        this.bdi = bdi;
        mapDIIdToC1 = new Map<Id, Contact>();
        mapDIIdToC2 = new Map<Id, Contact>();
        mapDIKeyToContact = new Map<String, Contact>();
    }

    /*******************************************************************************************************
    * @description cached map to get Contact1 for a DI
    */
    private Map<Id, Contact> mapDIIdToC1;

    /*******************************************************************************************************
    * @description cached map to get Contact2 for a DI
    */
    private Map<Id, Contact> mapDIIdToC2;

    /*******************************************************************************************************
    * @description map that holds multiple DIKeys for each Contact
    */
    private Map<String, Contact> mapDIKeyToContact;

    /*******************************************************************************************************
    * @description the data import service we are invoked from
    */
    private BDI_DataImportService bdi;

    /*******************************************************************************************************
    * @description map of DI Fieldnames for Contact1 to Contact fieldnames
    */
    private Map<String, String> mapDIFieldToC1Field {
        get {
            if (mapDIFieldToC1Field == null) {
                mapDIFieldToC1Field = BDI_DataImportService.mapFieldsForDIObject('Contact1', 'Contact', BDI_DataImportService.listStrDataImportFields);
            }
            return mapDIFieldToC1Field;
        }
        set;
    }

    /*******************************************************************************************************
    * @description map of DI Fieldnames for Contact2 to Contact fieldnames
    */
    private Map<String, String> mapDIFieldToC2Field {
        get {
            if (mapDIFieldToC2Field == null) {
                mapDIFieldToC2Field = BDI_DataImportService.mapFieldsForDIObject('Contact2', 'Contact', BDI_DataImportService.listStrDataImportFields);
            }
            return mapDIFieldToC2Field;
        }
        set;
    }

    /*******************************************************************************************************
    * @description handles importing or updating Contact1 and Contact2, creating their Household if none
    * exists. at completion, appropriate contact and household account lookups will be populated.
    * @return void
    */
    public void importContactsAndHouseholds() {

        // first, validate any required fields on contacts
        verifyContactData();

        // try to match our existing contacts
        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('matchExistingContacts');
        matchExistingContacts();
        pl.stop();

        if (bdi.isDryRun) {
            return;
        }

        // defer household naming until the end
        HH_HouseholdNaming.disableHouseholdNaming(true);

        Set<Id> setDIIdUpdated = updateAndSaveContacts('Contact1');
        setDIIdUpdated.addAll(updateAndSaveContacts('Contact2'));

        // now update HH Names that we deferred
        HH_HouseholdNaming.disableHouseholdNaming(false);
        Set<Id> setHHId = new Set<Id>();
        for (DataImport__c di : bdi.listDI) {
            if (setDIIdUpdated.contains(di.Id)) {
                setHHId.add(di.HouseholdAccountImported__c);
            }
        }
        if (setHHId.size() > 0) {
            HH_HouseholdNaming hn = new HH_HouseholdNaming();
            hn.UpdateNames(new List<Id>(setHHId));
        }
    }

    /*******************************************************************************************************
    * @description for every di with C1 or C2 data, make sure they have a lastname (unless SFId provided).
    * @return void
    */
    private void verifyContactData() {
        for (DataImport__c di: bdi.listDI) {
            if (isContactSpecified(di, 'Contact1') && string.isBlank(di.Contact1_Lastname__c) && di.Contact1Imported__c == null) {
                bdi.LogBDIError(di, label.bdiErrorInvalidLastname, 'Contact1ImportStatus__c');
                continue;
            }
            if (isContactSpecified(di, 'Contact2') && string.isBlank(di.Contact2_Lastname__c) && di.Contact2Imported__c == null) {
                di.Contact2_Lastname__c = di.Contact1_Lastname__c;
                if (di.Contact2_Lastname__c == null && di.Contact1Imported__c == null)
                    bdi.LogBDIError(di, label.bdiErrorInvalidLastname, 'Contact2ImportStatus__c');
            }
        }
    }

    /*******************************************************************************************************
    * @description looks to see if any of the dikey fields for the Contact are specified.
    * @param di the Data Import record
    * @param strCx specifies which contact's fields to look at; either Contact1 or Contact2
    * @return Boolean true if any of the contact's dikey fields are not empty
    */
    private boolean isContactSpecified(DataImport__c di, String strCx) {
        return di.get(strCx + 'Imported__c') != null ||
            di.get(strCx + '_Firstname__c') != null ||
            di.get(strCx + '_Lastname__c') != null ||
            di.get(strCx + '_Personal_Email__c') != null ||
            di.get(strCx + '_Work_Email__c') != null ||
            di.get(strCx + '_Alternate_Email__c') != null ||
            di.get(strCx + '_Home_Phone__c') != null ||
            di.get(strCx + '_Mobile_Phone__c') != null ||
            di.get(strCx + '_Other_Phone__c') != null ||
            di.get(strCx + '_Work_Phone__c') != null;
    }

    /*******************************************************************************************************
    * @description for each DI, updates the appropriate contact with values from the DI and then saves
    * the Contacts to the database.
    * @param strCx specifies which contact to update and save; either Contact1 or Contact2
    * @return Set<Id> the set of DI Id's that were updated
    */
    private Set<Id> updateAndSaveContacts(String strCx) {
        Set<Id> setDIIdUpdated = new Set<Id>();
        Integer iCx = strCx == 'Contact1' ? 1 : 2;

        // handle multiple di's referring to the same existing contact
        Set<String> setDIKeyUpsert = new Set<String>();
        List<Contact> listConUpsert = new List<Contact>();
        List<DataImport__c> listDIUpsert = new List<DataImport__c>();

        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, iCx);
            if (con == null)
                continue;

            boolean isModified = false;

            // make sure correct household account is specified on the Contact
            if (di.HouseholdAccountImported__c != null && di.HouseholdAccountImported__c != con.AccountId) {
                con.AccountId = di.HouseholdAccountImported__c;
                isModified = true;
            }

            // copy over all fields with data
            Map<String, String> mapDIFieldToConField = (strCx == 'Contact1') ? mapDIFieldToC1Field : mapDIFieldToC2Field;
            for (String strDIField : mapDIFieldToConField.keySet()) {
                if (BDI_DataImportService.isCopiedDIField(di, strDIField, con, mapDIFieldToConField)) {
                    isModified = true;
                }
            }

            if (isModified) {
                boolean isAlreadyAdded = false;
                // add all dikeys for the contact to make sure we don't try to upsert the contact twice
                for (String dikey : listDiKeyContact(con)) {
                    if (!setDIKeyUpsert.add(diKey))
                        isAlreadyAdded = true;
                }
                if (!isAlreadyAdded) {
                    listConUpsert.add(con);
                    listDIUpsert.add(di);
                }
            }

            // testing error handling
            if (Test.isRunningTest() && con.LastName != null && con.LastName.startsWith('FailTest'))
                con.LastName = null;
        }

        if (listConUpsert.size() > 0) {
            List<Database.UpsertResult> listUR = UTIL_DMLService.upsertRecords(listConUpsert, false);
            for (integer i = 0; i < listUR.size(); i++) {
                Database.UpsertResult ur = listUR[i];
                if (!ur.isSuccess()) {
                    bdi.LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), strCx + 'ImportStatus__c');
                } else {
                    setDIIdUpdated.add(listDIUpsert[i].Id);
                }
            }
        }

        // update each DI with its new contact ID
        Set<Id> setConId = new Set<Id>();
        for (DataImport__c di : bdi.listDI) {
            Id conId = (Id)di.get(strCx + 'Imported__c');
            if (conId == null) {
                Contact con = ContactFromDi(di, iCx);
                if (con != null) {
                    di.put(strCx + 'Imported__c', con.Id);
                    conId = con.Id;
                }
            }
            setConId.add(conId);
        }

        if (strCx == 'Contact1') {
            refreshContact1HouseholdAccounts(setConId);
        }

        return setDIIdUpdated;
    }

    /*******************************************************************************************************
    * @description requeries Contact1's, to get their possibly new Household Account, and updates the
    * Contact and DI record.
    * @return void
    */
    private void refreshContact1HouseholdAccounts(Set<Id> setConId) {
        // get the Household Accounts for C1's
        Map<Id, Id> mapC1IdToHHId = new Map<Id, Id>();
        for (Contact con : database.query(getSoqlSelectForContact() + ' WHERE Id IN :setConId')) {
            mapC1IdToHHId.put(con.Id, con.AccountId);
        }
        // store it back in C1 and the DI for later use
        for (DataImport__c di : bdi.listDI) {
            if (di.Contact1Imported__c != null) {
                Id HHId = mapC1IdToHHId.get(di.Contact1Imported__c);
                if (HHId != null) {
                    Contact con = ContactFromDi(di, 1);
                    con.AccountId = HHId;
                    di.HouseholdAccountImported__c = HHId;
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description looks for existing contacts that match C1 or C2, and if found, updates their Id's in
    * the DI's.  if not found, creates a new contact object for that DI.
    * @return void
    */
    private void matchExistingContacts() {

        loadCandidateContacts();

        // first we process c1's
        associateDIsWithMatchedOrNewContacts('Contact1');

        // before we process c2's, we want to add some "looser" keys
        // for any c2's to match against existing household members just by firstname
        addHouseholdMemberDIKeys();

        // now process c2's
        associateDIsWithMatchedOrNewContacts('Contact2');
    }

    /*******************************************************************************************************
    * @description for each DI, finds its matching Contact, or creates a new Contact, and updates our map.
    * @param strCx Contact1 or Contact2
    * @return void
    */
    private void associateDIsWithMatchedOrNewContacts(String strCx) {
        Integer iCx = strCx == 'Contact1' ? 1 : 2;

        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            List<String> listDiKey = listDIKeyCx(di, strCx);
            Contact con = ContactFromDiKeys(listDiKey);
            if (con != null) {
                if (con.Id != null && con.AccountId != null && con.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                    bdi.LogBDIError(di, label.bdiErrorNonHHAccountContact, strCx + 'ImportStatus__c');
                    continue;
                }
                di.put(strCx + 'Imported__c', con.id);
                di.put(strCx + 'ImportStatus__c', con.id != null ? bdi.statusMatchedExisting() : bdi.statusMatchedNew());
                if (con.AccountId != null && di.HouseholdAccountImported__c == null) {
                        di.HouseholdAccountImported__c = con.AccountId;
                }
            } else if (listDiKey.size() > 0) {
                con = new Contact();
                di.put(strCx + 'ImportStatus__c', bdi.statusCreatedNew());
                di.put(strCx + '_Preferred_Email__c', strPreferredEmail(di, iCx));
                di.put(strCx + '_Preferred_Phone__c', strPreferredPhone(di, iCx));

                // if no lastname specified for c2, we need to get it from c1 (which may only be implicit via Contact1_Imported)
                if (strCx == 'Contact2' && di.Contact2_Lastname__c == null) {
                    Contact con1 = ContactFromDi(di, 1);
                    di.Contact2_Lastname__c = con1.Lastname;
                }
            }

            // associate the Contact and its dikeys with the di
            setContactForDi(con, di, listDiKey, iCx);
        }
    }

    /*******************************************************************************************************
    * @description for all the household members of C1 households, add additional dikeys for them to our
    * map, to support matching of C2's to existing household members.
    * @return void
    */
    private void addHouseholdMemberDIKeys() {
        // before we process c2's, we want to add some "looser" keys
        // for any c2's to match against existing household members just by firstname
        Set<Id> setHHId = new Set<Id>();
        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 1);
            if (con != null && con.AccountId != null) {
                setHHId.add(con.AccountId);
            }
        }

        String strSoql = getSoqlSelectForContact();
        strSoql += ' WHERE AccountId IN :setHHId';
        List<Contact> listHHContacts = database.query(strSoql);
        for (Contact con : listHHContacts) {
            mapDIKeyToContact.put(con.Firstname + '|' + con.AccountId, con);
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
            for (String diKey : listDiKeyContact(con)) {
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
        // unfortunately, if middlename or suffix is enabled, we can't use the Name index; it won't
        // match against 'firstname lastname' if the Contact has a middlename or suffix, and there
        // currently is a bug in core that soql'ing on Name = 'firstname middlename lastname suffix'
        // fails to match, even though the Name field returns that full String.
        // known issue salesforce has Won't Fixed:
        // https://success.salesforce.com/issues_view?id=a1p30000000eQRxAAM
        Boolean filterOnlyByName =
                isFirstnameInContactMatchRules &&
                isLastnameInContactMatchRules &&
                !UTIL_Describe.isMiddleNameEnabled() &&
                !UTIL_Describe.isNameSuffixEnabled();

        for (DataImport__c di : bdi.listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
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

        String strSoql = getSoqlSelectForContact();
        strSoql += ' WHERE (Id IN :setSFId) ';

        if (isCustomIDInContactMatchRules && isCustomIdInContactDatatypeString) {
            strSoql += ' OR (' + bdi.diSettings.Contact_Custom_Unique_ID__c + ' IN :setCustomIDString) ';
        } else if (isCustomIDInContactMatchRules && !isCustomIdInContactDatatypeString) {
            strSoql += ' OR (' + bdi.diSettings.Contact_Custom_Unique_ID__c + ' IN :setCustomIDNumber) ';
        }

        UTIL_Finder finderByName = new UTIL_Finder(Contact.SObjectType)
            .withWhere(new UTIL_Where.FieldExpression(Contact.Name).inSet(setName));

        if (filterOnlyByName) {

            if (finderByName.isSoql()) {
                strSoql += ' OR (Name IN :setName) ';
            } else if (!setName.isEmpty()) {
                setSFId.addAll(new Map<Id, SObject>(finderByName.find()).keySet());
            }

        } else {
            String soqlConnector = ' OR (';
            String strAnd = '';

            if (finderByName.isSoql()) {
                strAnd = soqlConnector;

                if (isFirstnameInContactMatchRules) {
                    strSoql += strAnd + 'Firstname IN :setFName ';
                    strAnd = ' AND ';
                }
                if (isLastnameInContactMatchRules) {
                    strSoql += strAnd + 'Lastname IN :setLName ';
                    strAnd = ' AND ';
                }

            } else {
                UTIL_Where.GroupExpression criteria = UTIL_Where.AndGroup();
                if (isFirstnameInContactMatchRules && !setFName.isEmpty()) {
                    criteria.add(new UTIL_Where.FieldExpression(Contact.FirstName).inSet(setFName));
                }
                if (isLastnameInContactMatchRules && !setLName.isEmpty()) {
                    criteria.add(new UTIL_Where.FieldExpression(Contact.LastName).inSet(setLName));
                }

                if (!criteria.getFields().isEmpty()) {
                    UTIL_Finder finder = new UTIL_Finder(Contact.SObjectType)
                        .withWhere(new UTIL_Where().add(criteria));

                    setSFId.addAll(new Map<Id, SObject>(finder.find()).keySet());
                }
            }

            if (isEmailInContactMatchRules) {
                strAnd = String.isBlank(strAnd) ? soqlConnector : strAnd;

                strSoql += strAnd + '(' +
                    'Email IN :setEmail OR ' +
                    'npe01__AlternateEmail__c IN :setEmail OR ' +
                    'npe01__HomeEmail__c IN :setEmail OR ' +
                    'npe01__WorkEmail__c IN :setEmail) ';
                strAnd = ' AND ';
            }

            if (isPhoneInContactMatchRules) {
                strAnd = String.isBlank(strAnd) ? soqlConnector : strAnd;

                strSoql += strAnd + '(' +
                    'Phone IN :setPhone OR ' +
                    'HomePhone IN :setPhone OR ' +
                    'MobilePhone IN :setPhone OR ' +
                    'OtherPhone IN :setPhone OR ' +
                    'npo02__Formula_HouseholdPhone__c IN :setPhone OR ' +
                    'npe01__WorkPhone__c IN :setPhone)';
            }

            strSoql += String.isBlank(strAnd) ? '' : ')';
        }

        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('SOQL existing Contacts', BDI_PerfLogger.QUERY);
        List<Contact> listCon = database.query(strSoql);
        pl.stop();
        return listCon;
    }

    /*******************************************************************************************************
    * @description provides the soql String for selecting all necessary fields from Contact.
    * @return String the soql ('SELECT ... FROM Contact')
    */
    private String getSoqlSelectForContact() {
        Set<String> setContactFields = new Set<String> {
            'Id', 'Firstname', 'Lastname', 'AccountId', 'Account.npe01__SYSTEM_AccountType__c',
            UTIL_Namespace.StrTokenNSPrefix('Primary_Affiliation__c'),
            'Email', 'npe01__AlternateEmail__c', 'npe01__HomeEmail__c', 'npe01__WorkEmail__c',
            'Phone', 'HomePhone', 'MobilePhone', 'OtherPhone', 'npo02__Formula_HouseholdPhone__c', 'npe01__WorkPhone__c' };
        setContactFields.addAll(mapDIFieldToC1Field.values());
        setContactFields.addAll(mapDIFieldToC2Field.values());
        return 'SELECT ' + String.join(new List<String>(setContactFields), ',') + ' FROM Contact ';
    }

    /*******************************************************************************************************
    * @description returns the Contact's full name for use in querying
    * @param di the Data Import record
    * @param iCon 1 or 2 to specify which contact, eg Contact1 or Contact2
    * @return String the Contact's full name or null
    */
    private String getContactNameFromDi(DataImport__c di, Integer iCon) {
        String strCx = UTIL_Namespace.StrTokenNSPrefix('Contact' + String.valueOf(iCon));
        String firstname = (String)di.get(strCx + '_Firstname__c');
        String lastname = (String)di.get(strCx + '_Lastname__c');

        // note that we don't try to support middlename and suffix due to known
        // salesforce won't fix issue: https://success.salesforce.com/issues_view?id=a1p30000000eQRxAAM
        // String middlename = getMiddleName(di, strCx);
        // String suffix = getNameSuffix(di, strCx);

        String fullname = '';
        if (firstname != null) {
            fullname += firstname + ' ';
        }
        if (lastname != null) {
            fullname += lastname;
        }
        return (fullname);
    }

    /*******************************************************************************************************
    * @description adds a non-null String to the provided set
    * @param str the String value
    * @param setStr the set to add to
    * @return void
    */
    private void addStringToSet(String str, Set<String> setStr) {
        if (String.isNotBlank(str)) {
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
    * @return List<String> a list of diKeys
    */
    private List<String> listDiKeyContact(Contact con) {
        if (con == null)
            return null;

        List<String> listDiKey = new List<String>();

        // we need any Contact SFId key to always be checked first when matching
        if (con.Id != null) {
            listDiKey.add(con.Id);
        }

        // we need the Contact CustomId key to always be checked second when matching
        String strUniqueId = '';
        if (isCustomIDInContactMatchRules && (strUniqueId = bdi.strNull(con.get(bdi.diSettings.Contact_Custom_Unique_ID__c))) != '') {
            if (!isCustomIdInContactDatatypeString) {
                strUniqueId = String.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        List<String> listFName = new List<String>();
        List<String> listLName = new List<String>();
        List<String> listEmail = new List<String>();
        List<String> listPhone = new List<String>();

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
    private void addDiKeyPermutations(Set<String> setDiKey, List<String> listFname, List<String> listLName,
        List<String> listEmail, List<String> listPhone, String strUniqueId) {
        for (String strFName : listFName) {
            for (String strLName : listLName) {
                for (String strEmail : listEmail) {
                    for (String strPhone : listPhone) {
                        setDiKey.add(strFName + '|' + strLName + '|' + strEmail + '|' + strPhone + '|' + strUniqueId);
                    }
                }
            }
        }
        setDiKey.remove('||||');
    }

    /*******************************************************************************************************
    * @description return the dikeys for specified contact in the given di.
    * @param di the Data Import record
    * @param strCx specifies which contact, eg Contact1 or Contact2
    * @return List<String> the diKeys for the contact
    */
    private List<String> listDiKeyCx(DataImport__c di, String strCx) {
        BDI_PerfLogger.PerfLog pl = BDI_DataImportService.perfLogger.newPerfLog('listDiKeyCx');

        List<String> listDiKey = new List<String>();

        // we need the Contact Lookup key to always be checked first when matching
        String strUniqueId = '';
        if ((strUniqueId = bdi.strNull(di.get(strCx + 'Imported__c'))) != '') {
            listDiKey.add(strUniqueId);
            strUniqueId = '';
        }

        // we need the Contact CustomId key to always be checked second when matching
        if (isCustomIDInContactMatchRules && (strUniqueId = bdi.strNull(di.get(BDI_DataImportService.strDIContactCustomIDField(strCx, bdi.diSettings)))) != '') {
            if (!isCustomIdInContactDatatypeString) {
                strUniqueId = String.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        List<String> listFName = new List<String>();
        List<String> listLName = new List<String>();
        List<String> listEmail = new List<String>();
        List<String> listPhone = new List<String>();
        boolean addedToken = false;

        if (di.get(strCx + '_Firstname__c') != null) {
            listFName.add(String.valueOf(di.get(strCx + '_Firstname__c')));
            addedToken = true;
        }
        if (!isFirstnameInContactMatchRules || !addedToken) {
            listFName.add('');
        }

        addedToken = false;
        if (di.get(strCx + '_Lastname__c') != null) {
            listLName.add(String.valueOf(di.get(strCx + '_Lastname__c')));
            addedToken = true;
        }
        if (!isLastnameInContactMatchRules || !addedToken) {
            listLName.add('');
        }

        addedToken = false;
        if (di.get(strCx + '_Personal_Email__c') != null) {
            listEmail.add(String.valueOf(di.get(strCx + '_Personal_Email__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Work_Email__c') != null) {
            listEmail.add(String.valueOf(di.get(strCx + '_Work_Email__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Alternate_Email__c') != null) {
            listEmail.add(String.valueOf(di.get(strCx + '_Alternate_Email__c')));
            addedToken = true;
        }
        if (!isEmailInContactMatchRules || !addedToken) {
            listEmail.add('');
        }

        addedToken = false;
        if (di.get(strCx + '_Home_Phone__c') != null) {
            listPhone.add(String.valueOf(di.get(strCx + '_Home_Phone__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Mobile_Phone__c') != null) {
            listPhone.add(String.valueOf(di.get(strCx + '_Mobile_Phone__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Other_Phone__c') != null) {
            listPhone.add(String.valueOf(di.get(strCx + '_Other_Phone__c')));
            addedToken = true;
        }
        if (di.get(strCx + '_Work_Phone__c') != null) {
            listPhone.add(String.valueOf(di.get(strCx + '_Work_Phone__c')));
            addedToken = true;
        }
        if (!isPhoneInContactMatchRules || !addedToken) {
            listPhone.add('');
        }

        Set<String> setDiKey = new Set<String>();
        addDiKeyPermutations(setDiKey, listFName, listLName, ListEmail, listPhone, strUniqueId);
        listDiKey.addAll(setDiKey);

        // if we didn't create any dikey's for this di due to it not matching all constraints,
        // we have to still add a single key that this di can use to find the new contact to be created.
        if (listDiKey.size() == 0) {
            String diKey =  bdi.strNull(di.get(strCx + '_Firstname__c')) + '|' + bdi.strNull(di.get(strCx + '_Lastname__c')) + '|';

            // email
            if (di.get(strCx + '_Personal_Email__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Personal_Email__c'));
            } else if (di.get(strCx + '_Work_Email__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Work_Email__c'));
            } else if (di.get(strCx + '_Alternate_Email__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Alternate_Email__c'));
            }
            diKey += '|';

            // phone
            if (di.get(strCx + '_Home_Phone__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Home_Phone__c'));
            } else if (di.get(strCx + '_Mobile_Phone__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Mobile_Phone__c'));
            } else if (di.get(strCx + '_Other_Phone__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Other_Phone__c'));
            } else if (di.get(strCx + '_Work_Phone__c') != null) {
                diKey += String.valueOf(di.get(strCx + '_Work_Phone__c'));
            }

            diKey += '|' + strUniqueId;

            if (diKey != '||||') {
                listDiKey.add(diKey);
            }
        }

        // for c2's that we know their household, we want to add a "looser" key to match by as well.
        if (strCx == 'Contact2' && di.HouseholdAccountImported__c != null && di.get('Contact2_Firstname__c') != null) {
            listDiKey.add(di.get('Contact2_Firstname__c') + '|' + di.HouseholdAccountImported__c);
        }
        pl.stop();
        return listDiKey;
    }

    /*******************************************************************************************************
    * @description finds a contact in our map, by matching against all the contact dikeys
    * @param listDiKey list of dikey's to try to match against
    * @return Contact the found Contact
    */
    private Contact ContactFromDiKeys(List<String> listDiKey) {
        for (String diKey : listDiKey) {
            Contact con = mapDIKeyToContact.get(diKey);
            if (con != null) {
                return con;
            }
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
        Contact con;
        if (iCon == 1) {
            con = mapDIIdToC1.get(di.Id);
        } else {
            con = mapDIIdToC2.get(di.Id);
        }
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
        for (String diKey : listDiKey) {
            mapDIKeyToContact.put(diKey, con);
        }
    }

    /*******************************************************************************************************
    * @description returns the type of Preferred Email if only one email is set in the di.
    * @param di the Data Import record
    * @param iCon 1 or 2, for specifying Contact1 or Contact2
    * @return String the type of Preferred Email (Personal, Work, Alternate). null if ambiguous.
    */
    private String strPreferredEmail(DataImport__c di, integer iCon) {
        String strPreferred = null;
        String strCx = UTIL_Namespace.StrTokenNSPrefix('Contact' + String.valueOf(iCon));

        if ((strPreferred = (String)di.get(strCx + '_Preferred_Email__c')) != null) {
            return strPreferred;
        }
        if (di.get(strCx + '_Personal_Email__c') != null) {
            strPreferred = 'Personal';
        }
        if (di.get(strCx + '_Work_Email__c') != null) {
            if (strPreferred != null) {
                return null;
            }
            strPreferred = 'Work';
        }
        if (di.get(strCx + '_Alternate_Email__c') != null) {
            if (strPreferred != null) {
                return null;
            }
            strPreferred = 'Alternate';
        }
        return strPreferred;
    }

    /*******************************************************************************************************
    * @description returns the type of Preferred Phone if only one phone is set in the di.
    * @param di the Data Import record
    * @param iCon 1 or 2, for specifying Contact1 or Contact2
    * @return String the type of Preferred Phone (Personal, Work, Alternate). null if ambiguous.
    */
    private String strPreferredPhone(DataImport__c di, integer iCon) {
        String strPreferred = null;
        String strCx = UTIL_Namespace.StrTokenNSPrefix('Contact' + String.valueOf(iCon));

        if ((strPreferred = (String)di.get(strCx + '_Preferred_Phone__c')) != null) {
            return strPreferred;
        }
        if (di.get(strCx + '_Home_Phone__c') != null) {
            strPreferred = 'Home';
        }
        if (di.get(strCx + '_Work_Phone__c') != null) {
            if (strPreferred != null) {
                return null;
            }
            strPreferred = 'Work';
        }
        if (di.get(strCx + '_Mobile_Phone__c') != null) {
            if (strPreferred != null) {
                return null;
            }
            strPreferred = 'Mobile';
        }
        if (di.get(strCx + '_Other_Phone__c') != null) {
            if (strPreferred != null) {
                return null;
            }
            strPreferred = 'Other';
        }
        return strPreferred;
    }

    /*******************************************************************************************************
    * @description whether the firstname field is in our contact matching rules
    */
    private boolean isFirstnameInContactMatchRules {
        get {
            String str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '') {
                return false;
            }
            return str.contains('Firstname');
        }
    }

    /*******************************************************************************************************
    * @description whether the lastname field is in our contact matching rules
    */
    private boolean isLastnameInContactMatchRules {
        get {
            String str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '') {
                return false;
            }
            return str.contains('Lastname');
        }
    }

    /*******************************************************************************************************
    * @description whether the email field is in our contact matching rules
    */
    private boolean isEmailInContactMatchRules {
        get {
            String str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '') {
                return false;
            }
            return str.contains('Email');
        }
    }

    /*******************************************************************************************************
    * @description whether the phone field is in our contact matching rules
    */
    private boolean isPhoneInContactMatchRules {
        get {
            String str = bdi.diSettings.Contact_Matching_Rule__c;
            if (str == null || str == '') {
                return false;
            }
            return str.contains('Phone');
        }
    }

    /*******************************************************************************************************
    * @description whether the Contact Custom Unique ID field is in our contact matching rules
    */
    private boolean isCustomIdInContactMatchRules {
        get {
            String str = bdi.diSettings.Contact_Custom_Unique_ID__c;
            if (str == null || str == '') {
                return false;
            }
            return true;
        }
    }

    /*******************************************************************************************************
    * @description whether the Contact Custom Uniue ID field is a String datatype
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