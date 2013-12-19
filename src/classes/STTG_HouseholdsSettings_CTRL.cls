/*
    Copyright (c) 2011, Salesforce.com Foundation
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
* @date 2011 (2.0)
* @description The controller for the Household Settings VF page 
*/
public with sharing class STTG_HouseholdsSettings_CTRL {  
    
    public npo02__Households_Settings__c pageSettings;
    public npo02__Households_Settings__c getSettings(){return pageSettings;}
    public boolean runningBatch {get; set;}
    public string activeTab {get; set;}
    public boolean editRollupSettingsTab{get; set;}
    public boolean editHouseholdSettingsTab{get; set;}
    public boolean hasErrors{get; set;}
    public List<Error__c> errorList{get; set;}
     
    
    public STTG_HouseholdsSettings_CTRL(){
        acctRTs = new List<string>();
        acctTypes = new List<string>();
        contactRTs = new List<string>();
        contactTypes = new List<string>();
        scContactRoles = new List<string>();
        hhContactRTExclusions = new List<string>();
        OCRContactRTExclusions = new List<string>();        
        
        if (runningbatch == null)
            runningbatch = false;
        activeTab = 'HouseholdSettingsTab'; 
        editHouseholdSettingsTab = false;
        editRollupSettingsTab = false;   
        
        //retrieve errors, if any        
        errorList = [select Error_Type__c, Record_URL__c, 
                            Object_Type__c, Full_Message__c, 
                            Datetime__c, Name, Id from Error__c limit 999];
                
        if (!errorList.isEmpty()){
            hasErrors = true;            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, system.label.npo02.RollupErrorMessage);
            ApexPages.addMessage(myMsg);            
        }   
        else{
            hasErrors = false;
        }             
    }    
       
    //we can't do a DML in a getter, so I call it from the action of the page
    public PageReference getSettingsFirstTime() {
           
        //set a null page reference
        PageReference pr = null;                
        
        //if we don't have default settings
        pageSettings= npo02__Households_Settings__c.getOrgDefaults(); 
        
        if (pageSettings == null){
           pageSettings = HH_Households.getHouseholdsSettings();
           
           //no point in scheduling a rollup, since the default
           //has it disabled, just call a page refresh to get to the 
           //callout           
           pr = ApexPages.currentPage(); 
        }
        
        //we can safely call out to 
        else{
           pageSettings = HH_Households.getHouseholdsSettings();
           pr = scheduleRollups();
        }          
                
        //set the multi-select fields
        if(pageSettings.npo02__Excluded_Account_Opp_Types__c!=null){
            acctTypes = pageSettings.npo02__Excluded_Account_Opp_Types__c.split(';',0);
        }
        
         if(pageSettings.npo02__Excluded_Contact_Opp_Types__c!=null){
            contactTypes = pageSettings.npo02__Excluded_Contact_Opp_Types__c.split(';',0);
        }
        
         if(pageSettings.npo02__Excluded_Account_Opp_Rectypes__c!=null){
            acctRTs = pageSettings.npo02__Excluded_Account_Opp_Rectypes__c.split(';',0);
        }
        
         if(pageSettings.npo02__Excluded_Contact_Opp_Rectypes__c!=null){
            contactRTs = pageSettings.npo02__Excluded_Contact_Opp_Rectypes__c.split(';',0);
        }
        
        if (pageSettings.npo02__Soft_Credit_Roles__c != null){
            scContactRoles = pageSettings.npo02__Soft_Credit_Roles__c.split(';',0);
        }        
        
        if (pageSettings.npo02__Household_OCR_Excluded_Recordtypes__c != null){
            OCRContactRTExclusions = pageSettings.npo02__Household_OCR_Excluded_Recordtypes__c.split(';',0);   
        }        
          
        if (pageSettings.npo02__Household_Creation_Excluded_Recordtypes__c != null){
            hhContactRTExclusions = pageSettings.npo02__Household_Creation_Excluded_Recordtypes__c.split(';',0);           
        }
        
        
        if (pr != null){
            pr.setRedirect(true);
        }
            
        return pr;
    }
    
    public List<SelectOption> contactRoles = new List<SelectOption>();
    public List<String> acctRTs {get;set;}
    public List<String> acctTypes {get;set;}
    public List<String> contactRTs {get;set;}
    public List<String> contactTypes {get;set;}
    public List<String> scContactRoles {get;set;}
    public List<String> OCRContactRTExclusions {get; set;}
    public List<String> hhContactRTExclusions {get; set;}
    
    public List<SelectOption> getcontactRoles() {
    
        if(contactRoles.size()==0){
            contactRoles.add(new SelectOption(' ','- none -'));
            Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role; 
            List<Schema.PicklistEntry> P = F.getPicklistValues();
            for(Schema.PicklistEntry pe : P){
                contactRoles.add(new SelectOption(pe.getLabel(), pe.getLabel()));
            }
        }
        return contactRoles;
    }
    
    List<SelectOption> householdrules;
    List<SelectOption> RTypes;
    List<SelectOption> Types;
    List<SelectOption> conRTypes;
    List<SelectOption> oppStages = new List<SelectOption>();
   
    public PageReference scheduleRollups(){
        PageReference pr = null;
        
        if(pageSettings.npo02__Enable_Opp_Rollup_Triggers__c){
            
            Integer scheduledJobLimit;
            if (pageSettings.npo02__Schedule_Job_Limit__c != null)
                scheduledJobLimit = (integer)pageSettings.npo02__Schedule_Job_Limit__c;
            else
                scheduledJobLimit = 25;
            
            boolean alreadyScheduled = false;            
            List<cronTrigger> scheduledRollups = new List<cronTrigger>();
            //added NextFireTime check to make sure the job is still actively scheduled before checking it against the limit
            scheduledRollups = [SELECT Id FROM cronTrigger where NextFireTime != null limit :scheduledJobLimit];
            
            if(pageSettings.npo02__Opp_Rollup_Scheduled_Job_Id__c != null){
                for(cronTrigger thisScheduledJob : scheduledRollups){ 
                    if(thisScheduledJob.id == pageSettings.npo02__Opp_Rollup_Scheduled_Job_Id__c){
                        alreadyScheduled = true;
                        break;
                    }
                }
            }
            
            if(!alreadyScheduled){
                if(scheduledRollups.size()<scheduledJobLimit){     
                    
                    RLLP_OppRollup_SCHED rollUp = new RLLP_OppRollup_SCHED(); 
                    //need to check for already scheduled job
                    String sch='17 11 2 * * ?'; 
                    scheduledRollups.clear();
                    //added nextfiretime check to make sure we're getting an actual active job 
                    scheduledRollups = [SELECT Id FROM cronTrigger where cronExpression = :sch and NextFireTime != null];
                                        
                    if (scheduledRollups.size()==0){
                        String jobId = system.schedule('Nightly Opportunity Roll Up', sch ,rollUp);
                        pageSettings.npo02__Opp_Rollup_Scheduled_Job_Id__c = jobId;
                        
                    } else {
                        pageSettings.npo02__Opp_Rollup_Scheduled_Job_Id__c = scheduledRollups[0].Id;
                    }
                    //if we update page settings, we need to call a redirect
                    update pageSettings;
                    pr = ApexPages.currentPage();
                    
                } else {
                    showMsg(label.npo02.Opportunity_Rollup_Scheduling_Error_Text, ApexPages.Severity.FATAL);
                }
            }    
        }
        return pr;
    }

    public List<SelectOption> gethouseholdrules() {
        if(householdrules == null){
            householdrules = new List<SelectOption>();
            householdrules.add(new SelectOption(HH_Households.ALL_PROCESSOR, HH_Households.ALL_PROCESSOR));
            householdrules.add(new SelectOption(HH_Households.ALL_INDIVIDUALS_PROCESSOR, HH_Households.ALL_INDIVIDUALS_PROCESSOR));
            householdrules.add(new SelectOption(HH_Households.NO_HOUSEHOLDS_PROCESSOR, HH_Households.NO_HOUSEHOLDS_PROCESSOR));
        }
        return householdrules;
    }
    
     public List<SelectOption> getoppStages() {
        
    
        if(oppStages.size()==0){
            oppStages.add(new SelectOption(' ','- none -'));
            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.StageName; 
            List<Schema.PicklistEntry> P = F.getPicklistValues();
            for(Schema.PicklistEntry pe : P){
                oppStages.add(new SelectOption(pe.getLabel(), pe.getLabel()));
            }
        }
        return oppStages;
    }
    
    public List<SelectOption> getConRTypes(){
        if (ConRTypes == null){
            RTypes = new List<SelectOption>();
            RTypes.add(new SelectOption(' ', '- none -'));
            RTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList('Contact'));            
        }       
        return RTypes;
    }    
        
    public List<SelectOption> getRTypes() {
        if(RTypes == null){
            RTypes = new List<SelectOption>();
            RTypes.add(new SelectOption(' ','- none -'));
            RTypes.addAll(UTIL_RecordTypes.getStringRecordTypesForSelectList('Opportunity'));
        }
        return RTypes;
    }
    
    public List<SelectOption> getTypes() {
        if(Types == null){
            Types = new List<SelectOption>();
            Types.add(new SelectOption(' ','- none -'));
            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.Type; 
            List<Schema.PicklistEntry> P = F.getPicklistValues();
        
            for (Schema.PicklistEntry plistentry: P) {
                Types.add(new SelectOption(plistentry.getLabel(),plistentry.getLabel()));
            }
            
        }
        return Types;
    }
    
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }
    
    public void updateSettings(){
        String s = '';
        for (String rt : acctRTs) {
            if (rt!=null&&rt!='')
            s += ';' + rt;
        }
        system.debug('s: ' + s);
        if (s != '') pageSettings.npo02__Excluded_Account_Opp_Rectypes__c = s.substring(1);
        
        s = '';
        for (String rt : contactRTs) {
            if (rt!=null&&rt!='')
            s += ';' + rt;
        }
        if (s != '') pageSettings.npo02__Excluded_Contact_Opp_Rectypes__c = s.substring(1);
        
        s='';
        for (String scocr : scContactRoles){
            if (scocr != null && scocr != ''){
                s+= ';' + scocr;
            }           
        }
        if (s!='')pageSettings.npo02__Soft_Credit_Roles__c = s.substring(1);
        
        s = '';
        for (String tp : acctTypes) {
            if (tp!=null&&tp!='')
            s += ';' + tp;
        }
        if (s != '') pageSettings.npo02__Excluded_Account_Opp_Types__c = s.substring(1);
        s = '';

        for (String tp : contactTypes) {
            if (tp!=null&&tp!='')
            s += ';' + tp;
        }
        if (s != '') pageSettings.npo02__Excluded_Contact_Opp_Types__c = s.substring(1);
        s = '';

        for (String tp : OCRContactRTExclusions){
            if (tp!=null&&tp!='')
            s+= ';' + tp;
            
        }
        if (s!='')pageSettings.npo02__Household_OCR_Excluded_Recordtypes__c = s.substring(1);
        s = '';

        for (String tp : hhContactRTExclusions){
            if (tp!=null&&tp!='')
            s+= ';' + tp;            
        }
        if (s!='')pageSettings.npo02__Household_Creation_Excluded_Recordtypes__c = s.substring(1);        

        
        update pageSettings;
        showMsg('Households Settings updated',ApexPages.Severity.INFO);
        editHouseholdSettingsTab = false;
        editRollupSettingsTab = false;
        //schedule the rollup if need be
        scheduleRollups();
    }
    
    public void activateHouseholdNaming(){
        runningBatch = true; 
                
        pageSettings.npo02__Advanced_Household_Naming__c = true;
        update pageSettings;
        
        //call advanced rolup batch process
        HH_HouseholdNaming hn = new HH_Householdnaming();
        hn.ActivateAdvancedGreetings(false);
    }
    
    public pageReference cancel(){      
        editHouseholdSettingsTab = false;
        editRollupSettingsTab = false;
        pageReference pr = ApexPages.currentPage().setRedirect(true);        
        return pr;
    }
    public pageReference editHouseholdSettings(){
        editHouseholdSettingsTab = true;
        editRollupSettingsTab = false;
        return null;    
    }   
    public pageReference editRollupSettings(){
        editHouseholdSettingsTab = false;
        editRollupSettingsTab = true;
        return null;
    }    
    public pageReference deleteErrors(){
        delete [select id from Error__c];
        hasErrors = false;
        return null;
    }    
    
}