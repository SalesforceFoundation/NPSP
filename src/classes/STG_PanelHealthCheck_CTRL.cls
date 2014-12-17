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
    
    public boolean isAllTestsPassed { 
        get {
            if (!hasResults)
                return false;
            for (DetectResult dr : listDR) {
                if (dr.strStatus == 'Error')
                    return false;
            }
            return true;
        }
    }
    
    public string strTime { get; set; }
    
    public string strNow {
    	get {
    		return datetime.now().format();  // this will put it in the time zone of the current user.
    	}
    }
    
    // the main entry to run Health Check
    public PageReference runDetector() { 
        isRunningDetector = true;
        listDR.clear();
        runAllDetections();
        return null;
    }
    
    public list<DetectResult> listDR { get; private set; }
    
    // class we use to report back the results of each Health Check test
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
        if (strStatus != 'Error' && listDR.size() > 0)
            listDR.add(0, dr);
        else
            listDR.add(dr);
    }    

    // calls all of the specific detection routines
    private void runAllDetections() {
        
        DateTime dtStart = system.now();
        
        verifyRecordTypes(); 
        verifyAccountModel(); 
        verifyAccountData();
        verifyAccountData2();
        verifyContactData();
        verifyNoOrphanedHouseholds();
        verifyNoOrphanedOne2OneAccounts();
        verifyReports(); 
        verifyFields(); 
        STG_PanelADDRVerification_CTRL.verifyAddressVerificationService(this);
        STG_PanelPaymentMapping_CTRL.verifyPaymentMappings(this);
        STG_PanelUserRollup_CTRL.verifyUserRollups(this);
        STG_PanelRDCustomFieldMapping_CTRL.verifyRDMappings(this);
        STG_PanelRDCustomInstallment_CTRL.verifyRDSaving(this);
        STG_PanelRelAuto_CTRL.verifyAutoCreateRels(this);
        STG_PanelRelReciprocal_CTRL.verifyRelLookups(this);
        STG_PanelOppRollups_CTRL.verifyFiscalYearRollups(this);
        verifyScheduledJobs();
        ERR_Notifier.verifyErrorSettings(this);
        verifyOppContactRoles();

        DateTime dtEnd = system.now();
        double msec = dtEnd.getTime() - dtStart.getTime();
        strTime = string.valueOf(double.valueOf(msec / 1000));
    }
    
    // verify settings are consistent with the chosen Account Model
    private void verifyAccountModel() {
        string strAccModel = UTIL_Describe.getFieldLabel('npe01__Contacts_And_Orgs_Settings__c', 'npe01__Account_Processor__c');
        
        if (CAO_Constants.isHHAccountModel()) {
            if (STG_Panel.stgService.stgHH.npo02__Household_Rules__c != HH_Households.NO_HOUSEHOLDS_PROCESSOR) {
                string strHHRules = UTIL_Describe.getFieldLabel('npo02__Households_Settings__c', 'npo02__Household_Rules__c');
                createDR(strHHRules, 'Error', label.healthDetailsHHAccountModel, 
                    string.format(label.healthSolutionEditSetting, new string[]{strHHRules, Label.stgNavPeople, Label.stgNavHouseholds} ));
                return;                 
            }           
        } else if (CAO_Constants.isOneToOne()) {
            // nothing to check         
        } else if (CAO_Constants.isBucketModel()) {
            // nothing to check         
        } else {
            createDR(strAccModel, 'Error', label.healthDetailsAccountModel, 
                string.format(label.healthSolutionEditSetting, new string[]{strAccModel, Label.stgNavPeople, Label.stgNavAccountModel} ));
            return;         
        }
        createDR(strAccModel, 'Success', null, STG_Panel.stgService.stgCon.npe01__Account_Processor__c);
    }
    
    // verify Account data is consistent with the chosen Account Model
    private void verifyAccountData() { 
    	integer cBucket = 0;
    	integer cOne2One = 0;
    	integer cHH = 0;
        boolean isMixedAccs = false;
        
    	try {    	
	    	cBucket = [select count() from Account where npe01__SYSTEM_AccountType__c = :CAO_Constants.BUCKET_ORGANIZATION_TYPE limit 9999];
	        cOne2One = [select count() from Account where npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE limit 9999];
	        cHH = [select count() from Account where npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE limit 9999];
	        if (cBucket > 0 && !CAO_Constants.isBucketModel())
	            isMixedAccs = true;    	
	        if (cOne2One > 0 && !CAO_Constants.isOneToOne())
	            isMixedAccs = true;     
	        if (cHH > 0 && !CAO_Constants.isHHAccountModel())
	            isMixedAccs = true;     
	    	
	        string strInfo = '';
	        if (isMixedAccs) {
	            strInfo = string.format(Label.healthDetailsAccountProcessor, new string[]{UTIL_CustomSettingsFacade.getContactsSettings().npe01__Account_Processor__c});
	        }
	        strInfo += '<BR/>' + CAO_Constants.BUCKET_ORGANIZATION_TYPE + ': ' + cBucket + (cBucket == 9999 ? '+' : '');
	        strInfo += '<BR/>' + CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE + ': ' + cOne2One + (cOne2One == 9999 ? '+' : '');
	        strInfo += '<BR/>' + CAO_Constants.HH_ACCOUNT_TYPE + ': ' + cHH + (cHH == 9999 ? '+' : '');        
	        
	        createDR(Label.healthLabelAccountModelData, isMixedAccs ? 'Error' : 'Success',  isMixedAccs ? strInfo : null, isMixedAccs ? null : strInfo);        
    	} catch (exception ex) {
            createDR(Label.healthLabelAccountModelData, 'Error',  ex.getMessage(), null);            		
    	}    
    }

    // verify Account data is consistent with the chosen Account Model
    // this one ensures that system fields match account record types
    private void verifyAccountData2() { 
        integer cOne2One = 0;
        integer cHH = 0;
        string strError = '';

        try {                        
		    ID rectype = STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c;
		    if (rectype != null) {
		        cHH = [select count() from Account where RecordTypeId = :rectype and
		            (npe01__SYSTEM_AccountType__c != :CAO_Constants.HH_ACCOUNT_TYPE or npe01__SYSTEMISINDIVIDUAL__c = false)
		            limit 9999]; 
		        if (cHH > 0) {
		            strError += string.format(Label.healthDetailsAccountRTIssue, new string[]{string.valueOf(cHH), CAO_Constants.HH_ACCOUNT_TYPE});                
		        }
		    }
		    rectype = STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c;
		    if (rectype != null) {
		        cOne2One = [select count() from Account where RecordTypeId = :rectype and
		            (npe01__SYSTEM_AccountType__c != :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE or npe01__SYSTEMISINDIVIDUAL__c = false)
		            limit 9999];
		        if (cOne2One > 0) {
		        	if (cHH > 0) strError += '<BR/>';
		            strError += string.format(Label.healthDetailsAccountRTIssue, new string[]{string.valueOf(cOne2One), CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE});                
		        }
		    }
		    
		    if (cHH > 0 || cOne2One > 0) {
		        createDR(Label.healthLabelAccountModelData, 'Error', strError, Label.healthSolutionAccountRTIssue);
		    } else {          
		        createDR(Label.healthLabelAccountModelData, 'Success', null, Label.healthLabelAccountRTIssueValid);
		    }            
        } catch (exception ex) {
            createDR(Label.healthLabelAccountModelData, 'Error',  ex.getMessage(), null);                   
        }    
    }

    // verify that all Contacts have an account
    private void verifyContactData() {
    	try {
	        integer cContact = [select Count() from Contact where AccountId = null limit 9999];   
	        if (cContact > 0) {
	            createDR(Label.healthLabelContactData, 'Error', string.format(Label.healthDetailsContactData, new string[]{string.valueOf(cContact)}), null);                	
	        } else {
	            createDR(Label.healthLabelContactData, 'Success', null, null); 
	        }  
        } catch (exception ex) {
            createDR(Label.healthLabelContactData, 'Error',  ex.getMessage(), null);                   
        }    
    }
    
    // verify there are no Households Accounts and Objects with no Contacts
    private void verifyNoOrphanedHouseholds() {
    	try {
	        integer cHHObj = [select Count() from npo02__Household__c 
	            where Number_of_Household_Members__c = 0 limit 9999];
	            //where Id not in (select npo02__Household__c from Contact where npo02__Household__c <> null) limit 9999];        
	        integer cHHAcc = [select Count() from Account 
	            where npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE and 
	                Number_of_Household_Members__c = 0 limit 9999];
	                //Id not in (select AccountId from Contact where AccountId <> null and Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE) limit 9999];        
	        if (cHHObj > 0) {
	            createDR(Label.healthLabelHHObjData, 'Error', 
	                string.format(Label.healthDetailsHHObNoContacts, new string[]{string.valueOf(cHHObj)}),
	                Label.healthSolutionHHObjNoContacts);                 
	        } 
	        if (cHHAcc > 0) {
	            createDR(Label.healthLabelHHAccData, 'Error', 
	                string.format(Label.healthDetailsHHActNoContacts, new string[]{string.valueOf(cHHAcc)}),
	                Label.healthSolutionHHAccNoContacts);                 
	        }         
	        if (cHHObj == 0 && cHHAcc == 0) {
	            createDR(Label.healthLabelHHData, 'Success', null, null); 
	        }  
        } catch (exception ex) {
            createDR(Label.healthLabelHHAccData, 'Error',  ex.getMessage(), null);                   
        }    
    }

    // verify there are no 1:1 Accounts with no Contacts
    private void verifyNoOrphanedOne2OneAccounts() {
    	try {
	        integer cAcc = [select Count() from Account 
	            where Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE and Account.npe01__One2OneContact__c = null limit 9999];
	                //Id not in (select AccountId from Contact where AccountId <> null and Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) limit 9999];        
	        if (cAcc > 0) {
	            createDR(Label.healthLabelAccountData, 'Error', 
	                string.format(Label.healthDetailsAccOne2OneNoContacts, new string[]{string.valueOf(cAcc)}),
	                Label.healthSolutionAccOne2OneNoContacts);                 
	        } else {
	            createDR(Label.healthLabelAccountData, 'Success', null, null); 
	        }  
        } catch (exception ex) {
            createDR(Label.healthLabelAccountData, 'Error',  ex.getMessage(), null);                   
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
                createDR(strField, 'Error', 
	                string.format(Label.healthDetailsBadReportId, new string[]{rptId}),
	                string.format(label.healthSolutionEditSetting, new string[]{strField, Label.stgNavPeople, Label.stgNavHouseholds}));        
                return;
            }
        } else {
            list<Report> listRpt = [select id from Report where DeveloperName = 'NPSP_Campaign_Household_Mailing_List'];
            if (listRpt.size() == 0) {
                createDR(strField, 'Error', Label.healthDetailsMailingListReportMissing, 
                   string.format(Label.healthSolutionMailingListReportMissing, new string[]{Label.stgNavPeople, Label.stgNavHouseholds}));
               return;
            }
        }
        createDR(strField, 'Success', null, rptId);

    }
    
    // check all fields that are used in settings
    private void verifyFields() {
    
        // check Relationship Gender field on Contact
        string strSetting = UTIL_Describe.getFieldLabel('npe4__Relationship_Settings__c', 'npe4__Gender_Field__c');
        string strField = STG_Panel.stgService.stgRel.npe4__Gender_Field__c;
        if (strField != null && !UTIL_Describe.isValidField('Contact', strField)) {
            createDR(strSetting, 'Error', 
                string.format(Label.healthDetailsGenderField, new string[]{strField}),
                string.format(label.healthSolutionEditSetting, new string[]{strSetting, Label.stgNavRelationships, Label.stgNavRelationships}));        
        } else {
            createDR(strSetting, 'Success', null, strField == null ? label.healthLabelNone : strField);
        }        
    }
    
    // check all settings that contain recordType ID's to make sure they are valid.
    private void verifyRecordTypes() {
    
        checkRecordTypeId('Account', STG_Panel.stgService.stgCon.npe01__HH_Account_RecordTypeID__c, 
            'npe01__Contacts_And_Orgs_Settings__c', 'npe01__HH_Account_RecordTypeID__c', Label.stgNavPeople, Label.stgNavAccountModel);
        checkRecordTypeId('Account', STG_Panel.stgService.stgCon.npe01__One_to_One_RecordTypeID__c, 
            'npe01__Contacts_And_Orgs_Settings__c', 'npe01__One_to_One_RecordTypeID__c', Label.stgNavPeople, Label.stgNavAccountModel);        
        checkRecordTypeId('Opportunity', STG_Panel.stgService.stgRD.npe03__Record_Type__c, 
            'npe03__Recurring_Donations_Settings__c', 'npe03__Record_Type__c', Label.stgNavRecurringDonations, Label.stgNavRecurringDonations);       
        checkRecordTypeMulti('Contact', STG_Panel.stgService.stgHH.npo02__Household_Creation_Excluded_Recordtypes__c, false,
            'npo02__Households_Settings__c', 'npo02__Household_Creation_Excluded_Recordtypes__c', Label.stgNavPeople, Label.stgNavHouseholds);
        checkRecordTypeMulti('Contact', STG_Panel.stgService.stgHH.npo02__Household_OCR_Excluded_Recordtypes__c, false,
            'npo02__Households_Settings__c', 'npo02__Household_OCR_Excluded_Recordtypes__c', Label.stgNavDonations, Label.stgNavContactRoles);            
        checkRecordTypeMulti('Opportunity', STG_Panel.stgService.stgHH.npo02__Excluded_Account_Opp_Rectypes__c, false,
            'npo02__Households_Settings__c', 'npo02__Excluded_Account_Opp_Rectypes__c', Label.stgNavDonations, Label.stgNavDonorStatistics);
        checkRecordTypeMulti('Opportunity', STG_Panel.stgService.stgHH.npo02__Excluded_Contact_Opp_Rectypes__c, false,
            'npo02__Households_Settings__c', 'npo02__Excluded_Contact_Opp_Rectypes__c', Label.stgNavDonations, Label.stgNavDonorStatistics);
        checkRecordTypeMulti('Opportunity', STG_Panel.stgService.stgHH.npo02__Membership_Record_Types__c, false,
            'npo02__Households_Settings__c', 'npo02__Membership_Record_Types__c', Label.stgNavDonations, Label.stgNavMembership);            

    }

    // helper to deal with a setting that contains multiple recordType Id's in a semi-colon delimeted string
    private void checkRecordTypeMulti(string strObject, string strValues, boolean isIds, string strSettingObj, string strSettingField, string strTabLevel, string strTabname) {
        if (strValues != null) {
            list<string> listStr = strValues.split(';',0);
            for (string strRT : listStr) {
                if (isIds)
                    checkRecordTypeId(strObject, strRT, strSettingObj, strSettingField, strTabLevel, strTabname);
                else
                    checkRecordTypeName(strObject, strRT, strSettingObj, strSettingField, strTabLevel, strTabname);              
            }
        } else {
            string strField = UTIL_Describe.getFieldLabel(strSettingObj, strSettingField);
            createDR(strField, 'Success', null, Label.healthLabelNone);                          
        }
    }

    // does the work to see if the recordType Id is valid, and logs an appropriate DetectResult    
    private void checkRecordTypeId(string strObject, string rtId, string strSettingObj, string strSettingField, string strTabLevel, string strTabname) {
        string strField = UTIL_Describe.getFieldLabel(strSettingObj, strSettingField);
        string strRT = UTIL_RecordTypes.GetRecordTypeName(strObject, rtId);
        if (rtId != null && strRT == null) {
            createDR(strField, 'Error', 
                string.format(label.healthDetailsInvalidRecordtypeId, new string[]{rtId}),        
                string.format(label.healthSolutionEditSetting, new string[]{strField, strTabLevel, strTabname}));
        } else {
        	if (rtId == null) strRT = Label.healthLabelNone;
            createDR(strField, 'Success', null, strRT);               
        }           
    }
    
    // does the work to see if the recordType Name is valid, and logs an appropriate DetectResult    
    private void checkRecordTypeName(string strObject, string strRTName, string strSettingObj, string strSettingField, string strTabLevel, string strTabname) {
        string strField = UTIL_Describe.getFieldLabel(strSettingObj, strSettingField);
        if (strRTName != null && UTIL_RecordTypes.GetRecordTypeId(strObject, strRTName) == null) {
            createDR(strField, 'Error', 
                string.format(label.healthDetailsInvalidRecordtypeName, new string[]{strRTName}),        
                string.format(label.healthSolutionEditSetting, new string[]{strField, strTabLevel, strTabname}));        
        } else {
        	if (strRTName == null) strRTName = Label.healthLabelNone;
            createDR(strField, 'Success', null, strRTName);               
        }           
    }

    // verify that our Master Scheduler jobs are actually scheduled, and that all of the entries are valid - called by HealthCheck
    private void verifyScheduledJobs() {
        try {        
	        // make sure the Master Jobs are scheduduled
	        List<CronTrigger> jobs = [select Id, CronJobDetail.Id from CronTrigger 
	           where CronJobDetail.Name IN :UTIL_MasterSchedulableHelper.scheduledJobs and CronJobDetail.JobType = '7'];        
	        if (jobs.size() != 3) {
	            createDR(Label.healthLabelScheduler, 'Error', Label.healthDetailsNothingScheduled, 
	                String.format(label.healthSolutionNothingScheduled, UTIL_MasterSchedulableHelper.scheduledJobs));
	            return;            
	        }
	
	        // make sure the entries we expect are there.
	        Integer numOfJobs = [select count() from Schedulable__c where Class_Name__c IN :UTIL_MasterSchedulableHelper.scheduledClasses];
	        if (numOfJobs != UTIL_MasterSchedulableHelper.scheduledClasses.size()) {
	            createDR(Label.healthLabelScheduler, 'Error', Label.healthDetailsScheduleJobs, Label.healthSolutionScheduleJobs);
	            return;            
	        }
	         
	        // now make sure all entries are valid
	        boolean isValidAll = true;
	        List<Schedulable__c> schedClasses = [select Name, Class_Name__c, Last_Time_Run__c, Frequency__c from Schedulable__c where Active__c = true];
	        for (Schedulable__c schedClass : schedClasses) {
	            Type classType = Type.forName(schedClass.Class_Name__c);
	            if (classType != null) {
	                Object instance = classType.newInstance();
	                if (instance != null) {
	                    if (instance instanceof UTIL_MasterSchedulableHelper.UTIL_IRecurring) {
	                        // this entry is good!
	                        continue;
	                    }
	                }
	            }
	            isValidAll = false;
	            createDR(Label.healthLabelScheduler, 'Error', 
	                string.format(label.healthDetailsInvalidScheduledJob, new string[]{schedClass.Class_Name__c}),
	                label.healthSolutionInvalidScheduledJob);
	        }            
	         
	        if (isValidAll) {
	            createDR(Label.healthLabelScheduler, 'Success', null, label.healthLabelSchedulerValid);
	        }   
        } catch (exception ex) {
            createDR(Label.healthLabelScheduler, 'Error',  ex.getMessage(), null);                   
        }    
	        
    }
    
    // verify that no Opportunities have multiple primary contact roles, which would throw off opp rollups.
    private void verifyOppContactRoles() {
        try {
            // detect duplicate primary ocr's
            // we understand this will fail if there are over 50k OCR's in they system,
            // but it is better than nothing, since for many orgs that will be fine.
            integer cOpp = 0;
			list<AggregateResult> listAR = [select count(Id), OpportunityId from OpportunityContactRole 
			     where IsPrimary=true group by OpportunityId having count(Id) > 1 limit 50000];
			cOpp = listAR.size();

			if (cOpp > 0) {
		        createDR(label.healthLabelOCRCheck, 'Error', 
		          string.format(label.healthDetailsOCRDupPrimary, new string[]{string.valueOf(cOpp)}), label.healthSolutionOCRDupPrimary);    	
			} else {
		        createDR(label.healthLabelOCRCheck, 'Success', null, label.healthDetailsOCRDupPrimaryValid);
			}    
        } catch (exception ex) {
            createDR(Label.healthLabelOCRCheck, 'Error',  ex.getMessage(), label.healthSolutionOCRException);                   
        }    
    }
    
}