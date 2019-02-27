/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
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
    public static String strSoqlForBatchProcess(Id batchId) {
        String batchQuery;

        // construct or SOQL for the batch
        batchQuery = 'SELECT ' + String.join(listStrDataImportFields, ',');
        batchQuery += ' FROM ' + UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        batchQuery += ' WHERE Status__c <> \'' + BDI_DataImport_API.bdiImported + '\' ';

        if (batchId != null) {
            batchQuery += ' AND NPSP_Data_Import_Batch__c = \'' + batchId + '\'';
        } else {
            batchQuery += ' AND NPSP_Data_Import_Batch__c = NULL';
        }
        // this ensures consistency for our test code, but also should
        // help users figure out import problems by importing in a consistent order.
        batchQuery += ' ORDER BY Name ';
        return batchQuery;
    }

    /*******************************************************************************************************
    * @description loads the data import batch.
    * @param batchId id of batch to load
    * @return DataImportBatch__c
    */
    private static DataImportBatch__c loadBatch(Id batchId) {

        List<DataImportBatch__c> dataImportBatches = BDI_DataImportBatch_SEL.selectByIds(new Set<Id>{ batchId });
        if (dataImportBatches.size() == 1) {
            return dataImportBatches[0];
        } else {
            throw(new BDIException(String.format(Label.bdiInvalidBatchId, new List<String>{ batchId })));
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
    public static Data_Import_Settings__c diSettingsFromDiBatch(DataImportBatch__c dataImportBatch) {
        return new Data_Import_Settings__c(
            Account_Custom_Unique_ID__c = dataImportBatch.Account_Custom_Unique_ID__c,
            Batch_Size__c = dataImportBatch.Batch_Process_Size__c,
            Contact_Custom_Unique_ID__c = dataImportBatch.Contact_Custom_Unique_ID__c,
            Contact_Matching_Rule__c = dataImportBatch.Contact_Matching_Rule__c,
            Donation_Matching_Behavior__c = dataImportBatch.Donation_Matching_Behavior__c,
            Donation_Matching_Implementing_Class__c = dataImportBatch.Donation_Matching_Implementing_Class__c,
            Donation_Matching_Rule__c = dataImportBatch.Donation_Matching_Rule__c,
            Donation_Date_Range__c = dataImportBatch.Donation_Date_Range__c,
            Run_Opportunity_Rollups_while_Processing__c = dataImportBatch.Run_Opportunity_Rollups_while_Processing__c,
            Post_Process_Implementing_Class__c = dataImportBatch.Post_Process_Implementing_Class__c
        );
    }

    /*******************************************************************************************************
    * @description creates a batch object from a settings object
    * @param diSettings the settings to copy fields from
    * @return DataImportBatch__c
    */
    public static DataImportBatch__c diBatchFromDiSettings(Data_Import_Settings__c dataImportSettings) {
        return new DataImportBatch__c(
            Account_Custom_Unique_ID__c = dataImportSettings.Account_Custom_Unique_ID__c,
            Batch_Process_Size__c = dataImportSettings.Batch_Size__c,
            Contact_Custom_Unique_ID__c = dataImportSettings.Contact_Custom_Unique_ID__c,
            Contact_Matching_Rule__c = dataImportSettings.Contact_Matching_Rule__c,
            Donation_Matching_Behavior__c = dataImportSettings.Donation_Matching_Behavior__c,
            Donation_Matching_Implementing_Class__c = dataImportSettings.Donation_Matching_Implementing_Class__c,
            Donation_Matching_Rule__c = dataImportSettings.Donation_Matching_Rule__c,
            Donation_Date_Range__c = dataImportSettings.Donation_Date_Range__c,
            Run_Opportunity_Rollups_while_Processing__c = dataImportSettings.Run_Opportunity_Rollups_while_Processing__c,
            Post_Process_Implementing_Class__c = dataImportSettings.Post_Process_Implementing_Class__c
        );
    }

    /*******************************************************************************************************
    * @description validates the Batch's data import settings.  Used by UI as well as at runtime by the batch.
    * throws an exception if there are any invalid settings.
    * @param diBatch the batch to validate
    * @return void
    */
    public static void validateSettings(DataImportBatch__c dataImportBatch) {
        // make sure name set
        if (String.isBlank(dataImportBatch.Name)) {
            throw(new BDIException(Label.bdiErrorBatchNameRequired));
        }
        // defer all other validation to the actual settings
        validateSettings(diSettingsFromDiBatch(dataImportBatch));
    }

    /*******************************************************************************************************
    * @description validates the data import settings.  Used by UI as well as at runtime by the batch.
    * throws an exception if there are any invalid settings.
    * @return void
    */
    public static void validateSettings(Data_Import_Settings__c dataImportSettings) {

        String dataImportSettingsObject = UTIL_Namespace.StrTokenNSPrefix('Data_Import_Settings__c');
        String strDataImportObj = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');

        // validate matching rules
        if (dataImportSettings.Donation_Matching_Behavior__c != null &&
            dataImportSettings.Donation_Matching_Behavior__c != BDI_DataImport_API.DoNotMatch &&
            String.isBlank(dataImportSettings.Donation_Matching_Rule__c)) {

            throw(new BDIException(Label.bdiDonationMatchingRuleEmpty));
        }

        // validate Batch Process Size
        if (dataImportSettings.Batch_Size__c == null || dataImportSettings.Batch_Size__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new List<String>{
                    UTIL_Describe.getFieldLabelSafe(dataImportSettingsObject, UTIL_Namespace.StrTokenNSPrefix('Batch_Size__c'))
                }
            )));
        }

        // validate Donation Date Range
        if (dataImportSettings.Donation_Date_Range__c < 0) {
            throw(new BDIException(String.format(Label.bdiPositiveNumber,
                new List<String>{
                    UTIL_Describe.getFieldLabelSafe(
                        dataImportSettingsObject, UTIL_Namespace.StrTokenNSPrefix('Donation_Date_Range__c')
                    )
                }
            )));
        }

        // validate donation implementing class by instantiating it
        instantiateClassForInterface('BDI_IMatchDonations', dataImportSettings.Donation_Matching_Implementing_Class__c);

        // validate post process implementing class by instantiating it
        instantiateClassForInterface('BDI_IPostProcess', dataImportSettings.Post_Process_Implementing_Class__c);

        // ensure we are in the household account model!
        // if HEDA + Advancement is installed, one-to-one is also valid
        Boolean validAccountModel = CAO_Constants.isHHAccountModel() 
            || (ADV_PackageInfo_SVC.useAdv() && CAO_Constants.isOneToOne());
        if (!validAccountModel){
            throw(new BDIException(Label.bdiHouseholdModelRequired));
        }

        // validate settings
        if (dataImportSettings.Contact_Custom_Unique_ID__c != null) {
            // make sure c1 and c2 have the appropriately named field
            String strContact1 = strDIContactCustomIDField('Contact1', dataImportSettings);
            String strContact2 = strDIContactCustomIDField('Contact2', dataImportSettings);

            if (!UTIL_Describe.isValidField(strDataImportObj, strContact1) ||
                !UTIL_Describe.isValidField(strDataImportObj, strContact2)) {
                throw(new BDIException(String.format(Label.bdiContactCustomIdError,
                    new List<String>{ dataImportSettings.Contact_Custom_Unique_ID__c, strContact1, strContact2 })));
            }
        }

        if (dataImportSettings.Account_Custom_Unique_ID__c != null) {
            // make sure a1 and a2 have the appropriately named field
            String strAccount1 = strDIAccountCustomIDField('Account1', dataImportSettings);
            String strAccount2 = strDIAccountCustomIDField('Account2', dataImportSettings);

            if (!UTIL_Describe.isValidField(strDataImportObj, strAccount1) ||
                !UTIL_Describe.isValidField(strDataImportObj, strAccount2)) {
                throw(new BDIException(String.format(Label.bdiAccountCustomIdError,
                    new List<String>{ dataImportSettings.Account_Custom_Unique_ID__c, strAccount1, strAccount2 })));
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
        if (!setDMBehavior.contains(dataImportSettings.Donation_Matching_Behavior__c)) {
            throw(new BDIException(String.format(Label.bdiInvalidDonationMatchingBehavior,
                new List<String>{ dataImportSettings.Donation_Matching_Behavior__c })));
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
            DataImportBatch__c dataImportBatch = loadBatch(batchId);
            Integer cRecordsProcessed = [
                SELECT COUNT()
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c = :dataImportBatch.Id
                AND ApexJobId__c = :apexJobId
            ];
            Integer cRecordsSucceeded = [
                SELECT COUNT()
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c = :dataImportBatch.Id
                AND Status__c = :BDI_DataImport_API.bdiImported
                AND ApexJobId__c = :apexJobId
            ];
            Integer cRecordsFailed = cRecordsProcessed - cRecordsSucceeded;

            dataImportBatch.Last_Processed_On__c = System.now();
            dataImportBatch.Records_Successfully_Processed__c = cRecordsSucceeded;
            dataImportBatch.Records_Failed__c = cRecordsFailed;
            UTIL_DMLService.updateRecord(dataImportBatch);
        }
    }

    /*******************************************************************************************************
    * @description maps to keep track of the objects we will create.
    * all are indexed by the object's matching key or the dataImport.Id
    */
    public Map<String, Account> mapDIKeyToAccount = new Map<String, Account>();
    private Map<Id, Address__c> mapDIIdToAddr = new Map<Id, Address__c>();
    public Map<String, Id> campaignNameToCampaignId = new Map<String, Id>();
    private Map<String, Campaign> campaignNameToNewCampaign = new Map<String, Campaign>();
    private Map<String, List<DataImport__c>> newCampaignNameToDataImports = new Map<String, List<DataImport__c>>();

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
    private Boolean isCustomIdInAccountMatchRules {
        get {
            String str = diSettings.Account_Custom_Unique_ID__c;
            if (str == null || str == '') {
                return false;
            }
            return true;
        } private set;
    }

    /*******************************************************************************************************
    * @description whether the Account Custom Unique ID field is a String datatype
    */
    private Boolean isCustomIdInAccountDatatypeString {
        get {
            if (isCustomIdInAccountDatatypeString == null) {
                isCustomIdInAccountDatatypeString = false;
                if (isCustomIdInAccountMatchRules) {
                    Schema.DisplayType dt = UTIL_Describe.getFieldDisplaytype(
                        'Account', diSettings.Account_Custom_Unique_ID__c
                    );

                    if (dt == Schema.DisplayType.String ||
                        dt == Schema.DisplayType.TextArea ||
                        dt == Schema.DisplayType.Id ||
                        dt == Schema.DisplayType.URL ||
                        dt == Schema.DisplayType.Phone ||
                        dt == Schema.DisplayType.Reference) {
                        isCustomIdInAccountDatatypeString = true;
                    }

                }
            }
            return isCustomIdInAccountDatatypeString;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Sets diSettings based on the input settings. The method is called from tests only 
    * since the variable is global with private set().
    * @param diSettings Data Import Settings
    * @return void
    */
    @TestVisible
    private void injectDataImportSettings(Data_Import_Settings__c settings) {
        this.diSettings = settings;
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
        if (str == null) {
            return '';
        } else {
            return str;
        }
    }

    /*******************************************************************************************************
    * @description label to use for matched existing records, taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedExisting() {
        return isDryRun ? System.Label.bdiDryRunMatched : System.Label.bdiMatched;
    }

    /*******************************************************************************************************
    * @description label to use for matched best records (donations), taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedBest() {
        return isDryRun ? System.Label.bdiDryRunMatchedBest : System.Label.bdiMatchedBest;
    }

    /*******************************************************************************************************
    * @description label to use for matched by Id (donations), taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedById() {
        return isDryRun ? System.Label.bdiDryRunMatchedId : System.Label.bdiMatchedId;
    }

    /*******************************************************************************************************
    * @description label to use for matched none (donations), taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedNone() {
        return isDryRun ? System.Label.bdiDryRunNoMatch : System.Label.bdiMatchedNone;
    }

    /*******************************************************************************************************
    * @description label to use for matches to new records going to be created, taking into account if in Dry Run
    * @return String
    */
    public String statusMatchedNew() {
        return isDryRun ? System.Label.bdiDryRunNoMatch : System.Label.bdiMatched;
    }

    /*******************************************************************************************************
    * @description label to use for matches to new records going to be created, taking into account if in Dry Run
    * @return String
    */
    public String statusCreatedNew() {
        return isDryRun ? System.Label.bdiDryRunNoMatch : System.Label.bdiCreated;
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
    public static void execute(Id apexJobId, Data_Import_Settings__c dataImportSettings, List<DataImport__c> dataImports,
        Boolean isDryRun) {

        BDI_DataImportService dataImportService = new BDI_DataImportService(isDryRun);
        dataImportService.process(apexJobId, dataImportSettings, dataImports);
    }

    /*******************************************************************************************************
    * @description The real work gets done here! Given a list of data import records, process them.
    * @param apexJobId the apexJob that this is executing under
    * @param diSettings the settings to control processing behavior
    * @param listDI a list of Data Import records to import
    * @return void
    */
    public void process(Id apexJobId, Data_Import_Settings__c dataImportSettings, List<DataImport__c> dataImports) {

        // initialize our performance logger
        perfLogger = new BDI_PerfLogger(dataImports[0].NPSP_Data_Import_Batch__c, dataImports.size());
        BDI_PerfLogger.PerfLog pl;

        SavePoint sp = Database.setSavepoint();

        try {
            this.listDI = dataImports;
            this.diSettings = dataImportSettings;

            // first set a clean state for each DI
            for (DataImport__c dataImport : dataImports) {
                dataImport.Status__c = null;
                dataImport.ImportedDate__c = null;
                dataImport.ApexJobId__c = null;
                dataImport.FailureInformation__c = null;
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
            List<DataImport__c> dataImportErrors = new List<DataImport__c>();
            for (DataImport__c dataImport : dataImports) {
                dataImportErrors.add(new DataImport__c(
                    Id = dataImport.Id,
                    Status__c = statusDIFailed(),
                    FailureInformation__c = dataImport.Status__c == statusDIFailed() ? dataImport.FailureInformation__c : e.getMessage(),
                    ApexJobId__c = apexJobId
                ));
            }

            UTIL_DMLService.updateRecords(dataImportErrors);

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
        for (DataImport__c dataImport : listDI) {
            if (dataImport.Status__c == null) {
                dataImport.Status__c = statusDISuccess();
            } else if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                dataImport.Status__c = statusDIFailed();
            }
            dataImport.ImportedDate__c = System.now();
            dataImport.ApexJobId__c = apexJobId;

            // because a contact might be first imported in C1 location, but then moved to another
            // household since it later shows up in C2, location, we can't be assured that the
            // contact's original household account is the same (and valid). Thus we must fixup
            // all Household Account Id lookups in our di records.
            Contact c1 = ContactFromDi(dataImport, 1);
            if (c1 != null) {
                dataImport.HouseholdAccountImported__c = c1.AccountId;
            }

            // our matching marks non-matches with created, assuming they will get created
            // but if there were errors that stopped that creation, let's clear the status
            if (dataImport.Contact1Imported__c == null && dataImport.Contact1ImportStatus__c == System.Label.bdiCreated) {
                dataImport.Contact1ImportStatus__c = null;
            }

            if (dataImport.Contact2Imported__c == null && dataImport.Contact2ImportStatus__c == System.Label.bdiCreated) {
                dataImport.Contact2ImportStatus__c = null;
            }

            if (dataImport.Account1Imported__c == null && dataImport.Account1ImportStatus__c == System.Label.bdiCreated) {
                dataImport.Account1ImportStatus__c = null;
            }

            if (dataImport.Account2Imported__c == null && dataImport.Account2ImportStatus__c == System.Label.bdiCreated) {
                dataImport.Account2ImportStatus__c = null;
            }
        }

        UTIL_DMLService.updateRecords(listDI);
    }

    /*******************************************************************************************************
    * @description if the user has specified a custom post process class, invoke it with our saved
    * DI records
    * @return void
    */
    private void customPostProcess() {
        BDI_IPostProcess iPostProcess =
            (BDI_IPostProcess)instantiateClassForInterface(
                'BDI_IPostProcess', diSettings.Post_Process_Implementing_Class__c
            );
        if (iPostProcess != null) {
            iPostProcess.process(this);
        }
    }

    /*******************************************************************************************************
    * @description instantiate a class for the provided interface
    */
    public static Object instantiateClassForInterface(String interfaceName, String className) {

        if (className == null || className == '') {
            return null;
        }

        Type classType = Type.forName(className);
        if (classType != null) {
            Object classInstance = classType.newInstance();

            if (interfaceName == 'BDI_IPostProcess' && classInstance instanceOf BDI_IPostProcess) {
                return classInstance;
            }

            if (interfaceName == 'BDI_IMatchDonations' && classInstance instanceOf BDI_IMatchDonations) {
                return classInstance;
            }
        }
        throw new BDIException(
            String.format(Label.bdiErrorInvalidIMatchDonations, new List<String>{className, interfaceName})
        );
    }

    /*******************************************************************************************************
    * @description Copies the specific error into the provide dataImport.
    * @param di the DataImport record
    * @param strError the error message
    * @param strStatusField the developer name of an additional status field to save the error message in
    * @return void
    */
    public void LogBDIError(DataImport__c dataImport, String errorMessage, String statusField) {
        dataImport.Status__c = BDI_DataImport_API.bdiFailed;
        dataImport.FailureInformation__c = errorMessage;
        if (statusField != null) {
            dataImport.put(statusField, errorMessage.left(255));
        }
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
    private class FLSException extends Exception {}

    /*******************************************************************************************************
    * @description our exception object for Data Import errors.
    */
    private class BDIException extends Exception {}

    /*******************************************************************************************************
    * @description flag to allow us to test out field level security exception
    */
    public static Boolean failFieldLevelSecurity = false;

    /*******************************************************************************************************
    * @description returns the target object (api name) for a given Data Import field
    * @param sourceFieldName the api name of the Data Import field
    * @return String the api name of the target object for that field, derived from the help text
    */
    public static String getTargetObject(String sourceFieldName) {

        // record type is special-cased by BDI so in some orgs, it has no help text
        // BGE needs this object for display purposes only
        if (sourceFieldName == UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c')) {
            return 'Opportunity';
        }

        sourceFieldName = sourceFieldName.toLowerCase();
        String dataImportObjectName = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(dataImportObjectName, sourceFieldName);
        String targetObject = dfr.inlineHelpText != null ? dfr.inlineHelpText.split('\\.')[0] : null;

        switch on targetObject {
            when 'Account', 'Contact', 'Opportunity' {
                return targetObject;
            }
            when 'Payment' {
                return 'npe01__OppPayment__c';
            }
            when 'Household' {
                return 'npo02__Household__c';
            }
            when 'Address' {
                return UTIL_Namespace.StrTokenNSPrefix('Address__c');
            }
            when else {
                // any unhandled object names in help text will be ignored but shouldn't throw a blocking error
                return targetObject;
            }
        }

    }

    /*******************************************************************************************************
    * @description returns the target field api name for a given Data Import field
    * @param sourceFieldName the api name of the Data Import field
    * @return String the api name of the target field for that source field, derived from the help text
    */
    public static String getTargetField(String sourceFieldName) {

        // record type is special-cased by BDI so in some orgs, it has no help text
        // BGE needs this for display purposes only
        if (sourceFieldName == UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c')) {
            return 'RecordTypeId';
        }

        sourceFieldName = sourceFieldName.toLowerCase();
        String dataImportObjectName = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(dataImportObjectName, sourceFieldName);
        String targetField = dfr.inlineHelpText != null ? dfr.inlineHelpText.split('\\.')[1] : null;

        return targetField;
    }

    /*******************************************************************************************************
    * @description returns a map of fields from the DataImport to fields for the given 'object',
    * from the list of DataImport Fields, which have the form DIObject.developerfieldname in the field's help text property.
    * @param dataImportObjectName the bdi object we care about (Contact1, Contact2, Account1, etc)
    * @param targetObjectName the underlying object the bdi object is (ie, Contact, Account, etc)
    * @param dataImportFields the DataImport fields to consider
    * @return Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    */
    global static Map<String, String> mapFieldsForDIObject(String dataImportObjectName, String targetObjectName, List<String> dataImportFields) {

        Map<String, String> dataImportFieldToTargetField = new Map<String, String>();

        for (String dataImportField : dataImportFields) {

            DescribeFieldResult fieldDescribe =
                UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), dataImportField);
            String helpText = fieldDescribe.getInlineHelpText();

            if (helpText != null && helpText != '') {
                List<String> parts = helpText.split('\\.', 2);

                if (parts.size() == 2 && parts[0] == dataImportObjectName && parts[1] != '') {
                    String fieldName = parts[1];
                    //if we aren't in the npsp namespace, remove those tokens from help text
                    //also removes tokens from actual detected namespace, if we happen to be
                    //in a non-npsp namespace
                    if (UTIL_Namespace.getNamespace() != 'npsp') {
                        String fieldNameOld = fieldName;
                        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);

                        //if we have a detected namespace, and removed a namespace from the current field
                        //add the current namespace back in, allowing this code to run in any namespace
                        if (fieldName != fieldNameOld && UTIL_Namespace.getNamespace() != '') {
                            fieldName = UTIL_Namespace.StrAllNSPrefix(fieldName);
                        }
                    }

                    // make sure they have permissions to modify the target field
                    // we can't do this in all tests, because many profiles won't have FLS set for all our new fields!
                    if (!Test.isRunningTest() || failFieldLevelSecurity) {
                        fieldDescribe = UTIL_Describe.getFieldDescribe(targetObjectName, fieldName);
                        Set<String> setAuditFields = new Set<String>{
                            'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid'
                        };
                        Boolean isAuditField = setAuditFields.contains(fieldName.toLowerCase());

                        if (failFieldLevelSecurity ||
                            fieldDescribe == null ||
                            !fieldDescribe.isCreateable() ||
                            (!isAuditField && !fieldDescribe.isUpdateable())) {
                                throw (new FLSException(
                                    String.format(System.Label.flsError, new List<String>{ targetObjectName + '.' + fieldName }
                                )));
                        }
                    }

                    dataImportFieldToTargetField.put(dataImportField, fieldName);
                }
            }
        }

        if (isCurrencyMapped(targetObjectName)) {
            addCurrencyIsoCode(dataImportFieldToTargetField);
        }

        return dataImportFieldToTargetField;
    }

    /*******************************************************************************************************
    * @description Checks if this is one of the objects where we want to have a currency mapped.
    * As of now, that object is Opportunity. Payment CurrencyISOCode is inherited from the Opportunity.
    * @param strBaseObj the underlying object the bdi object is (ie, Contact, Account, etc)
    * @return Boolean if the strBaseObj is an Opportunity.
    */
    private static Boolean isCurrencyMapped(String objectName) {
        return objectName.equalsIgnoreCase('Opportunity');
    }

    /*******************************************************************************************************
    * @description Adds the currencyisocode to the Map passed as parameter.
    * @param Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    * @return void.
    */
    private static void addCurrencyIsoCode(Map<String, String> fieldMap) {

        // handle multicurrency if it's enabled
        if (UserInfo.isMultiCurrencyOrganization()) {
            fieldMap.put('currencyisocode', 'CurrencyIsoCode');
        }
    }

    /*******************************************************************************************************
    * @description Copies non-null DI field values to the destination object, given the provided mapping.
    * also explicitly ignores boolean false's, since we can't differentiate null from false.
    * @param dataImport The DataImport record
    * @param dataImportField The DI field to copy from
    * @param objDst The object to copy to
    * @param mapDIFieldToDstField The field map from a DI field to the destination field
    * @return boolean True if copied, False is not copied.
    */
    public static Boolean isCopiedDIField(DataImport__c dataImport, String dataImportField, SObject destinationRecord,
        Map<String, String> mapDIFieldToDstField) {

        Object value = dataImport.get(dataImportField);

        // explicitly avoid updating unchecked booleans (since we can't tell the difference between null and false)
        if (value != null && value != false) {
            String destinationField = mapDIFieldToDstField.get(dataImportField);

            // if values haven't changed, don't copy it and say the object was modified!
            if (destinationRecord.get(destinationField) == value) {
                return false;
            }

            destinationRecord.put(destinationField, value);
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
    @TestVisible private void disableAllOppRollups() {
        if (diSettings.Run_Opportunity_Rollups_while_Processing__c) {
            return;
        }

        TDTM_Config_API.disableAllRollupTriggers();
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
        if (mapDIFieldToHHField.size() == 0) {
            return;
        }

        // holds the Households that need updating
        List<Account> householdsToUpdate = new List<Account>();
        Set<Id> setHHIdUpdate = new Set<Id>();
        List<DataImport__c> listDIUpdate = new List<DataImport__c>();

        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            if (dataImport.HouseholdAccountImported__c == null) {
                continue;
            }

            Boolean isModified = false;
            Account household = new Account(Id = dataImport.HouseholdAccountImported__c);
            for (String dataImportField : mapDIFieldToHHField.keySet()) {
                if (isCopiedDIField(dataImport, dataImportField, household, mapDIFieldToHHField)) {
                    isModified = true;
                }
            }

            if (isModified && setHHIdUpdate.add(household.Id)) {
                householdsToUpdate.add(household);
                listDIUpdate.add(dataImport);
            }

        }

        //UTIL_Debug.debug('****DJH about to upsert household Accounts: ' + householdsToUpdate);
        List<Database.UpsertResult> listUR = UTIL_DMLService.upsertRecords(householdsToUpdate, false);
        for (Integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listDIUpdate[i], ur.getErrors()[0].getMessage(), null);
            }
        }
    }

    /*******************************************************************************************************
    * @description returns the field name of the Contact CustomID field for contact1 or contact2 in the
    * Data Import object.
    * @param contactReference  which contact to reference (Contact1 or Contact2)
    * @param dataImportSettings the settings object to read the setting from
    * @return String
    */
    public static String strDIContactCustomIDField(String contactReference, Data_Import_Settings__c dataImportSettings) {
        return strDICustomIDField(contactReference, dataImportSettings.Contact_Custom_Unique_ID__c);
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
    * the resultant field.  dataImport.get(fieldname) works without the namespace.
    *
    * @param objectReference  which object to reference (Contact1, Contact2, Account1, Account2)
    * @param customField the custom field from the object
    * @return String
    */
    @TestVisible private static String strDICustomIDField(String objectReference, String customField) {
        if (customField == null) {
            return null;
        }

        // handle standard fields
        if (!customField.endsWith('__c')) {
            if (Test.isRunningTest()) {
                return UTIL_Namespace.StrTokenNSPrefix(objectReference + '_' + customField + '__c');
            } else {
                return objectReference + '_' + customField + '__c';
            }
        }

        // look for namespace
        Integer i = customField.indexOf('__');
        if (i != -1 && i <> customField.indexOf('__c')) {
            // is it our namespace, in which case this is probably unmanaged npsp code,
            // so any manual testing will need the namespace in the DI custom field.
            if (customField.left(i).equalsIgnoreCase(UTIL_Namespace.getNamespace())) {
                return UTIL_Namespace.StrTokenNSPrefix(objectReference + '_' + customField.subString(i + 2));
            } else {
                // skip namespace
                return objectReference + '_' + customField.subString(i + 2);
            }
        }

        // custom fields without namespace
        return objectReference + '_' + customField;
    }

    /*******************************************************************************************************
    * @description finds a contact in our map, by matching against all the contact dikeys
    * @param dataImport the Data Import record
    * @param contactNumber 1 specifies Contact1 otherwise use Contact2
    * @return Contact the found Contact
    */
    global Contact contactFromDi(DataImport__c dataImport, Integer contactNumber) {
        return contactService.ContactFromDi(dataImport, contactNumber);
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
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            Account acc = AccountFromDi(dataImport, 1);
            if (acc == null) {
                continue;
            }

            Boolean isModified = false;
            for (String strDIField : mapDIFieldToA1Field.keySet()) {
                if (isCopiedDIField(dataImport, strDIField, acc, mapDIFieldToA1Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                Boolean isAlreadyAdded = false;
                for (String diKey : listDiKeyA1(dataImport)) {
                    if (!setDIKeyUpsert.add(diKey)) {
                        isAlreadyAdded = true;
                    }
                }
                if (!isAlreadyAdded) {
                    listAccUpsert.add(acc);
                    listDIUpsert.add(dataImport);
                }
            }
            // testing error handling
            if (Test.isRunningTest() && acc.Name != null && acc.Name.startsWith('FailTest')) {
                acc.Name = null;
            }
        }

        if (listAccUpsert.size() > 0) {
            List<Database.UpsertResult> listUR = Database.upsert(listAccUpsert, false);
            for (Integer i = 0; i < listUR.size(); i++) {
                Database.UpsertResult ur = listUR[i];
                if (!ur.isSuccess()) {
                    LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Account1ImportStatus__c');
                }
            }
        }

        // update each DI with its new Account1 ID
        // and set contact's primary affiliations
        Map<Id, Contact> mapConIdToConUpdate = new Map<Id, Contact>();
        for (DataImport__c dataImport : listDI) {
            if (dataImport.Account1Imported__c == null) {
                Account acc = AccountFromDi(dataImport, 1);
                if (acc != null) {
                    dataImport.Account1Imported__c = acc.Id;
                }
            }
            // set c1's primary affilation
            if (dataImport.Account1Imported__c != null) {
                Contact c1 = ContactFromDi(dataImport, 1);
                if (c1 != null && c1.Primary_Affiliation__c != dataImport.Account1Imported__c) {
                    c1.Primary_Affiliation__c = dataImport.Account1Imported__c;
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
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            Account acc = AccountFromDi(dataImport, 2);
            if (acc == null) {
                continue;
            }

            Boolean isModified = false;
            for (String strDIField : mapDIFieldToA2Field.keySet()) {
                if (isCopiedDIField(dataImport, strDIField, acc, mapDIFieldToA2Field)) {
                    isModified = true;
                }
            }
            if (isModified) {
                Boolean isAlreadyAdded = false;
                for (String diKey : listDiKeyA2(dataImport)) {
                    if (!setDIKeyUpsert.add(diKey)) {
                        isAlreadyAdded = true;
                    }
                }
                if (!isAlreadyAdded) {
                    listAccUpsert.add(acc);
                    listDIUpsert.add(dataImport);
                }
            }
            // testing error handling
            if (Test.isRunningTest() && acc.Name != null && acc.Name.startsWith('FailTest')) {
                acc.Name = null;
            }
        }

        if (listAccUpsert.size() > 0) {
            List<Database.UpsertResult> listUR = Database.upsert(listAccUpsert, false);
            for (Integer i = 0; i < listUR.size(); i++) {
                Database.UpsertResult ur = listUR[i];
                if (!ur.isSuccess()) {
                    LogBDIError(listDIUpsert[i], ur.getErrors()[0].getMessage(), 'Account2ImportStatus__c');
                }
            }
        }

        // update each DI with its new Account2 ID
        // and set contact's primary affiliations
        for (DataImport__c dataImport: listDI) {
            if (dataImport.Account2Imported__c == null) {
                Account acc = AccountFromDi(dataImport, 2);
                if (acc != null) {
                    dataImport.Account2Imported__c = acc.Id;
                }
            }
            // set c2's primary affilation
            if (dataImport.Account2Imported__c != null) {
                Contact c2 = ContactFromDi(dataImport, 2);
                if (c2 != null && c2.Primary_Affiliation__c != dataImport.Account2Imported__c) {
                    c2.Primary_Affiliation__c = dataImport.Account2Imported__c;
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
        if (acc == null) {
            return null;
        }

        List<String> listDiKey = new List<String>();

        // we need any Account SFId key to always be checked first when matching
        if (acc.Id != null) {
            listDiKey.add(acc.Id);
        }

        // we need the Account CustomId key to always be checked second when matching
        String strUniqueId = '';
        if (isCustomIDInAccountMatchRules &&
            (strUniqueId = strNull(acc.get(diSettings.Account_Custom_Unique_ID__c))) != '') {

            if (!isCustomIdInAccountDatatypeString) {
                strUniqueId = String.valueOf(Double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        if (acc.Name != null) {
            listDiKey.add(acc.Name + '|' + strUniqueId);
        }

        return listDiKey;
    }

    /*******************************************************************************************************
    * @description return the dikeys for Account1 in the given dataImport.
    * @param di the Data Import record
    * @return List<String> the diKeys for the account
    */
    private List<String> listDiKeyA1(DataImport__c dataImport) {
        return listDiKeyAx(dataImport, 'Account1');
    }

    /*******************************************************************************************************
    * @description return the dikeys for Account2 in the given dataImport.
    * @param di the Data Import record
    * @return List<String> the diKeys for the account
    */
    private List<String> listDiKeyA2(DataImport__c dataImport) {
        return listDIKeyAx(dataImport, 'Account2');
    }

    /*******************************************************************************************************
    * @description return the dikeys for specified Account in the given dataImport.
    * @param di the Data Import record
    * @param strAx specifies which Account, eg Account1 or Account2
    * @return List<String> the diKeys for the Account
    */
    private List<String> listDiKeyAx(DataImport__c dataImport, String strAx) {
        List<String> listDiKey = new List<String>();

        // we need the Account Lookup key to always be checked first when matching
        String strUniqueId = '';
        if ((strUniqueId = strNull(dataImport.get(strAx + 'Imported__c'))) != '') {
            listDiKey.add(strUniqueId);
            strUniqueId = '';
        }

        // we need the Account CustomId key to always be checked second when matching
        if (isCustomIDInAccountMatchRules &&
            (strUniqueId = strNull(dataImport.get(strDIAccountCustomIDField(strAx, diSettings)))) != '') {

            if (!isCustomIdInAccountDatatypeString) {
                strUniqueId = String.valueOf(Double.valueOf(strUniqueId));
            }
            listDiKey.add(strUniqueId);
        }

        // now create any other dikeys
        String strName;
        if ((strName = String.valueOf(dataImport.get(strAx + '_Name__c'))) != null) {
            listDiKey.add(strName + '|' + strUniqueId);
        }

        return listDiKey;
    }

    /*******************************************************************************************************
    * @description finds an Account in our map, by matching against all the Account dikeys
    * @param di the Data Import record
    * @param iAcc 1 specifies Account1 otherwise use Account2
    * @return Account the found Account
    */
    global Account AccountFromDi(DataImport__c dataImport, Integer iAcc) {
        for (String diKey : listDiKeyAx(dataImport, iAcc == 1 ? 'Account1' : 'Account2')) {
            Account acc = mapDIKeyToAccount.get(diKey);
            if (acc != null) {
                return acc;
            }
        }
        return null;
    }

    /*******************************************************************************************************
    * @description looks for existing Accounts that match A1 or A2, and if found,
    * updates their Id's in the Di's. if not found, creates a new account object for that dataImport.
    * @return void
    */
    private void matchExistingAccounts() {

        Set<String> setName = new Set<String>();
        Set<String> setCustomIDString = new Set<String>();
        Set<Double> setCustomIDNumber = new Set<Double>();
        Set<Id> setSFId = new Set<Id>();
        String a1CustomIDField = BDI_DataImportService.strDIAccountCustomIDField('Account1', diSettings);
        String a2CustomIDField = BDI_DataImportService.strDIAccountCustomIDField('Account2', diSettings);


        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            // a1
            if (dataImport.Account1Imported__c != null) {
                setSFId.add(dataImport.Account1Imported__c);
            }

            if (dataImport.Account1_Name__c != null) {
                setName.add(dataImport.Account1_Name__c);
            }

            if (isCustomIDInAccountMatchRules) {
                Object val = dataImport.get(a1CustomIDField);
                if (val != null) {
                    if (isCustomIdInAccountDatatypeString) {
                        setCustomIDString.add(String.valueOf(val));
                    } else {
                        setCustomIDNumber.add(Double.valueOf(val));
                    }
                }
            }
            // a2
            if (dataImport.Account2Imported__c != null) {
                setSFId.add(dataImport.Account2Imported__c);
            }

            if (dataImport.Account2_Name__c != null) {
                setName.add(dataImport.Account2_Name__c);
            }

            if (isCustomIDInAccountMatchRules) {
                Object val = dataImport.get(a2CustomIDField);
                if (val != null) {
                    if (isCustomIdInAccountDatatypeString) {
                        setCustomIDString.add(String.valueOf(val));
                    } else {
                        setCustomIDNumber.add(Double.valueOf(val));
                    }
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

        if (isCustomIDInAccountMatchRules && isCustomIdInAccountDatatypeString) {
            strSoql += ' OR ' + diSettings.Account_Custom_Unique_ID__c + ' IN :setCustomIDString';
        } else if (isCustomIDInAccountMatchRules && !isCustomIdInAccountDatatypeString) {
            strSoql += ' OR ' + diSettings.Account_Custom_Unique_ID__c + ' IN :setCustomIDNumber';
        }

        BDI_PerfLogger.PerfLog pl = perfLogger.newPerfLog('SOQL existing Accounts', BDI_PerfLogger.QUERY);
        List<Account> listAcc = Database.query(strSoql);
        pl.stop();

        // put all Accounts into our map
        for (Account acc : listAcc) {
            for (String diKey : listDiKeyAccount(acc)) {
                mapDIKeyToAccount.put(dikey, acc);
            }
        }

        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            Account acc = AccountFromDi(dataImport, 1);
            List<String> listDiKey = listDiKeyA1(dataImport);
            if (acc != null) {
                dataImport.Account1Imported__c = acc.Id;
                dataImport.Account1ImportStatus__c = (acc.Id != null ? statusMatchedExisting() : statusMatchedNew());
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                dataImport.Account1ImportStatus__c = statusCreatedNew();
            }
            // make sure all dikeys for that account are in the map
            for (String diKey : listDiKey) {
                mapDIKeyToAccount.put(diKey, acc);
            }

            acc = AccountFromDi(dataImport, 2);
            listDiKey = listDiKeyA2(dataImport);
            if (acc != null) {
                dataImport.Account2Imported__c = acc.Id;
                dataImport.Account2ImportStatus__c = (acc.Id != null ? statusMatchedExisting() : statusMatchedNew());
            } else if (listDiKey.size() > 0) {
                acc = new Account();
                dataImport.Account2ImportStatus__c = statusCreatedNew();
            }
            // make sure all dikeys for that account are in the map
            for (String diKey : listDiKey) {
                mapDIKeyToAccount.put(diKey, acc);
            }
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
                mapDIFieldToA1Field = BDI_DataImportService.mapFieldsForDIObject(
                    'Account1', 'Account', BDI_DataImportService.listStrDataImportFields
                );
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
                mapDIFieldToA2Field =
                    BDI_DataImportService.mapFieldsForDIObject(
                        'Account2', 'Account', BDI_DataImportService.listStrDataImportFields
                    );
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
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            Contact con = ContactFromDi(dataImport, 1);
            if (con != null && con.AccountId != null) {
                setHHId.add(con.AccountId);
            }
        }
        BDI_PerfLogger.PerfLog pl = perfLogger.newPerfLog('SOQL existing Addresses', BDI_PerfLogger.QUERY);
        List<Address__c> listAddrExisting = [
            SELECT Id,
                Household_Account__c,
                MailingStreet__c,
                MailingCity__c,
                MailingState__c,
                MailingPostalCode__c
            FROM Address__c
            WHERE Household_Account__c IN :setHHId
        ];
        pl.stop();

        Map<String, Id> mapHHAddrKeyToId = new Map<String, Id>();
        for (Address__c addr : listAddrExisting) {
            mapHHAddrKeyToId.put(strKeyOfAddr(addr), addr.Id);
        }

        Map<String, String> mapDIFieldToAddrField =
            mapFieldsForDIObject('Address', UTIL_Namespace.StrTokenNSPrefix('Address__c'), listStrDataImportFields);
        List<Address__c> addressesToInsert = new List<Address__c>();
        List<DataImport__c> dataImportsToInsert = new List<DataImport__c>();
        Map<String, Address__c> mapHHAddrKeyToAddrNew = new Map<String, Address__c>();
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            Contact con = ContactFromDi(dataImport, 1);
            Address__c address = new Address__c();
            address.Address_Type__c = 'Home';
            address.Default_Address__c = true;
            address.Household_Account__c = (con != null ? con.AccountId : null);
            Boolean isEmpty = true;
            for (String dataImportField : mapDIFieldToAddrField.keySet()) {
                if (isCopiedDIField(dataImport, dataImportField, address, mapDIFieldToAddrField)) {
                    isEmpty = false;
                }
            }
            if (!isEmpty) {
                // only create Home Address if we have a household
                if (con == null || con.AccountId == null) {
                    dataImport.HomeAddressImportStatus__c = System.Label.bdiIgnored;
                    continue;
                }

                // check to see if we already have this address in this hh.
                Id addressId = mapHHAddrKeyToId.get(strKeyOfAddr(address));
                if (addressId != null) {
                    dataImport.HomeAddressImported__c = addressId;
                    dataImport.HomeAddressImportStatus__c = statusMatchedExisting();
                } else {
                    // see if we are already creating this new address
                    Address__c addrNew = mapHHAddrKeyToAddrNew.get(strKeyOfAddr(address));
                    if (addrNew != null) {
                        address = addrNew;
                        dataImport.HomeAddressImportStatus__c = statusMatchedNew();
                    } else {
                        mapHHAddrKeyToAddrNew.put(strKeyOfAddr(address), address);
                        addressesToInsert.add(address);
                        dataImportsToInsert.add(dataImport);
                        dataImport.HomeAddressImportStatus__c = statusCreatedNew();
                    }
                    mapDIIdToAddr.put(dataImport.Id, address);
                }
            }
            if (Test.isRunningTest() && address.MailingCity__c != null && address.MailingCity__c.startsWith('FailTest')) {
                address.Household_Account__c = dataImport.Id;  // a bogus id for this field
            }
        }

        // done matching for Dry Run
        if (isDryRun) {
            return;
        }

        // two prong strategy! if any address object fails to save, do one
        // address record at a time, so we can log the failing address with the correct bdi record.
        try  {
            UTIL_DMLService.insertRecords(addressesToInsert);
        } catch (Exception ex) {
            for (Integer i = 0; i < addressesToInsert.size(); i++) {
                Database.SaveResult sr = UTIL_DMLService.insertRecord(addressesToInsert[i], false);
                if (!sr.isSuccess()) {
                    LogBDIError(dataImportsToInsert[i], sr.getErrors()[0].getMessage(), 'HomeAddressImportStatus__c');
                }
            }
        }

        // update each DI with its new home address
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            if (dataImport.HomeAddressImported__c == null) {
                Address__c addr = mapDIIdToAddr.get(dataImport.Id);
                if (addr != null && addr.Id != null) {
                    dataImport.HomeAddressImported__c = addr.Id;
                    dataImport.HomeAddressImportStatus__c = statusCreatedNew();
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
        return addr.Household_Account__c + addr.MailingStreet__c + addr.MailingCity__c + addr.MailingState__c +
            addr.MailingPostalCode__c;
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
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            if (dataImport.HouseholdAccountImported__c != null) {
                setHHId.add(dataImport.HouseholdAccountImported__c);
            }
        }
        Map<Id, Account> mapHHIdToAcc = new Map<Id, Account>([
            SELECT Id,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingPostalCode,
                BillingCountry
            FROM Account
            WHERE Id IN :setHHId
        ]);

        // now update home address on the contacts and hh account
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }
            Contact con1 = ContactFromDi(dataImport, 1);
            Contact con2 = ContactFromDi(dataImport, 2);
            Account accHH = mapHHIdToAcc.get(dataImport.HouseholdAccountImported__c);

            if (dataImport.Home_Street__c != null ||
                dataImport.Home_City__c != null ||
                dataImport.Home_State_Province__c != null ||
                dataImport.Home_Zip_Postal_Code__c != null ||
                dataImport.Home_Country__c != null) {

                // use an Address object, so we can leverage the copy methods that support state & country picklists.
                Address__c addr = new Address__c();
                addr.MailingStreet__c = dataImport.Home_Street__c;
                addr.MailingCity__c = dataImport.Home_City__c;
                addr.MailingState__c = dataImport.Home_State_Province__c;
                addr.MailingPostalCode__c = dataImport.Home_Zip_Postal_Code__c;
                addr.MailingCountry__c = dataImport.Home_Country__c;
                addr.Address_Type__c = 'Home';

                if (con1 != null) {
                    ADDR_Addresses_TDTM.copyAddressAddrSObj(addr, con1, 'Mailing', 'npe01__Primary_Address_Type__c');
                    if (setIdUpdate.add(con1.Id)) {
                        listCon1Update.add(con1);
                        listCon1Di.add(dataImport);
                    }
                }
                if (con2 != null) {
                    ADDR_Addresses_TDTM.copyAddressAddrSObj(addr, con2, 'Mailing', 'npe01__Primary_Address_Type__c');
                    if (setIdUpdate.add(con2.Id)) {
                        listCon2Update.add(con2);
                        listCon2Di.add(dataImport);
                    }
                }
                if (accHH != null) {
                    ADDR_Addresses_TDTM.copyAddressAddrSObj(addr, accHH, 'Billing', null);
                    if (setIdUpdate.add(accHH.Id)) {
                        listAccUpdate.add(accHH);
                        listAccDi.add(dataImport);
                    }
                }
            }
        }

        // now update the objects
        List<Database.UpsertResult> listUR = UTIL_DMLService.upsertRecords(listCon1Update, false);
        for (Integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listCon1Di[i], ur.getErrors()[0].getMessage(), 'Contact1ImportStatus__c');
            }
        }
        listUR = UTIL_DMLService.upsertRecords(listCon2Update, false);
        for (Integer i = 0; i < listUR.size(); i++) {
            Database.UpsertResult ur = listUR[i];
            if (!ur.isSuccess()) {
                LogBDIError(listCon2Di[i], ur.getErrors()[0].getMessage(), 'Contact2ImportStatus__c');
            }
        }
        listUR = UTIL_DMLService.upsertRecords(listAccUpdate, false);
        for (Integer i = 0; i < listUR.size(); i++) {
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
        Set<String> uniqueCampaignNames = new Set<String>();

        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            if (dataImport.Donation_Campaign_Name__c != null) {
                uniqueCampaignNames.add(dataImport.Donation_Campaign_Name__c);
            }
        }

        // add the existing campaigns to our map
        List<Campaign> uniqueCampaigns = [
                SELECT Id, Name
                FROM Campaign
                WHERE Name IN :uniqueCampaignNames
                ORDER BY CreatedDate DESC
        ];

        for (Campaign cmp : uniqueCampaigns) {
            campaignNameToCampaignId.put(cmp.Name, cmp.Id);
        }

        // create any new campaigns and set status fields
        for (DataImport__c dataImport : listDI) {
            // skip di's that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            String campaignName = dataImport.Donation_Campaign_Name__c;

            setCampaignImportStatusField(dataImport);
            setCampaignIdIfMatchedByName(dataImport, campaignName);

            // Create a new Campaign during processing if no match on Name
            if (!isDryRun && dataImport.DonationCampaignImportStatus__c == System.Label.bdiMatchedNone) {

                createNewCampaignIfUnique(campaignName);
                associateCampaignWithDataImport(dataImport, campaignName);

            }
        }

        List<Campaign> campaignsToInsert = campaignNameToNewCampaign.values();

        List<Database.SaveResult> saveResults = UTIL_DMLService.insertRecords(campaignsToInsert, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult sr = saveResults[i];
            String campaignName = campaignsToInsert[i].Name;
            campaignNameToCampaignId.put(campaignName, sr.getId()); //necessary for importing Campaign Members
            List<DataImport__c> dataImportsToUpdateForSavedCampaign = newCampaignNameToDataImports.get(campaignName);

            for (DataImport__c dataImport : dataImportsToUpdateForSavedCampaign) {
                if (!sr.isSuccess()) {
                    LogBDIError(dataImport, sr.getErrors()[0].getMessage(), 'DonationCampaignImportStatus__c');
                } else {
                    dataImport.DonationCampaignImported__c = sr.getId();
                    dataImport.DonationCampaignImportStatus__c = System.Label.bdiCreated;
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description determine matching status based on campaign ID and/or name
    * @param dataImport reference to the Data Import object to check and update
    * @return void
    */
    private void setCampaignImportStatusField(DataImport__c dataImport) {

        String campaignName = dataImport.Donation_Campaign_Name__c;
        String currentImportStatus = dataImport.DonationCampaignImportStatus__c; 
        Id campaignId = dataImport.DonationCampaignImported__c;

        // if we have a campaign Id, and it isn't populated from previous dry-run match, set the status
        if (campaignId != null && currentImportStatus != System.Label.bdiDryRunMatched) {
            dataImport.DonationCampaignImportStatus__c = System.Label.bdiMatchedId;
        } else if (campaignName != null) {
            Boolean campaignNameFound = campaignNameToCampaignId.containsKey(campaignName);
            if (campaignNameFound) {
                // The campaign exists!
                dataImport.DonationCampaignImportStatus__c = System.Label.bdiMatched;
            } else {
                dataImport.DonationCampaignImportStatus__c = System.Label.bdiMatchedNone;                
            }
        }
    }

    /*******************************************************************************************************
     * @description If the data import needs a match and the name matches a current campaign, populate the lookup
     * with the matched campaign id
     * @param dataImport reference to the Data Import object to check and update
     * @param campaignName the name of the Campaign in the Donation_Campaign_Name__c field on the Data Import
     * @return void
     */
    private void setCampaignIdIfMatchedByName(DataImport__c dataImport, String campaignName) {
        if (dataImport.DonationCampaignImported__c == null && campaignNameToCampaignId.containsKey(campaignName)) {
            dataImport.DonationCampaignImported__c = campaignNameToCampaignId.get(campaignName);
        }
    }

    /*******************************************************************************************************
     * @description Track duplicate campaign names so we only insert 1 campaign of the same name, but we associate
     * that campaign with all the DIs that reference it
     * @param dataImport the Data Import object to check
     * @param campaignName name of the Campaign in the Donation_Campaign_Name__c field on the Data Import
     * @return void
     */
    private void associateCampaignWithDataImport(DataImport__c dataImport, String campaignName) {
        //if we haven't created a list for this campaign name yet, create a new list in the newCampaignNameToDataImports for it
        if (!newCampaignNameToDataImports.containsKey(campaignName)) {
            newCampaignNameToDataImports.put(campaignName, new List<DataImport__c>());
        }
        newCampaignNameToDataImports.get(campaignName).add(dataImport);
    }

    /*******************************************************************************************************
     * @description Create new campaign to be inserted if we don't have one queued up with the same name already
     * @param campaignName the name of the Campaign in the Donation_Campaign_Name__c field on the Data Import
     * @return void
     */
    private void createNewCampaignIfUnique(String campaignName) {
        if (!campaignNameToNewCampaign.containsKey(campaignName)) {
            Campaign cmp = new Campaign(Name = campaignName, IsActive = true);
            campaignNameToNewCampaign.put(campaignName, cmp);
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
        for (DataImport__c dataImport : listDI) {
            // skip that already have an error
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                continue;
            }

            // only create CMs here for rows that don't have an opportunity
            if (dataImport.Donation_Campaign_Name__c != null && dataImport.DonationImported__c == null) {
                // assume errors would have already been thrown
                Id campaignId = campaignNameToCampaignId.get(dataImport.Donation_Campaign_Name__c);
                String diStatus =
                    String.isBlank(dataImport.Campaign_Member_Status__c) ?
                        Label.campaignMemberStatusDefault : dataImport.Campaign_Member_Status__c;

                if (dataImport.Contact1Imported__c != null) {
                    newCmContactIds.add(dataImport.Contact1Imported__c);
                    listCampaignIds.add(campaignId); // current campaign for row
                    listCmStatues.add(diStatus);
                }
                if (dataImport.Contact2Imported__c != null) {
                    newCmContactIds.add(dataImport.Contact2Imported__c);
                    listCampaignIds.add(campaignId); // current campaign for row
                    listCmStatues.add(diStatus);
                }
            }
        }

        // return DML wrapper for new CMs
        TDTM_Runnable.DMLWrapper newCmWrapper =
            CON_AddToCampaign.CreateCampaignMembers(newCmContactIds, listCampaignIds, listCmStatues);

        // process dmls for CMs
        TDTM_TriggerHandler.processDML(newCmWrapper);
    }

}