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
* @description Controller for the Health Check wizard
*/
public with sharing class STG_PanelHealthCheck_CTRL extends STG_Panel {

    public STG_PanelHealthCheck_CTRL() {
        isRunningDetector = false;
        listDR = new list<DetectResult>();
    }
    
    public override string idPanel() { return 'idPanelHealthCheck'; }
    
    public boolean isRunningDetector { get; set; }
    public boolean hasResults { 
        get {
            return (listDR != null && listDR.size() > 0);
        }
    }
    
    public string strTimeMessage { get; set; }
    
    public PageReference runDetector() { 
        isRunningDetector = true;
        listDR.clear();
        runallDetections();
        return null;
    }
    
    public list<DetectResult> listDR { get; private set; }
    
    public class DetectResult {
        public string strName { get; set; }
        public string strStatus { get; set; }
        public string strDetails { get; set; }
        public string strSolution { get; set; }
    }
    
    // creates and stores a DetectResult
    public void createDR(string strName, string strStatus, string strDetails, string strSolution) {
        DetectResult dr = new DetectResult();
        dr.strName = strName;
        dr.strStatus = strStatus;
        dr.strDetails = strDetails;
        dr.strSolution = strSolution;
        listDR.add(dr);
    }    

    // calls all of the specific detection routines
    private void runAllDetections() {
        
        DateTime dtStart = system.now();
        
        verifyRecordTypes(); 
        verifyAccountModel(); 
        verifyAccountData();
        verifyContactData();
        verifyNoOrphanedHouseholds();
        verifyNoOrphanedOne2OneAccounts();
        verifyReports(); 
        verifyFields(); 
        STG_PanelPaymentMapping_CTRL.verifyPaymentMappings(this);
        STG_PanelUserRollup_CTRL.verifyUserRollups(this);
        STG_PanelRDCustomFieldMapping_CTRL.verifyRDMappings(this);
        STG_PanelRDCustomInstallment_CTRL.verifyRDSaving(this);
        STG_PanelRelAuto_CTRL.verifyAutoCreateRels(this);
        STG_PanelRelReciprocal_CTRL.verifyRelLookups(this);
        STG_PanelOppRollups_CTRL.verifyFiscalYearRollups(this);
        verifyScheduledJobs();
        STG_PanelADDRVerification_CTRL.verifyAddressVerificationService(this);
        ERR_Notifier.verifyErrorSettings(this);

        DateTime dtEnd = system.now();
        double msec = dtEnd.getTime() - dtStart.getTime();
        strTimeMessage = 'Detection time in seconds: ' + double.valueOf(msec / 1000);

    }
    
    // verify settings are consistent with the chosen Account Model
    private void verifyAccountModel() {
        string strAccModel = UTIL_Describe.getFieldLabel('npe01__Contacts_And_Orgs_Settings__c', 'npe01__Account_Processor__c');
        
        if (CAO_Constants.isHHAccountModel()) {
            if (STG_Panel.stgService.stgHH.npo02__Household_Rules__c != HH_Households.NO_HOUSEHOLDS_PROCESSOR) {
                string strHHRules = UTIL_Describe.getFieldLabel('npo02__Households_Settings__c', 'npo02__Household_Rules__c');
                createDR(strHHRules,
                    'Error', 'When using the Household Account Model, Household Rules must be set to No Contacts.', 
                    'Edit the ' + strHHRules + ' on the ' + Label.stgNavHouseholds + ' tab in NPSP Settings.');  
                return;                 
            }           
        } else if (CAO_Constants.isOneToOne()) {
            // nothing to check         
        } else if (CAO_Constants.isBucketModel()) {
            // nothing to check         
        } else {
            createDR(strAccModel, 'Error', 'There is no valid Account Model specified', 
                'Edit the ' + strAccModel + ' on the ' + Label.stgNavAccountModel + ' tab in NPSP Settings.');
            return;         
        }
        createDR(strAccModel, 'Success', null, null);
    }
    
    // verify Account data is consistent with the chosen Account Model
    private void verifyAccountData() { 
    	integer cBucket = 0;
    	integer cOne2One = 0;
    	integer cHH = 0;
    	integer cOther = -1;
        boolean isMixedAccs = false;
    	
    	list<AggregateResult> listAgg = [select npe01__SYSTEM_AccountType__c, Count(Id) cAccounts from Account 
    	   where npe01__SYSTEM_AccountType__c <> null
    	   group by rollup(npe01__SYSTEM_AccountType__c) 
    	   limit 9999];
    	for (AggregateResult agg : listAgg) {
            string strAccType = string.valueOf(agg.get('npe01__SYSTEM_AccountType__c'));
            integer cAccounts = integer.valueOf(agg.get('cAccounts'));
            if (strAccType == CAO_Constants.BUCKET_ORGANIZATION_TYPE) {
                cBucket += cAccounts;
                if (!CAO_Constants.isBucketModel())
                    isMixedAccs = true;
            } else if (strAccType == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
                cOne2One += cAccounts;
                if (!CAO_Constants.isOneToOne())
                    isMixedAccs = true;
            } else if (strAccType == CAO_Constants.HH_ACCOUNT_TYPE) {
                cHH += cAccounts;
                if (!CAO_Constants.isHHAccountModel())
                    isMixedAccs = true;
            } else if (cOther == -1) {
                cOther = cAccounts;  
            }          
    	}
    	
        string strInfo;
        if (isMixedAccs) {
            strInfo = 'The Account Model is set to ' + CAO_Constants.getContactsSettings().npe01__Account_Processor__c;
            strInfo += ', but there are a mixture of Account types being used. ';
        }
        strInfo += '<BR/>' + CAO_Constants.BUCKET_ORGANIZATION_TYPE + ': ' + cBucket;
        strInfo += '<BR/>' + CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE + ': ' + cOne2One;
        strInfo += '<BR/>' + CAO_Constants.HH_ACCOUNT_TYPE + ': ' + cHH;        
        
        createDR('Account Model Data', isMixedAccs ? 'Error' : 'Success',  strInfo, null);        
    
    }

    // verify that all Contacts have an account
    private void verifyContactData() {
        integer cContact = [select Count() from Contact where AccountId = null limit 9999];   
        if (cContact > 0) {
            createDR('Contact Data', 'Error', 'There are ' + cContact + ' Contacts who have no Account.  These Contacts will be private to the user who created them only.', null);                	
        } else {
            createDR('Contact Data', 'Success', null, null); 
        }  
    }
    
    // verify there are no Households Accounts and Objects with no Contacts
    private void verifyNoOrphanedHouseholds() {
        integer cHHObj = [select Count() from npo02__Household__c where Id not in (select npo02__Household__c from Contact where npo02__Household__c <> null) limit 9999];        
        integer cHHAcc = [select Count() from Account 
            where Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE and
                Id not in (select AccountId from Contact where AccountId <> null and Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE) limit 9999];        
        if (cHHObj > 0) {
            createDR('Household Object Data', 'Error', 'There are ' + cHHObj + ' Household objects who have no Contacts.', 'Consider deleting these unused Household objects to save space.');                 
        } 
        if (cHHAcc > 0) {
            createDR('Household Account Data', 'Error', 'There are ' + cHHAcc + ' Household Accounts who have no Contacts.', 'Consider deleting these unused Household Accounts to save space.');                 
        }         
        if (cHHObj == 0 && cHHAcc == 0) {
            createDR('Household Data', 'Success', null, null); 
        }  
    }

    // verify there are no 1:1 Accounts with no Contacts
    private void verifyNoOrphanedOne2OneAccounts() {
        integer cAcc = [select Count() from Account 
            where Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE and
                Id not in (select AccountId from Contact where AccountId <> null and Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) limit 9999];        
        if (cAcc > 0) {
            createDR('Account Data', 'Error', 'There are ' + cAcc + ' One-to-One Accounts who have no Contacts.', 'Consider deleting these unused One-to-One Accounts to save space.');                 
        } else {
            createDR('Account Data', 'Success', null, null); 
        }  
    }

    // verify all reports exist that settings use
    private void verifyReports() {
        string rptId = null;
        
        // Household Mailing List Report
        rptId = STG_Panel.stgService.stgHH.npo02__Household_Mailing_List_ID__c;
        string strField = UTIL_Describe.getFieldLabel('npo02__Households_Settings__c', 'npo02__Household_Mailing_List_ID__c');
        if (rptId != null && rptId != '') { 
            list<Report> listRpt = [select Id from Report where Id = :rptId];
            if (listRpt.size() == 0) {
                createDR(strField, 'Error', 'Invalid Report ' + rptId + ' specified.', 'Edit the ' + strField + ' on the ' + Label.stgNavHouseholds + ' tab in NPSP Settings.');
                return;
            }
        } else {
            list<Report> listRpt = [select id from Report where DeveloperName = 'NPSP_Campaign_Household_Mailing_List'];
            if (listRpt.size() == 0) {
                createDR(strField, 'Error', 'The NPSP_Campaign_Household_Mailing_List report is missing which is used by the Household Mailing List button.', 
                   'Create a report based on Campaigns with Contacts, where Member Status does not contain Duplicate. Then specify this report on the ' + Label.stgNavHouseholds + ' tab in NPSP Settings.');
               return;
            }
        }
        createDR(strField, 'Success', null, null);

    }
    
    // check all fields that are used in settings
    private void verifyFields() {
    
        // check Relationship Gender field on Contact
        string strSetting = UTIL_Describe.getFieldLabel('npe4__Relationship_Settings__c', 'npe4__Gender_Field__c');
        string strField = STG_Panel.stgService.stgRel.npe4__Gender_Field__c;
        if (strField != null && !UTIL_Describe.isValidField('Contact', strField)) {
            createDR(strSetting, 'Error', 'Gender field ' + strField + ' does not exist on Contact', 
                'Add a Gender field to Contact and specify it on the ' + Label.stgNavRelationships + ' tab in NPSP Settings.');    
        } else {
            createDR(strSetting, 'Success', null, strField);
        }        
    }
    
    // check all settings that contain recordType ID's to make sure they are valid.
    private void verifyRecordTypes() {
    
        checkRecordTypeId('Account', STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c, 
            'npe01__Contacts_And_Orgs_Settings__c', 'npe01__HH_Account_RecordTypeID__c', Label.stgNavAccountModel);
        checkRecordTypeId('Account', STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c, 
            'npe01__Contacts_And_Orgs_Settings__c', 'npe01__One_to_One_RecordTypeID__c', Label.stgNavAccountModel);        
        checkRecordTypeId('Opportunity', STG_Panel.stgService.stgRD.npe03__Record_Type__c, 
            'npe03__Recurring_Donations_Settings__c', 'npe03__Record_Type__c', Label.stgNavRecurringDonations);       
        checkRecordTypeMulti('Contact', STG_Panel.stgService.stgHH.npo02__Household_Creation_Excluded_Recordtypes__c, true,
            'npo02__Households_Settings__c', 'npo02__Household_Creation_Excluded_Recordtypes__c', Label.stgNavHouseholds);
        checkRecordTypeMulti('Contact', STG_Panel.stgService.stgHH.npo02__Household_OCR_Excluded_Recordtypes__c, true,
            'npo02__Households_Settings__c', 'npo02__Household_OCR_Excluded_Recordtypes__c', Label.stgNavContactRoles);            
        checkRecordTypeMulti('Opportunity', STG_Panel.stgService.stgHH.npo02__Excluded_Account_Opp_Rectypes__c, false,
            'npo02__Households_Settings__c', 'npo02__Excluded_Account_Opp_Rectypes__c', Label.stgNavDonorStatistics);
        checkRecordTypeMulti('Opportunity', STG_Panel.stgService.stgHH.npo02__Excluded_Contact_Opp_Rectypes__c, false,
            'npo02__Households_Settings__c', 'npo02__Excluded_Contact_Opp_Rectypes__c', Label.stgNavDonorStatistics);
        checkRecordTypeMulti('Opportunity', STG_Panel.stgService.stgHH.npo02__Membership_Record_Types__c, false,
            'npo02__Households_Settings__c', 'npo02__Membership_Record_Types__c', Label.stgNavMembership);            

    }

    // helper to deal with a setting that contains multiple recordType Id's in a semi-colon delimeted string
    private void checkRecordTypeMulti(string strObject, string strValues, boolean isIds, string strSettingObj, string strSettingField, string strTabname) {
        if (strValues != null) {
            list<string> listStr = strValues.split(';',0);
            for (string strRT : listStr) {
                if (isIds)
                    checkRecordTypeId(strObject, strRT, strSettingObj, strSettingField, strTabname);
                else
                    checkRecordTypeName(strObject, strRT, strSettingObj, strSettingField, strTabname);              
            }
        } else {
            string strField = UTIL_Describe.getFieldLabel(strSettingObj, strSettingField);
            createDR(strField, 'Success', null, '(none)');                          
        }
    }

    // does the work to see if the recordType Id is valid, and logs an appropriate DetectResult    
    private void checkRecordTypeId(string strObject, string rtId, string strSettingObj, string strSettingField, string strTabname) {
        string strField = UTIL_Describe.getFieldLabel(strSettingObj, strSettingField);
        string strRT = UTIL_RecordTypes.GetRecordTypeName(strObject, rtId);
        if (rtId != null && strRT == null) {
            createDR(strField, 'Error', 'Recordtype Id ' + rtId + ' is invalid.', 'Edit the ' + strField + ' on the ' + strTabname + ' tab in NPSP Settings.');    
        } else {
        	if (rtId == null) strRT = '(none)';
            createDR(strField, 'Success', null, strRT);               
        }           
    }
    
    // does the work to see if the recordType Name is valid, and logs an appropriate DetectResult    
    private void checkRecordTypeName(string strObject, string strRTName, string strSettingObj, string strSettingField, string strTabname) {
        string strField = UTIL_Describe.getFieldLabel(strSettingObj, strSettingField);
        if (strRTName != null && UTIL_RecordTypes.GetRecordTypeId(strObject, strRTName) == null) {
            createDR(strField, 'Error', 'Recordtype Name ' + strRTName + ' is invalid.', 'Edit the ' + strField + ' on the ' + strTabname + ' tab in NPSP Settings.');    
        } else {
            createDR(strField, 'Success', null, strRTName);               
        }           
    }

    // verify that our Global Scheduler is actually scheduled, and that all of the entries are valid - called by HealthCheck
    private void verifyScheduledJobs() {
        
        // make sure the Global Job is scheduduled
        List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name = :UTIL_GlobalSchedulable.jobName and CronJobDetail.JobType = '7'];        
        if (scheduledJobs.size() == 0) {
            createDR('NPSP Global Scheduler', 'Error', 'The NPSP Global Scheduled class is not scheduled.', 
                'You must schedule the class UTIL_GlobalSchedulable to run daily with the job name ' + UTIL_GlobalSchedulable.jobName + '.');
            return;            
        }

        // make sure the entries we expect are there.
        Integer numOfJobs = [select count() from Schedulable__c where Class_Name__c IN ('RD_RecurringDonations_SCHED','RLLP_OppRollup_SCHED','ADDR_SEASONAL_SCHED')];
        if (numOfJobs != 3) {
            createDR('NPSP Global Scheduler', 'Error', 
                'One or more of the Opportunity Rollup, Recurring Donation, and Seasonal Address jobs are missing from the Schedulable__c object.', 
                'You must add records for RLLP_OppRollup_SCHED, RD_RecurringDonations_SCHED, and ADDR_SEASONAL_SCHED to Schedulable__c in order for these features to work correctly.');
            return;            
        }
         
        // now make sure all entries are valid
        boolean isValidAll = true;
        List<Schedulable__c> jobs = [select Name, Class_Name__c, Last_Time_Run__c, Frequency__c from Schedulable__c where Active__c = true];
        for (Schedulable__c job : jobs) {
            Type classType = Type.forName(job.Class_Name__c);
            if (classType != null) {
                Object instance = classType.newInstance();
                if (instance != null) {
                    if (instance instanceof UTIL_IScheduled) {
                        // this entry is good!
                        continue;
                    }
                }
            }
            isValidAll = false;
            createDR('NPSP Global Scheduler', 'Error', 
                'The record ' + job.Class_Name__c + ' in the Schedulable__c object is not valid.', 
                'You must update the record to have a valid Class the implements the UTIL_IScheduled interface.');
        }            
         
        if (isValidAll) {
            createDR('NPSP Global Scheduler', 'Success', null, null);
        }   
        
    }
    
}