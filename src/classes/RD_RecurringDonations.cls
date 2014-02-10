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
* @description The main class for controlling the behavior of Recurring Donations, both open ended and standard 
*/
public with sharing class RD_RecurringDonations {
    
    /*** Public Vars ***/ 
    
    public enum RecurringDonationCloseOptions {Delete_Open_Opportunities, Mark_Opportunities_Closed_Lost, No_Action}
    public static npe03__Recurring_Donations_Settings__c recurringDonationsSettings;    
    public static map<string, npe03__Custom_Field_Mapping__c> customFieldMappingSettings = new map<string, npe03__Custom_Field_Mapping__c>();
    
    /*** Multicurrency Support Fields ***/
    
    private static SObjectField RDCurrField;
    public static SObjectfield RDCurrencyField{get{
        if (RDCurrField == null){
            RDCurrField = Schema.sObjectType.npe03__Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode');
        }   
        return RDCurrField;
    }set;}    
    private static Sobjectfield OppCurrField;
    public static SObjectField OppCurrencyField{get{
        if (OppCurrField == null)
            OppCurrField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
        return OppCurrField;
    }set;}       
    private static boolean isMc;
    public static boolean isMultiCurrency{get{
        if (isMc == null){          
            if (Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode') != null)
                isMc = true;
            else
                isMc = false;           
        }           
        return isMc;                
    }set;}
    
    
    /*** BEGIN STATIC METHODS ***/    
    
    @future
    public static void updateRecurringDonationOnOppChangeFuture(set<id> RDids){updateRecurringDonationOnOppChange(RDids, null);} 
    public static void updateRecurringDonationOnOppChange(set<id> RDids, TDTM_Runnable.DmlWrapper dmlWrapper){
  
        //Use NPSP OCR Support?
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
        
        //set of RDs to be updated         
        map<id, npe03__Recurring_Donation__c> updateMap = new map<id, npe03__Recurring_Donation__c>();
        
        //Get our settings
        npe03__Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();     
         
        //Get the open label for opps
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        
        //get all possible rd records that may need updating, exclude ones not in an open state  
        map<id, npe03__Recurring_Donation__c> rdMap = new map<id, npe03__Recurring_Donation__c>([select id, npe03__Paid_Amount__c, npe03__Next_Payment_Date__c, 
                                                                                    npe03__Contact__c, npe03__Organization__c, npe03__Amount__c, 
                                                                                    npe03__Date_Established__c, npe03__Recurring_Donation_Campaign__c,
                                                                                     npe03__Installment_Period__c, npe03__Installments__c,
                                                                                     npe03__Last_Payment_Date__c, npe03__Open_Ended_Status__c,
                                                                                     npe03__Schedule_Type__c, npe03__Total_Paid_Installments__c,
                                                                                     npe03__Donor_Name__c
                                                                                  from npe03__Recurring_Donation__c 
                                                                                  where npe03__Open_Ended_Status__c = :openLabel
                                                                                  and id IN :RDids]);
        
        //get the cumulative values to update the recurring donations
        list<sobject> sobjs = [select count(id) oppcount, MIN(CloseDate) MinDate, MAX(CloseDate) MaxDate, SUM(Amount) Total,
                                  isClosed, npe03__Recurring_Donation__r.id rdid, isWon
                                  from Opportunity where npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c = :openLabel 
                                  and npe03__Recurring_Donation__r.id IN :rdMap.keySet()
                                  group by rollup(npe03__Recurring_Donation__r.id, isClosed, isWon)]; 
        
        //holds the rdid of all evaluated closed sets, allows us to figure out the various summary rows
        //this is a workaorund for the null boolean aggregate result bug
        set<id> isClosedEvaluatedSet = new set<id>();
        map<id, date> maxOpenPaymentMap = new map<id, date>();
        
        //we want this outside of the loop so the grand summary row (null id) always refers to the 
        //rdids before it
        npe03__Recurring_Donation__c rd;        
        //update the rc next payment date 
        //and add new donation objects needed 
        for (sobject obj : sobjs){
            id rdid = (id)obj.get('rdid'); 
            
            //the summary isclosed row will contain a null boolean
            //which is evaluated as false, so we'll need to mark 
            //this rdid as having had the nonsummary false isclosed value 
            //already used, so we don't accidentally use the summary row below
            boolean isClosed = (boolean)obj.get('isClosed');
            boolean isWon = (boolean)obj.get('isWon');            
            if (isClosed == null) isClosed = false;
            if (isWon == null) isWon = false;
            
            if (rdid != null){
                //if we already have values for this RD, get it from our rdid map, otherwise just grab
                //the one we're already working on 
                if (!updateMap.containsKey(rdid)){
                    rd = rdMap.get(rdid);
                }
                else{
                    rd = updateMap.get(rdid);
                }
                //if this is the open set for this rd
                if (!isClosed && !isWon && !isClosedEvaluatedSet.contains(rdid)){
                    rd.npe03__Next_Payment_Date__c = (date)obj.get('MinDate');
                    maxOpenPaymentMap.put(rdid, (date)obj.get('MaxDate'));
                    isClosedEvaluatedSet.add(rdid);
                    updateMap.put(rdid, rd);                                       
                }
                //if this is the closed set     
                else if (isClosed && isWon){
                    rd.npe03__Last_Payment_Date__c = (date)obj.get('MaxDate');
                    rd.npe03__Paid_Amount__c = (decimal)obj.get('Total');     
                    rd.npe03__Total_Paid_Installments__c = (integer)obj.get('oppcount');
                    updateMap.put(rdid, rd);                        
                }                   
            }
            else{          
                rd.npe03__Installments__c = (integer)obj.get('oppcount'); 
                updateMap.put(rd.id, rd);               
            }                            
        }
        
        if (!updateMap.isEmpty()){
        	if (dmlWrapper != null)
                dmlWrapper.objectsToUpdate.putAll((map<Id, SObject>) updateMap);
        	else
                update updateMap.values();
        }
    } 
   
    // requery for all the fields we need on the list of new RD's (including currency info) 
    public static list<npe03__Recurring_Donation__c> requeryListRD(set<Id> setRDId) {    
        string queryRCD = strQueryRDNoWhere();
        queryRCD += ' where Id in :setRDId';
        
        //execute query
        return Database.query(queryRCD);
    }
    
    // shared helper routine to create the soql string against Recurring Donations.
    // includes fields from the custom field map, and currencyiso fields.
    // does not include the where clause (since different callers had different filtering needs)
    public static string strQueryRDNoWhere() {
    	
        set<string> existingFields = new set<string>{  'npe03__open_ended_status__c', 'npe03__next_payment_date__c', 'name',
                                                       'npe03__organization__c', 'npe03__contact__c', 'npe03__installment_amount__c',
                                                       'npe03__installments__c', 'npe03__amount__c', 'npe03__total__c', 'npe03__installment_period__c',
                                                       'npe03__date_established__c', 'npe03__donor_name__c', 'npe03__schedule_type__c', 
                                                       'npe03__recurring_donation_campaign__c', 'npe03__total_paid_installments__c'};
        
        String queryRCD = 'select id';
        for (string s : existingFields){
            queryRCD += ', ' + s;               
        }
   
        //add any custom mapping to make sure we have the required fields
        map<string, npe03__Custom_Field_Mapping__c> cfmMap = new map<string, npe03__Custom_Field_Mapping__c>();
        cfmMap = npe03__Custom_Field_Mapping__c.getAll();
        for (string s : cfmMap.keySet()){
            string RDFieldName = cfmMap.get(s).npe03__Recurring_Donation_Field__c;             
            if (!existingFields.contains(RDFieldName.toLowerCase()) && s != 'id'){
               queryRCD = queryRCD + ',' + cfmMap.get(s).npe03__Recurring_Donation_Field__c;
               existingFields.add(RDFieldName.toLowerCase());   
            }
        }       
   
        //if currencyiso field exists add it to query for use later
        if (isMultiCurrency)
            queryRCD = queryRCD + ',CurrencyIsoCode';
    
        queryRCD=queryRCD+' from npe03__Recurring_Donation__c';
        
        return (queryRCD);
    }   
     
    //future wrapper for rds with no opptys closed
    @future
    public static void insertOppsOnRecurringDonationInsertFuture(set<id> recids){
        delete [select id from Opportunity where isClosed = false and npe03__Recurring_Donation__r.id IN :recids];

        list<npe03__Recurring_Donation__c> reclist = requeryListRD(recids);
        insertOppsOnRecurringDonationInsert(reclist);
    }
    
    //Creates new Opportunities when a RecurringDonation is inserted
    public static void insertOppsOnRecurringDonationInsert(list<npe03__Recurring_Donation__c> recurringDonations) {
        //Lists used for final Insert
        list<Opportunity> opportunityInserts = new list<Opportunity>();
        
        npe03__Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        customFieldMappingSettings = npe03__Custom_Field_Mapping__c.getAll();        
        
        //grab the contact id for role to take advantage of NPSP C&O if it exists
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
        set<id> updateRecurringDonationSet = new set<id>();            
        
        //Create a list of ContactIds used in these RecurringDonations
        list<Id> contactIds = new list<Id>();
        map<Id,Id> recConMap = new map<Id,Id>();
        for(npe03__Recurring_Donation__c r : recurringDonations){
            updateRecurringDonationSet.add(r.id);
            if (r.npe03__Contact__c != null){ 
                contactIds.add(r.npe03__Contact__c);
                recConMap.put(r.Id,r.npe03__Contact__c);
            }
        }

        //Create a Map of Contact Ids and Contact Records
        map<Id,Contact> contactMap;
        map<Id,Account> accountMap;
        if (contactIds.size() > 0){
            contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
        }
        
        //Loop through the Recurring Donations and create the appropriate number of Opportunities
        for(npe03__Recurring_Donation__c r : recurringDonations){
            //if we're not looking at an open-ended type donation, handle it the 'old' way        
            if (r.npe03__Open_Ended_Status__c != system.label.npe03.RecurringDonationOpenStatus && r.npe03__Open_Ended_Status__c != system.label.npe03.RecurringDonationClosedStatus){          
        
                Decimal installs = r.npe03__Installments__c;
                Integer installments = installs.intValue();
                
                for ( Integer j=0;j<installments;j++ )
                {
                    Opportunity opp = new Opportunity();
                
                    if ( r.npe03__Organization__c != null )
                    {
                       opp.AccountId = r.npe03__Organization__c;
                    }
                    else
                    if ( contactMap.containsKey(r.npe03__Contact__c) )
                    {
                        Contact c = contactMap.get(r.npe03__Contact__c);
                        opp.AccountId = c.AccountId;
                    } 

                    // James Melville 05/03/2011 Added to support multi-currency sfdc.  
                    // we check currency iscode before entering the loop since it's a system check
                    if(isMultiCurrency){                        
                        //set the donation currency field to equal the recurring donation currency
                        opp.put(OppCurrencyField,r.get(RDCurrencyField));                        
                    }
                
                    //add the remainder to the last installment, otherwise use the amount
                    if (j + 1 == installments && installments * r.npe03__Installment_Amount__c != r.npe03__Total__c)
                    {
                        opp.Amount = r.npe03__Total__c - (j * r.npe03__Installment_Amount__c);
                    } else {
                        opp.Amount = r.npe03__Installment_Amount__c;
                    }
                
                    if (r.npe03__Installment_Period__c == system.label.npe03.RecurringDonationInstallmentPeriodYearly)
                    {
                        opp.CloseDate = (r.npe03__Date_Established__c).addYears(j);
                    } else
                    if (r.npe03__Installment_Period__c == system.label.npe03.RecurringDonationInstallmentPeriodQuarterly)
                    {
                       opp.CloseDate = (r.npe03__Date_Established__c).addMonths(3*j);
                    } else
                    if (r.npe03__Installment_Period__c == system.label.npe03.RecurringDonationInstallmentPeriodMonthly)
                    {
                       opp.CloseDate = (r.npe03__Date_Established__c).addMonths(j);
                    } else
                    if (r.npe03__Installment_Period__c == system.label.npe03.RecurringDonationInstallmentPeriodWeekly)
                    {
                       opp.CloseDate = (r.npe03__Date_Established__c).addDays(7*j);
                    } else
                    {
                       opp.CloseDate = (r.npe03__Date_Established__c);
                    }
                
                    String oName = '';
                    oName += r.npe03__Donor_Name__c; 
                    oName += ' ';
                    oName += system.label.npe03.RecurringDonationPrefix;
                    oName += ' (';
                    oName += j+1;
                    oName += ' of ';
                    oName += installments;
                    oName += ') ';
                    oName += opp.CloseDate.format();
                    opp.Name = oName;
                
                    opp.StageName = system.label.npe03.RecurringDonationStageName;
                    opp.npe03__Recurring_Donation__c = r.Id;
                    if (r.npe03__Recurring_Donation_Campaign__c != null && (rds.npe03__Add_Campaign_to_All_Opportunites__c || j < 1)){
                       opp.CampaignId = r.npe03__Recurring_Donation_Campaign__c;
                    }                                        
                    if (rds.npe03__Record_Type__c != null){
                        opp.RecordTypeID = rds.npe03__Record_Type__c;
                    }                    
                    
                    //evaluate any custom field mappings
                    for (string s : customFieldMappingSettings.keySet()){
                        npe03__Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                        opp.put(cfm.npe03__Opportunity_Field__c, r.get(cfm.npe03__Recurring_Donation_Field__c));
                    }
                    
                    opportunityInserts.add(opp);
                    if ( opportunityInserts.size() == 100 )
                    {
                       Database.SaveResult[] lsr = Database.insert(opportunityInserts, false);
                       opportunityInserts.clear();
                    }
                }
            }
            
            //this is an open-ended rd that needs opptys
            else{
                //if its not 'open', we're not doing anything to it
                if (r.npe03__Open_Ended_Status__c == system.label.npe03.RecurringDonationOpenStatus){
                    //get settings so we can figure out how many donations to create                    
                    date OppCloseDate;
                    date loop_date;
                  
                    if (r.npe03__Next_Payment_Date__c != null)                     
                        OppCloseDate = r.npe03__Next_Payment_Date__c;
                    else{
                        OppCloseDate = r.npe03__Date_Established__c;                                                                        
                    }                                             
                    /*
                    if (r.npe03__Total_Paid_Installments__c > 0){
                            OppCloseDate = getNextDate(OppCloseDate, r.npe03__Installment_Period__c);
                    } */   
                    date incrementdate = OppCloseDate;
                    integer rdcounter = 1;
                    if (r.npe03__Total_Paid_Installments__c > 0)
                        rdcounter = (integer)r.npe03__Total_Paid_Installments__c + 1;
                            
                    do{
                        Opportunity o = new Opportunity();
                        o.CloseDate = OppCloseDate;
                                                                                                          
                        if(isMultiCurrency){
                            //set the donation currency field to equal the recurring donation currency
                            o.put(OppCurrencyField,r.get(RDCurrencyField));
                        }
                    
                        if (r.npe03__Organization__c != null){
                            o.AccountId = r.npe03__Organization__c;
                        }
                        else if (contactMap.containsKey(r.npe03__Contact__c)){
                            Contact c = contactMap.get(r.npe03__Contact__c);
                            o.AccountId = c.AccountId;
                            if (ConIDForRole != null){
                                o.put('npe01__Contact_Id_For_Role__c', (string)c.id);
                            }
                        }       
                                       
                        o.Amount = r.npe03__Amount__c;
                    
                        OppCloseDate = getNextDate(OppCloseDate, r.npe03__Installment_Period__c);
                    
                        String oName = '';
                        oName += r.npe03__Donor_Name__c; 
                        oName += ' ';
                        oName += system.label.npe03.RecurringDonationPrefix;
                        oName += ' (';
                        oName += string.valueOf(rdcounter);
                        oName += ') ';
                        oName += o.CloseDate.format();
                        o.Name = oName;
                        
                        if (rds.npe03__Record_Type__c != null){
                            o.RecordTypeID = rds.npe03__Record_Type__c;
                        }                
                        o.StageName = system.label.npe03.RecurringDonationStageName;
                        o.npe03__Recurring_Donation__c = r.Id;
                        if (r.npe03__Recurring_Donation_Campaign__c != null && (rds.npe03__Add_Campaign_to_All_Opportunites__c || rdcounter == 1)){
                            o.CampaignId = r.npe03__Recurring_Donation_Campaign__c;
                        }   
                        
                        //evaluate any custom field mappings
                        for (string s : customFieldMappingSettings.keySet()){
                            npe03__Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                            o.put(cfm.npe03__Opportunity_Field__c, r.get(cfm.npe03__Recurring_Donation_Field__c)); 
                        }
                        opportunityInserts.add(o);    
                        rdcounter++;                                                                                       
                    }while (OppCloseDate < incrementdate.addMonths((integer)rds.npe03__Opportunity_Forecast_Months__c));                                        
                }
            }                 
        }
        
        if( opportunityInserts.size() > 0 )
        {   
            set<id> RDID = new set<id>();           
            for (Opportunity o : opportunityInserts){
                RDID.add(o.npe03__Recurring_Donation__c);
            }
            
            Database.SaveResult[] lsr;
            list<Database.SaveResult> badSRs = new list<Database.SaveResult>();
            list<Opportunity> badOpps = new list<Opportunity>();
            set<id> createdOppIds = new set<id>();  
            
            //we're probably coming from the UI if we're only updating one RD, so lets 
            //let the error bubble up to the top
            if (RDID.size() == 1)
                lsr = Database.insert(opportunityInserts, true);
            //otherwise, this is a bulk operation so fail to the error handler 
            else
                lsr = Database.insert(opportunityInserts, false);        
                    
            integer i = 0;                          
            for (Database.SaveResult s : lsr){
                if (s.isSuccess() == true){
                    //get all the new OppIds into a list
                    createdOppIds.add(s.getId());
                }    
                //handle errors on insert   
                else{
                    badSRs.add(s);
                    badOpps.add(opportunityInserts[i]);            
                }                     
                i++;
            }
                    
            if (ConIDForRole == null || Test.isRunningTest()){ 
                if (!system.isFuture() && !system.isBatch() && !RD_ProcessControl.batchButton)
                    oppContactRolesFuture(createdOppIds); 
                else
                    oppContactRoles(createdOppIds);                    
            }
            
            if (!badSRs.isEmpty()){
            	ERR_Handler errorHandler = new ERR_Handler();
                errorHandler.processInsertResults(badSRs, badOpps, ERR_Handler.Context.RD);
            }            
            
            if (!system.isBatch() && !system.isFuture() && !RD_ProcessControl.batchButton)
                updateRecurringDonationOnOppChangeFuture(updateRecurringDonationSet); 
            else
                updateRecurringDonationOnOppChange(updateRecurringDonationSet, null);
        }
    }
    
    //async wrapper for oppcontact role creation
    @future 
    public static void oppContactRolesFuture(set<id> oppIds){oppContactRoles(oppIds);}
    public static void oppContactRoles( Set<Id> oppIds ){
        List<OpportunityContactRole> contactRoleInserts = new List<OpportunityContactRole>();
        map <String,Id> contactOppToContactRole = new Map <String,Id> ();
            
        Opportunity[] oppsFromRecurringDontaions = [select id, npe03__Recurring_Donation__c,npe03__Recurring_Donation__r.npe03__Contact__c from Opportunity where Id IN :oppIds AND npe03__Recurring_Donation__r.npe03__Contact__c!=null];
        
        if(oppsFromRecurringDontaions.size()>0){
            // query for OppConRoles where primary=true and OppID in arg set
            OpportunityContactRole[] conRoles = [select Id,OpportunityId, ContactId From OpportunityContactRole WHERE IsPrimary = true AND Opportunity.Id IN :oppIds ];
            String uniqueConRole = '';
            // now loop through the results and build the map
            for (OpportunityContactRole thisCR : conRoles) {
                uniqueConRole = string.valueOf(thisCR.OpportunityId) + string.valueOf(thisCR.ContactId);
                contactOppToContactRole.put(uniqueConRole , thisCR.Id );
            }
                
            for (Opportunity createdOpp : oppsFromRecurringDontaions) {
              
                OpportunityContactRole ocr = new OpportunityContactRole();
                ocr.OpportunityId = createdOpp.Id;
                ocr.Role = system.label.npe03.RecurringDonationContactRole;
                ocr.IsPrimary = true;
                
                uniqueConRole = string.valueOf(createdOpp.Id)+string.valueOf(createdOpp.npe03__Recurring_Donation__r.npe03__Contact__c);
                if(contactOppToContactRole.get(uniqueConRole)==null){
                    ocr.ContactId = createdOpp.npe03__Recurring_Donation__r.npe03__Contact__c;
                    contactRoleInserts.add(ocr);
                    if ( contactRoleInserts.size() == 100 )
                    {
                        Database.SaveResult[] osr = Database.insert(contactRoleInserts, false);
                        contactRoleInserts.clear();
                    }
                }
            }
        }
        if ( contactRoleInserts.size() > 0 )
        {
            Database.SaveResult[] osr = Database.insert(contactRoleInserts, false);
        }
    }
    
    //updates opps that are part of a recurring donation that was updated
    @future
    public static void updateExistingOppsFuture(set<id>recIDs){updateExistingOpps(recIDs, null);}
    public static void updateExistingOpps(set<id> recIDs, TDTM_Runnable.DmlWrapper dmlWrapper){
        
        
        npe03__Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        map<id, npe03__Recurring_Donation__c> rdMap = new map<id, npe03__Recurring_Donation__c>([select id, npe03__Paid_Amount__c, npe03__Next_Payment_Date__c, 
                                                                                    npe03__Contact__c, npe03__Organization__c, npe03__Amount__c, 
                                                                                    npe03__Date_Established__c, npe03__Recurring_Donation_Campaign__c,
                                                                                     npe03__Installment_Period__c, npe03__Installments__c,
                                                                                     npe03__Last_Payment_Date__c, npe03__Open_Ended_Status__c,
                                                                                     npe03__Schedule_Type__c, npe03__Total_Paid_Installments__c,
                                                                                     npe03__Donor_Name__c
                                                                                  from npe03__Recurring_Donation__c 
                                                                                  where npe03__Open_Ended_Status__c = :openLabel 
                                                                                  and id IN :recIDs]);        
                           
        list<Opportunity> oppList = [select id, Amount, Name, CampaignId, AccountID, CloseDate, npe03__Recurring_Donation__r.id                                         
                                       from Opportunity 
                                       where npe03__Recurring_Donation__r.id IN :rdMap.keySet() 
                                       and isClosed = false
                                       order by CloseDate asc];

        //build a map of recurring donation ID and opps 
        map<id, list<Opportunity>> RDOppMap = new map<id, list<Opportunity>>(); 
        for (Opportunity o : opplist){
            if (RDOppMap.containsKey(o.npe03__Recurring_Donation__r.id)){
                list<Opportunity> opps = RDOppMap.get(o.npe03__Recurring_Donation__r.id);
                opps.add(o);
                RDOppMap.put(o.npe03__Recurring_Donation__r.id, opps);
            }
            else{
                RDOppMap.put(o.npe03__Recurring_Donation__r.id, new list<Opportunity>{o});
            }
        }       
        
        //opps for updating
        list<Opportunity> updateOppsList = new list<Opportunity>();
        
        //loop through existing opps for each RD and update according to values on the RD
        for (id RDid : RDOppMap.keySet()){
            
            date PaymentDate = RDMap.get(RDid).npe03__Next_Payment_Date__c;
            
            for (Opportunity o : RDOppMap.get(RDid)){
                
                o.Amount = rdMap.get(RDid).npe03__Amount__c;
                if (rdMap.get(RDid).npe03__Recurring_Donation_Campaign__c != null && rds.npe03__Add_Campaign_to_All_Opportunites__c){ 
                    o.CampaignId = rdMap.get(RDid).npe03__Recurring_Donation_Campaign__c;
                }               
                
                //changed for beta 7 - dont' update with a null org unless we need to
                if (rdMap.get(RDid).npe03__Organization__c != null)
                    o.AccountID = rdMap.get(RDid).npe03__Organization__c;
                o.CloseDate = PaymentDate;                      
                
                //rebuild the donor string by plucking out the installment number for re-use
                integer lbracket = o.Name.indexOf('(');
                integer rbracket = o.Name.indexOf(')');
                string iNumber = '';
                if (lbracket > 0 && rbracket > lbracket)
                   iNumber = o.Name.substring(lbracket, rbracket + 1);
                //modify the name 
                String oName = '';
                oName += rdMap.get(RDid).npe03__Donor_Name__c; 
                oName += ' ';
                oName += system.label.npe03.RecurringDonationPrefix;
                oName += ' ' + iNumber + ' ';
                oName += o.CloseDate.format();
                o.Name = oName;
                
                //now append appropriate amount to this date
                PaymentDate = getNextDate(PaymentDate, RDMap.get(RDid).npe03__Installment_Period__c);
                updateOppsList.add(o);
            }
        }
        
        if (!updateOppsList.isEmpty()) {
            if (dmlWrapper != null)
                dmlWrapper.objectsToUpdate.putAll(new map<Id, SObject>((list<SObject>) updateOppsList));
            else
                update updateOppsList;
        }
        
        
        if (system.isFuture() || RDOppMap.keySet().size() == 1 || system.isBatch() || RD_ProcessControl.batchButton){
            updateRecurringDonationOnOppChange(RDOppMap.keySet(), null);
        }          
        else{
            updateRecurringDonationOnOppChangeFuture(RDOppMap.keySet());            
        }
    }
         
    //handles updates to the recurring donations object
    public static void handleRecurringDonationUpdate(list<npe03__Recurring_Donation__c> recurringDonations, map<id, npe03__Recurring_Donation__c> oldRecurringDonations, TDTM_Runnable.DmlWrapper dmlWrapper){
        
        //opening a closed recurring donation
        set<id> reevaluateOpps = new set<id>();
        list<npe03__Recurring_Donation__c> reinsertOpps = new list<npe03__Recurring_Donation__c>(); 
        // closed an open recurring donation
        list<npe03__Recurring_Donation__c> newlycloseddonations = new list<npe03__Recurring_Donation__c>();
         
        string openlabel = system.label.npe03.RecurringDonationOpenStatus;
        string closedlabel = system.label.npe03.RecurringDonationClosedStatus;        
        
        for (npe03__Recurring_Donation__c r : recurringDonations){
            npe03__Recurring_Donation__c oldRD = oldRecurringDonations.get(r.id);
            
            //if we're closing an open ended donation, modify the existing opps as required by the custom setting
            if (r.npe03__Open_Ended_Status__c == closedlabel && oldRD.npe03__Open_Ended_Status__c != r.npe03__Open_Ended_Status__c){
                newlycloseddonations.add(r);        
            }            
            
            //if there's any other change that would require a reevaluation of existing Opps
            else if (r.npe03__Open_Ended_Status__c == openlabel){
                if (r.npe03__Amount__c != oldRD.npe03__Amount__c ||
                    r.npe03__Recurring_Donation_Campaign__c != oldRD.npe03__Recurring_Donation_Campaign__c ||
                    r.npe03__Organization__c != oldRD.npe03__Organization__c ||
                    r.npe03__Next_Payment_Date__c != oldRD.npe03__Next_Payment_Date__c                    
                    ){
                    reevaluateopps.add(r.id);
                }
                else if (r.npe03__Installment_Period__c != oldRD.npe03__Installment_Period__c || r.npe03__Contact__c != oldRD.npe03__Contact__c){
                    reinsertopps.add(r);
                }                                        
            }
        }      
        
        if (!newlycloseddonations.isEmpty()){
            runRecurringDonationClosedActions(newlycloseddonations, dmlWrapper);
        }
        if (!reevaluateopps.isEmpty()){
            if (reevaluateopps.size() == 1 || system.isBatch())
                updateExistingOpps(reevaluateopps, dmlWrapper);
            else
                updateExistingOppsFuture(reevaluateopps);
        }
        //needs a total reinsert, not an update
        if (!reinsertopps.isEmpty()){
            //clear existing open opps and recreate
            delete [select id from Opportunity where npe03__Recurring_Donation__c IN :reinsertopps and isClosed = false];
            if (reinsertopps.size() == 1 || system.isBatch()){
                insertOppsOnRecurringDonationInsert(reinsertopps);                  
            }
            else{
                set<id> rdset = new set<id>();
                for (npe03__Recurring_Donation__c r : reinsertopps)
                    rdset.add(r.id);
                insertOppsOnRecurringDonationInsertFuture(rdset);   
            }
        }
    }
    

    public static void evaluateRecurringDonationsForNewOppInsert(list<npe03__Recurring_Donation__c> recurringDonationsToEvaluate){
        
        npe03__Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
    
        list<Opportunity> oppInsertList = new list<Opportunity>();
        
        //get the total number of forecast months
        integer forecast_months = (integer)rds.npe03__Opportunity_Forecast_Months__c;
        
        //grab the contact id for role to take advantage of NPSP C&O if it exists
        Sobjectfield ConIDForRole = Schema.sObjectType.Opportunity.fields.getMap().get('npe01__Contact_Id_for_Role__c');
        
        string openlabel = system.label.npe03.RecurringDonationOpenStatus;
        
        //get the existing donations
        list<sobject> sobjs = [select count(id) oppCount, MAX(CloseDate) MaxDate,
                                  npe03__Recurring_Donation__r.id rdid
                                  from Opportunity where npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c = :openLabel 
                                  and npe03__Recurring_Donation__r.id IN :recurringDonationsToEvaluate                                  
                                  group by rollup(npe03__Recurring_Donation__r.id)]; 
        
        map<id, date> lastOppMap = new map<id, date>();
        map<id, integer> oppCountMap = new map<id, integer>();
        set<id> contactIDs = new set<id>();
                
        for (npe03__Recurring_Donation__c rd : recurringDonationsToEvaluate){
            if (rd.npe03__Contact__c != null ){
                contactIds.add(rd.npe03__Contact__c);
            }
        }            
        //Create a Map of Contact Ids and Contact Records
        map<id,Contact> contactMap;        
        if (contactIds.size() > 0){
            contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
        }        
 
        for (sobject obj : sobjs){
            id rdid = (id)obj.get('rdid'); 
            if ((date)obj.get('MaxDate') != null){
                lastOppMap.put(rdid, (date)obj.get('MaxDate'));
            }
                                  
            oppCountMap.put(rdid, (integer)obj.get('oppCount'));                 
        }
        
        customFieldMappingSettings = npe03__Custom_Field_Mapping__c.getAll();
        //if the RD has no opps, we'll need to bail back to the insert methods
        list<npe03__Recurring_Donation__c> reRollRDs = new list<npe03__Recurring_Donation__c>();
        for (npe03__Recurring_Donation__c rd : recurringDonationsToEvaluate){
            
            //only proceed if there are some opps, otherwise we need to start over from scratch 
            if (oppCountMap.containsKey(rd.id)){
                integer oppCounter = oppCountMap.get(rd.id) + 1;                    
                           
                if (system.today().addMonths(forecast_months) > lastOppMap.get(rd.id)){
                    date oppclosedate = lastOppMap.get(rd.id);
                    do{
                        Opportunity o = new Opportunity();

                        //multicurrency?
                        if(isMultiCurrency)
                            o.put(OppCurrencyField,rd.get(RDCurrencyField));
                    
                        //account or contact?
                        if (rd.npe03__Organization__c != null){
                           o.AccountId = rd.npe03__Organization__c;
                        }
                        else if (contactMap.containsKey(rd.npe03__Contact__c)){
                            Contact c = contactMap.get(rd.npe03__Contact__c);
                            o.AccountId = c.AccountId;
                            if (ConIDForRole != null){
                                o.put('npe01__Contact_Id_For_Role__c', (string)c.id);
                            }
                        }                    
                    
                        oppclosedate = getNextDate(oppclosedate, rd.npe03__Installment_Period__c);
                        o.CloseDate = oppclosedate;                                                                                        
                        string oName = rd.npe03__Donor_Name__c + ' ' + system.label.npe03.RecurringDonationPrefix +
                        ' (' + string.valueOf(oppCounter) + ') ' + o.CloseDate.format();
                    
                        o.Name = oName;
                        o.Amount = rd.npe03__Amount__c;
                        o.StageName = system.label.npe03.RecurringDonationStageName;                    
                        o.npe03__Recurring_Donation__c = rd.Id;                    
                        //evaluate any custom field mappings
                        for (string s : customFieldMappingSettings.keySet()){
                            npe03__Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                            o.put(cfm.npe03__Opportunity_Field__c, rd.get(cfm.npe03__Recurring_Donation_Field__c));
                        }
                    
                        if (rd.npe03__Recurring_Donation_Campaign__c != null && (rds.npe03__Add_Campaign_to_All_Opportunites__c || oppCounter == 1)){
                            o.CampaignId = rd.npe03__Recurring_Donation_Campaign__c;
                        }
                    
                        oppCounter++;
                        oppInsertList.add(o);                   
                    }while(oppclosedate < system.today().addMonths(forecast_months));
                }
            }
            else{
                reRollRDs.add(rd);
            }
        }
        if (!reRollRDs.isEmpty())
            insertOppsOnRecurringDonationInsert(reRollRDs);
       
        set<id> RDID = new set<id>();  
        if(!oppInsertList.isEmpty())
        {
            Database.SaveResult[] lsr;
            list<Database.SaveResult> badSRs = new list<Database.SaveResult>();
            list<Opportunity> badOpps = new list<Opportunity>();
            set<id> createdOppIds = new set<id>();  
            
            //we're probably coming from the UI if we're only updating one RD, so lets 
            //let the error bubble up to the top
            if (RDID.size() == 1)
                lsr = Database.insert(oppInsertList, true);
            //otherwise, this is a bulk operation so fail to the error handler 
            else
                lsr = Database.insert(oppInsertList, false);        
                    
            integer i = 0;                          
            for (Database.SaveResult s : lsr){
                if (s.isSuccess() == true){
                    //get all the new OppIds into a list
                    createdOppIds.add(s.getId());
                    RDID.add(oppInsertList[i].npe03__Recurring_Donation__c);                    
                }    
                //handle errors on insert   
                else{
                    badSRs.add(s);
                    badOpps.add(oppInsertList[i]);            
                }                     
                i++;
            }
                    
            if (ConIDForRole == null || Test.isRunningTest()){
                if (!system.isFuture() && !system.isBatch() && !RD_ProcessControl.batchButton)
                    oppContactRolesFuture(createdOppIds); 
                else 
                    oppContactRoles(createdOppIds);                    
            }
            
            if (!badSRs.isEmpty()){
            	ERR_Handler errorHandler = new ERR_Handler();
                errorHandler.processInsertResults(badSRs, badOpps, ERR_Handler.Context.RD);
            }
        }
        
        if (system.isFuture() || system.isBatch() || (recurringDonationsToEvaluate.size() == 1 && !system.isFuture() && !system.isBatch()) || RD_ProcessControl.batchButton){
            updateRecurringDonationOnOppChange(RDID, null);
        }
        else{
            updateRecurringDonationOnOppChangeFuture(RDID); 
        }   
    }
  
    /// <name> approveDeleteRecDonations </name>
    /// <summary> Validates that a Recurring Donation can be deleted </summary>
    /// <param name="listRD"> RecurringDonation objects that are being triggered </param>
    public static void approveDeleteRecDonations(list<npe03__Recurring_Donation__c> listRD) {
        Map<Id,Id> mapRDIdOppId = new Map<Id,Id>();

        for (Opportunity o : [Select Id, npe03__Recurring_Donation__c from Opportunity where npe03__Recurring_Donation__c in :listRD]) {
            mapRDIdOppId.put(o.npe03__Recurring_Donation__c,o.Id);
        }
        
        // don't allow deleting any RD which still has Opps pointing to it.
        for (npe03__Recurring_Donation__c r : listRD) {
            if (mapRDIdOppId.containsKey(r.Id)) {
                r.addError(system.label.npe03.RecurringDonationCantDeleteError);
            }
        }
    }
    
    /*** UTILITY METHODS ***/
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings() {
        //if no settings exist, create defaults
        if (recurringDonationsSettings == null) {
            //first see if we already have settings
            recurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
            //if the save behavior is null, then we'll need to upsert new settings, otherwise, we have valid settings as its 
            //the only field w/o a default defined
            if (recurringDonationsSettings.npe03__Open_Opportunity_Behavior__c == null){  
                recurringDonationsSettings.npe03__Open_Opportunity_Behavior__c = RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name();
                recurringDonationsSettings.npe03__Add_Campaign_to_All_Opportunites__c = true;
                recurringDonationsSettings.npe03__Enable_Update_Check__c = true;
                //recurringDonationsSettings.npe03__Error_Email_Notifications__c = 'All Sys Admins'; *This field has been moved to the ERR_Settings__c custom setting
                recurringDonationsSettings.npe03__Maximum_Donations__c = 50;
                recurringDonationsSettings.npe03__Opportunity_Forecast_Months__c = 12;
                recurringDonationsSettings.npe03__Update_Check_Interval__c = 90;
                id myid = [select id from RecordType where sobjecttype = 'Opportunity' limit 1].id;
                recurringDonationsSettings.npe03__Record_Type__c = myid; 
                upsert recurringDonationsSettings;    
                recurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();                           
            }
        }         
        return recurringDonationsSettings;
    }

    //handles action for opps on recurring donations
    private static void runRecurringDonationClosedActions(list<npe03__Recurring_Donation__c> closedRDs, TDTM_Runnable.DmlWrapper dmlWrapper) {
        // determine the update type - 
        npe03__Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        //system.debug('IN THE PRIVATE METHOD');
        if (!closedRDs.isEmpty() && rds.npe03__Open_Opportunity_Behavior__c != RecurringDonationCloseOptions.No_Action.name()) {
            map<Id, Opportunity> mapIdOpp = new map<Id, Opportunity>([select Id, StageName, npe03__Recurring_Donation__r.id from Opportunity where npe03__Recurring_Donation__r.id IN :closedRDs and isClosed = false]);
         
            if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Delete_Open_Opportunities.name()){
                //system.debug('IN THE PRIVATE METHOD3');
                if (dmlWrapper != null) {
                    List<SObject> oppsToDelete = new List<SObject>();
                    for(Id oppToDeleteId : mapIdOpp.keySet()) {
                    	oppsToDelete.add(new Opportunity(Id = oppToDeleteId));
                    }
                    dmlWrapper.objectsToDelete.addAll(oppsToDelete);
                } else {
                    database.delete(mapIdOpp.values());
                }
            }              
            else if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()){
                for (Opportunity o : mapIdOpp.values()){
                    o.StageName = system.label.npe03.RecurringDonationClosedLostOpportunityStage;
                }            
                if (dmlWrapper != null)
                    dmlWrapper.objectsToUpdate.putAll((map<Id, SObject>) mapIdOpp); 
                else
                    update mapIdOpp.values();
            }
        }
    }

    //helper for calculating the next date in the sequence based on the RD schedule type 
    private static date getNextDate(date CalcDate, string InstallmentType){
        npe03__Recurring_Donations_Settings__c rds = getRecurringDonationsSettings();
        
        if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodYearly){
            CalcDate = CalcDate.addYears(1);
        } 
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodQuarterly){
            CalcDate = CalcDate.addMonths(3);
        } 
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodMonthly){
            CalcDate = CalcDate.addMonths(1);
        } 
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodWeekly){
            CalcDate = CalcDate.addDays(7);
        }
      /*  else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodCustom){ 
            CalcDate = CalcDate.addDays((integer)rds.Custom_Days__c);
        }*/
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriod1stand15th){
            //increment it by one day until we hit either the 1st or 15th            
            do{
                CalcDate = CalcDate.addDays(1);
            }while (CalcDate.day() != 15 && CalcDate.day() != 1);
        }        
        else{
            map<string, npe03__Custom_Installment_Settings__c> cisMap = npe03__Custom_Installment_Settings__c.getAll();
            //handle custom installment types           
            if (cisMap.containsKey(InstallmentType)){
                npe03__Custom_Installment_Settings__c c = cisMap.get(InstallmentType);
                
                if (c.npe03__Increment__c == 'Days'){
                    CalcDate = CalcDate.addDays(integer.valueOf(c.npe03__Value__c));
                }
                else if (c.npe03__Increment__c == 'Weeks'){
                    CalcDate = CalcDate.addDays(integer.valueOf(c.npe03__Value__c * 7));
                }
                else if (c.npe03__Increment__c == 'Months'){
                    CalcDate = CalcDate.addMonths(integer.valueOf(c.npe03__Value__c));
                }
                else if (c.npe03__Increment__c == 'Years'){
                    CalcDate = CalcDate.addYears(integer.valueOf(c.npe03__Value__c));
                }           
            }
            //if its not a valid value, set it to the max last payment date plus the 
            //the open ended value so we only create one opp max                           
            else{   
                CalcDate = CalcDate.addMonths((integer)rds.npe03__Opportunity_Forecast_Months__c);
            }                
        }
        return CalcDate;
    }
}