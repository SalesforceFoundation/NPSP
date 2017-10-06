/*
    Copyright (c) 2014 Salesforce.org
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
* @date 2014
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Batch class for the Batch Data Importer.
*
* The Data Import Service for BDI that processes Data Import records
*
*/
global with sharing class BDI_DataImportService {

    /*******************************************************************************************************
    * @description constructor
    */
    public BDI_DataImportService() {
    }

    /*******************************************************************************************************
    * @description constructs the soql string to run a Data Import process with or without a Batch.
    * @param batchId an optional DataImportBatch to scope the records to
    * @return String the soql string
    */
    public static String strSoqlForBatchProcess(ID batchId) {
        String strSoql;

        // construct or SOQL for the batch
        strSoql = 'SELECT ' + string.join(listStrDataImportFields, ',');
        strSoql += ' FROM ' + UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        strSoql += ' WHERE Status__c <> \'' + label.bdiImported + '\' ';

        if (batchId != null) {
            strSoql += ' AND NPSP_Data_Import_Batch__c = \'' + batchId + '\'';
        } else {
            strSoql += ' AND NPSP_Data_Import_Batch__c = NULL';
        }
        // this ensures consistency for our test code, but also should
        // help users figure out import problems by importing in a consistent order.
        strSoql += ' ORDER BY Name ';
        return strSoql;
    }

    /*******************************************************************************************************
    * @description loads the data import batch.
    * @param batchId id of batch to load
    * @return DataImportBatch__c
    */
    private static DataImportBatch__c loadBatch(ID batchId) {

        list<DataImportBatch__c> listDIBatch = BDI_DataImportBatch_SEL.selectByIds(new Set<Id>{batchId});
        if (listDIBatch.size() == 1) {
            return listDIBatch[0];
        } else {
            throw(new BDIException(string.format(Label.bdiInvalidBatchId, new string[]{batchId})));
        }
    }

    /*******************************************************************************************************
    * @description loads the data import settings to use for this batch.  these may be either from
    * custom settings, or if a specific BatchId was specified, the settings specified for that batch.
    * @param batchId the batch to load settings from. if null, use custom settings.
    * @return Data_Import_Settings__c
    */
    public static Data_Import_Settings__c loadSettings(Id batchId) {

        // load up the default or specific settings
        if (batchId == null) {
            return UTIL_CustomSettingsFacade.getDataImportSettings();
        } else {
            return diSettingsFromDiBatch(loadBatch(batchId));
        }
    }

    /*******************************************************************************************************
    * @description creates a settings object from a batch object
    * @param diBatch the batch to copy fields from
    * @return Data_Import_Settings__c
    */
    public static Data_Import_Settings__c diSettingsFromDiBatch(DataImportBatch__c diBatch) {
        return new Data_Import_Settings__c(
            Account_Custom_Unique_ID__c = diBatch.Account_Custom_Unique_ID__c,
            Batch_Size__c = diBatch.Batch_Process_Size__c,
            Contact_Custom_Unique_ID__c = diBatch.Contact_Custom_Unique_ID__c,
            Contact_Matching_Rule__c = diBatch.Contact_Matching_Rule__c,
            Donation_Matching_Behavior__c = diBatch.Donation_Matching_Behavior__c,
            Donation_Matching_Implementing_Class__c = diBatch.Donation_Matching_Implementing_Class__c,
            Donation_Matching_Rule__c = diBatch.Donation_Matching_Rule__c,
            Donation_Date_Range__c = diBatch.Donation_Date_Range__c,
            Post_Process_Implementing_Class__c = diBatch.Post_Process_Implementing_Class__c
        );
    }

    /*******************************************************************************************************
    * @description creates a batch object from a settings object
    * @param diSettings the settings to copy fields from
    * @return DataImportBatch__c
    */
    public static DataImportBatch__c diBatchFromDiSettings(Data_Import_Settings__c diSettings) {
        return new DataImportBatch__c(
            Account_Custom_Unique_ID__c = diSettings.Account_Custom_Unique_ID__c,
            Batch_Process_Size__c = diSettings.Batch_Size__c,
            Contact_Custom_Unique_ID__c = diSettings.Contact_Custom_Unique_ID__c,
            Contact_Matching_Rule__c = diSettings.Contact_Matching_Rule__c,
            Donation_Matching_Behavior__c = diSettings.Donation_Matching_Behavior__c,
            Donation_Matching_Implementing_Class__c = diSettings.Donation_Matching_Implementing_Class__c,
            Donation_Matching_Rule__c = diSettings.Donation_Matching_Rule__c,
            Donation_Date_Range__c = diSettings.Donation_Date_Range__c,
            Post_Process_Implementing_Class__c = diSettings.Post_Process_Implementing_Class__c
        );
    }

    /*******************************************************************************************************
    * @description validates the Batch's data import settings.  Used by UI as well as at runtime by the batch.
    * throws an exception if there are any invalid settings.
    * @param diBatch the batch to validate
    * @return void
    */
    public static void validateSettings(DataImportBatch__c diBatch) {
        // make sure name set
        if (String.isBlank(diBatch.Name)) {
            throw(new BDIException(Label.bdiErrorBatchNameRequired));
        }
        // defer all other validation to the actual settings
        validateSettings(diSettingsFromDiBatch(diBatch));
    }

    /*******************************************************************************************************
    * @description validates the data import settings.  Used by UI as well as at runtime by the batch.
    * throws an exception if there are any invalid settings.
    * @return void
    */
    public static void validateSettings(Data_Import_Settings__c diSettings) {

        string strSettingsObj = UTIL_Namespace.StrTokenNSPrefix('Data_Import_Settings__c');
        string strDataImportObj = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');

        // validate matching rules
        if (diSettings.Donation_Matching_Behavior__c != null &&
            diSettings.Donation_Matching_Behavior__c != BDI_DataImport_API.DoNotMatch &&
            String.isBlank(diSettings.Donation_Matching_Rule__c)) {
            throw(new BDIException(Label.bdiDonationMatchingRuleEmpty));
        }

        // validate Batch Process Size
        if (diSettings.Batch_Size__c == null || diSettings.Batch_Size__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new list<String>{UTIL_Describe.getFieldLabelSafe(strSettingsObj, UTIL_Namespace.StrTokenNSPrefix('Batch_Size__c'))})));
        }

        // validate Donation Date Range
        if (diSettings.Donation_Date_Range__c < 0) {
            throw(new BDIException(string.format(Label.bdiPositiveNumber,
                new list<String>{UTIL_Describe.getFieldLabelSafe(strSettingsObj, UTIL_Namespace.StrTokenNSPrefix('Donation_Date_Range__c'))})));
        }

        // validate donation implementing class by instantiating it
        instantiateClassForInterface('BDI_IMatchDonations', diSettings.Donation_Matching_Implementing_Class__c);

        // validate post process implementing class by instantiating it
        instantiateClassForInterface('BDI_IPostProcess', diSettings.Post_Process_Implementing_Class__c);

        // ensure we are in the household account model!
        if (!CAO_Constants.isHHAccountModel())
            throw(new BDIException(Label.bdiHouseholdModelRequired));

        // validate settings
        if (diSettings.Contact_Custom_Unique_ID__c != null) {
            // make sure c1 and c2 have the appropriately named field
            string strContact1 = strDIContactCustomIDField('Contact1', diSettings);
            string strContact2 = strDIContactCustomIDField('Contact2', diSettings);

            if (!UTIL_Describe.isValidField(strDataImportObj, strContact1) ||
                !UTIL_Describe.isValidField(strDataImportObj, strContact2)) {
                throw(new BDIException(string.format(Label.bdiContactCustomIdError,
                    new string[]{diSettings.Contact_Custom_Unique_ID__c, strContact1, strContact2})));
            }
        }

        if (diSettings.Account_Custom_Unique_ID__c != null) {
            // make sure a1 and a2 have the appropriately named field
            string strAccount1 = strDIAccountCustomIDField('Account1', diSettings);
            string strAccount2 = strDIAccountCustomIDField('Account2', diSettings);

            if (!UTIL_Describe.isValidField(strDataImportObj, strAccount1) ||
                !UTIL_Describe.isValidField(strDataImportObj, strAccount2)) {
                throw(new BDIException(string.format(Label.bdiAccountCustomIdError,
                    new string[]{diSettings.Account_Custom_Unique_ID__c, strAccount1, strAccount2})));
            }
        }

        // make sure they have specified a valid Donation Matching Behavior
        set<String> setDMBehavior = new set<String> {
            BDI_DataImport_API.DoNotMatch,
            BDI_DataImport_API.RequireNoMatch,
            BDI_DataImport_API.RequireExactMatch,
            BDI_DataImport_API.ExactMatchOrCreate,
            BDI_DataImport_API.RequireBestMatch,
            BDI_DataImport_API.BestMatchOrCreate
        };
        if (!setDMBehavior.contains(diSettings.Donation_Matching_Behavior__c)) {
            throw(new BDIException(String.format(Label.bdiInvalidDonationMatchingBehavior, new String[]{diSettings.Donation_Matching_Behavior__c})));
        }
    }

    /*******************************************************************************************************
    * @description update the (optional) Batch's statistics.
    * @param apexJobId the apexJob this process was running under
    * @param batchId the Id of the batch to update
    * @return void
    */
    public static void updateDIBatchStatistics(Id apexJobId, Id batchId) {
        if (batchId != null) {
            DataImportBatch__c diBatch = loadBatch(batchId);
            integer cRecordsProcessed = [
                SELECT COUNT()
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c = :diBatch.Id
                AND ApexJobId__c = :apexJobId
            ];
            integer cRecordsSucceeded = [
                SELECT COUNT()
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c = :diBatch.Id
                AND Status__c = :label.bdiImported
                AND ApexJobId__c = :apexJobId
            ];
            integer cRecordsFailed = cRecordsProcessed - cRecordsSucceeded;

            diBatch.Last_Processed_On__c = System.now();
            diBatch.Records_Successfully_Processed__c = cRecordsSucceeded;
            diBatch.Records_Failed__c = cRecordsFailed;
            update diBatch;
        }
    }

    /*******************************************************************************************************
    * @description maps to keep track of the objects we will create.
    * all are indexed by the object's matching key or the di.Id
    */
    public map<string, Contact> mapDIKeyToContact = new map<string, Contact>();
    public map<string, Account> mapDIKeyToAccount = new map<string, Account>();
    private map<Id, Address__c> mapDIIdToAddr = new map<Id, Address__c>();
    public map<string, Id> mapStrNameToCampaignId = new map<string, Id>();

    /*******************************************************************************************************
    * @description holds the list of DataImport records we are currently processing
    */
    global list<DataImport__c> listDI;

    /*******************************************************************************************************
    * @description holds the data import settings to use for this batch.  these may be either from
    * custom settings, or if a specific BatchId was specified, the settings specified for that batch.
    */
    global Data_Import_Settings__c diSettings { get; private set; }

    /*******************************************************************************************************
    * @description whether the firstname field is in our contact matching rules
    */
    private boolean isFirstnameInContactMatchRules {
        get {
            string str = diSettings.Contact_Matching_Rule__c;
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
            string str = diSettings.Contact_Matching_Rule__c;
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
            string str = diSettings.Contact_Matching_Rule__c;
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
            string str = diSettings.Contact_Matching_Rule__c;
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
            string str = diSettings.Contact_Custom_Unique_ID__c;
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
                    Schema.Displaytype dt = UTIL_Describe.getFieldDisplaytype('Contact', diSettings.Contact_Custom_Unique_ID__c);
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

    /*******************************************************************************************************
    * @description whether the Account Custom Unique ID field is in our account matching rules
    */
    private boolean isCustomIdInAccountMatchRules {
        get {
            string str = diSettings.Account_Custom_Unique_ID__c;
            if (str == null || str == '')
                return false;
            return true;
        }
    }

    /*******************************************************************************************************
    * @description whether the Account Custom Uniue ID field is a string datatype
    */
    private boolean isCustomIdInAccountDatatypeString {
        get {
            if (isCustomIdInAccountDatatypeString == null) {
                isCustomIdInAccountDatatypeString = false;
                if (isCustomIdInAccountMatchRules) {
                    Schema.Displaytype dt = UTIL_Describe.getFieldDisplaytype('Account', diSettings.Account_Custom_Unique_ID__c);
                    if (dt == Schema.Displaytype.String ||
                        dt == Schema.Displaytype.TextArea ||
                        dt == Schema.Displaytype.Id ||
                        dt == Schema.Displaytype.URL ||
                        dt == Schema.Displaytype.Reference)
                        isCustomIdInAccountDatatypeString = true;
                }
            }
            return isCustomIdInAccountDatatypeString;
        }
        set;
    }

    /*******************************************************************************************************
    * @description coerces an object to a string value
    * @param obj an Object
    * @return String either the string value or an empty string ''
    */
    private string strNull(Object obj) {
        return strNull(string.valueOf(obj));
    }

    /*******************************************************************************************************
    * @description handles null strings to always return a valid string or empty string
    * @param str a string or null
    * @return String either the string value or an empty string ''
    */
    private string strNull(string str) {
        if (str == null)
            return '';
        else
            return str;
    }

    /*******************************************************************************************************
    * @description The real work gets done here! Given a list of di records, process them.
    * @param apexJobId the apexJob that this is executing under
    * @param diSettings the settings to control processing behavior
    * @param listDI a list of Data Import records to import
    * @return void
    */
    public static void execute(Id apexJobId, Data_Import_Settings__c diSettings, List<DataImport__c> listDI) {
        BDI_DataImportService bdi = new BDI_DataImportService();
        bdi.process(apexJobId, diSettings, listDI);
    }

    /*******************************************************************************************************
    * @description The real work gets done here! Given a list of di records, process them.
    * @param apexJobId the apexJob that this is executing under
    * @param diSettings the settings to control processing behavior
    * @param listDI a list of Data Import records to import
    * @return void
    */
    public void process(Id apexJobId, Data_Import_Settings__c diSettings, List<DataImport__c> listDI) {
        SavePoint sp = Database.setSavepoint();

        try {
            this.listDI = listDI;
            this.diSettings = diSettings;

            // first set a clean state for each DI
            for (DataImport__c di: listDI) {
                di.Status__c = null;
                di.ImportedDate__c = null;
                di.ApexJobId__c = null;
                di.FailureInformation__c = null;
            }

            importContactsAndHouseholds();

            importHouseholdAccountFields();

            importAccounts();

            importAddresses();

            importCampaigns();

            BDI_Donations bdiDonations = new BDI_Donations(this);
            bdiDonations.importDonations();

            importCampaignMembers();

            updateDIStatuses(apexJobId);

            customPostProcess();

        } catch (Exception e) {
            //UTIL_Debug.debug('****DJH Exception ' + e);

            // we should only hit this exception if a truly unexpected runtime
            // error occurs.  not even database updates/inserts should get here,
            // since we now handle all database updates/inserts using the flavor
            // of the api that allows us to specify AllOrNothing=false, and we mark
            // the failed update/inserts on the di record with the problem.
            // So go ahead and rollback the entire transaction on these totally unexpected errors.
            Database.rollback(sp);

            // log the unexpected error
            ERR_Handler.processError(e, ERR_Handler_API.Context.BDI);

            // update all the di's with errors with the error state.
            // those di's without specific errors will get the exception's error
            list<DataImport__c> listDIError = new list<DataImport__c>();
            for (DataImport__c di : listDI) {
                listDIError.add(new DataImport__c(
                    Id = di.Id,
                    Status__c = label.bdiFailed,
                    FailureInformation__c = di.Status__c == label.bdiFailed ? di.FailureInformation__c : e.getMessage(),
                    ApexJobId__c = apexJobId
                ));
            }

            update listDIError;

            // unfortunately, we can't let the system think the batch failed, or
            // then it would rollback our setting of failure state in the DI records.
            // so we just return, and rely on our Data Import ui to notify the user.
        }
    }

    /*******************************************************************************************************
    * @description updates the status of each DI record and commits them to the database
    * @return void
    */
    private void updateDIStatuses(Id apexJobId) {
        // update final status for each DI
        for (DataImport__c di: listDI) {
            if (di.Status__c == null)
                di.Status__c = label.bdiImported;
            di.ImportedDate__c = system.now();
            di.ApexJobId__c = apexJobId;

            // because a contact might be first imported in C1 location, but then moved to another
            // household since it later shows up in C2, location, we can't be assured that the
            // contact's original household account is the same (and valid). Thus we must fixup
            // all Household Account Id lookups in our di records.
            if (di.Status__c == label.bdiImported) {
                Contact c1 = ContactFromDi(di, 1);
                if (c1 != null)
                    di.HouseholdAccountImported__c = c1.AccountId;
            } else {
                di.HouseholdAccountImported__c = null;
            }

            // our matching marks non-matches with created, assuming they will get created
            // but if there were errors that stopped that creation, let's clear the status
            if (di.Contact1Imported__c == null && di.Contact1ImportStatus__c == label.bdiCreated)
                di.Contact1ImportStatus__c = null;
            if (di.Contact2Imported__c == null && di.Contact2ImportStatus__c == label.bdiCreated)
                di.Contact2ImportStatus__c = null;
            if (di.Account1Imported__c == null && di.Account1ImportStatus__c == label.bdiCreated)
                di.Account1ImportStatus__c = null;
            if (di.Account2Imported__c == null && di.Account2ImportStatus__c == label.bdiCreated)
                di.Account2ImportStatus__c = null;
        }

        //UTIL_Debug.debug('****DJH final update to listDI: ' + listDI);
        update listDI;
    }

    /*******************************************************************************************************
    * @description if the user has specified a custom post process class, invoke it with our saved
    * DI records
    * @return void
    */
    private void customPostProcess() {
        BDI_IPostProcess iPostProcess = (BDI_IPostProcess)instantiateClassForInterface('BDI_IPostProcess', diSettings.Post_Process_Implementing_Class__c);
        if (iPostProcess != null) {
            iPostProcess.process(this);
        }
    }

    /*******************************************************************************************************
    * @description instantiate a class for the provided interface
    */
    public static Object instantiateClassForInterface(String strInterface, String strClass) {

        if (strClass == null || strClass == '') {
            return null;
        }

        Type classType = Type.forName(strClass);
        if (classType != null) {
            Object classInstance = classType.newInstance();

            if (strInterface == 'BDI_IPostProcess' && classInstance instanceOf BDI_IPostProcess) {
                return classInstance;
            }

            if (strInterface == 'BDI_IMatchDonations' && classInstance instanceOf BDI_IMatchDonations) {
                return classInstance;
            }
        }
        throw new BDIException(String.format(Label.bdiErrorInvalidIMatchDonations, new list<String>{strClass, strInterface}));
    }

    /*******************************************************************************************************
    * @description Copies the specific error into the provide di.
    * @param di the DataImport record
    * @param strError the error message
    * @param strStatusField the developer name of an additional status field to save the error message in
    * @return void
    */
    public void LogBDIError(DataImport__c di, string strError, string strStatusField) {
        //system.debug('****DJH: LogBDIError di: ' + di + ' strError: ' + strError + ' field: ' + strStatusField);
        di.Status__c = label.bdiFailed;
        di.FailureInformation__c = strError;
        if (strStatusField != null)
            di.put(strStatusField, strError.left(255));
    }

    /*******************************************************************************************************
    * @description list of all the fields in the Data Import object
    */
    global static list<string> listStrDataImportFields {
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

    /*******************************************************************************************************
    * @description our exception object for Field Level Security errors.
    */
    private class flsException extends Exception {}

    /*******************************************************************************************************
    * @description our exception object for Data Import errors.
    */
    private class BDIException extends Exception {}

    /*******************************************************************************************************
    * @description flag to allow us to test out field level security exception
    */
    public static boolean failFieldLevelSecurity = false;

    /*******************************************************************************************************
    * @description returns a map of fields from the DataImport to fields for the given 'object',
    * from the list of DataImport Fields, which have the form DIObject.developerfieldname in the field's help text property.
    * @param strObj the bdi object we care about (Contact1, Contact2, Account1, etc)
    * @param strBaseObj the underlying object the bdi object is (ie, Contact, Account, etc)
    * @param listStrDIFields the DataImport fields to consider
    * @return map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    */
    global static map<string, string> mapFieldsForDIObject(string strObj, string strBaseObj, list<string> listStrDIFields) {
        map<string, string> mapDIFieldToObjField = new map<string, string>();
        for (string strF : listStrDIFields) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), strF);
            string strHelpText = dfr.getInlineHelpText();
            if (strHelpText != null && strHelpText != '') {
                list<string> strParts = strHelpText.split('\\.', 2);
                if (strParts.size() == 2 && strParts[0] == strObj && strParts[1] != '') {
                    string strField = strParts[1];
                    //if we aren't in the npsp namespace, remove those tokens from help text
                    //also removes tokens from actual detected namespace, if we happen to be
                    //in a non-npsp namespace
                    if (UTIL_Namespace.getNamespace() != 'npsp') {
                        string strFieldOld = strField;
                        strField = UTIL_Namespace.StrTokenRemoveNSPrefix(strField);

                        //if we have a detected namespace, and removed a namespace from the current field
                        //add the current namespace back in, allowing this code to run in any namespace
                        if (strField != strFieldOld && UTIL_Namespace.getNamespace() != '') {
                            strField = UTIL_Namespace.StrAllNSPrefix(strField);
                        }
                    }

                    // make sure they have permissions to modify the target field
                    // we can't do this in all tests, because many profiles won't have FLS set for all our new fields!
                    if (!Test.isRunningTest() || failFieldLevelSecurity) {
                        dfr = UTIL_Describe.getFieldDescribe(strBaseObj, strField);
                        Set<String> setAuditFields = new Set<String>{'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid'};
                        Boolean isAuditField = setAuditFields.contains(strField.toLowerCase());

                        if (failFieldLevelSecurity ||
                            dfr == null ||
                            !dfr.isCreateable() ||
                            (!isAuditField && !dfr.isUpdateable())) {
                                throw (new flsException(string.format(label.flsError, new string[]{
                                    strBaseObj + '.' + strField
                                })));
                        }
                    }

                    mapDIFieldToObjField.put(strF, strField);
                }
            }
        }
        return mapDIFieldToObjField;
    }

    /*******************************************************************************************************
    * @description Copies non-null DI field values to the destination object, given the provided mapping.
    * also explicitly ignores boolean false's, since we can't differentiate null from false.
    * @param di The DataImport record
    * @param strDIField The DI field to copy from
    * @param objDst The object to copy to
    * @param mapDIFieldToDstField The field map from a DI field to the destination field
    * @return boolean True if copied, False is not copied.
    */
    public static boolean isCopiedDIField(DataImport__c di, String strDIField, SObject objDst, map<string, string> mapDIFieldToDstField) {

        Object val = di.get(strDIField);

        // explicitly avoid updating unchecked booleans (since we can't tell the difference between null and false)
        if (val != null && val != false) {
            objDst.put(mapDIFieldToDstField.get(strDIField), val);
            return true;
        } else {
            return false;
        }
    }

    //********************************************* CONTACTS & HOUSEHOLDS ************************************************

    /*******************************************************************************************************
    * @description handles importing or updating Contact1 and Contact2, creating their Household if none
    * exists. at completion, appropriate contact and household account lookups will be popuplated.
    * @return void
    */
    private void importContactsAndHouseholds() {

        // first, validate any required fields on contacts
        verifyContactData();

        // try to match our existing contacts
        matchExistingContacts();

        // handle multiple di's referring to the same existing contact
        set<string> setDIKeyUpsert = new set<string>();
        list<Contact> listConUpsert = new list<Contact>();
        list<DataImport__c> listDIUpsert = new list<DataImport__c>();

        // create/update our c1's
        map<string, string> mapDIFieldToC1Field = mapFieldsForDIObject('Contact1', 'Contact', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 1);
            if (con == null)
                continue;

            boolean isModified = false;

            // potentially set c1's household if provided
            if (di.HouseholdAccountImported__c != null && di.HouseholdAccountImported__c != con.AccountId) {
                con.AccountId = di.HouseholdAccountImported__c;
                isModified = true;
            }

            // copy over all fields with data
            for (string strDIField : mapDIFieldToC1Field.keySet()) {
                if (isCopiedDIField(di, strDIField, con, mapDIFieldToC1Field)) {
                    isModified = true;
                }
            }

            if (isModified) {
                boolean isAlreadyAdded = false;
                // add all dikeys for the contact to make sure we don't try to upsert the contact twice
                for (string dikey : listDiKeyContact(con)) {
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
        //system.debug('****DJH about to upsert c1s: ' + listConUpsert);
        list<Database.UpsertResult> listUR = database.upsert(listConUpsert, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Contact1ImportStatus__c');
            }
        }

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

        // get the Household Accounts for C1's
        map<Id, Id> mapC1IdToHHId = new map<Id, Id>();
        for (Contact con : [select Id, AccountId from Contact where Id in :setC1Id]) {
            mapC1IdToHHId.put(con.Id, con.AccountId);
        }
        // store it back in C1 and the DI for later use
        for (DataImport__c di : listDI) {
            if (di.Contact1Imported__c != null) {
                Id HHId = mapC1IdToHHId.get(di.Contact1Imported__c);
                if (HHId != null) {
                    Contact con = ContactFromDi(di, 1);
                    con.AccountId = HHId;
                    di.HouseholdAccountImported__c = HHId;
                }
            }
        }

        // now create our c2's
        map<string, string> mapDIFieldToC2Field = mapFieldsForDIObject('Contact2', 'Contact', listStrDataImportFields);
        setDIKeyUpsert.clear();
        listConUpsert.clear();
        listDIUpsert.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 2);
            if (con == null)
                continue;

            boolean isModified = false;

            // set c2's household to match c1
            if (con.AccountId != mapC1IdToHHId.get(di.Contact1Imported__c)) {
                con.AccountId = mapC1IdToHHId.get(di.Contact1Imported__c);
                isModified = true;
            }

            // copy over all fields with data
            for (string strDIField : mapDIFieldToC2Field.keySet()) {
                if (isCopiedDIField(di, strDIField, con, mapDIFieldToC2Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                boolean isAlreadyAdded = false;
                // add all dikeys for the contact to make sure we don't try to upsert the contact twice
                for (string dikey : listDiKeyContact(con)) {
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
        //system.debug('****DJH about to upsert c2s: ' + listConUpsert);
        //system.debug('****DJH listDIUpsert: ' + listDIUpsert);
        //system.debug('****DJH setDIKeyUpsert: ' + setDIKeyUpsert);
        listUR = database.upsert(listConUpsert, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Contact2ImportStatus__c');
            }
        }

        // update each DI with its new contact2 ID
        for (DataImport__c di: listDI) {
            if (di.Contact2Imported__c == null) {
                Contact con = ContactFromDi(di, 2);
                if (con != null)
                    di.Contact2Imported__c = con.Id;
            }
        }
    }

    /*******************************************************************************************************
    * @description Imports any custom fields specified for Household Accounts
    * @return void
    */
    private void importHouseholdAccountFields() {

        // get our mapping of household custom fields
        map<string, string> mapDIFieldToHHField = mapFieldsForDIObject('Household', 'Account', listStrDataImportFields);

        // bail out if no custom fields
        if (mapDIFieldToHHField.size() == 0)
            return;

        // holds the Households that need updating
        list<Account> listAccHHUpdate = new list<Account>();
        set<Id> setHHIdUpdate = new set<Id>();
        list<DataImport__c> listDIUpdate = new list<DataImport__c>();

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            if (di.HouseholdAccountImported__c == null)
                continue;

            boolean isModified = false;
            Account accHH = new Account(Id=di.HouseholdAccountImported__c);
            for (string strDIField : mapDIFieldToHHField.keySet()) {
                if (isCopiedDIField(di, strDIField, accHH, mapDIFieldToHHField)) {
                    isModified = true;
                }
            }

            if (isModified && setHHIdUpdate.add(accHH.Id)) {
                listAccHHUpdate.add(accHH);
                listDIUpdate.add(di);
            }

        }

        //UTIL_Debug.debug('****DJH about to upsert household Accounts: ' + listAccHHUpdate);
        list<Database.UpsertResult> listUR = database.upsert(listAccHHUpdate, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpdate[i], ur.getErrors()[0].getMessage(), null);
            }
        }
    }

    /*******************************************************************************************************
    * @description for every di with C1 or C2 data, make sure they have a lastname
    * @return void
    */
    private void verifyContactData() {
        for (DataImport__c di: listDI) {
            if (isContactSpecified(di, 'Contact1') && di.Contact1_Lastname__c == null && di.Contact1Imported__c == null) {
                LogBDIError(di, label.bdiErrorInvalidLastname, 'Contact1ImportStatus__c');
                continue;
            }
            if (isContactSpecified(di, 'Contact2') && di.Contact2_Lastname__c == null && di.Contact2Imported__c == null) {
                di.Contact2_Lastname__c = di.Contact1_Lastname__c;
                if (di.Contact2_Lastname__c == null && di.Contact1Imported__c == null)
                    LogBDIError(di, label.bdiErrorInvalidLastname, 'Contact2ImportStatus__c');
            }
        }
    }

    /*******************************************************************************************************
    * @description looks to see if any of the dikey fields for the Contact are specified.
    * @param di the Data Import record
    * @param strCx specifies which contact's fields to look at; either Contact1 or Contact2
    * @return Boolean true if any of the contact's dikey fields are not empty
    */
    private boolean isContactSpecified(DataImport__c di, string strCx) {
        if (di.get(strCx + 'Imported__c') != null)
            return true;
        if (di.get(strCx + '_Firstname__c') != null)
            return true;
        if (di.get(strCx + '_Lastname__c') != null)
            return true;
        if (di.get(strCx + '_Personal_Email__c') != null)
            return true;
        if (di.get(strCx + '_Work_Email__c') != null)
            return true;
        if (di.get(strCx + '_Alternate_Email__c') != null)
            return true;
        if (di.get(strCx + '_Home_Phone__c') != null)
            return true;
        if (di.get(strCx + '_Mobile_Phone__c') != null)
            return true;
        if (di.get(strCx + '_Other_Phone__c') != null)
            return true;
        if (di.get(strCx + '_Work_Phone__c') != null)
            return true;

        // no dikey data about the contact
        return false;
    }

    /*******************************************************************************************************
    * @description returns the field name of the Contact CustomID field for contact1 or contact2 in the
    * Data Import object.
    * @param strCx  which contact to reference (Contact1 or Contact2)
    * @param diSettings the settings object to read the setting from
    * @return string
    */
    private static string strDIContactCustomIDField(string strCx, Data_Import_Settings__c diSettings) {
        return strDICustomIDField(strCx, diSettings.Contact_Custom_Unique_ID__c);
    }

    /*******************************************************************************************************
    * @description returns the field name of the Object's CustomID field in the
    * Data Import object.  The format of the setting is the full path name to the field on Object.  But
    * the Data Import field we want to return will need to be different depending on the source.  There
    * are three cases:
    *
    *   - Standard field
    *       Website => Contact1_Website__c
    *
    *   - custom field
    *       myUniqueId => Contact1_myUniqueId__c
    *
    *   - custom field that is namespaced
    *       ns__UniqueId__c => Contact1_UniqueId__c
    *       Yes, we assume that even if the object field is packaged, the DI field is not packaged,
    *       unless the namespace happens to be ours, in which case we'll return ns__Contact1_UniqueId__c
    *
    * Note that when running managed under the NPSP namespace, we don't need to add npsp__ in front of
    * the resultant field.  di.get(fieldname) works without the namespace.
    *
    * @param strObjx  which object to reference (Contact1, Contact2, Account1, Account2)
    * @param strCustomId the custom field from the object
    * @return string
    */
    @TestVisible private static string strDICustomIDField(string strObjx, string strCustomId) {
        if (strCustomId == null) {
            return null;
        }

        // handle standard fields
        if (!strCustomId.endsWith('__c')) {
            if (Test.isRunningTest()) {
                return UTIL_Namespace.StrTokenNSPrefix(strObjx + '_' + strCustomId + '__c');
            } else {
                return strObjx + '_' + strCustomId + '__c';
            }
        }

        // look for namespace
        Integer i = strCustomId.indexOf('__');
        if (i != -1 && i <> strCustomId.indexOf('__c')) {
            // is it our namespace, in which case this is probably unmanaged npsp code,
            // so any manual testing will need the namespace in the DI custom field.
            if (strCustomId.left(i).equalsIgnoreCase(UTIL_Namespace.getNamespace())) {
                return UTIL_Namespace.StrTokenNSPrefix(strObjx + '_' + strCustomId.substring(i + 2));
            } else {
                // skip namespace
                return strObjx + '_' + strCustomId.substring(i + 2);
            }
        }

        // custom fields without namespace
        return strObjx + '_' + strCustomId;
    }

    /*******************************************************************************************************
    * @description looks for existing contacts that match C1 or C2, and if found, updates their Id's in
    * the DI's.  if not found, creates a new contact object for that DI.
    * @return void
    */
    private void matchExistingContacts() {

        set<string> setFname = new set<string>();
        set<string> setLname = new set<string>();
        set<string> setEmail = new set<string>();
        set<string> setPhone = new set<string>();
        set<string> setCustomIDString = new set<string>();
        set<double> setCustomIDNumber = new set<double>();
        set<Id> setSFId = new set<Id>();
        set<Id> setHHId = new set<Id>();

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            // c1
            if (di.Contact1Imported__c != null)
                setSFId.add(di.Contact1Imported__c);
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
            if (di.Contact1_Home_Phone__c != null)
                setPhone.add(di.Contact1_Home_Phone__c);
            if (di.Contact1_Mobile_Phone__c != null)
                setPhone.add(di.Contact1_Mobile_Phone__c);
            if (di.Contact1_Other_Phone__c != null)
                setPhone.add(di.Contact1_Other_Phone__c);
            if (di.Contact1_Work_Phone__c != null)
                setPhone.add(di.Contact1_Work_Phone__c);
            if (isCustomIDInContactMatchRules) {
                object val = di.get(strDIContactCustomIDField('Contact1', diSettings));
                if (val != null) {
                    if (isCustomIdInContactDatatypeString)
                        setCustomIDString.add(string.valueOf(val));
                    else
                        setCustomIDNumber.add(double.valueOf(val));
                }
            }

            // c2
            if (di.Contact2Imported__c != null)
                setSFId.add(di.Contact2Imported__c);
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
            if (di.Contact2_Home_Phone__c != null)
                setPhone.add(di.Contact2_Home_Phone__c);
            if (di.Contact2_Mobile_Phone__c != null)
                setPhone.add(di.Contact2_Mobile_Phone__c);
            if (di.Contact2_Other_Phone__c != null)
                setPhone.add(di.Contact2_Other_Phone__c);
            if (di.Contact2_Work_Phone__c != null)
                setPhone.add(di.Contact2_Work_Phone__c);
            if (isCustomIDInContactMatchRules) {
                object val = di.get(strDIContactCustomIDField('Contact2', diSettings));
                if (val != null) {
                    if (isCustomIdInContactDatatypeString)
                        setCustomIDString.add(string.valueOf(val));
                    else
                        setCustomIDNumber.add(double.valueOf(val));
                }
            }
        }

        string strSoql = 'Select Id, Firstname, Lastname, AccountId, Account.npe01__SYSTEM_AccountType__c, ';
        if (isCustomIDInContactMatchRules)
            strSoql += diSettings.Contact_Custom_Unique_ID__c + ', ';
        strSoql += ' Email, npe01__AlternateEmail__c, npe01__HomeEmail__c, npe01__WorkEmail__c, ';
        strSoql += ' Phone, HomePhone, MobilePhone, OtherPhone, npo02__Formula_HouseholdPhone__c, npe01__WorkPhone__c ';
        strSoql += ' from Contact where ';
        if (setSFId.size() > 0) {
            strSoql += ' (Id in :setSFId) or ';
        }
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
        if (isPhoneInContactMatchRules) {
            strSoql += strAnd + '(' +
                'Phone in :setPhone or ' +
                'HomePhone in :setPhone or ' +
                'MobilePhone in :setPhone or ' +
                'OtherPhone in :setPhone or ' +
                'npo02__Formula_HouseholdPhone__c in :setPhone or ' +
                'npe01__WorkPhone__c in :setPhone )';
            strAnd = ' and ';
        }
        if (isCustomIDInContactMatchRules && isCustomIdInContactDatatypeString) {
            strSoql += ') or (' + diSettings.Contact_Custom_Unique_ID__c + ' in :setCustomIDString';
        } else if (isCustomIDInContactMatchRules && !isCustomIdInContactDatatypeString) {
            strSoql += ') or (' + diSettings.Contact_Custom_Unique_ID__c + ' in :setCustomIDNumber';
        }
        strSoql += ')';

        //system.debug('****DJH about to soql contacts: ' + strSoql);
        list<Contact> listCon = database.query(strSoql);
        //system.debug('****DJH potential existing contacts: ' + listCon);

        // put all potential contacts into our map
        for (Contact con : listCon) {
            for (string diKey : listDiKeyContact(con))
                mapDIKeyToContact.put(diKey, con);
        }
        //system.debug('****DJH after adding potential contacts mapDIKeyToContact: ' + mapDIKeyToContact);

        // first we process c1's
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 1);
            list<string> listDiKey = listDIKeyC1(di);
            //system.debug('****DJH listDiKey: ' + listDiKey);
            if (con != null) {
                if (con.Id != null && con.AccountId != null && con.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                    LogBDIError(di, label.bdiErrorNonHHAccountContact, 'Contact1ImportStatus__c');
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
            // make sure all dikeys for that contact are in the map
            for (string diKey : listDiKey)
                mapDIKeyToContact.put(diKey, con);
            //system.debug('****DJH after add di keys to mapDIKeyToContact: ' + mapDIKeyToContact);
        }

        // before we process c2's, we want to add some "looser" keys
        // for any c2's to match against existing household members just by firstname
        list<Contact> listHHContacts = [select Id, Firstname, Lastname, AccountId, Account.npe01__SYSTEM_AccountType__c
        from Contact where AccountId in :setHHId];
        for (Contact con : listHHContacts) {
            mapDIKeyToContact.put(con.Firstname + '|' + con.AccountId, con);
        }

        // now process c2's
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 2);
            list<string> listDiKey = listDiKeyC2(di);
            if (con != null) {
                if (con.Id != null && con.AccountId != null && con.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                    LogBDIError(di, label.bdiErrorNonHHAccountContact, 'Contact2ImportStatus__c');
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
            // make sure all dikeys for that contact are in the map
            for (string diKey : listDiKey)
                mapDIKeyToContact.put(diKey, con);
        }
        //system.debug('****DJH at end of MatchExistingCOntacts, mapDIKeyToContact: ' + mapDIKeyToContact);
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
    private list<string> listDiKeyContact(Contact con) {
        if (con == null)
            return null;

        list<string> listDiKey = new list<string>();

        // we need any Contact SFId key to always be checked first when matching
        if (con.Id != null) {
            listDiKey.add(con.Id);
        }

        // we need the Contact CustomId key to always be checked second when matching
        string strUniqueId = '';
        if (isCustomIDInContactMatchRules && (strUniqueId = strNull(con.get(diSettings.Contact_Custom_Unique_ID__c))) != '') {
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

        set<string> setDiKey = new set<string>();
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
    private void addDiKeyPermutations(set<string> setDiKey, list<string> listFname, list<string> listLName,
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
        list<string> listDiKey = new list<string>();

        // we need the Contact Lookup key to always be checked first when matching
        string strUniqueId = '';
        if ((strUniqueId = strNull(di.get(strCx + 'Imported__c'))) != '') {
            listDiKey.add(strUniqueId);
            strUniqueId = '';
        }

        // we need the Contact CustomId key to always be checked second when matching
        if (isCustomIDInContactMatchRules && (strUniqueId = strNull(di.get(strDIContactCustomIDField(strCx, diSettings)))) != '') {
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

        set<string> setDiKey = new set<string>();
        addDiKeyPermutations(setDiKey, listFName, listLName, ListEmail, listPhone, strUniqueId);
        listDiKey.addAll(setDiKey);

        // if we didn't create any dikey's for this di due to it not matching all constraints,
        // we have to still add a single key that this di can use to find the new contact to be created.
        if (listDiKey.size() == 0) {
            string diKey =  strNull(di.get(strCx + '_Firstname__c')) + '|' + strNull(di.get(strCx + '_Lastname__c')) + '|';

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
        return listDiKey;
    }

    /*******************************************************************************************************
    * @description finds a contact in our map, by matching against all the contact dikeys
    * @param di the Data Import record
    * @param iCon 1 specifies Contact1 otherwise use Contact2
    * @return Contact the found Contact
    */
    global Contact ContactFromDi(DataImport__c di, integer iCon) {
        for (string diKey : listDiKeyCx(di, iCon == 1 ? 'Contact1' : 'Contact2')) {
            Contact con = mapDIKeyToContact.get(diKey);
            if (con != null)
                return con;
        }
        return null;
    }

    //********************************************* ACCOUNTS ************************************************

    /*******************************************************************************************************
    * @description importing or updating Account1 and Account2, and setting the contacts' Primary Affiliation.
    * @return void
    */
    private void importAccounts() {

        // first, try to match our existing Accounts
        matchExistingAccounts();

        // handle multiple di's referring to the same existing account
        set<string> setDIKeyUpsert = new set<string>();
        list<Account> listAccUpsert = new list<Account>();
        list<DataImport__c> listDIUpsert = new list<DataImport__c>();

        // create/update our A1's
        map<string, string> mapDIFieldToA1Field = mapFieldsForDIObject('Account1', 'Account', listStrDataImportFields);
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;

            Account acc = AccountFromDi(di, 1);
            if (acc == null)
                continue;

            boolean isModified = false;
            for (string strDIField : mapDIFieldToA1Field.keySet()) {
                if (isCopiedDIField(di, strDIField, acc, mapDIFieldToA1Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                boolean isAlreadyAdded = false;
                for (string diKey : listDiKeyA1(di)) {
                    if (!setDIKeyUpsert.add(diKey))
                        isAlreadyAdded = true;
                }
                if (!isAlreadyAdded) {
                    listAccUpsert.add(acc);
                    listDIUpsert.add(di);
                }
            }
            // testing error handling
            if (Test.isRunningTest() && acc.Name != null && acc.Name.startsWith('FailTest'))
                acc.Name = null;
        }
        //upsert listAccUpsert;
        list<Database.UpsertResult> listUR = database.upsert(listAccUpsert, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Account1ImportStatus__c');
            }
        }

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
        map<string, string> mapDIFieldToA2Field = mapFieldsForDIObject('Account2', 'Account', listStrDataImportFields);
        listAccUpsert.clear();
        listDIUpsert.clear();
        setDIKeyUpsert.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;

            Account acc = AccountFromDi(di, 2);
            if (acc == null)
                continue;

            boolean isModified = false;
            for (string strDIField : mapDIFieldToA2Field.keySet()) {
                if (isCopiedDIField(di, strDIField, acc, mapDIFieldToA2Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                boolean isAlreadyAdded = false;
                for (string diKey : listDiKeyA2(di)) {
                    if (!setDIKeyUpsert.add(diKey))
                        isAlreadyAdded = true;
                }
                if (!isAlreadyAdded) {
                    listAccUpsert.add(acc);
                    listDIUpsert.add(di);
                }
            }
            // testing error handling
            if (Test.isRunningTest() && acc.Name != null && acc.Name.startsWith('FailTest'))
                acc.Name = null;
        }
        //upsert listAccUpsert;
        listUR = database.upsert(listAccUpsert, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Account2ImportStatus__c');
            }
        }

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
        update mapConIdToConUpdate.values();
    }

    /*******************************************************************************************************
    * @description returns the field name of the Account CustomID field for Account1 or Account2 in the
    * Data Import object.
    * @param strAx  which account to reference (account1 or account2)
    * @param diSettings the settings object to read the setting from
    * @return string
    */
    private static string strDIAccountCustomIDField(string strAx, Data_Import_Settings__c diSettings) {
        return strDICustomIDField(strAx, diSettings.Account_Custom_Unique_ID__c);
    }

    /*******************************************************************************************************
    * @description return all the diKeys for a given Account
    * @param acc the Account
    * @return List<string> a list of diKeys
    */
    private list<string> listDiKeyAccount(Account acc) {
        if (acc == null)
            return null;

        list<string> listDiKey = new list<string>();

        // we need any Account SFId key to always be checked first when matching
        if (acc.Id != null) {
            listDiKey.add(acc.Id);
        }

        // we need the Account CustomId key to always be checked second when matching
        string strUniqueId = '';
        if (isCustomIDInAccountMatchRules && (strUniqueId = strNull(acc.get(diSettings.Account_Custom_Unique_ID__c))) != '') {
            if (!isCustomIdInAccountDatatypeString) {
                strUniqueId = string.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        if (acc.Name != null)
            listDiKey.add(acc.Name + '|' + strUniqueId);
        return listDiKey;
    }

    /*******************************************************************************************************
    * @description return the dikeys for Account1 in the given di.
    * @param di the Data Import record
    * @return list<string> the diKeys for the account
    */
    private list<string> listDiKeyA1(DataImport__c di) {
        return listDiKeyAx(di, 'Account1');
    }

    /*******************************************************************************************************
    * @description return the dikeys for Account2 in the given di.
    * @param di the Data Import record
    * @return list<string> the diKeys for the account
    */
    private list<string> listDiKeyA2(DataImport__c di) {
        return listDIKeyAx(di, 'Account2');
    }

    /*******************************************************************************************************
    * @description return the dikeys for specified Account in the given di.
    * @param di the Data Import record
    * @param strAx specifies which Account, eg Account1 or Account2
    * @return list<string> the diKeys for the Account
    */
    private list<string> listDiKeyAx(DataImport__c di, string strAx) {
        list<string> listDiKey = new list<string>();

        // we need the Account Lookup key to always be checked first when matching
        string strUniqueId = '';
        if ((strUniqueId = strNull(di.get(strAx + 'Imported__c'))) != '') {
            listDiKey.add(strUniqueId);
            strUniqueId = '';
        }

        // we need the Account CustomId key to always be checked second when matching
        if (isCustomIDInAccountMatchRules && (strUniqueId = strNull(di.get(strDIAccountCustomIDField(strAx, diSettings)))) != '') {
            if (!isCustomIdInAccountDatatypeString) {
                strUniqueId = string.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        // now create any other dikeys
        string strName;
        if ((strName = string.valueOf(di.get(strAx + '_Name__c'))) != null)
            listDiKey.add(strName + '|' + strUniqueId);
        return listDiKey;
    }

    /*******************************************************************************************************
    * @description finds an Account in our map, by matching against all the Account dikeys
    * @param di the Data Import record
    * @param iAcc 1 specifies Account1 otherwise use Account2
    * @return Account the found Account
    */
    global Account AccountFromDi(DataImport__c di, integer iAcc) {
        for (string diKey : listDiKeyAx(di, iAcc == 1 ? 'Account1' : 'Account2')) {
            Account acc = mapDIKeyToAccount.get(diKey);
            if (acc != null)
                return acc;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description looks for existing Accounts that match A1 or A2, and if found,
    * updates their Id's in the Di's. if not found, creates a new account object for that di.
    * @return void
    */
    private void matchExistingAccounts() {

        set<string> setName = new set<string>();
        set<string> setCustomIDString = new set<string>();
        set<double> setCustomIDNumber = new set<double>();
        set<Id> setSFId = new set<Id>();

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;

            // a1
            if (di.Account1Imported__c != null)
                setSFId.add(di.Account1Imported__c);
            if (di.Account1_Name__c != null)
                setName.add(di.Account1_Name__c);
            if (isCustomIDInAccountMatchRules) {
                object val = di.get(strDIAccountCustomIDField('Account1', diSettings));
                if (val != null) {
                    if (isCustomIdInAccountDatatypeString)
                        setCustomIDString.add(string.valueOf(val));
                    else
                        setCustomIDNumber.add(double.valueOf(val));
                }
            }
            // a2
            if (di.Account2Imported__c != null)
                setSFId.add(di.Account2Imported__c);
            if (di.Account2_Name__c != null)
                setName.add(di.Account2_Name__c);
            if (isCustomIDInAccountMatchRules) {
                object val = di.get(strDIAccountCustomIDField('Account2', diSettings));
                if (val != null) {
                    if (isCustomIdInAccountDatatypeString)
                        setCustomIDString.add(string.valueOf(val));
                    else
                        setCustomIDNumber.add(double.valueOf(val));
                }
            }
        }


        string strSoql = 'Select Id, ';
        if (isCustomIDInAccountMatchRules)
            strSoql += diSettings.Account_Custom_Unique_ID__c + ', ';
        strSoql += 'Name from Account where ';
        if (setSFId.size() > 0) {
            strSoql += ' (Id in :setSFId) or ';
        }
        strSoql += 'Name in :setName';
        if (isCustomIDInAccountMatchRules && isCustomIdInAccountDatatypeString)
            strSoql += ' or ' + diSettings.Account_Custom_Unique_ID__c + ' in :setCustomIDString';
        else if (isCustomIDInAccountMatchRules && !isCustomIdInAccountDatatypeString)
            strSoql += ' or ' + diSettings.Account_Custom_Unique_ID__c + ' in :setCustomIDNumber';
        list<Account> listAcc = database.query(strSoql);

        // put all Accounts into our map
        for (Account acc : listAcc) {
            for (string diKey : listDiKeyAccount(acc))
                mapDIKeyToAccount.put(dikey, acc);
        }

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;

            Account acc = AccountFromDi(di, 1);
            list<string> listDiKey = listDiKeyA1(di);
            if (acc != null) {
                di.Account1Imported__c = acc.id;
                di.Account1ImportStatus__c = label.bdiMatched;
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                di.Account1ImportStatus__c = label.bdiCreated;
            }
            // make sure all dikeys for that account are in the map
            for (string diKey : listDiKey)
                mapDIKeyToAccount.put(diKey, acc);

            acc = AccountFromDi(di, 2);
            listDiKey = listDiKeyA2(di);
            if (acc != null) {
                di.Account2Imported__c = acc.id;
                di.Account2ImportStatus__c = label.bdiMatched;
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                di.Account2ImportStatus__c = label.bdiCreated;
            }
            // make sure all dikeys for that account are in the map
            for (string diKey : listDiKey)
                mapDIKeyToAccount.put(diKey, acc);
        }
    }

    //********************************************* ADDRESSES ************************************************

    /*******************************************************************************************************
    * @description create the default Household Address for each household.
    * must ensure the address doesn't already exist for the case of updating existing contacts and accounts.
    * @return void
    */
    private void importAddresses() {

        // if address mgmt is turned off, then we want to save Home address fields directly on the contacts and HH account
        if (UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c) {
            importAddressesAsAddressFields();
            return;
        }

        // only create Home Address if it doesn't already exist on the Household.
        // so we need to get all the households, and then get all their addresses.
        set<Id> setHHId = new set<Id>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 1);
            if (con != null && con.AccountId != null)
                setHHId.add(con.AccountId);
        }
        list<Address__c> listAddrExisting = [select Id, Household_Account__c, MailingStreet__c, MailingCity__c, MailingState__c,
            MailingPostalCode__c from Address__c where Household_Account__c in :setHHId];
        map<String, Id> mapHHAddrKeyToId = new map<String, Id>();
        for (Address__c addr : listAddrExisting) {
            mapHHAddrKeyToId.put(strKeyOfAddr(addr), addr.Id);
        }

        map<string, string> mapDIFieldToAddrField = mapFieldsForDIObject('Address', UTIL_Namespace.StrTokenNSPrefix('Address__c'), listStrDataImportFields);
        list<Address__c> listAddrInsert = new list<Address__c>();
        list<DataImport__c> listDIInsert = new list<DataImport__c>();
        map<String, Address__c> mapHHAddrKeyToAddrNew = new map<String, Address__c>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;

            Contact con = ContactFromDi(di, 1);
            Address__c addr = new Address__c();
            addr.Address_Type__c = 'Home';
            addr.Default_Address__c = true;
            addr.Household_Account__c = (con != null ? con.AccountId : null);
            boolean isEmpty = true;
            for (string strDIField : mapDIFieldToAddrField.keySet()) {
                if (isCopiedDIField(di, strDIField, addr, mapDIFieldToAddrField)) {
                    isEmpty = false;
                }
            }
            if (!isEmpty) {
                // only create Home Address if we have a household
                if (con == null || con.AccountId == null) {
                    di.HomeAddressImportStatus__c = label.bdiIgnored;
                    continue;
                }

                // check to see if we already have this address in this hh.
                ID idAddr = mapHHAddrKeyToId.get(strKeyOfAddr(addr));
                if (idAddr != null) {
                    di.HomeAddressImported__c = idAddr;
                    di.HomeAddressImportStatus__c = label.bdiMatched;
                } else {
                    // see if we are already creating this new address
                    Address__c addrNew = mapHHAddrKeyToAddrNew.get(strKeyOfAddr(addr));
                    if (addrNew != null) {
                        addr = addrNew;
                    } else {
                        mapHHAddrKeyToAddrNew.put(strKeyOfAddr(addr), addr);
                        listAddrInsert.add(addr);
                        listDIInsert.add(di);
                    }
                    mapDIIdToAddr.put(di.Id, addr);
                }
            }
            if (Test.isRunningTest() && addr.MailingCity__c != null && addr.MailingCity__c.startsWith('FailTest')) {
                addr.Household_Account__c = di.Id;  // a bogus id for this field
            }
        }

        // two prong strategy! if any address object fails to save, do one
        // address record at a time, so we can log the failing address with the correct bdi record.
        try  {
            insert listAddrInsert;
        } catch (exception ex) {
            for (integer i = 0; i < listAddrInsert.size(); i++) {
                Database.SaveResult sr = database.insert(listAddrInsert[i], false);
                if (!sr.isSuccess()) {
                    LogBDIError(listDIInsert[i], sr.getErrors()[0].getMessage(), 'HomeAddressImportStatus__c');
                }
            }
        }

        // update each DI with its new home address
        for (DataImport__c di: listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            if (di.HomeAddressImported__c == null) {
                Address__c addr = mapDIIdToAddr.get(di.Id);
                if (addr != null && addr.Id != null) {
                    di.HomeAddressImported__c = addr.Id;
                    di.HomeAddressImportStatus__c = label.bdiCreated;
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description returns the unique address key for the given address
    * @param addr the Address
    * @return String the key for the Address
    */
    private static string strKeyOfAddr(Address__c addr) {
        return addr.Household_Account__c + addr.MailingStreet__c + addr.MailingCity__c + addr.MailingState__c + addr.MailingPostalCode__c;
    }

    /*******************************************************************************************************
    * @description update the contacts and household account with the Home Address information
    * @return void
    */
    private void importAddressesAsAddressFields() {

        // track the contacts and hh accounts to update
        set<Id> setIdUpdate = new set<Id>();
        list<Contact> listCon1Update = new list<Contact>();
        list<Contact> listCon2Update = new list<Contact>();
        list<Account> listAccUpdate = new list<Account>();
        list<DataImport__c> listCon1Di = new list<DataImport__c>();
        list<DataImport__c> listCon2Di = new list<DataImport__c>();
        list<DataImport__c> listAccDi = new list<DataImport__c>();

        // first get our Household Accounts
        set<Id> setHHId = new set<Id>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            if (di.HouseholdAccountImported__c != null)
                setHHId.add(di.HouseholdAccountImported__c);
        }
        map<Id, Account> mapHHIdToAcc = new map<Id, Account>([select Id, BillingStreet, BillingCity,
            BillingState, BillingPostalCode, BillingCountry from Account where Id in :setHHId]);

        // now update home address on the contacts and hh account
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            Contact con1 = ContactFromDi(di, 1);
            Contact con2 = ContactFromDi(di, 2);
            Account accHH = mapHHIdToAcc.get(di.HouseholdAccountImported__c);

            if (di.Home_Street__c != null ||
                di.Home_City__c != null ||
                di.Home_State_Province__c != null ||
                di.Home_Zip_Postal_Code__c != null ||
                di.Home_Country__c != null) {

                // use an Address object, so we can leverage the copy methods that support state & country picklists.
                Address__c addr = new Address__c();
                addr.MailingStreet__c = di.Home_Street__c;
                addr.MailingCity__c = di.Home_City__c;
                addr.MailingState__c = di.Home_State_Province__c;
                addr.MailingPostalCode__c = di.Home_Zip_Postal_Code__c;
                addr.MailingCountry__c = di.Home_Country__c;
                addr.Address_Type__c = 'Home';

                if (con1 != null) {
                    ADDR_Addresses_TDTM.copyAddressAddrSObj(addr, con1, 'Mailing', 'npe01__Primary_Address_Type__c');
                    if (setIdUpdate.add(con1.Id)) {
                        listCon1Update.add(con1);
                        listCon1Di.add(di);
                    }
                }
                if (con2 != null) {
                    ADDR_Addresses_TDTM.copyAddressAddrSObj(addr, con2, 'Mailing', 'npe01__Primary_Address_Type__c');
                    if (setIdUpdate.add(con2.Id)) {
                        listCon2Update.add(con2);
                        listCon2Di.add(di);
                    }
                }
                if (accHH != null) {
                    ADDR_Addresses_TDTM.copyAddressAddrSObj(addr, accHH, 'Billing', null);
                    if (setIdUpdate.add(accHH.Id)) {
                        listAccUpdate.add(accHH);
                        listAccDi.add(di);
                    }
                }
            }
        }

        // now update the objects
        list<Database.UpsertResult> listUR = database.upsert(listCon1Update, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listCon1Di[i], ur.getErrors()[0].getMessage(), 'Contact1ImportStatus__c');
            }
        }
        listUR = database.upsert(listCon2Update, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listCon2Di[i], ur.getErrors()[0].getMessage(), 'Contact2ImportStatus__c');
            }
        }
        listUR = database.upsert(listAccUpdate, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listAccDi[i], ur.getErrors()[0].getMessage(), 'HomeAddressImportStatus__c');
            }
        }

    }


    //********************************************* CAMPAIGNS ************************************************

    /*******************************************************************************************************
    * @description matches existing campaigns, and creates new campaigns, as needed.
    * @return void
    */
    private void importCampaigns() {

        // need to find all the Campaigns that we might need
        set<string> setStrCampaign = new set<string>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
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
        list<DataImport__c> listDINew = new list<DataImport__c>();
        setStrCampaign.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            string strName = di.Donation_Campaign_Name__c;
            Campaign cmp;
            if (strName != null && setStrCampaign.add(strName)) {
                if (mapStrNameToCampaignId.get(strName) == null) {
                    cmp = new Campaign(Name=strName, IsActive=true);
                    listCmpNew.add(cmp);
                    listDINew.add(di);
                }
            }
            if (Test.isRunningTest() && strName != null && strName.startsWith('FailTest'))
                cmp.Name = null;
        }
        //insert listCmpNew;
        list<Database.UpsertResult> listUR = database.upsert(listCmpNew, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDINew[i], ur.getErrors()[0].getMessage(), 'DonationImportStatus__c');
            }
        }

        // add the new campaigns to our map
        for (Campaign cmp : listCmpNew) {
            mapStrNameToCampaignId.put(cmp.Name, cmp.Id);
        }

    }

    //********************************************* CAMPAIGN MEMBERS ************************************************

    /*******************************************************************************************************
    * @description creates any new CampaignMembers for imported Contacts and Campaigns
    * @return void
    */
    private void importCampaignMembers() {
        list<string> newCmContactIds = new list<string>();
        list<string> listCampaignIds = new list<string>();
        list<string> listCmStatues = new list<string>();
        // loop over the dis contacts and find existing cms or new cms to create (if they have a campaign)
        for (DataImport__c di : listDI) {
            // skip that already have an error
            if (di.Status__c == label.bdiFailed)
                continue;
            // only create CMs here for rows that don't have an opportunity
            if (di.Donation_Campaign_Name__c != null && di.DonationImported__c == null) {
                // assume errors would have already been thrown
                Id idCmp = mapStrNameToCampaignId.get(di.Donation_Campaign_Name__c);
                string diStatus = String.isBlank(di.Campaign_Member_Status__c) ? Label.campaignMemberStatusDefault : di.Campaign_Member_Status__c;

                if (di.Contact1Imported__c != null) {
                    newCmContactIds.add(di.Contact1Imported__c);
                    listCampaignIds.add(idCmp); // current campaign for row
                    listCmStatues.add(diStatus);
                }
                if (di.Contact2Imported__c != null) {
                    newCmContactIds.add(di.Contact2Imported__c);
                    listCampaignIds.add(idCmp); // current campaign for row
                    listCmStatues.add(diStatus);
                }
            }
        }

        // return DML wrapper for new CMs
        TDTM_Runnable.DMLWrapper newCmWrapper = CON_AddToCampaign.CreateCampaignMembers(newCmContactIds,listCampaignIds,listCmStatues);

        // process dmls for CMs
        TDTM_TriggerHandler.processDML(newCmWrapper);
    }
}