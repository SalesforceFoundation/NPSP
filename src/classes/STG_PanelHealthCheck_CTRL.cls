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
* @group Settings
* @description Controller for the Health Check wizard
*/
public without sharing class STG_PanelHealthCheck_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description The panel's constructor
    */
    public STG_PanelHealthCheck_CTRL() {
        isRunningDetector = false;
        listDR = new List<DetectResult>();
    }

    /*********************************************************************************************************
    * @description Returns the String Id of the Health Check panel.
    */
    public override String idPanel() { return 'idPanelHealthCheck'; }

    /*********************************************************************************************************
    * @description Whether Health Check is currently running
    */
    public boolean isRunningDetector { get; set; }

    /*********************************************************************************************************
    * @description Whether Health Check has results to report
    */
    public boolean hasResults {
        get {
            return (listDR != null && listDR.size() > 0);
        } private set;
    }

    /*********************************************************************************************************
    * @description Save Error Settings "Disable Record Data Health Checks" checkbox
    *   related to the data Health Check verification.
    * @return PageReference 
    */
    public override PageReference saveSettings() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
            Boolean hasUpdatePermission = UTIL_Describe.getObjectDescribe(
                String.valueOf(Error_Settings__c.SObjectType)
            ).isUpdateable();

            if (!hasUpdatePermission) {
                throw new HealthCheckException(
                    String.format(
                        System.Label.flsError,
                        new List<String>{Schema.SObjectType.Error_Settings__c.getLabel()})
                );
            }

            if (STG_Panel.stgService.stgErr != null && !Test.isRunningTest()) {
                update STG_Panel.stgService.stgErr;
            }

            //Clear out health check results when configuration changes.
            listDR = new List<DetectResult>();

        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }

        return null;
    }

    /*********************************************************************************************************
    * @description Custom exception for NPSP Health Check page
    */
    public class HealthCheckException extends Exception {}

    /*********************************************************************************************************
    * @description Whether all tests passed Health Check
    */
    public boolean isAllTestsPassed {
        get {
            if (!hasResults)
                return false;
            for (DetectResult dr : listDR) {
                if (dr.strStatus == statusError)
                    return false;
            }
            return true;
        } private set;
    }

    /*********************************************************************************************************
    * @description How long did Health Check take to run
    */
    public String strTime { get; set; }

    /*********************************************************************************************************
    * @description The current time
    */
    public String strNow {
        get {
            return datetime.now().format();  // this will put it in the time zone of the current user.
        } private set;
    }

    /*********************************************************************************************************
    * @description Action Method to run Health Check
    * @return null
    */
    public PageReference runDetector() {
        isRunningDetector = true;
        listDR.clear();
        runAllDetections();
        return null;
    }

    /*********************************************************************************************************
    * @description The list of DetectResults from Health Check
    */
    public List<DetectResult> listDR { get; private set; }

    /*********************************************************************************************************
    * @description Used to report back the results of each Health Check test
    */
    public class DetectResult {
        public String strName { get; set; }
        public String strStatus { get; set; }
        public String strDetails { get; set; }
        public String strSolution { get; set; }
    }

    /*******************************************************************************************************
    * @description status value for Success
    */
    public static final String statusSuccess = 'Success';

    /*******************************************************************************************************
    * @description status value for Warning
    */
    public static final String statusWarning = 'Warning';

    /*******************************************************************************************************
    * @description status value for Error
    */
    public static final String statusError = 'Error';

    /*********************************************************************************************************
    * @description Creates and Stores a DetectResult
    * @param strName The test name
    * @param strStatus The status ('Success', 'Error', 'Warning')
    * @param strDetails The error details
    * @param strSolution The suggested solution to the problem
    * @return void
    */
    public void createDR(String strName, String strStatus, String strDetails, String strSolution) {
        DetectResult dr = new DetectResult();
        dr.strName = strName;
        dr.strStatus = strStatus;
        dr.strDetails = strDetails;
        dr.strSolution = strSolution;
        if (strStatus == statusSuccess && listDR.size() > 0)
            listDR.add(0, dr);
        else
            listDR.add(dr);
    }

    /*********************************************************************************************************
    * @description calls all of the specific detection routines
    */
    private void runAllDetections() {

        DateTime dtStart = system.now();

        verifyRecordTypes();
        verifyAccountModel();
        verifyAccountModelRecordType();
        verifyReports();
        verifyFields();
        new STG_PanelADDRVerification_CTRL().verifyAddressVerificationService(this);
        STG_PanelPaymentMapping_CTRL.verifyPaymentMappings(this);
        STG_PanelUserRollup_CTRL.verifyUserRollups(this);
        STG_PanelRDCustomFieldMapping_CTRL.verifyRDMappings(this);
        STG_PanelRDHealthCheck.verifyRecurringDonationConfiguration(this);
        STG_PanelRelAuto_CTRL.verifyAutoCreateRels(this);
        STG_PanelRelReciprocal_CTRL.verifyRelLookups(this);
        STG_PanelOppRollups_CTRL.verifyFiscalYearRollups(this);
        STG_PanelOpps_CTRL.verifyOpportunityStageForPaymentAutoCloseIsActiveClosedWon(this);
        verifyScheduledJobs();
        STG_PanelERR_CTRL.verifyErrorSettings(this);
        verifyOppContactRolesSettings();
        verifyTriggerHandlers();
        verifyLevels();

        if (STG_Panel.stgService.stgErr.DisableRecordDataHealthChecks__c == true) {
            addDisableRecordHealthCheckWarnings();

        } else {
            executeDataRecordsHealthChecks();
        }

        DateTime dtEnd = system.now();
        double msec = dtEnd.getTime() - dtStart.getTime();
        strTime = String.valueOf(double.valueOf(msec / 1000));
    }

    /*********************************************************************************************************
    * @description Execute all the record data health checks
    */
    private void executeDataRecordsHealthChecks() {
        verifyAccountData();
        verifyAccountData2();
        verifyContactData();
        verifyNoOrphanedHouseholds();
        verifyNoOrphanedOne2OneAccounts();
        verifyOppContactRoles();
        verifyNoMissingOppPayments();
    }

    /*********************************************************************************************************
    * @description Generate warning messages for disabled record health checks
    */
    private void addDisableRecordHealthCheckWarnings() {
        List<String> healthChecksNotRun = new List<String> {
            System.Label.healthLabelAccountModelData,
            System.Label.healthLabelContactData,
            System.Label.healthLabelHHAccData,
            System.Label.healthLabelAccountData,
            System.Label.healthLabelOCRCheck,
            System.Label.healthLabelOppPayments
        };

        createDR(
            System.Label.healthLabelDataBatchNotRun,
            statusWarning,
            null,
            String.join(healthChecksNotRun, '; ')
        );
    }

    /*********************************************************************************************************
    * @description Verifies settings are consistent with the chosen Account Model
    */
    private void verifyAccountModel() {
        String strAccModel = UTIL_Describe.getFieldLabel('npe01__Contacts_And_Orgs_Settings__c', 'npe01__Account_Processor__c');

        if (CAO_Constants.isHHAccountModel()) {
            if (STG_Panel.stgService.stgHH.npo02__Household_Rules__c != HH_Households.NO_HOUSEHOLDS_PROCESSOR) {
                String strHHRules = UTIL_Describe.getFieldLabel('npo02__Households_Settings__c', 'npo02__Household_Rules__c');
                createDR(strHHRules, statusError, label.healthDetailsHHAccountModel,
                    String.format(label.healthSolutionEditSetting, new String[]{strHHRules, Label.stgNavPeople, Label.stgNavHouseholds} ));
                return;
            }
        } else if (CAO_Constants.isOneToOne()) {
            // nothing to check
        } else if (CAO_Constants.isBucketModel()) {
            // nothing to check
        } else {
            createDR(strAccModel, statusError, label.healthDetailsAccountModel,
                String.format(label.healthSolutionEditSetting, new String[]{strAccModel, Label.stgNavPeople, Label.stgNavAccountModel} ));
            return;
        }
        createDR(strAccModel, statusSuccess, null, STG_Panel.stgService.stgCon.npe01__Account_Processor__c);
    }

    /*********************************************************************************************************
    * @description Verifies Account data is consistent with the chosen Account Model
    */
    private void verifyAccountData() {
        Integer cBucket = 0;
        Integer cOne2One = 0;
        Integer cHH = 0;
        boolean isMixedAccs = false;

        try {
            cBucket = [SELECT count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.BUCKET_ORGANIZATION_TYPE LIMIT 9999];
            cOne2One = [SELECT count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE LIMIT 9999];
            cHH = [SELECT count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE LIMIT 9999];
            if (cBucket > 0 && !CAO_Constants.isBucketModel())
                isMixedAccs = true;
            if (cOne2One > 0 && !CAO_Constants.isOneToOne())
                isMixedAccs = true;
            if (cHH > 0 && !CAO_Constants.isHHAccountModel())
                isMixedAccs = true;

            String strInfo = '';
            if (isMixedAccs) {
                strInfo = String.format(Label.healthDetailsAccountProcessor, new String[]{UTIL_CustomSettingsFacade.getContactsSettings().npe01__Account_Processor__c});
            }
            strInfo += '<br/>' + CAO_Constants.BUCKET_ORGANIZATION_TYPE + ': ' + cBucket + (cBucket == 9999 ? '+' : '');
            strInfo += '<br/>' + CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE + ': ' + cOne2One + (cOne2One == 9999 ? '+' : '');
            strInfo += '<br/>' + CAO_Constants.HH_ACCOUNT_TYPE + ': ' + cHH + (cHH == 9999 ? '+' : '');

            createDR(Label.healthLabelAccountModelData, isMixedAccs ? statusError : statusSuccess,  isMixedAccs ? strInfo : null,
               isMixedAccs ? label.healthSolutionAccountModel : strInfo);
        } catch (Exception ex) {
            createDR(Label.healthLabelAccountModelData, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies Account system fields match account record types
    */
    private void verifyAccountData2() {
        Integer cOne2One = 0;
        Integer cHH = 0;
        String strError = '';

        try {
            ID rectype = STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c;
            if (rectype != null) {
                cHH = [
                    SELECT count()
                    FROM Account
                    WHERE RecordTypeId = :rectype
                    AND (npe01__SYSTEM_AccountType__c != :CAO_Constants.HH_ACCOUNT_TYPE OR npe01__SYSTEMISINDIVIDUAL__c = false)
                    LIMIT 9999
                ];
                if (cHH > 0) {
                    strError += String.format(Label.healthDetailsAccountRTIssue, new String[]{String.valueOf(cHH), CAO_Constants.HH_ACCOUNT_TYPE});
                }
            }
            rectype = STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c;
            if (rectype != null) {
                cOne2One = [
                    SELECT count()
                    FROM Account
                    WHERE RecordTypeId = :rectype
                    AND (npe01__SYSTEM_AccountType__c != :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE OR npe01__SYSTEMISINDIVIDUAL__c = false)
                    LIMIT 9999
                ];

                if (cOne2One > 0) {
                    if (cHH > 0) strError += '<BR/>';
                    strError += String.format(Label.healthDetailsAccountRTIssue, new String[]{String.valueOf(cOne2One), CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE});
                }
            }

            if (cHH > 0 || cOne2One > 0) {
                createDR(Label.healthLabelAccountModelData, statusError, strError, Label.healthSolutionAccountRTIssue);
            } else {
                createDR(Label.healthLabelAccountModelData, statusSuccess, null, Label.healthLabelAccountRTIssueValid);
            }
        } catch (Exception ex) {
            createDR(Label.healthLabelAccountModelData, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies HouseHold and One To One RecordTypes are not the default RecordType for the current User.
    */
    @TestVisible
    private void verifyAccountModelRecordType() {
        try {

            Id npspHouseholdRecordType = STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c;
            Id npspOneToOneRecordType = STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c;
            Map<Id,Schema.RecordTypeInfo> accountRecordTypeInfosById = UTIL_Describe.getObjectDescribe('Account').getRecordTypeInfosById();

            //Check if the Household and the One To One Record Type in the Settings are valid.
            //This should never happen, unless the User manually updates the Account Model Record Type in the Custom Settings.
            if (
                (npspHouseholdRecordType != null && accountRecordTypeInfosById.keySet().contains(npspHouseholdRecordType) == false) ||
                (npspOneToOneRecordType != null && accountRecordTypeInfosById.keySet().contains(npspOneToOneRecordType) == false)
            ) {
                createDR(System.Label.healthLabelAccountDefaultRT, statusError, System.Label.healthDetailsAccountDefaultRTInvalid, System.Label.healthSolutionAccountDefaultRTInvalid);
                return;
            }

            //Check the Household and One To One Record Type in the Settings and create a failed test if it is the Default one on the Account.
            for (Schema.RecordTypeInfo accountRecordTypeInfo : accountRecordTypeInfosById.values()) {
                if (
                    accountRecordTypeInfo.isDefaultRecordTypeMapping() &&
                    (accountRecordTypeInfo.getRecordTypeId() == npspHouseholdRecordType || accountRecordTypeInfo.getRecordTypeId() == npspOneToOneRecordType)
                ) {
                    createDR(
                        System.Label.healthLabelAccountDefaultRT,
                        statusError,
                        String.format(System.Label.healthDetailsAccountDefaultRTIssue, new List<String>{accountRecordTypeInfo.getName().escapeEcmaScript()}),
                        System.Label.healthSolutionAccountDefaultRTIssue
                    );
                    return;
                }
            }

            //Create a success test
            createDR(System.Label.healthLabelAccountDefaultRT, statusSuccess, null, null);
        }
        catch(Exception ex) {
            createDR(System.Label.healthLabelAccountDefaultRT, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies that all Contacts have an account
    */
    private void verifyContactData() {
        try {
            Integer cContact = [SELECT Count() FROM Contact WHERE AccountId = null LIMIT 9999];
            if (cContact > 0) {
                createDR(Label.healthLabelContactData, statusError,
                   String.format(Label.healthDetailsContactData, new String[]{String.valueOf(cContact)}), label.healthSolutionContactData);
            } else {
                createDR(Label.healthLabelContactData, statusSuccess, null, null);
            }
        } catch (Exception ex) {
            createDR(Label.healthLabelContactData, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies there are no Households Accounts and Objects with no Contacts
    */
    private void verifyNoOrphanedHouseholds() {
        try {
            Integer cHHObj = [
                SELECT Count()
                FROM npo02__Household__c
                WHERE Number_of_Household_Members__c = 0
                LIMIT 9999
            ];
                //WHERE Id not in (SELECT npo02__Household__c FROM Contact WHERE npo02__Household__c <> null) LIMIT 9999];
            Integer cHHAcc = [
                SELECT Count()
                FROM Account
                WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE and
                    Number_of_Household_Members__c = 0
                LIMIT 9999
            ];
                    //Id not in (SELECT AccountId FROM Contact WHERE AccountId <> null and Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE) LIMIT 9999];
            if (cHHObj > 0) {
                createDR(Label.healthLabelHHObjData, statusError,
                    String.format(Label.healthDetailsHHObNoContacts, new String[]{String.valueOf(cHHObj)}),
                    Label.healthSolutionHHObjNoContacts);
            }
            if (cHHAcc > 0) {
                createDR(Label.healthLabelHHAccData, statusError,
                    String.format(Label.healthDetailsHHActNoContacts, new String[]{String.valueOf(cHHAcc)}),
                    Label.healthSolutionHHAccNoContacts);
            }
            if (cHHObj == 0 && cHHAcc == 0) {
                createDR(Label.healthLabelHHData, statusSuccess, null, null);
            }
        } catch (Exception ex) {
            createDR(Label.healthLabelHHAccData, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies there are no 1:1 Accounts with no Contacts
    */
    private void verifyNoOrphanedOne2OneAccounts() {
        try {
            Integer cAcc = [
                SELECT Count()
                FROM Account
                WHERE Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE
                    AND Account.npe01__One2OneContact__c = null
                LIMIT 9999
             ];
                    //Id not in (SELECT AccountId FROM Contact WHERE AccountId <> null AND Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) LIMIT 9999];
            if (cAcc > 0) {
                createDR(Label.healthLabelAccountData, statusError,
                    String.format(Label.healthDetailsAccOne2OneNoContacts, new String[]{String.valueOf(cAcc)}),
                    Label.healthSolutionAccOne2OneNoContacts);
            } else {
                createDR(Label.healthLabelAccountData, statusSuccess, null, null);
            }
        } catch (Exception ex) {
            createDR(Label.healthLabelAccountData, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies all reports exist that settings use
    */
    private void verifyReports() {
        String rptId = null;

        // Household Mailing List Report
        rptId = STG_Panel.stgService.stgHH.npo02__Household_Mailing_List_ID__c;
        String strField = UTIL_Describe.getFieldLabel('npo02__Households_Settings__c', 'npo02__Household_Mailing_List_ID__c');
        if (rptId != null && rptId != '') {
            List<Report> listRpt = [SELECT Id FROM Report WHERE Id = :rptId];
            if (listRpt.size() == 0) {
                createDR(strField, statusError,
                    String.format(Label.healthDetailsBadReportId, new String[]{rptId}),
                    String.format(label.healthSolutionEditSetting, new String[]{strField, Label.stgNavPeople, Label.stgNavHouseholds}));
                return;
            }
        } else {
            List<Report> listRpt = [SELECT Id FROM Report WHERE DeveloperName = 'NPSP_Campaign_Household_Mailing_List'];
            if (listRpt.size() == 0) {
                createDR(strField, statusError, Label.healthDetailsMailingListReportMissing,
                   String.format(Label.healthSolutionMailingListReportMissing, new String[]{Label.stgNavPeople, Label.stgNavHouseholds}));
               return;
            }
        }
        createDR(strField, statusSuccess, null, rptId);

    }

    /*********************************************************************************************************
    * @description Checks all fields that are used in settings
    */
    private void verifyFields() {
        // check Relationship Gender field on Contact
        String strSetting = UTIL_Describe.getFieldLabel('npe4__Relationship_Settings__c', 'npe4__Gender_Field__c');
        String strField = STG_Panel.stgService.stgRel.npe4__Gender_Field__c;
        if (strField != null && !UTIL_Describe.isValidField('Contact', strField)) {
            createDR(strSetting, statusError,
                String.format(Label.healthDetailsGenderField, new String[]{strField}),
                String.format(label.healthSolutionEditSetting, new String[]{strSetting, Label.stgNavRelationships, Label.stgNavRelationships}));
        } else {
            createDR(strSetting, statusSuccess, null, strField == null ? label.healthLabelNone : strField);
        }
    }

    /*********************************************************************************************************
    * @description Checks all settings that contain recordType ID's to make sure they are valid.
    */
    @TestVisible
    private void verifyRecordTypes() {
        checkRecordTypeId(Account.sObjectType, STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c,
            'npe01__Contacts_And_Orgs_Settings__c', 'npe01__HH_Account_RecordTypeID__c', Label.stgNavPeople, Label.stgNavAccountModel);
        checkRecordTypeId(Account.sObjectType, STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c,
            'npe01__Contacts_And_Orgs_Settings__c', 'npe01__One_to_One_RecordTypeID__c', Label.stgNavPeople, Label.stgNavAccountModel);
        checkMultiRecordTypeIds(Opportunity.sObjectType, STG_Panel.stgService.stgCon.Opp_RecTypes_Excluded_for_Payments__c,
            'npe01__Contacts_And_Orgs_Settings__c', UTIL_Namespace.StrTokenNSPrefix('Opp_RecTypes_Excluded_for_Payments__c'), Label.stgNavDonations, Label.stgNavPayments);

        checkRecordTypeId(Opportunity.sObjectType, STG_Panel.stgService.stgRD.npe03__Record_Type__c,
            'npe03__Recurring_Donations_Settings__c', 'npe03__Record_Type__c', Label.stgNavRecurringDonations, Label.stgNavRecurringDonations);

        checkMultiRecordTypeIds(Contact.sObjectType, STG_Panel.stgService.stgHH.npo02__Household_Creation_Excluded_Recordtypes__c,
            'npo02__Households_Settings__c', 'npo02__Household_Creation_Excluded_Recordtypes__c', Label.stgNavPeople, Label.stgNavHouseholds);
        checkMultiRecordTypeIds(Contact.sObjectType, STG_Panel.stgService.stgHH.npo02__Household_OCR_Excluded_Recordtypes__c,
            'npo02__Households_Settings__c', 'npo02__Household_OCR_Excluded_Recordtypes__c', Label.stgNavDonations, Label.stgNavContactRoles);
        if (! STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c) {
            checkMultiRecordTypeIds(Opportunity.sObjectType, STG_Panel.stgService.stgAllo.Excluded_Opp_RecTypes__c,
                    UTIL_Namespace.StrTokenNSPrefix('Allocations_Settings__c'), UTIL_Namespace.StrTokenNSPrefix('Excluded_Opp_RecTypes__c'), Label.stgNavDonations, Label.stgNavAllocations);
            checkMultiRecordTypeIds(Opportunity.sObjectType, STG_Panel.stgService.stgHH.npo02__Excluded_Account_Opp_Rectypes__c,
                    'npo02__Households_Settings__c', 'npo02__Excluded_Account_Opp_Rectypes__c', Label.stgNavDonations, Label.stgNavDonorStatistics);
            checkMultiRecordTypeIds(Opportunity.sObjectType, STG_Panel.stgService.stgHH.npo02__Excluded_Contact_Opp_Rectypes__c,
                    'npo02__Households_Settings__c', 'npo02__Excluded_Contact_Opp_Rectypes__c', Label.stgNavDonations, Label.stgNavDonorStatistics);
            checkMultiRecordTypeIds(Opportunity.sObjectType, STG_Panel.stgService.stgHH.npo02__Membership_Record_Types__c,
                    'npo02__Households_Settings__c', 'npo02__Membership_Record_Types__c', Label.stgNavDonations, Label.stgNavMembership);
        }

        // avoid reusing the same recordtype in Account models
        String idHH = STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c;
        String idOne = STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c;
        if (idHH != null && idOne != null && idHH == idOne) {
            String strField = UTIL_Describe.getFieldLabel('npe01__Contacts_And_Orgs_Settings__c', 'npe01__One_to_One_RecordTypeID__c');
            createDR(strField, statusError, label.healthDetailsDuplicateAcctRT,
                String.format(label.healthSolutionEditSetting, new String[]{strField, Label.stgNavPeople, Label.stgNavAccountModel}));
        }
    }

    /*********************************************************************************************************
    * @description Checks a setting that contains multiple Record Type Ids in a semi-colon delimeted String
    * @param objectType The Object to check Record Type against
    * @param values A semicolon separated String of values to check
    * @param settingsObject The Settings object
    * @param settingsField The Settings field
    * @param parentTab The parent tab the setting is on
    * @param settingsTab The tab the setting is on
    * @return void
    */
    private void checkMultiRecordTypeIds(
        sObjectType objectType, String values,
        String settingsObject, String settingsField,
        String parentTab, String settingsTab
    ) {
        if (values != null) {
            List<String> recordTypes = values.split(';',0);
            for (String recordType : recordTypes) {
                checkRecordTypeId(objectType, recordType, settingsObject, settingsField, parentTab, settingsTab);
            }
        } else {
            String fieldLabel = UTIL_Describe.getFieldLabel(settingsObject, settingsField);

        	createDR(fieldLabel, statusSuccess, null, Label.healthLabelNone);
        }
    }

    /*********************************************************************************************************
    * @description Checks whether the Record Type Id is valid, and logs an appropriate DetectResult
    * @param objectType The Object to check recordtypes against
    * @param recordType A Record Type Id
    * @param settingsObject The Settings object
    * @param settingsField The Settings field
    * @param parentTab The parent tab the setting is on
    * @param settingsTab The tab the setting is on
    * @return void
    */
    private void checkRecordTypeId(sObjectType objectType, String recordType, String settingsObject, String settingsField, String parentTab, String settingsTab) {
        String fieldLabel = UTIL_Describe.getFieldLabel(settingsObject, settingsField);

        String recordTypeName = recordType instanceOf Id
            ? UTIL_RecordTypes.GetRecordTypeName(objectType, recordType)
            : '';

        if (String.isNotBlank(recordType) && String.isBlank(recordTypeName)) {
            createDR(fieldLabel, statusError,
                String.format(label.healthDetailsInvalidRecordtypeId, new String[]{ recordType.escapeEcmaScript() }),
                String.format(label.healthSolutionEditSetting, new String[]{ fieldLabel, parentTab, settingsTab }));
        } else {
            if (String.isBlank(recordType)) {
                recordTypeName = Label.healthLabelNone;
            }
            createDR(fieldLabel, statusSuccess, null, recordTypeName.escapeEcmaScript());
        }
    }

    /*********************************************************************************************************
    * @description Verifies that our Master Scheduler jobs are actually scheduled, and that all of the entries are valid
    */
    private void verifyScheduledJobs() {
        try {
            // make sure all default jobs are scheduduled
            List<CronTrigger> jobs = [
                SELECT Id, CronJobDetail.Id
                FROM CronTrigger
                WHERE CronJobDetail.Name IN :UTIL_MasterSchedulableHelper.defaultScheduledJobs.keySet()
                AND CronJobDetail.JobType = '7'
            ];

            if (jobs.size() != UTIL_MasterSchedulableHelper.defaultScheduledJobs.size()) {
                createDR(
                    Label.healthLabelScheduler,
                    statusError,
                    Label.healthDetailsNothingScheduled,
                    label.healthSolutionNothingScheduled
                );
                return;
            }
            createDR(Label.healthLabelScheduler, statusSuccess, null, label.healthLabelSchedulerValid);
        } catch (Exception ex) {
            createDR(Label.healthLabelScheduler, statusError,  ex.getMessage(), null);
        }
    }

    /*********************************************************************************************************
    * @description Verifies that no Opportunities have multiple primary contact roles, which would throw off opp rollups.
    */
    @TestVisible
    private void verifyOppContactRoles() {
        try {
            // detect duplicate primary ocr's
            // we understand this will fail if there are over 50k OCR's in they system,
            // but it is better than nothing, since for many orgs that will be fine.
            Integer cOpp = 0;
            List<AggregateResult> listAR = [
                SELECT count(Id), OpportunityId
                FROM OpportunityContactRole
                WHERE IsPrimary=true group by OpportunityId having count(Id) > 1
                LIMIT 50000
            ];
            cOpp = listAR.size();

            if (cOpp > 0) {
                createDR(label.healthLabelOCRCheck, statusError,
                  String.format(label.healthDetailsOCRDupPrimary, new String[]{String.valueOf(cOpp)}), label.healthSolutionOCRDupPrimary);
            } else {
                createDR(label.healthLabelOCRCheck, statusSuccess, null, label.healthDetailsOCRDupPrimaryValid);
            }
        } catch (Exception ex) {
            createDR(Label.healthLabelOCRCheck, statusError, ex.getMessage(), label.healthSolutionOCRException);
        }
    }

    /*********************************************************************************************************
    * @description Verifies that no OCR settings are conflicting.
    */
    public void verifyOppContactRolesSettings() {
        List<String> invalidOCRSettings = STG_PanelContactRoles_CTRL.getInvalidOCRSettings();
        if (invalidOCRSettings.isEmpty()) {
            createDR(Label.healthLabelOCRSettings, statusSuccess, null, Label.healthDetailsOCRSettingsValid);
        } else {
            String invalidOCRErrors = '';
            for (Integer i=0; i<invalidOCRSettings.size(); i+=2) {
                invalidOCRErrors += String.format(Label.healthDetailsOCR, new List<String>{invalidOCRSettings[i], invalidOCRSettings[i+1]}) + '<br/>';
            }
            createDR(Label.healthLabelOCRSettings, statusError, invalidOCRErrors, Label.healthDetailsOCRSettingsResolution);
        }
    }

    /*********************************************************************************************************
    * @description Verifies that the default trigger handlers exist in the Trigger_Handler object, and warns
    * about any NPSP triggers marked as Async.
    */
    @TestVisible
    private void verifyTriggerHandlers() {
        try {
            List<Trigger_Handler__c> listHandlersDefault = TDTM_DefaultConfig.getDefaultRecords();
            List<Trigger_Handler__c> listHandlersCurrent = [
                SELECT Asynchronous__c, Class__c, Load_Order__c,
                    Object__c, Active__c, Trigger_Action__c, User_Managed__c
                FROM Trigger_Handler__c
            ];
            String strInfo = '<ul class="clsDRDetailsUL">';

            for (Trigger_Handler__c defaultHandler : listHandlersDefault) {
                Boolean alreadyExists = false;
                Integer cExactMatch = 0;
                for (Trigger_Handler__c existingHandler : listHandlersCurrent) {
                    if (defaultHandler.Class__c == existingHandler.Class__c && defaultHandler.Object__c == existingHandler.Object__c) {
                        alreadyExists = true;

                        // Determine if order, action, active, async has changed
                        if (defaultHandler.Load_Order__c != existingHandler.Load_Order__c ||
                            !compareTriggerHandlerActions(defaultHandler, existingHandler) ||
                            defaultHandler.Active__c != existingHandler.Active__c ||
                            defaultHandler.Asynchronous__c != existingHandler.Asynchronous__c) {

                            strInfo += '<li>';
                            strInfo += String.format(label.healthDetailsTriggerHandlerMismatch, new String[]{defaultHandler.Class__c, defaultHandler.Object__c});
                            strInfo += '</li>';
                        } else {
                            cExactMatch++;
                        }
                    }
                }
                if (!alreadyExists) {
                    strInfo += '<li>';
                    strInfo += String.format(label.healthDetailsTriggerHandlerMissing, new String[]{defaultHandler.Class__c, defaultHandler.Object__c});
                    strInfo += '</li>';
                } else if (cExactMatch > 1) {
                    strInfo += '<li>';
                    strInfo += String.format(label.healthDetailsTriggerHandlerDuplicate, new String[]{defaultHandler.Class__c, defaultHandler.Object__c});
                    strInfo += '</li>';
                }
            }
            if (strInfo != '<ul class="clsDRDetailsUL">') {
                strInfo += '</ul>';
                createDR(Label.healthLabelTriggerHandlerCheck, statusWarning, strInfo, label.healthSolutionTriggerHandlerMismatch);
            } else
                createDR(Label.healthLabelTriggerHandlerCheck, statusSuccess, null, label.healthLabelTriggerHandlersValid);

        } catch (Exception ex) {
            createDR(Label.healthLabelTriggerHandlerCheck, statusError, ex.getMessage(), null);
        }
    }

    /**
     * @description Compare the Trigger_Action list between two trigger handlers using logic that can ignore
     * both case and the sequence of the actions in the list.
     */
    private static Boolean compareTriggerHandlerActions(Trigger_Handler__c handlerA, Trigger_Handler__c handlerB) {
        List<String> listA = String.isNotBlank(handlerA.Trigger_Action__c)
            ? handlerA.Trigger_Action__c.toLowerCase().split(';')
            : new List<String>();
        List<String> listB = String.isNotBlank(handlerB.Trigger_Action__c)
            ? handlerB.Trigger_Action__c.toLowerCase().split(';')
            : new List<String>();

        Set<String> unionBintoA = new Set<String>();
        unionBintoA.addAll(listA);
        unionBintoA.addAll(listB);

        // The number of elements in in unionBintoA should match the number of elements in listA and listB
        if (listA.size() != listB.size() || unionBintoA.size() != listA.size() || unionBintoA.size() != listB.size()) {
            return false;
        }
        return true;
    }

    /*********************************************************************************************************
    * @description Verifies that there are no Opportunities that are missing payment records
    */
    public void verifyNoMissingOppPayments() {
        if (!UTIL_CustomSettingsFacade.getContactsSettings().npe01__Payments_Enabled__c)
            return;
        try {
            Set<String> setOppTypeNoPayment = PMT_PaymentCreator.setOppTypeNoPayment;
            Set<Id> setOppRecordTypeIdNoPayment = PMT_PaymentCreator.setOppRecordTypeIdNoPayment;
            String soql = 'SELECT count() FROM Opportunity WHERE npe01__Number_of_Payments__c = 0 AND Amount > 0 ' +
                ' AND (isWon = true OR isClosed = false) ' +
                ' AND npe01__Do_Not_Automatically_Create_Payment__c = false ' +
                ' AND  Type NOT IN :setOppTypeNoPayment ';

            SObjectField oppRecordTypeId = Schema.sObjectType.Opportunity.fields.getMap().get('RecordTypeId');
            if (oppRecordTypeId != null)
                soql += ' AND RecordTypeId NOT IN :setOppRecordTypeIdNoPayment ';

            soql += 'LIMIT 1001';

            Integer cMissing = Database.countQuery(soql);
            if (cMissing > 0) {
                String sMissing;

                if (cMissing > 1000) {
                    sMissing = '1000+';
                } else {
                    sMissing = String.valueOf(cMissing);
                }

                createDR(Label.healthLabelOppPayments, statusWarning, String.format(Label.healthDetailsMissingOppPayments, new String[]{sMissing}), label.healthSolutionMissingOppPayments);
            } else {
                createDR(Label.healthLabelOppPayments, statusSuccess, null, label.healthLabelNoMissingOppPayments);
            }
        } catch (Exception ex) {
            createDR(Label.healthLabelOppPayments, statusError, ex.getMessage(), null);
        }

    }


    /*********************************************************************************************************
    * @description Verifies that all Level records refer to existing fields of the correct type
    */
    public void verifyLevels() {
        try {
            // get all our levels for this object type
            List<Level__c> listAllLvls = [
                SELECT Id, Name, Target__c, Source_Field__c, Level_Field__c,
                    Previous_Level_Field__c, Active__c, Minimum_Amount__c, Maximum_Amount__c
                FROM Level__c
                ORDER BY Level_Field__c ASC, Minimum_Amount__c ASC];

            Integer cErrors = 0;
            for (Level__c lvl : listAllLvls) {
                for (Integer i = 0; i < 3; i++) {
                    String strField;
                    if (i == 0) {
                        strField = lvl.Source_Field__c;

                    } else if (i == 1) {
                        strField = lvl.Level_Field__c;

                    } else if (i == 2) {
                        strField = lvl.Previous_Level_Field__c;
                    }

                    // ensure the field exists
                    if (strField != null && !UTIL_Describe.isValidField(lvl.Target__c, strField)) {
                        cErrors++;
                        createDR(Label.healthLabelVerifyLevels, statusError,
                            String.format(Label.healthDetailsInvalidLevelField, new String[]{lvl.Name, strField, lvl.Target__c}),
                            String.format(label.healthSolutionInvalidLevelField, new String[]{lvl.Name}));
                    }
                    // ensure the datatype is valid
                    else if (strField != null) {
                        Schema.Displaytype dt = UTIL_Describe.getFieldDisplayType(lvl.Target__c, strField);
                        if (i == 0 && !UTIL_Describe.canDisplaytypesCopy(dt, Schema.DisplayType.Double)) {
                            cErrors++;
                            createDR(Label.healthLabelVerifyLevels, statusError,
                                String.format(Label.healthDetailsInvalidFieldNumeric, new String[]{lvl.Name, strField, lvl.Target__c}),
                                String.format(label.healthSolutionInvalidLevelField, new String[]{lvl.Name}));
                        }
                        if (i > 0 && !UTIL_Describe.canDisplaytypesCopy(dt, Schema.DisplayType.Reference)) {
                            cErrors++;
                            createDR(Label.healthLabelVerifyLevels, statusError,
                                String.format(Label.healthDetailsInvalidLevelFieldReference, new String[]{lvl.Name, strField, lvl.Target__c}),
                                String.format(label.healthSolutionInvalidLevelField, new String[]{lvl.Name}));
                        }
                    }
                }
            }

            if (cErrors == 0) {
                createDR(Label.healthLabelVerifyLevels, statusSuccess, null, label.healthLabelVerifyLevelsSuccess);
            }

        } catch (Exception ex) {
            createDR(Label.healthLabelVerifyLevels, statusError, ex.getMessage(), null);
        }
    }
}