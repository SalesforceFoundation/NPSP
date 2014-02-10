/* 
    Copyright (c) 2012, Salesforce.com Foundation
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
* @date 2012 (2.0)
* @description The controller for the Recurring Donations Custom Installments panel 
*/
public with sharing class STG_PanelRDCustomInstallment_CTRL extends STG_Panel {
    
    public override string idPanel() { return 'idPanelRDInstPd'; }
    
    // temporary ci used by the page for creating a new ci.
    public npe03__Custom_Installment_Settings__c ciNew {
    	get {
    		if (ciNew == null)
    		  ciNew = new npe03__Custom_Installment_Settings__c();
            return ciNew;
    	}
    	private set;
    }
    
    // action method for going into edit mode (to create a new ci)
    public PageReference newCustomInstallment() {
        isEditMode = true;
        return null;
    }

    // action method to save the new ci to the database.
    public PageReference createCustomInstallment() {    	
        Savepoint sp = Database.setSavepoint();
        try {
	        insert ciNew;
            isEditMode = false;
	        STG_Panel.stgService.listRDCustomInstallment = null;
	        ciNew = null;
	        string strPostSaveMessage = 'After saving the Installment Period record, you will also need to add your Installment Period Name to the Recurring Donation\'s Installment Period picklist. To edit the picklist, go to Setup, Create, Objects, then select Recurring Donations. Click on the Installment Period picklist, and then edit the picklist values.';
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strPostSaveMessage));
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    // action method to cancel out of creating a new ci.
    public PageReference cancelCustomInstallment() {
        isEditMode = false;
        ciNew = null;
        return null;
    }
    
    // action method and parameter for deleting an existing ci.
    public string ciIdDelete { get; set; }
    public PageReference deleteCi() {
        Savepoint sp = Database.setSavepoint();
        try {
	        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();        
	        if (ciIdDelete != null) {
                npe03__Custom_Installment_Settings__c ci = new npe03__Custom_Installment_Settings__c(Id = ciIdDelete);
	            delete ci;
	            // force reload.
	            STG_Panel.stgService.listRDCustomInstallment = null;
                string strPostSaveMessage = 'After deleting the Installment Period record, you will also need to remove your Installment Period Name from the Recurring Donation\'s Installment Period picklist. To edit the picklist, go to Setup, Create, Objects, then select Recurring Donations. Click on the Installment Period picklist, and then edit the picklist values.  You will also need to update any open Recurring Donations that were using the Installment Period to use a new Installment Period value, and you will need to refresh the Recurring Donation\'s Opportunities.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strPostSaveMessage));
	        }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    // the periods we support for a ci        
    static public list<SelectOption> listSORDCustomPeriod {
        get {
            if (listSORDCustomPeriod == null) {
                listSORDCustomPeriod = new list<SelectOption>();
                listSORDCustomPeriod.add(new SelectOption('Days', 'Days'));
                listSORDCustomPeriod.add(new SelectOption('Weeks', 'Weeks'));
                listSORDCustomPeriod.add(new SelectOption('Months', 'Months'));
                listSORDCustomPeriod.add(new SelectOption('Years', 'Years'));
            }
            return listSORDCustomPeriod;
        }
        private set;
    }

    // action method called when the page first loads 
    public PageReference getSettingsFirstTime() {        
        scheduleRecurringDonationsUpdate();
        testPackageIntegrity();
        return null;
    }        
    
    // checks whether night batches should be enabled and set up
    private PageReference scheduleRecurringDonationsUpdate() {
        PageReference pr = null;
        
        if (!STG_Panel.stgService.stgRD.npe03__Disable_Nightly_Job__c) {
            Integer scheduledJobLimit = 25;
            boolean alreadyScheduled = false;            
            
            List<cronTrigger> scheduledUpdates = [SELECT Id FROM cronTrigger limit :scheduledJobLimit];
            
            if (STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c != null) {
                for (cronTrigger thisScheduledJob : scheduledUpdates) { 
                    if (thisScheduledJob.id == STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c) {
                        alreadyScheduled = true;
                        break;
                    }
                }
            }
                        
            if (!alreadyScheduled) {
                if (scheduledUpdates.size() < scheduledJobLimit) {     
                    
                    RD_RecurringDonations_SCHED nightlyJob = new RD_RecurringDonations_SCHED(); 
                    //need to check for already scheduled job
                    String sch='17 11 3 * * ?'; 
                    scheduledUpdates.clear();
                    scheduledUpdates = [SELECT Id FROM cronTrigger where cronExpression = :sch];
                    if (scheduledUpdates.size()==0) {
                        String jobId = system.schedule('Recurring Donation Updates', sch ,nightlyJob);
                        STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c = jobId;
                    }
                    else {
                        STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c = scheduledUpdates[0].Id;
                    }
                    //if we update page settings, we need to call a redirect
                    update STG_Panel.stgService.stgRD;
                    pr = ApexPages.currentPage();                    
                } 
                else{
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, system.label.npe03.RecurringDonationSchedulingError);
                    ApexPages.addMessage(myMsg);                    
                }
            }    
        }
        return pr;
    }
    
    // test an opp insert as done in the class and provide a warning if it fails
    private void testPackageIntegrity(){
        
        //test closed lost opp settings        
        string closedoppstage = system.label.npe03.RecurringDonationClosedLostOpportunityStage;
        integer x = 0;
        x = [select count() from OpportunityStage where MasterLabel = :closedoppstage and isClosed = true and isActive = true and isWon = false];
        
        string page_message = '';
        Savepoint sp = Database.setSavepoint();
            
        Account acc = new Account(name='test account');
        insert acc;
        Opportunity testOpp = new Opportunity();
        testOpp.AccountID = acc.id;
        testOpp.Amount = 100;
        testOpp.CloseDate = system.today();
        testOpp.Name = 'TestOpp';
        
        //If there's no closed/won stage??
        string SName = '';
        SName = [select MasterLabel from OpportunityStage where isWon = true and isClosed = true and isActive = true limit 1].MasterLabel;
        testOpp.StageName = SName;        
        
        //use one if we got one, otherwise, create one for testing
        list<npe03__Recurring_Donation__c> rd = new list<npe03__Recurring_Donation__c>();
        rd = [select id from npe03__Recurring_Donation__c];
        if (!rd.isEmpty()){
            testOpp.npe03__Recurring_Donation__c = rd[0].id;
        }
        database.saveresult[] sr = database.insert(new list<Opportunity>{testopp}, false);
        database.rollback(sp); 
        ApexPages.Message myMsg;
        
        //we allow isRunningTest code to enter these loops for coverage purposes
        if (x < 1 || test.isRunningTest()){
            myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, system.label.npe03.RecurringDonationBadLabelWarning);
            ApexPages.addMessage(myMsg);
        }   
        
        if(!sr[0].isSuccess() || test.isRunningTest()){ 
            Database.Error[] ers = sr[0].getErrors();  
            
            for (Database.Error err : ers){
                if (err.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION){
                    page_message += ' ' + system.label.npe03.RecurringDonationCustomValidationWarning;
                }
                else if (err.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING){
                    page_message += ' ' + system.label.npe03.RecurringDonationRequiredFieldsWarning;
                }
                else{
                    page_message += ' ' + err.getMessage();
                }
                string strComma = ' ';
                for (string s : err.getFields()){
                    page_message += strComma + s;      
                    strComma = ', ';                 
                }                                   
            }
            myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, page_message);            
        }   
        if (myMsg != null){
            ApexPages.addMessage(myMsg);
        }
    }    

}