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
    * @param isDryRun whether to run in Dry Run mode or commit records.
    */
    public BDI_DataImportService(Boolean isDryRun) {
        contactService = new BDI_ContactService(this);
        this.isDryRun = isDryRun;
    }

    /*******************************************************************************************************
    * @description constructs the soql String to run a Data Import process with or without a Batch.
    * @param batchId an optional DataImportBatch to scope the records to
    * @return String the soql String
    */
    public static String strSoqlForBatchProcess(ID batchId) {
        String strSoql;

        // construct or SOQL for the batch
        strSoql = 'SELECT ' + String.join(listStrDataImportFields, ',');
        strSoql += ' FROM ' + UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        strSoql += ' WHERE Status__c <> \'' + BDI_DataImport_API.bdiImported + '\' ';

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

        List<DataImportBatch__c> listDIBatch = BDI_DataImportBatch_SEL.selectByIds(new Set<Id>{batchId});
        if (listDIBatch.size() == 1) {
            return listDIBatch[0];
        } else {
            throw(new BDIException(String.format(Label.bdiInvalidBatchId, new String[]{batchId})));
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
            Run_Opportunity_Rollups_while_Processing__c = diBatch.Run_Opportunity_Rollups_while_Processing__c,
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
            Run_Opportunity_Rollups_while_Processing__c = diSettings.Run_Opportunity_Rollups_while_Processing__c,
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

        String strSettingsObj = UTIL_Namespace.StrTokenNSPrefix('Data_Import_Settings__c');
        String strDataImportObj = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');

        // validate matching rules
        if (diSettings.Donation_Matching_Behavior__c != null &&
            diSettings.Donation_Matching_Behavior__c != BDI_DataImport_API.DoNotMatch &&
            String.isBlank(diSettings.Donation_Matching_Rule__c)) {
            throw(new BDIException(Label.bdiDonationMatchingRuleEmpty));
        }

        // validate Batch Process Size
        if (diSettings.Batch_Size__c == null || diSettings.Batch_Size__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new List<String>{UTIL_Describe.getFieldLabelSafe(strSettingsObj, UTIL_Namespace.StrTokenNSPrefix('Batch_Size__c'))})));
        }

        // validate Donation Date Range
        if (diSettings.Donation_Date_Range__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new List<String>{UTIL_Describe.getFieldLabelSafe(strSettingsObj, UTIL_Namespace.StrTokenNSPrefix('Donation_Date_Range__c'))})));
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
            String strContact1 = strDIContactCustomIDField('Contact1', diSettings);
            String strContact2 = strDIContactCustomIDField('Contact2', diSettings);

            if (!UTIL_Describe.isValidField(strDataImportObj, strContact1) ||
                !UTIL_Describe.isValidField(strDataImportObj, strContact2)) {
                throw(new BDIException(String.format(Label.bdiContactCustomIdError,
                    new String[]{diSettings.Contact_Custom_Unique_ID__c, strContact1, strContact2})));
            }
        }

        if (diSettings.Account_Custom_Unique_ID__c != null) {
            // make sure a1 and a2 have the appropriately named field
            String strAccount1 = strDIAccountCustomIDField('Account1', diSettings);
            String strAccount2 = strDIAccountCustomIDField('Account2', diSettings);

            if (!UTIL_Describe.isValidField(strDataImportObj, strAccount1) ||
                !UTIL_Describe.isValidField(strDataImportObj, strAccount2)) {
                throw(new BDIException(String.format(Label.bdiAccountCustomIdError,
                    new String[]{diSettings.Account_Custom_Unique_ID__c, strAccount1, strAccount2})));
            }
        }

        // make sure they have specified a valid Donation Matching Behavior
        Set<String> setDMBehavior = new Set<String> {
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
                AND Status__c = :BDI_DataImport_API.bdiImported
                AND ApexJobId__c = :apexJobId
            ];
            integer cRecordsFailed = cRecordsProcessed - cRecordsSucceeded;

            diBatch.Last_Processed_On__c = System.now();
            diBatch.Records_Successfully_Processed__c = cRecordsSucceeded;
            diBatch.Records_Failed__c = cRecordsFailed;
            UTIL_DMLService.updateRecord(diBatch);
        }
    }

    /*******************************************************************************************************
    * @description maps to keep track of the objects we will create.
    * all are indexed by the object's matching key or the di.Id
    */
    //public Map<String, Contact> mapDIKeyToContact = new Map<String, Contact>();
    public Map<String, Account> mapDIKeyToAccount = new Map<String, Account>();
    private Map<Id, Address__c> mapDIIdToAddr = new Map<Id, Address__c>();
    public Map<String, Id> mapStrNameToCampaignId = new Map<String, Id>();

    /*******************************************************************************************************
    * @description holds the list of DataImport records we are currently processing
    */
    global List<DataImport__c> listDI;

    /*******************************************************************************************************
    * @description holds the data import settings to use for this batch.  these may be either from
    * custom settings, or if a specific BatchId was specified, the settings specified for that batch.
    */
    global Data_Import_Settings__c diSettings { get; private set; }

    /*******************************************************************************************************
    * @description whether the processing should be done in Dry Run mode (vs. normal mode).
    */
    global Boolean isDryRun { get; private set; }

    /*******************************************************************************************************
    * @description holds the performance logger object for tracking performance metrics during processing.
    */
    public static BDI_PerfLogger perfLogger { get; private set; }

    /*******************************************************************************************************
    * @description holds the Contact Service class for use during processing
    */
    private BDI_ContactService contactService { get; private set; }

    /*******************************************************************************************************
    * @description whether the Account Custom Unique ID field is in our account matching rules
    */
    private boolean isCustomIdInAccountMatchRules {
        get {
            String str = diSettings.Account_Custom_Unique_ID__c;
            if (str == null || str == '')
                return false;
            return true;
        }
    }

    /*******************************************************************************************************
    * @description whether the Account Custom Uniue ID field is a String datatype
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
                        dt == Schema.Displaytype.Phone ||
                        dt == Schema.Displaytype.Reference)
                        isCustomIdInAccountDatatypeString = true;
                }
            }
            return isCustomIdInAccountDatatypeString;
        }
        set;
    }

    /*******************************************************************************************************
    * @description coerces an object to a String value
    * @param obj an Object
    * @return String either the String value or an empty String ''
    */
    public String strNull(Object obj) {
        return strNull(String.valueOf(obj));
    }

    /*******************************************************************************************************
    * @description handles null Strings to always return a valid String or empty String
    * @param str a String or null
    * @return String either the String value or an empty String ''
    */
    public String strNull(String str) {
        if (str == null)
            return '';
        else
            return str;
    }

    /*******************************************************************************************************
    * @description label to use for matched existing records, taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedExisting() {
        return isDryRun ? label.bdiDryRunMatched : label.bdiMatched;
    }

    /*******************************************************************************************************
    * @description label to use for matched best records (donations), taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedBest() {
        return isDryRun ? label.bdiDryRunMatchedBest : label.bdiMatchedBest;
    }

    /*******************************************************************************************************
    * @description label to use for matched by Id (donations), taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedById() {
        return isDryRun ? label.bdiDryRunMatchedId : label.bdiMatchedId;
    }

    /*******************************************************************************************************
    * @description label to use for matched none (donations), taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedNone() {
        return isDryRun ? label.bdiDryRunNoMatch : label.bdiMatchedNone;
    }

    /*******************************************************************************************************
    * @description label to use for matches to new records going to be created, taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedNew() {
        return isDryRun ? label.bdiDryRunNoMatch : label.bdiMatched;
    }

    /*******************************************************************************************************
    * @description label to use for matches to new records going to be created, taking into account if in Dry Run
    * @return String
    */
    public String statusCreatedNew() {
        return isDryRun ? label.bdiDryRunNoMatch : label.bdiCreated;
    }

    /*******************************************************************************************************
    * @description label to use for overall DI record status error/failed, taking into account if in Dry Run
    * @return String
    */
    public String statusDIFailed() {
        return isDryRun ? BDI_DataImport_API.bdiDryRunError : BDI_DataImport_API.bdiFailed;
    }

    /*******************************************************************************************************
    * @description label to use for overall DI record status success, taking into account if in Dry Run
    * @return String
    */
    public String statusDISuccess() {
        return isDryRun ? BDI_DataImport_API.bdiDryRunValidated : BDI_DataImport_API.bdiImported;
    }

    /*******************************************************************************************************
    * @description The real work gets done here! Given a list of di records, process them.
    * @param apexJobId the apexJob that this is executing under
    * @param diSettings the settings to control processing behavior
    * @param listDI a list of Data Import records to import
    * @param isDryRun whether to run in Dry Run mode or commit records.
    * @return void
    */
    public static void execute(Id apexJobId, Data_Import_Settings__c diSettings, List<DataImport__c> listDI, Boolean isDryRun) {
        BDI_DataImportService bdi = new BDI_DataImportService(isDryRun);
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

        // initialize our performance logger
        perfLogger = new BDI_PerfLogger(listDI[0].NPSP_Data_Import_Batch__c, listDI.size());
        BDI_PerfLogger.PerfLog pl;

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

            // do any performance optimizations to avoid unnecessary code
            disableAllOppRollups();

            pl = perfLogger.newPerfLog('importContactsAndHouseholds');
            contactService.importContactsAndHouseholds();
            pl.stop();

            pl = perfLogger.newPerfLog('importHouseholdAccountFields');
            importHouseholdAccountFields();
            pl.stop();

            pl = perfLogger.newPerfLog('importAccounts');
            importAccounts();
            pl.stop();

            pl = perfLogger.newPerfLog('importAddresses');
            importAddresses();
            pl.stop();

            pl = perfLogger.newPerfLog('importCampaigns');
            importCampaigns();
            pl.stop();

            pl = perfLogger.newPerfLog('importDonations');
            BDI_Donations bdiDonations = new BDI_Donations(this);
            bdiDonations.importDonations();
            pl.stop();

            pl = perfLogger.newPerfLog('importCampaignMembers');
            importCampaignMembers();
            pl.stop();

            pl = perfLogger.newPerfLog('updateDIStatuses');
            updateDIStatuses(apexJobId);
            pl.stop();

            pl = perfLogger.newPerfLog('customPostProcess');
            customPostProcess();
            pl.stop();

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
            List<DataImport__c> listDIError = new List<DataImport__c>();
            for (DataImport__c di : listDI) {
                listDIError.add(new DataImport__c(
                    Id = di.Id,
                    Status__c = statusDIFailed(),
                    FailureInformation__c = di.Status__c == statusDIFailed() ? di.FailureInformation__c : e.getMessage(),
                    ApexJobId__c = apexJobId
                ));
            }

            UTIL_DMLService.updateRecords(listDIError);

            // unfortunately, we can't let the system think the batch failed, or
            // then it would rollback our setting of failure state in the DI records.
            // so we just return, and rely on our Data Import ui to notify the user.
        } finally {
            perfLogger.stop();
            perfLogger.save();
        }
    }

    /*******************************************************************************************************
    * @description updates the status of each DI record and commits them to the database
    * @return void
    */
    private void updateDIStatuses(Id apexJobId) {
        // update final status for each DI
        for (DataImport__c di: listDI) {
            if (di.Status__c == null) {
                di.Status__c = statusDISuccess();
            } else if (di.Status__c == BDI_DataImport_API.bdiFailed) {
                di.Status__c = statusDIFailed();
            }
            di.ImportedDate__c = system.now();
            di.ApexJobId__c = apexJobId;

            // because a contact might be first imported in C1 location, but then moved to another
            // household since it later shows up in C2, location, we can't be assured that the
            // contact's original household account is the same (and valid). Thus we must fixup
            // all Household Account Id lookups in our di records.
            Contact c1 = ContactFromDi(di, 1);
            if (c1 != null) {
                di.HouseholdAccountImported__c = c1.AccountId;
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

        UTIL_DMLService.updateRecords(listDI);
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
        throw new BDIException(String.format(Label.bdiErrorInvalidIMatchDonations, new List<String>{strClass, strInterface}));
    }

    /*******************************************************************************************************
    * @description Copies the specific error into the provide di.
    * @param di the DataImport record
    * @param strError the error message
    * @param strStatusField the developer name of an additional status field to save the error message in
    * @return void
    */
    public void LogBDIError(DataImport__c di, String strError, String strStatusField) {
        //system.debug('****DJH: LogBDIError di: ' + di + ' strError: ' + strError + ' field: ' + strStatusField);
        di.Status__c = BDI_DataImport_API.bdiFailed;
        di.FailureInformation__c = strError;
        if (strStatusField != null)
            di.put(strStatusField, strError.left(255));
    }

    /*******************************************************************************************************
    * @description list of all the fields in the Data Import object
    */
    global static List<String> listStrDataImportFields {
        get {
            if (listStrDataImportFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.DataImport__c.fields.getMap();
                listStrDataImportFields = new List<String>();
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
    * @return Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    */
    global static Map<String, String> mapFieldsForDIObject(String strObj, String strBaseObj, List<String> listStrDIFields) {
        Map<String, String> mapDIFieldToObjField = new Map<String, String>();
        for (String strF : listStrDIFields) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), strF);
            String strHelpText = dfr.getInlineHelpText();
            if (strHelpText != null && strHelpText != '') {
                List<String> strParts = strHelpText.split('\\.', 2);
                if (strParts.size() == 2 && strParts[0] == strObj && strParts[1] != '') {
                    String strField = strParts[1];
                    //if we aren't in the npsp namespace, remove those tokens from help text
                    //also removes tokens from actual detected namespace, if we happen to be
                    //in a non-npsp namespace
                    if (UTIL_Namespace.getNamespace() != 'npsp') {
                        String strFieldOld = strField;
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
                                throw (new flsException(String.format(label.flsError, new String[]{
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
    public static boolean isCopiedDIField(DataImport__c di, String strDIField, SObject objDst, Map<String, String> mapDIFieldToDstField) {

        Object val = di.get(strDIField);

        // explicitly avoid updating unchecked booleans (since we can't tell the difference between null and false)
        if (val != null && val != false) {
            String strDstField = mapDIFieldToDstField.get(strDIField);

            // if values haven't changed, don't copy it and say the object was modified!
            if (objDst.get(strDstField) == val) {
                return false;
            }

            objDst.put(strDstField, val);
            return true;
        } else {
            return false;
        }
    }

    /*******************************************************************************************************
    * @description disables the Opportunity trigger handler that invokes rollups (unless settings say
    * otherwise!)
    * @return void
    */
    private void disableAllOppRollups() {
        if (!diSettings.Run_Opportunity_Rollups_while_Processing__c) {
            List<Trigger_Handler__c> handlers = TDTM_Config_API.getCachedRecords();
            for (Trigger_Handler__c th : handlers) {
                if (th.Object__c == 'Opportunity' && th.Class__c == 'RLLP_OppRollup_TDTM') {
                    th.Active__c = false;
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Imports any custom fields specified for Household Accounts
    * @return void
    */
    private void importHouseholdAccountFields() {

        // there is no work to do in Dry Run.
        if (isDryRun) {
            return;
        }

        // get our mapping of household custom fields
        Map<String, String> mapDIFieldToHHField = mapFieldsForDIObject('Household', 'Account', listStrDataImportFields);

        // bail out if no custom fields
        if (mapDIFieldToHHField.size() == 0)
            return;

        // holds the Households that need updating
        List<Account> listAccHHUpdate = new List<Account>();
        Set<Id> setHHIdUpdate = new Set<Id>();
        List<DataImport__c> listDIUpdate = new List<DataImport__c>();

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            if (di.HouseholdAccountImported__c == null)
                continue;

            boolean isModified = false;
            Account accHH = new Account(Id=di.HouseholdAccountImported__c);
            for (String strDIField : mapDIFieldToHHField.keySet()) {
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
        List<Database.UpsertResult> listUR = UTIL_DMLService.upsertRecords(listAccHHUpdate, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpdate[i], ur.getErrors()[0].getMessage(), null);
            }
        }
    }

    /*******************************************************************************************************
    * @description returns the field name of the Contact CustomID field for contact1 or contact2 in the
    * Data Import object.
    * @param strCx  which contact to reference (Contact1 or Contact2)
    * @param diSettings the settings object to read the setting from
    * @return String
    */
    public static String strDIContactCustomIDField(String strCx, Data_Import_Settings__c diSettings) {
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
    * @return String
    */
    @TestVisible private static String strDICustomIDField(String strObjx, String strCustomId) {
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
                return UTIL_Namespace.StrTokenNSPrefix(strObjx + '_' + strCustomId.subString(i + 2));
            } else {
                // skip namespace
                return strObjx + '_' + strCustomId.subString(i + 2);
            }
        }

        // custom fields without namespace
        return strObjx + '_' + strCustomId;
    }

    /*******************************************************************************************************
    * @description finds a contact in our map, by matching against all the contact dikeys
    * @param di the Data Import record
    * @param iCon 1 specifies Contact1 otherwise use Contact2
    * @return Contact the found Contact
    */
    global Contact ContactFromDi(DataImport__c di, integer iCon) {
        return contactService.ContactFromDi(di, iCon);
    }

    //********************************************* ACCOUNTS ************************************************

    /*******************************************************************************************************
    * @description importing or updating Account1 and Account2, and setting the contacts' Primary Affiliation.
    * @return void
    */
    private void importAccounts() {

        // first, try to match our existing Accounts
        BDI_PerfLogger.PerfLog pl = perfLogger.newPerfLog('matchExistingAccounts');
        matchExistingAccounts();
        pl.stop();

        // done matching for Dry Run.
        if (isDryRun) {
            return;
        }

        // handle multiple di's referring to the same existing account
        Set<String> setDIKeyUpsert = new Set<String>();
        List<Account> listAccUpsert = new List<Account>();
        List<DataImport__c> listDIUpsert = new List<DataImport__c>();

        // create/update our A1's
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;

            Account acc = AccountFromDi(di, 1);
            if (acc == null)
                continue;

            boolean isModified = false;
            for (String strDIField : mapDIFieldToA1Field.keySet()) {
                if (isCopiedDIField(di, strDIField, acc, mapDIFieldToA1Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                boolean isAlreadyAdded = false;
                for (String diKey : listDiKeyA1(di)) {
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

        if (listAccUpsert.size() > 0) {
            List<Database.UpsertResult> listUR = database.upsert(listAccUpsert, false);
            for (integer i = 0; i < listUR.size(); i++) {
                Database.UpsertResult ur = listUR[i];
                if (!ur.isSuccess()) {
                    LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Account1ImportStatus__c');
                }
            }
        }

        // update each DI with its new Account1 ID
        // and set contact's primary affiliations
        Map<Id, Contact> mapConIdToConUpdate = new Map<Id, Contact>();
        for (DataImport__c di: listDI) {
            if (di.Account1Imported__c == null) {
                Account acc = AccountFromDi(di, 1);
                if (acc != null)
                    di.Account1Imported__c = acc.Id;
            }
            // set c1's primary affilation
            if (di.Account1Imported__c != null) {
                Contact c1 = ContactFromDi(di, 1);
                if (c1 != null && c1.Primary_Affiliation__c != di.Account1Imported__c) {
                    c1.Primary_Affiliation__c = di.Account1Imported__c;
                    if (mapConIdToConUpdate.get(c1.Id) == null) {
                        mapConIdToConUpdate.put(c1.Id, c1);
                    }
                }
            }
        }

        // create/update our A2's
        listAccUpsert.clear();
        listDIUpsert.clear();
        setDIKeyUpsert.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;

            Account acc = AccountFromDi(di, 2);
            if (acc == null)
                continue;

            boolean isModified = false;
            for (String strDIField : mapDIFieldToA2Field.keySet()) {
                if (isCopiedDIField(di, strDIField, acc, mapDIFieldToA2Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                boolean isAlreadyAdded = false;
                for (String diKey : listDiKeyA2(di)) {
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

        if (listAccUpsert.size() > 0) {
            List<Database.UpsertResult> listUR = database.upsert(listAccUpsert, false);
            for (integer i = 0; i < listUR.size(); i++) {
                Database.UpsertResult ur = listUR[i];
                if (!ur.isSuccess()) {
                    LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Account2ImportStatus__c');
                }
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
                if (c2 != null && c2.Primary_Affiliation__c != di.Account2Imported__c) {
                    c2.Primary_Affiliation__c = di.Account2Imported__c;
                    if (mapConIdToConUpdate.get(c2.Id) == null) {
                        mapConIdToConUpdate.put(c2.Id, c2);
                    }
                }
            }
        }

        // now update the Contacts to create their Affiliations
        if (mapConIdToConUpdate.size() > 0) {
            UTIL_DMLService.updateRecords(mapConIdToConUpdate.values());
        }
    }

    /*******************************************************************************************************
    * @description returns the field name of the Account CustomID field for Account1 or Account2 in the
    * Data Import object.
    * @param strAx  which account to reference (account1 or account2)
    * @param diSettings the settings object to read the setting from
    * @return String
    */
    private static String strDIAccountCustomIDField(String strAx, Data_Import_Settings__c diSettings) {
        return strDICustomIDField(strAx, diSettings.Account_Custom_Unique_ID__c);
    }

    /*******************************************************************************************************
    * @description return all the diKeys for a given Account
    * @param acc the Account
    * @return List<String> a list of diKeys
    */
    private List<String> listDiKeyAccount(Account acc) {
        if (acc == null)
            return null;

        List<String> listDiKey = new List<String>();

        // we need any Account SFId key to always be checked first when matching
        if (acc.Id != null) {
            listDiKey.add(acc.Id);
        }

        // we need the Account CustomId key to always be checked second when matching
        String strUniqueId = '';
        if (isCustomIDInAccountMatchRules && (strUniqueId = strNull(acc.get(diSettings.Account_Custom_Unique_ID__c))) != '') {
            if (!isCustomIdInAccountDatatypeString) {
                strUniqueId = String.valueOf(double.valueOf(strUniqueId));
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
    * @return List<String> the diKeys for the account
    */
    private List<String> listDiKeyA1(DataImport__c di) {
        return listDiKeyAx(di, 'Account1');
    }

    /*******************************************************************************************************
    * @description return the dikeys for Account2 in the given di.
    * @param di the Data Import record
    * @return List<String> the diKeys for the account
    */
    private List<String> listDiKeyA2(DataImport__c di) {
        return listDIKeyAx(di, 'Account2');
    }

    /*******************************************************************************************************
    * @description return the dikeys for specified Account in the given di.
    * @param di the Data Import record
    * @param strAx specifies which Account, eg Account1 or Account2
    * @return List<String> the diKeys for the Account
    */
    private List<String> listDiKeyAx(DataImport__c di, String strAx) {
        List<String> listDiKey = new List<String>();

        // we need the Account Lookup key to always be checked first when matching
        String strUniqueId = '';
        if ((strUniqueId = strNull(di.get(strAx + 'Imported__c'))) != '') {
            listDiKey.add(strUniqueId);
            strUniqueId = '';
        }

        // we need the Account CustomId key to always be checked second when matching
        if (isCustomIDInAccountMatchRules && (strUniqueId = strNull(di.get(strDIAccountCustomIDField(strAx, diSettings)))) != '') {
            if (!isCustomIdInAccountDatatypeString) {
                strUniqueId = String.valueOf(double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        // now create any other dikeys
        String strName;
        if ((strName = String.valueOf(di.get(strAx + '_Name__c'))) != null)
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
        for (String diKey : listDiKeyAx(di, iAcc == 1 ? 'Account1' : 'Account2')) {
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

        Set<String> setName = new Set<String>();
        Set<String> setCustomIDString = new Set<String>();
        Set<double> setCustomIDNumber = new Set<double>();
        Set<Id> setSFId = new Set<Id>();
        String a1CustomIDField = BDI_DataImportService.strDIAccountCustomIDField('Account1', diSettings);
        String a2CustomIDField = BDI_DataImportService.strDIAccountCustomIDField('Account2', diSettings);


        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;

            // a1
            if (di.Account1Imported__c != null)
                setSFId.add(di.Account1Imported__c);
            if (di.Account1_Name__c != null)
                setName.add(di.Account1_Name__c);
            if (isCustomIDInAccountMatchRules) {
                object val = di.get(a1CustomIDField);
                if (val != null) {
                    if (isCustomIdInAccountDatatypeString)
                        setCustomIDString.add(String.valueOf(val));
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
                object val = di.get(a2CustomIDField);
                if (val != null) {
                    if (isCustomIdInAccountDatatypeString)
                        setCustomIDString.add(String.valueOf(val));
                    else
                        setCustomIDNumber.add(double.valueOf(val));
                }
            }
        }

        String strSoql = getSoqlSelectForAccount();
        strSoql += ' WHERE (Id IN :setSFId)';

        if (!setName.isEmpty()) {
            UTIL_Finder finder = new UTIL_Finder(Account.SObjectType)
                .withWhere(new UTIL_Where.FieldExpression(Account.Name).inSet(setName));

            if (finder.isSoql()) {
                strSoql += ' OR Name IN :setName';
            } else {
                setSFId.addAll(new Map<Id, SObject>(finder.find()).keySet());
            }
        }

        if (isCustomIDInAccountMatchRules && isCustomIdInAccountDatatypeString)
            strSoql += ' OR ' + diSettings.Account_Custom_Unique_ID__c + ' IN :setCustomIDString';
        else if (isCustomIDInAccountMatchRules && !isCustomIdInAccountDatatypeString)
            strSoql += ' OR ' + diSettings.Account_Custom_Unique_ID__c + ' IN :setCustomIDNumber';

        BDI_PerfLogger.PerfLog pl = perfLogger.newPerfLog('SOQL existing Accounts', BDI_PerfLogger.QUERY);
        List<Account> listAcc = database.query(strSoql);
        pl.stop();

        // put all Accounts into our map
        for (Account acc : listAcc) {
            for (String diKey : listDiKeyAccount(acc))
                mapDIKeyToAccount.put(dikey, acc);
        }

        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;

            Account acc = AccountFromDi(di, 1);
            List<String> listDiKey = listDiKeyA1(di);
            if (acc != null) {
                di.Account1Imported__c = acc.id;
                di.Account1ImportStatus__c = (acc.id != null ? statusMatchedExisting() : statusMatchedNew());
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                di.Account1ImportStatus__c = statusCreatedNew();
            }
            // make sure all dikeys for that account are in the map
            for (String diKey : listDiKey)
                mapDIKeyToAccount.put(diKey, acc);

            acc = AccountFromDi(di, 2);
            listDiKey = listDiKeyA2(di);
            if (acc != null) {
                di.Account2Imported__c = acc.id;
                di.Account2ImportStatus__c = (acc.id != null ? statusMatchedExisting() : statusMatchedNew());
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                di.Account2ImportStatus__c = statusCreatedNew();
            }
            // make sure all dikeys for that account are in the map
            for (String diKey : listDiKey)
                mapDIKeyToAccount.put(diKey, acc);
        }
    }

    /*******************************************************************************************************
    * @description provides the soql String for selecting all necessary fields from Account.
    * @return String the soql ('SELECT ... FROM Account')
    */
    private String getSoqlSelectForAccount() {
        Set<String> setAccountFields = new Set<String> {'Id', 'Name'};
            setAccountFields.addAll(mapDIFieldToA1Field.values());
            setAccountFields.addAll(mapDIFieldToA2Field.values());
        return 'SELECT ' + String.join(new List<String>(setAccountFields), ',') + ' FROM Account ';
    }

    /*******************************************************************************************************
    * @description map of DI Fieldnames for Account1 to Account fieldnames
    */
    private Map<String, String> mapDIFieldToA1Field {
        get {
            if (mapDIFieldToA1Field == null) {
                mapDIFieldToA1Field = BDI_DataImportService.mapFieldsForDIObject('Account1', 'Account', BDI_DataImportService.listStrDataImportFields);
            }
            return mapDIFieldToA1Field;
        }
        set;
    }

    /*******************************************************************************************************
    * @description map of DI Fieldnames for Account2 to Account fieldnames
    */
    private Map<String, String> mapDIFieldToA2Field {
        get {
            if (mapDIFieldToA2Field == null) {
                mapDIFieldToA2Field = BDI_DataImportService.mapFieldsForDIObject('Account2', 'Account', BDI_DataImportService.listStrDataImportFields);
            }
            return mapDIFieldToA2Field;
        }
        set;
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
        Set<Id> setHHId = new Set<Id>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            Contact con = ContactFromDi(di, 1);
            if (con != null && con.AccountId != null)
                setHHId.add(con.AccountId);
        }
        BDI_PerfLogger.PerfLog pl = perfLogger.newPerfLog('SOQL existing Addresses', BDI_PerfLogger.QUERY);
        List<Address__c> listAddrExisting = [select Id, Household_Account__c, MailingStreet__c, MailingCity__c, MailingState__c,
            MailingPostalCode__c from Address__c where Household_Account__c in :setHHId];
        pl.stop();

        Map<String, Id> mapHHAddrKeyToId = new Map<String, Id>();
        for (Address__c addr : listAddrExisting) {
            mapHHAddrKeyToId.put(strKeyOfAddr(addr), addr.Id);
        }

        Map<String, String> mapDIFieldToAddrField = mapFieldsForDIObject('Address', UTIL_Namespace.StrTokenNSPrefix('Address__c'), listStrDataImportFields);
        List<Address__c> listAddrInsert = new List<Address__c>();
        List<DataImport__c> listDIInsert = new List<DataImport__c>();
        Map<String, Address__c> mapHHAddrKeyToAddrNew = new Map<String, Address__c>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;

            Contact con = ContactFromDi(di, 1);
            Address__c addr = new Address__c();
            addr.Address_Type__c = 'Home';
            addr.Default_Address__c = true;
            addr.Household_Account__c = (con != null ? con.AccountId : null);
            boolean isEmpty = true;
            for (String strDIField : mapDIFieldToAddrField.keySet()) {
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
                    di.HomeAddressImportStatus__c = statusMatchedExisting();
                } else {
                    // see if we are already creating this new address
                    Address__c addrNew = mapHHAddrKeyToAddrNew.get(strKeyOfAddr(addr));
                    if (addrNew != null) {
                        addr = addrNew;
                        di.HomeAddressImportStatus__c = statusMatchedNew();
                    } else {
                        mapHHAddrKeyToAddrNew.put(strKeyOfAddr(addr), addr);
                        listAddrInsert.add(addr);
                        listDIInsert.add(di);
                        di.HomeAddressImportStatus__c = statusCreatedNew();
                    }
                    mapDIIdToAddr.put(di.Id, addr);
                }
            }
            if (Test.isRunningTest() && addr.MailingCity__c != null && addr.MailingCity__c.startsWith('FailTest')) {
                addr.Household_Account__c = di.Id;  // a bogus id for this field
            }
        }

        // done matching for Dry Run
        if (isDryRun) {
            return;
        }

        // two prong strategy! if any address object fails to save, do one
        // address record at a time, so we can log the failing address with the correct bdi record.
        try  {
            UTIL_DMLService.insertRecords(listAddrInsert);
        } catch (exception ex) {
            for (integer i = 0; i < listAddrInsert.size(); i++) {
                Database.SaveResult sr = UTIL_DMLService.insertRecord(listAddrInsert[i], false);
                if (!sr.isSuccess()) {
                    LogBDIError(listDIInsert[i], sr.getErrors()[0].getMessage(), 'HomeAddressImportStatus__c');
                }
            }
        }

        // update each DI with its new home address
        for (DataImport__c di: listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            if (di.HomeAddressImported__c == null) {
                Address__c addr = mapDIIdToAddr.get(di.Id);
                if (addr != null && addr.Id != null) {
                    di.HomeAddressImported__c = addr.Id;
                    di.HomeAddressImportStatus__c = statusCreatedNew();
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description returns the unique address key for the given address
    * @param addr the Address
    * @return String the key for the Address
    */
    private static String strKeyOfAddr(Address__c addr) {
        return addr.Household_Account__c + addr.MailingStreet__c + addr.MailingCity__c + addr.MailingState__c + addr.MailingPostalCode__c;
    }

    /*******************************************************************************************************
    * @description update the contacts and household account with the Home Address information
    * @return void
    */
    private void importAddressesAsAddressFields() {

        // there is no work to do in Dry Run.
        if (isDryRun) {
            return;
        }

        // track the contacts and hh accounts to update
        Set<Id> setIdUpdate = new Set<Id>();
        List<Contact> listCon1Update = new List<Contact>();
        List<Contact> listCon2Update = new List<Contact>();
        List<Account> listAccUpdate = new List<Account>();
        List<DataImport__c> listCon1Di = new List<DataImport__c>();
        List<DataImport__c> listCon2Di = new List<DataImport__c>();
        List<DataImport__c> listAccDi = new List<DataImport__c>();

        // first get our Household Accounts
        Set<Id> setHHId = new Set<Id>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            if (di.HouseholdAccountImported__c != null)
                setHHId.add(di.HouseholdAccountImported__c);
        }
        Map<Id, Account> mapHHIdToAcc = new Map<Id, Account>([select Id, BillingStreet, BillingCity,
            BillingState, BillingPostalCode, BillingCountry from Account where Id in :setHHId]);

        // now update home address on the contacts and hh account
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
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
        List<Database.UpsertResult> listUR = UTIL_DMLService.upsertRecords(listCon1Update, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listCon1Di[i], ur.getErrors()[0].getMessage(), 'Contact1ImportStatus__c');
            }
        }
        listUR = UTIL_DMLService.upsertRecords(listCon2Update, false);
        for (integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listCon2Di[i], ur.getErrors()[0].getMessage(), 'Contact2ImportStatus__c');
            }
        }
        listUR = UTIL_DMLService.upsertRecords(listAccUpdate, false);
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

        // since we don't currently fill in a campaign lookup or status on the DI record,
        // there is no work to do in Dry Run.
        if (isDryRun) {
            return;
        }

        // need to find all the Campaigns that we might need
        Set<String> setStrCampaign = new Set<String>();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            if (di.Donation_Campaign_Name__c != null)
                setStrCampaign.add(di.Donation_Campaign_Name__c);
        }

        // add the existing campaigns to our map
        for (Campaign cmp : [select Id, Name from Campaign where Name in :setStrCampaign]) {
            mapStrNameToCampaignId.put(cmp.Name, cmp.Id);
        }

        // create any new campaigns
        List<Campaign> listCmpNew = new List<Campaign>();
        List<DataImport__c> listDINew = new List<DataImport__c>();
        setStrCampaign.clear();
        for (DataImport__c di : listDI) {
            // skip di's that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            String strName = di.Donation_Campaign_Name__c;
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
        List<Database.UpsertResult> listUR = UTIL_DMLService.upsertRecords(listCmpNew, false);
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

        // there is no work to do in Dry Run.
        if (isDryRun) {
            return;
        }

        List<String> newCmContactIds = new List<String>();
        List<String> listCampaignIds = new List<String>();
        List<String> listCmStatues = new List<String>();

        // loop over the dis contacts and find existing cms or new cms to create (if they have a campaign)
        for (DataImport__c di : listDI) {
            // skip that already have an error
            if (di.Status__c == BDI_DataImport_API.bdiFailed)
                continue;
            // only create CMs here for rows that don't have an opportunity
            if (di.Donation_Campaign_Name__c != null && di.DonationImported__c == null) {
                // assume errors would have already been thrown
                Id idCmp = mapStrNameToCampaignId.get(di.Donation_Campaign_Name__c);
                String diStatus = String.isBlank(di.Campaign_Member_Status__c) ? Label.campaignMemberStatusDefault : di.Campaign_Member_Status__c;

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