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
* @description The controller for the VF page used for settings 
*/
public with sharing class STTG_RecurringDonations_CTRL {
    //invalid fields for opp mappings
    set<string> invalidOppFields = new set<string>{'accountid', 'amount', 'campaignid', 'closedate', 'createdbyid', 
                                                   'createddate', 'fiscal', 'fiscalquarter', 'fiscalyear', 'forecastcategory', 
                                                   'stagename', 'npe03__recurring_donation__c', 'forecastcategoryname',
                                                   'forecastname', 'hasopportunitylineitem', 'id', 'isclosed', 'isdeleted', 'isprivate', 
                                                   'iswon', 'lastactivitydate', 'lastmodifiedbyid', 'lastmodifieddate', 'recordtypeid', 
                                                   'systemmodstamp', 'totalopportunityquantity'};        
    public boolean canEditRDSettings {get; set;}
    public boolean canEditCISettings {get; set;}
    public boolean deleteInstallmentMode {get; set;}
    public boolean addingFieldMapping{get; set;}
    public npe03__Recurring_Donations_Settings__c rds {get; set;}
    public list<npe03__Custom_Installment_Settings__c> cis {get; set;}
    public list<npe03__Custom_Field_Mapping__c> cfm {get; set;}
    public list<Error__c> rdeq {get; set;}
    public string selectedTab {get; set;}
    public integer cisSize{get; set;} 
    public integer cfmSize{get; set;}
    public integer rdeqSize{get; set;}
    public string selectedInstallmentName{get; set;}
    public string replacementInstallment{get; set;}
    public map<string, npe03__Custom_Installment_Settings__c> cisMap;
    public map<string, npe03__Custom_Field_Mapping__c> cfmMap;
    public Map<Id, Error__c> rdeqMap;
    public string fieldMappingName{get; set;}
    public boolean runningBatch{get; set;}
    //holds value to evaluate change in forecast months
    public integer forecastMonths;
    public RecordType RTName{
        get{
            RecordType rectypeforname;
            list<RecordType> rtNames = new list<RecordType>();
            rtNames = [select Name from RecordType where ID = :rds.npe03__Record_Type__c];
            if (rtNames.size() == 1)
                rectypeforname = rtNames[0];
            
            //there was an invalid rectype, so set a new one
            else{               
                rectypeforname = new RecordType(Name = 'Invalid Recordtype - Default Will Be Used', sobjecttype='Opportunity');                         
            }                          
            return rectypeforname;
        }
    }
    //we're going to borrow the group object to generate the proper output field 
    public Group EmailErrorDisplayName{
        get{
            Group g = new Group();
            g.Name = rds.npe03__Error_Email_Notifications__c;          
            if (rds.npe03__Error_Email_Notifications__c instanceof id){
                if (rds.npe03__Error_Email_Notifications__c.startsWith('00G')){
                    g.Name = 'Group: ';
                    g.Name += [select Name from Group where id = :rds.npe03__Error_Email_Notifications__c].Name;                   
                }
                else if (rds.npe03__Error_Email_Notifications__c.startsWith('005')){
                    g.Name = 'User: ';
                    g.Name += [select Name from User where id = :rds.npe03__Error_Email_Notifications__c].Name;
                }               
            }
            return g;
        }
    }
    public list<SelectOption> validInstallments{
        get{
            list<SelectOption> Installments = new list<SelectOption>(); 
            list<string> custominstallments = new list<string>();
            
            cisMap = npe03__Custom_Installment_Settings__c.getAll().clone();
            //custominstallments = cisMap.keySet();
            cisMap.remove(selectedInstallmentName);
                       
            for (string s : cisMap.keySet()){
                Installments.add(new SelectOption(s,s));
            }
            Installments.add(new SelectOption(system.label.npe03.RecurringDonationInstallmentPeriodYearly,system.label.npe03.RecurringDonationInstallmentPeriodYearly));
            Installments.add(new SelectOption(system.label.npe03.RecurringDonationInstallmentPeriodYearly,system.label.npe03.RecurringDonationInstallmentPeriodWeekly));
            Installments.add(new SelectOption(system.label.npe03.RecurringDonationInstallmentPeriodYearly,system.label.npe03.RecurringDonationInstallmentPeriodQuarterly));
            Installments.add(new SelectOption(system.label.npe03.RecurringDonationInstallmentPeriodYearly,system.label.npe03.RecurringDonationInstallmentPeriodMonthly));
            Installments.add(new SelectOption(system.label.npe03.RecurringDonationInstallmentPeriodYearly,system.label.npe03.RecurringDonationInstallmentPeriod1stand15th));
            return Installments;
        }
    }
    public list<SelectOption> closeOptions{
        get{
            list<RD_RecurringDonations.RecurringDonationCloseOptions> CloseOptionValues = RD_RecurringDonations.RecurringDonationCloseOptions.values();       
            list<SelectOption> options = new list<SelectOption>();
            for (RD_RecurringDonations.RecurringDonationCloseOptions rdco : CloseOptionValues){
                options.add(new SelectOption(rdco.name(), rdco.name()));
            }
            return options;
        }
    }
    public list<SelectOption> RecordTypeList{
        get{
            list<SelectOption> options = new list<SelectOption>();          
            list<RecordType> rtlist = [select id, Name from RecordType where sobjecttype = 'Opportunity'];
            for (RecordType rt : rtlist){
                options.add(new SelectOption(rt.id, rt.Name));
            }   
            return options;
        }
    }                   
    public list<SelectOption> ErrorEmailOptions{
        get{
            list<SelectOption> options = new list<SelectOption>();
            options.add(new SelectOption('None', 'None'));
            options.add(new SelectOption('All Sys Admins', 'All Sys Admins'));
            for (User u : [select Name, id from User where User.Profile.Name = 'System Administrator']){
                options.add(new SelectOption(u.id, 'User: ' + u.Name));
            }
            for (Group g : [select id, Name from Group where Type = 'Regular']){
                options.add(new SelectOption(g.id, 'Group: ' + g.Name));
            }       
            return options;
        }
    }    
    public list<SelectOption> availableRDFields{
        get{
            list<SelectOption> fieldlist = new list<SelectOption>();
            map<String, Schema.SObjectField> M = schema.SObjectType.npe03__Recurring_Donation__c.fields.getMap();            
            for (string s : m.keySet()){
                fieldlist.add(new SelectOption(s,s));
            }
            return sortOptionList(fieldlist);
        }
    }
    public string RDField{get;set;}                   
    public list<SelectOption> availableOpportunityFields{
        get{
            list<SelectOption> fieldlist = new list<SelectOption>();
            map<String, Schema.SObjectField> M = schema.SObjectType.Opportunity.fields.getMap();            
            for (npe03__Custom_Field_Mapping__c cf : cfm){
                invalidOppFields.add(cf.npe03__Opportunity_Field__c);   
            }            
            for (string s : m.keySet()){
                if (!invalidOppFields.contains(s))
                    fieldlist.add(new SelectOption(s, s));
            }
            return sortOptionList(fieldlist);
        }            
    }
    public string OppField{get;set;}
                
    //called from action method for page 
    public PageReference getSettingsFirstTime() {
        rds = RD_RecurringDonations.getRecurringDonationsSettings();     
        forecastMonths = (integer)rds.npe03__Opportunity_Forecast_Months__c;              
        cisMap = npe03__Custom_Installment_Settings__c.getAll();
        cfmMap = npe03__Custom_Field_Mapping__c.getAll().clone();
        rdeqMap = new Map<Id, Error__c>([select Id, Name from Error__c]);
        rdeq = rdeqMap.values();
        cfm = cfmMap.values();        
        cis = cisMap.values();
        rdeqSize = rdeqMap.keySet().size();
        cisSize = cisMap.keySet().size();
        cfmSize = cfmMap.keySet().size();               
        
        Pagereference pr;
        pr = scheduleRecurringDonationsUpdate();
        boolean skipIntegrityCheck = false;
        if (pr == null){
            if (rds.npe03__Last_Update_Check__c == null){
                skipIntegrityCheck = true;
            }
        }
        
        if (!skipIntegrityCheck)
            testPackageIntegrity();
        return null;
    }        

    public STTG_RecurringDonations_CTRL(){
        if (selectedTab == null)
           selectedTab = 'general_settings';
        canEditRDSettings = false;
        canEditCISettings = false;
        deleteInstallmentMode = false;
        addingFieldMapping = false;
        runningBatch = false;
    }
    
    public pagereference editRDsettings(){
        canEditRDSettings = true;    
        selectedTab = 'general_settings';
        return null;
    }
    
    public pagereference editCISettings(){
        canEditCISettings = true;
        selectedTab = 'installment_settings';
        return null;
    }
    
    public pagereference addFieldMapping(){
        addingFieldMapping = true;
        selectedTab = 'field_mapping_settings';
        return null;
    }
    
    public pagereference cancel(){
        cis.clear();
        canEditRDSettings = false;
        canEditCISettings = false;
        deleteInstallmentMode = false;
        addingFieldMapping = false;
        cisMap = npe03__Custom_Installment_Settings__c.getAll();
        cis = cisMap.values();
        cisSize = cisMap.keySet().size();
        rds = RD_RecurringDonations.getRecurringDonationsSettings();        
        return null;
    }

    public pagereference saveRDSettings(){
        
        try{
            update rds;
            canEditRDSettings = false;
            //if we reduced the number of forecast months, we need to trim opps
            if (forecastMonths > rds.npe03__Opportunity_Forecast_Months__c){
                trimOpportunities();                
            }
            //if we added months, kick off the batch job to update the RDs
            else if (forecastMonths < rds.npe03__Opportunity_Forecast_Months__c){
                runBatch();
            }
            forecastMonths = (integer)rds.npe03__Opportunity_Forecast_Months__c;
        }
        catch (Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
            ApexPages.addMessage(myMsg);                        
        }
        return null;
    }
    
    //adds a row to the CI page
    public pageReference addCIRow(){        
        npe03__Custom_Installment_Settings__c c = new npe03__Custom_Installment_Settings__c();
        cis.add(c);
        cisSize++;
        return null; 
    }
    
    //saves a new CI setting
    public pageReference saveCISettings(){
        boolean invalidupsert = false;
        
        for (npe03__Custom_Installment_Settings__c c : cis){
            if (c.Name == null || c.npe03__Value__c < 1 || c.npe03__Increment__c == null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, system.label.npe03.RecurringDonationInvalidCustomInstallment);
                ApexPages.addMessage(myMsg);      
                invalidupsert = true;          
            }
            else{
                c.npe03__Value__c = c.npe03__Value__c.intValue();
            }
        }       
        if(!invalidupsert){
           upsert cis;
           canEditCISettings = false;
           cisMap = npe03__Custom_Installment_Settings__c.getAll();
           cis = cisMap.values();
           cisSize = cisMap.keySet().size();
        }              
        return null;
    }
    
    //initiates custom installmetn deletion wizard
    public pageReference runDeleteWizard(){
        deleteInstallmentMode = true;       
        selectedTab = 'installment_settings';
        return null;
    }
    
    //handles the delete & replace button
    public pageReference deleteInstallment(){
        
        list<npe03__Recurring_Donation__c> rdupdatelist = new list<npe03__Recurring_Donation__c>();
        rdupdatelist = [select npe03__Installment_Period__c from npe03__Recurring_Donation__c where npe03__Installment_Period__c = :selectedInstallmentName];
        for (npe03__Recurring_Donation__c rd : rdupdatelist){
           rd.npe03__Installment_Period__c = replacementInstallment;
        
        }
        delete [select id from npe03__Custom_Installment_Settings__c where Name = :selectedInstallmentName];
        cisMap = npe03__Custom_Installment_Settings__c.getAll();
        cis = cisMap.values();
        cisSize = cisMap.keySet().size();
        rds = RD_RecurringDonations.getRecurringDonationsSettings(); 
        
        selectedTab = 'installment_settings';
        deleteInstallmentMode = false;   
        return null;
    }    
    
    public pageReference saveFieldMapping(){
        //get existing Opp fields
        set<string> opptyFields = new set<string>();
        for (npe03__Custom_Field_Mapping__c cf : cfm){
            opptyFields.add(cf.npe03__Opportunity_Field__c);
        } 
        
        if (isValidMapping(RDField, OppField) && !opptyFields.contains(OppField)){
           string fmName = 'FieldMapping-' + system.now();   
           
           npe03__Custom_Field_Mapping__c myFM = new npe03__Custom_Field_Mapping__c(npe03__Opportunity_Field__c = OppField, npe03__Recurring_Donation_Field__c = RDField, Name = fmName); 
           insert myFM;
           cfm.add(myFM);
           cfmSize = cfm.size();
           cfmMap.put(myFM.Name, myFM); 
           addingFieldMapping = false;  
        }       
        //add error
        else{
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, system.label.npe03.RecurringDonationBadFieldMapping);
            ApexPages.addMessage(myMsg);
        }
        selectedTab = 'field_mapping_settings';        
        return null;
    }    
    
    public pageReference deleteFieldMapping(){
        if (fieldMappingName != null){
            delete [select id from npe03__Custom_Field_Mapping__c where Name = :fieldMappingName];
            cfmMap.remove(fieldMappingName);
            cfm = cfmMap.values();
            cfmSize = cfm.size();
        }               
        return null;
    }    
    
    public pageReference clearErrorQueue(){
        delete [select id from Error__c];
        rdeqSize = 0;
        return null;
    }
    public pageReference runBatch(){
        
        runningBatch = true;
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        string queryRCD = 'select id,npe03__Open_Ended_Status__c, npe03__Next_Payment_Date__c, npe03__Organization__c, ' + 
            'npe03__Contact__c,npe03__Installment_Amount__c,npe03__Installments__c,npe03__Amount__c,npe03__Total__c,npe03__Installment_Period__c, ' +
            'npe03__Date_Established__c,npe03__Donor_Name__c,npe03__Schedule_Type__c,npe03__Recurring_Donation_Campaign__c,npe03__Total_Paid_Installments__c, OwnerId ';
            //add any custom mapping to make sure we have the required fields
        map<string, npe03__Custom_Field_Mapping__c> cfmMap = new map<string, npe03__Custom_Field_Mapping__c>();
        cfmMap = npe03__Custom_Field_Mapping__c.getAll();
        for (string s : cfmMap.keySet()){
            queryRCD = queryRCD + ',' + cfmMap.get(s).npe03__Recurring_Donation_Field__c;
        }
            //if currencyiso field exists add it to query for use later
        if(Schema.sObjectType.npe03__Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
            queryRCD = queryRCD + ',CurrencyIsoCode';
        queryRCD=queryRCD+' from npe03__Recurring_Donation__c where npe03__Open_Ended_Status__c = \'' + openLabel + '\'';
        
        if(Test.isRunningTest())
            queryRCD=queryRCD+' LIMIT 50';
        
        //call the batch job, processing 50 at a time 
        Id batchInstanceId = Database.executeBatch(new RD_RecurringDonations_BATCH(queryRCD), 50); 
        
        return null; 
    }    
    
    public void trimOpportunities(){
        date limitDate = system.today().addMonths((integer)rds.npe03__Opportunity_Forecast_Months__c);
        string openlabel = system.label.npe03.RecurringDonationOpenStatus;
        delete [select id from Opportunity 
               where CloseDate > :limitDate 
               and isClosed != true 
               and npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c = :openLabel];
    }
    
    public pageReference scheduleRecurringDonationsUpdate(){
        PageReference pr = null;
        
        if (!rds.npe03__Disable_Nightly_Job__c){
            Integer scheduledJobLimit = 25;
            boolean alreadyScheduled = false;            
            
            List<cronTrigger> scheduledUpdates = [SELECT Id FROM cronTrigger limit :scheduledJobLimit];
            
            if(rds.npe03__Nightly_Update_ID__c != null){
                for(cronTrigger thisScheduledJob : scheduledUpdates){ 
                    if(thisScheduledJob.id == rds.npe03__Nightly_Update_ID__c){
                        alreadyScheduled = true;
                        break;
                    }
                }
            }
            
            if(!alreadyScheduled){
                if(scheduledUpdates.size()<scheduledJobLimit){     
                    
                    RD_RecurringDonations_SCHED nightlyJob = new RD_RecurringDonations_SCHED(); 
                    //need to check for already scheduled job
                    String sch='17 11 3 * * ?'; 
                    scheduledUpdates.clear();
                    scheduledUpdates = [SELECT Id FROM cronTrigger where cronExpression = :sch];
                    if (scheduledUpdates.size()==0){
                        String jobId = system.schedule('Recurring Donation Updates', sch ,nightlyJob);
                        rds.npe03__Nightly_Update_ID__c = jobId;
                    }
                    else{
                        rds.npe03__Nightly_Update_ID__c = scheduledUpdates[0].Id;
                    }
                    //if we update page settings, we need to call a redirect
                    update rds;
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
    
    //checks the compatibility of a recurring donation and opp field
    public boolean isValidMapping(string RDField, string OppField){
        boolean isValid = false;
        
        Schema.Sobjectfield schemaRDField = schema.SObjectType.npe03__Recurring_Donation__c.fields.getMap().get(RDField);
        Schema.Sobjectfield schemaOppField = schema.SobjectType.Opportunity.fields.getMap().get(OppField);
        
        if (schemaRDField != null && schemaOppField != null){
            Schema.DescribeFieldResult RDF = schemaRDField.getDescribe();
            Schema.DescribeFieldResult ODF = schemaOppField.getDescribe();                              
            if  (RDF.isAccessible() && (ODF.isAccessible() && !ODF.isDeprecatedAndHidden() && ODF.isUpdateable()) &&
                (RDF.getSoapType() == ODF.getSoapType())
               ){
                isValid = true;                           
            }
        }
        return isValid;
    }
    
    //test an opp insert as done in the class
    //and provide a warning if it fails
    public void testPackageIntegrity(){
        
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
                for (string s : err.getFields()){
                    page_message += s + ' ';                       
                }                                   
            }
            myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, page_message);            
        }   
        if (myMsg != null){
            ApexPages.addMessage(myMsg);
        }
    }    
        
    //http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
    private list<SelectOption> sortOptionList(list<SelectOption> ListToSort)
    {
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
            
        List<SelectOption> Less = new List<SelectOption>();
        List<SelectOption> Greater = new List<SelectOption>();
        integer pivot = ListToSort.size() / 2;
          
        // save the pivot and remove it from the list
        SelectOption pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        for(SelectOption x : ListToSort)
        {
            if(x.getLabel() <= pivotValue.getLabel())
                Less.add(x);
            else if(x.getLabel() > pivotValue.getLabel()) Greater.add(x);   
        }
        List<SelectOption> returnList = new List<SelectOption> ();
        returnList.addAll(SortOptionList(Less));
        returnList.add(pivotValue);
        returnList.addAll(SortOptionList(Greater));
        return returnList;   
    }
    
}