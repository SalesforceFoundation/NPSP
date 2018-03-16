/*
    Copyright (c) 2012, Salesforce.org
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
* @date 2012 (2.0)
* @group Recurring Donations
* @group-content ../../ApexDocContent/RecurringDonations.htm
*
* @description The main class for controlling the behavior of Recurring Donations, both open ended and standard.
*
* The logic of this class is quite complicated, so here is a summary of the call chain for various scenarios.
*
* Insert a new RD (open or non open):
*   RD_RecurringDonations_TDTM(AfterInsert)
*       insertOppsOnRecurringDonationInsert
*           Database.insert(opps)
*           updateRecurringDonationOnOppChange
*
* Update a non open-ended (fixed length) RD:
*   RD_RecurringDonations_TDTM(AfterUpdate)
*       handleRecurringDonationUpdate
*           handleFixedLengthScheduleRecalculation
*               updateRecurringDonationOnOppChange
*
* Update a open-ended RD to closed:
*   RD_RecurringDonations_TDTM(AfterUpdate)
*       handleRecurringDonationUpdate
*           runRecurringDonationClosedActions
*
* Update an open-ended RD with changes that require opp updating:
*   RD_RecurringDonations_TDTM(AfterUpdate)
*       handleRecurringDonationUpdate
*           handleOpenEndedScheduleRecalculation
*               updateRecurringDonationOnOppChange
*
* Update an open-ended RD to different schedule or contact (need to recreate opps):
*   RD_RecurringDonations_TDTM(AfterUpdate)
*       handleRecurringDonationUpdate
*           handleOpenEndedScheduleRecalculation
*               updateRecurringDonationOnOppChange
*
* Refresh Opportunities button on non open-ended (fixed length):
*   evaluateRecurringDonationsForNewOppInsert 
*       handleFixedLengthScheduleRecalculation
*           updateRecurringDonationOnOppChange
*
* Refresh Opportunities button or Nightly Batch on open-ended:
*   evaluateRecurringDonationsForNewOppInsert
*       handleOpenEndedScheduleRecalculation
*           updateRecurringDonationOnOppChange
*
* Update an Opportunity that belongs to a RD:
*   RD_RecurringDonations_Opp_TDTM(AfterUpdate)
*       updateRecurringDonationOnOppChange
*
*/
public class RD_RecurringDonations {
    
    /*******************************************************************************************************
    * @description Enum to specify behavior of what happens to open opportunities when their RD is closed.
    */ 
    public enum RecurringDonationCloseOptions {Delete_Open_Opportunities, Mark_Opportunities_Closed_Lost, No_Action}

    /*******************************************************************************************************
    * @description holds the current custom field mappings used when creating opps for the RD.
    */
    private static map<string, npe03__Custom_Field_Mapping__c> customFieldMappingSettings = UTIL_ListCustomSettingsFacade.getMapCustomFieldMappings();
    
    /*******************************************************************************************************
    * @description holds the RD's CurrencyIsoCode field that is enabled in multicurrency organizations.
    */ 
    private static SObjectField RDCurrField;

    /*******************************************************************************************************
    * @description holds the RD's CurrencyIsoCode field that is enabled in multicurrency organizations.
    */ 
    public static SObjectfield RDCurrencyField{get{
        if (RDCurrField == null){
            RDCurrField = Schema.sObjectType.npe03__Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode');
        }   
        return RDCurrField;
    }set;}    

    /*******************************************************************************************************
    * @description holds the Opp's CurrencyIsoCode field that is enabled in multicurrency organizations.
    */ 
    private static Sobjectfield OppCurrField;

    /*******************************************************************************************************
    * @description holds the Opp's CurrencyIsoCode field that is enabled in multicurrency organizations.
    */ 
    public static SObjectField OppCurrencyField{get{
        if (OppCurrField == null)
            OppCurrField = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
        return OppCurrField;
    }set;}       

    /*******************************************************************************************************
    * @description is MultiCurrency enabled in this org
    */ 
    private static boolean isMc;

    /*******************************************************************************************************
    * @description is MultiCurrency enabled in this org
    */ 
    public static boolean isMultiCurrency{get{
        if (isMc == null){          
            if (Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode') != null)
                isMc = true;
            else
                isMc = false;           
        }           
        return isMc;                
    }set;}
    
    /*******************************************************************************************************
    * @description Future method that updates the specified RD's by querying their Opps so it can update the RD's 
    * Next Payment Date, Last Payment Date, Paid Amount, Number of Paid Installments.
    * @param RDids The set of rd Id's to update
    * @return void
    */ 
    @future
    public static void updateRecurringDonationOnOppChangeFuture(set<id> RDids){
        updateRecurringDonationOnOppChange(RDids, null);
    }
    
    /*******************************************************************************************************
    * @description Updates the specified RD's by querying their Opps so it can update the RD's 
    * Next Payment Date, Last Payment Date, Paid Amount, Number of Paid Installments.
    * Applies to all RDs that are not marked "Closed", i.e., both
    * non-closed (still open) Open-Ended Recurring Donations (status = "Open")
    * and Fixed Length Recurring Donations (status = None or null).
    * @param RDids The set of rd Id's to update
    * @param dmlWrapper Object to hold the rd's to be updated
    * @return void
    */ 
    public static void updateRecurringDonationOnOppChange(set<id> RDids, TDTM_Runnable.DmlWrapper dmlWrapper){

        Boolean CRLPEnabled = UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Customizable_Rollups_Enabled__c;

        // only use this hard-coded RD rollup code if Customizable Rollups aren't enabled
        if (!CRLPEnabled) {

            //set of RDs to be updated
            map<id, npe03__Recurring_Donation__c> updateMap = new map<id, npe03__Recurring_Donation__c>();

            //Get the closed label for opps
            string closedLabel = system.label.npe03.RecurringDonationClosedStatus;

            //before we query for any RD's, we must make sure that all previous changes to them have been committed!
            if (dmlWrapper != null)
                TDTM_TriggerHandler.processDML(dmlWrapper);

            String rdQuery = strQueryRDNoWhere();
            rdQuery += ' where npe03__Open_Ended_Status__c <> :closedLabel and id IN :RDids';

            //get all possible rd records that may need updating, exclude ones that are closed.
            map<id, npe03__Recurring_Donation__c> rdMap = new map<id, npe03__Recurring_Donation__c>();
            for (sObject rd : database.query(rdQuery)) {
                rdMap.put((id) rd.get('id'), (npe03__Recurring_Donation__c) rd);
            }

            //get the cumulative values to update the recurring donations
            //update the rc next payment date
            //and the paid amounts and paid installments
            for (sobject obj : [
                    select count(id) oppcount, MIN(CloseDate) MinDate, MAX(CloseDate) MaxDate, SUM(Amount) Total,
                            isClosed, npe03__Recurring_Donation__c rdid, isWon
                    from Opportunity
                    where npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c <> :closedLabel
                    and npe03__Recurring_Donation__c IN :rdMap.keySet()
                    group by rollup(npe03__Recurring_Donation__c, isClosed, isWon)
            ]) {

                id rdid = (id) obj.get('rdid');

                boolean isClosed = (boolean) obj.get('isClosed');
                boolean isWon = (boolean) obj.get('isWon');

                if (rdid != null) {
                    npe03__Recurring_Donation__c rd;
                    //if we already have values for this RD, get it from our rdid map, otherwise just grab
                    //the one we're already working on
                    if (!updateMap.containsKey(rdid)) {
                        rd = rdMap.get(rdid);

                        //initialize fields to null that might not get set
                        rd.npe03__Next_Payment_Date__c = null;
                        rd.npe03__Last_Payment_Date__c = null;
                        rd.npe03__Paid_Amount__c = null;
                        rd.npe03__Total_Paid_Installments__c = null;
                        updateMap.put(rdid, rd);
                    } else {
                        rd = updateMap.get(rdid);
                    }

                    //if this is the summary row for this rd only update installments for open ended opportunities
                    if (isClosed == null && isWon == null && rd.npe03__open_ended_status__c == system.label.npe03.RecurringDonationOpenStatus) {
                        rd.npe03__Installments__c = (integer) obj.get('oppcount');
                        updateMap.put(rdid, rd);
                    }
                    //if this is the open set of opps
                    else if (isClosed == false && isWon == null) {
                        rd.npe03__Next_Payment_Date__c = (date) obj.get('MinDate');
                        updateMap.put(rdid, rd);
                    }
                    //if this is the closed set of opps
                    else if (isClosed == true && isWon == true) {
                        rd.npe03__Last_Payment_Date__c = (date) obj.get('MaxDate');

                        //convert rollup total to RD's currency
                        if (RLLP_OppRollup_UTIL.isMultiCurrency()) {
                            rd.npe03__Paid_Amount__c = UTIL_CurrencyConversion.convertFromCorporateUsingStandardRates((String) rd.get(RDCurrencyField), (Decimal) obj.get('Total'));
                        } else {
                            rd.npe03__Paid_Amount__c = (Decimal) obj.get('Total');
                        }
                        rd.npe03__Total_Paid_Installments__c = (integer) obj.get('oppcount');
                        updateMap.put(rdid, rd);
                    }

                    // if no open opportunities remain because forecast months is too short,
                    // use last payment date to project next payment date
                    if (rd.npe03__Last_Payment_Date__c != null) {
                        Date nextPaymentDate = getNextDate(rd.npe03__Last_Payment_Date__c, rd);
                        rd.npe03__Next_Payment_Date__c = nextPaymentDate;
                        updateMap.put(rdid, rd);
                    }
                }
            }

            if (!updateMap.isEmpty()) {
                if (dmlWrapper != null) {
                    dmlWrapper.objectsToUpdate.addAll((list<SObject>) updateMap.values());
                } else {
                    update updateMap.values();
                }
            }
        }
    } 
   
    /*******************************************************************************************************
    * @description Returns a list of RD's for the specified Id's, with all their fields queried.
    * @param setRDids The set of rd Id's to quer
    * @return list<npe03__Recurring_Donation__c>
    */ 
    public static list<npe03__Recurring_Donation__c> requeryListRD(set<Id> setRDId) {    
        string queryRCD = strQueryRDNoWhere();
        queryRCD += ' where Id in :setRDId';
        
        //execute query
        return Database.query(queryRCD);
    }
    
    /*******************************************************************************************************
    * @description Returns the soql string for RD's.  Includes fields from the custom field map and
    * currency iso fields.  Does not include the where clause since different callers have different
    * filtering needs.
    * @return string
    */
    public static string strQueryRDNoWhere() {

        // these must be lowercase so set.contains() will work
        set<string> existingFields = new set<string>{  'npe03__open_ended_status__c', 'npe03__next_payment_date__c', 'npe03__last_payment_date__c', 'name', 'npe03__Paid_Amount__c',
                'npe03__organization__c', 'npe03__contact__c', 'npe03__installment_amount__c',
                'npe03__installments__c', 'npe03__amount__c', 'npe03__total__c', 'npe03__installment_period__c',
                'npe03__date_established__c', 'npe03__donor_name__c', 'npe03__schedule_type__c',
                'npe03__recurring_donation_campaign__c', 'npe03__total_paid_installments__c', 'ownerid',
                'always_use_last_day_of_month__c'};

        String queryRCD = 'select id';
        for (string s : existingFields){
            queryRCD += ', ' + s;
        }

        //add any custom mapping to make sure we have the required fields
        for (string s : customFieldMappingSettings.keySet()){
            string RDFieldName = customFieldMappingSettings.get(s).npe03__Recurring_Donation_Field__c;
            if (!existingFields.contains(RDFieldName.toLowerCase()) && s != 'id'){
                queryRCD = queryRCD + ',' + customFieldMappingSettings.get(s).npe03__Recurring_Donation_Field__c;
                existingFields.add(RDFieldName.toLowerCase());
            }
        }

        //if currencyiso field exists add it to query for use later
        if (isMultiCurrency) {
            queryRCD = queryRCD + ',CurrencyIsoCode';
        }

        queryRCD=queryRCD+' from npe03__Recurring_Donation__c';

        return (queryRCD);
    }

    /*******************************************************************************************************
    * @description Future method that creates new Opportunities for the specified Recurring Donations.
    * @param recurringDonations The list of RD's being created
    * @return void
    */ 
    @future
    public static void insertOppsOnRecurringDonationInsertFuture(set<id> recids) {
        list<npe03__Recurring_Donation__c> reclist = requeryListRD(recids);
        insertOppsOnRecurringDonationInsert(reclist);
    }
    
    /*******************************************************************************************************
    * @description Creates new Opportunities for the specified Recurring Donations. Called by the AfterInsert
    * Trigger Handler on RD's, and also when RD's are updated and we delete and recreate their Opps.
    * @param recurringDonations The list of RD's being created
    * @return void
    */ 
    public static void insertOppsOnRecurringDonationInsert(list<npe03__Recurring_Donation__c> recurringDonations) {
        //Lists used for final Insert
        list<Opportunity> opportunityInserts = new list<Opportunity>();
        
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        
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
                Integer installments = (installs == null ? 0 : installs.intValue());
                    
                date oppCloseDate = getStartDate(r);

                Integer j=0;
                decimal installmentAmount = r.npe03__Installment_Amount__c;

                decimal paidAmount = 0;
                if (r.npe03__Paid_Amount__c != null)
                   paidAmount = r.npe03__Paid_Amount__c; 
                
                // deal with already paid installments.
                integer paidInstallments = 0;
                if (r.npe03__Total_Paid_Installments__c != null) {
                	paidInstallments = integer.valueOf(r.npe03__Total_Paid_Installments__c);
                    j = paidInstallments;
                    if (r.npe03__Schedule_Type__c != Label.npe03.RecurringDonationMultiplyValue) {
                        if (installments - paidInstallments > 0)                    
                            installmentAmount = (r.npe03__Amount__c - paidAmount) / (installments - paidInstallments);
                    }
                }
                    
                for ( ;j<installments;j++ )
                {
                    Opportunity opp = new Opportunity();
                    opp.CloseDate = oppCloseDate;
                    opp.OwnerId = r.OwnerId;
                
                    if ( r.npe03__Organization__c != null )
                    {
                       opp.AccountId = r.npe03__Organization__c;
                    }
                    else
                    if ( contactMap.containsKey(r.npe03__Contact__c) )
                    {
                        Contact c = contactMap.get(r.npe03__Contact__c);
                        opp.AccountId = c.AccountId;
                        if (ConIDForRole != null){
                            opp.put('npe01__Contact_Id_For_Role__c', (string)c.id);
                        }
                    } 

                    // James Melville 05/03/2011 Added to support multi-currency sfdc.  
                    // we check currency iscode before entering the loop since it's a system check
                    if(isMultiCurrency){                        
                        //set the donation currency field to equal the recurring donation currency
                        opp.put(OppCurrencyField,r.get(RDCurrencyField));                        
                    }
                
                    //add the remainder to the last installment, otherwise use the amount
                    decimal totalAmount = r.npe03__Total__c;
                    // current formula field doesn't handle a missing schedule type, but let's treat it as divide by.
                    if (r.npe03__Schedule_Type__c == null)
                        totalAmount = r.npe03__Amount__c;
                    if (j + 1 == installments && installments * r.npe03__Installment_Amount__c != totalAmount) {                    	
                        opp.Amount = totalAmount - paidAmount - ((j - paidInstallments) * installmentAmount);
                    } else {
                        opp.Amount = installmentAmount;
                    }

                    opp.Recurring_Donation_Installment_Number__c = j+1;

                    opp.Name = getOpportunityName(opp,r);

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
                       //all or nothing so errors not lost
                       insert opportunityInserts;
                       opportunityInserts.clear();
                    }

                    //get the close date for the next opp in the loop
                    oppCloseDate = getNextDate(OppCloseDate, r);

                }
            }
            
            //this is an open-ended rd that needs opptys
            else{
                //if its not 'open', we're not doing anything to it
                if (r.npe03__Open_Ended_Status__c == system.label.npe03.RecurringDonationOpenStatus){

                    integer forecast_months = (integer)rds.npe03__Opportunity_Forecast_Months__c;
                    Date dtForecast =  system.today().toStartOfMonth().addMonths(forecast_months);         

                    Integer rdcounter = 1;
                    if (r.npe03__Total_Paid_Installments__c > 0)
                        rdcounter = (integer)r.npe03__Total_Paid_Installments__c + 1;

                    Date oppCloseDate = getStartDate(r);

                    while (oppCloseDate < dtForecast) {
                        Contact con;
                        if (contactMap != null && contactMap.containsKey(r.npe03__Contact__c)) {
                            con = contactMap.get(r.npe03__Contact__c);
                        }
                    	Opportunity o = new Opportunity();
                        o = normalizeOppForRD(o,r,oppCloseDate,r.npe03__Amount__c,con,rdcounter);
                        opportunityInserts.add(o);
                        rdcounter++;
                        oppCloseDate = getNextDate(OppCloseDate, r);
                    }
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
            if (RDID.size() == 1) {
                lsr = Database.insert(opportunityInserts, true);
            }
            //otherwise, this is a bulk operation so fail to the error handler
            else {
                lsr = Database.insert(opportunityInserts, false);
            }
                    
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
                    
            if (ConIDForRole == null){ 
                if (createdOppIds.size() > 1 && !system.isFuture() && !system.isBatch() && !RD_RecurringDonations_BATCH.isBatchButton)
                    oppContactRolesFuture(createdOppIds); 
                else
                    oppContactRoles(createdOppIds);                    
            }
            
            if (!badSRs.isEmpty()) {
                ERR_Handler.Errors errors = ERR_Handler.getErrors(badSRs, badOpps);
                ERR_Handler.processErrors(errors.errorRecords, ERR_Handler_API.Context.RD.name());
            }            
            
            if (updateRecurringDonationSet.size() > 1 && !system.isBatch() && !system.isFuture() && !RD_RecurringDonations_BATCH.isBatchButton)
                updateRecurringDonationOnOppChangeFuture(updateRecurringDonationSet);
            else
                updateRecurringDonationOnOppChange(updateRecurringDonationSet, null);
        }
    }
    
    /*******************************************************************************************************
    * @description Future method that creates household OpportunityContactRoles for the specified Opps.
    * Since NPSP3, the RD code always leverages opp.npe01__Contact_Id_for_Role__c and this code isn't used.
    * @param oppIds The list of Opportunity Id's to create OCRS for
    * @return void
    */ 
    @future 
    public static void oppContactRolesFuture(set<id> oppIds){
       oppContactRoles(oppIds);
    }
    
    /*******************************************************************************************************
    * @description Creates household OpportunityContactRoles for the specified Opps.
    * Since NPSP3, the RD code always leverages opp.npe01__Contact_Id_for_Role__c and this code isn't used.
    * @param oppIds The list of Opportunity Id's to create OCRS for
    * @return void
    */ 
    public static void oppContactRoles(Set<Id> oppIds) {
        List<OpportunityContactRole> contactRoleInserts = new List<OpportunityContactRole>();
        Map<String, Id> contactOppToContactRole = new Map<String, Id>();
            
        Opportunity[] oppsFromRecurringDonations = [
            SELECT id, npe03__Recurring_Donation__c, npe03__Recurring_Donation__r.npe03__Contact__c 
            FROM Opportunity 
            WHERE Id IN :oppIds AND 
            npe03__Recurring_Donation__r.npe03__Contact__c != null
        ];
        
        if (!oppsFromRecurringDonations.isEmpty()) {
            String uniqueConRole = '';

            for (OpportunityContactRole thisCR : [
                SELECT Id, OpportunityId, ContactId 
                FROM OpportunityContactRole 
                WHERE IsPrimary = true AND 
                OpportunityId IN :oppIds 
            ]) {
                uniqueConRole = string.valueOf(thisCR.OpportunityId) + string.valueOf(thisCR.ContactId);
                contactOppToContactRole.put(uniqueConRole , thisCR.Id );
            }
                
            for (Opportunity createdOpp : oppsFromRecurringDonations) {
              
                OpportunityContactRole ocr = new OpportunityContactRole();
                ocr.OpportunityId = createdOpp.Id;
                ocr.Role = system.label.npe03.RecurringDonationContactRole;
                ocr.IsPrimary = true;
                
                uniqueConRole = string.valueOf(createdOpp.Id)+string.valueOf(createdOpp.npe03__Recurring_Donation__r.npe03__Contact__c);
                if (contactOppToContactRole.get(uniqueConRole) == null) {
                    ocr.ContactId = createdOpp.npe03__Recurring_Donation__r.npe03__Contact__c;
                    contactRoleInserts.add(ocr);

                    if (contactRoleInserts.size() == 100) {
                        // all or nothing so errors not lost
                        insert contactRoleInserts;
                        contactRoleInserts.clear();
                    }
                }
            }
        }
        if (!contactRoleInserts.isEmpty()) {
            // all or nothing so errors not lost
            insert contactRoleInserts;
        }
    }
    
    /*******************************************************************************************************
    * @description Future method that updates all the existing Opportunities for the specified Recurring Donations.
    * @param recIDs The set of RD id's to process
    * @param dmlWrapper Object to store the Opps that need updating
    * @return void
    */ 
    @future
    public static void updateExistingOppsFuture(set<id>recIDs){
       updateExistingOpps(recIDs, null);
    }
    
    /*******************************************************************************************************
    * @description Updates all the existing Opportunities for the specified Recurring Donations.
    * @param recIDs The set of RD id's to process
    * @param dmlWrapper Object to store the Opps that need updating
    * @return void
    */ 
    public static void updateExistingOpps(set<id> recIDs, TDTM_Runnable.DmlWrapper dmlWrapper){
        
        
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        string closedLabel = system.label.npe03.RecurringDonationClosedStatus;

        string rdQuery = strQueryRDNoWhere();
                rdQuery+=' where npe03__Open_Ended_Status__c <> :closedLabel ';
                rdQuery+=' and id IN :recIDs ';
        List<npe03__Recurring_Donation__c> rdsToUpdate = database.query(rdQuery);       
        map<id, npe03__Recurring_Donation__c> rdMap = new map<id, npe03__Recurring_Donation__c>(rdsToUpdate);  
                           
        list<Opportunity> oppList = [select id, Amount, Name, CampaignId, AccountID, CloseDate, Recurring_Donation_Installment_Number__c, npe03__Recurring_Donation__c                                         
                                       from Opportunity 
                                       where npe03__Recurring_Donation__c IN :rdMap.keySet() 
                                       and isClosed = false
                                       order by CloseDate asc];

        //build a map of recurring donation ID and opps 
        map<id, list<Opportunity>> RDOppMap = new map<id, list<Opportunity>>(); 
        for (Opportunity o : opplist){
            if (RDOppMap.containsKey(o.npe03__Recurring_Donation__c)){
                list<Opportunity> opps = RDOppMap.get(o.npe03__Recurring_Donation__c);
                opps.add(o);
                RDOppMap.put(o.npe03__Recurring_Donation__c, opps);
            }
            else{
                RDOppMap.put(o.npe03__Recurring_Donation__c, new list<Opportunity>{o});
            }
        }       
        
        //opps for updating
        list<Opportunity> updateOppsList = new list<Opportunity>();
        
        //loop through existing opps for each RD and update according to values on the RD
        for (id RDid : RDOppMap.keySet()){

            date PaymentDate = getStartDate(RDMap.get(RDid));

            for (Opportunity o : RDOppMap.get(RDid)){
                
                o.Amount = rdMap.get(RDid).npe03__Amount__c;
                if (rdMap.get(RDid).npe03__Recurring_Donation_Campaign__c != null && rds.npe03__Add_Campaign_to_All_Opportunites__c){ 
                    o.CampaignId = rdMap.get(RDid).npe03__Recurring_Donation_Campaign__c;
                }               
                
                //changed for beta 7 - dont' update with a null org unless we need to
                if (rdMap.get(RDid).npe03__Organization__c != null)
                    o.AccountID = rdMap.get(RDid).npe03__Organization__c;
                o.CloseDate = PaymentDate;                      
                
                o.Name = getOpportunityName(o,rdMap.get(RDid));

                //evaluate any custom field mappings
                for (string s : customFieldMappingSettings.keySet()){
                    npe03__Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
                    o.put(cfm.npe03__Opportunity_Field__c, rdMap.get(RDid).get(cfm.npe03__Recurring_Donation_Field__c));
                }
                updateOppsList.add(o);

                //now append appropriate amount to this date
                PaymentDate = getNextDate(PaymentDate, rdMap.get(RDid));
            }
        }
        
        if (!updateOppsList.isEmpty()) {
            //refresh opportunity names before update. if no opportunity names are defined, keeps original name
            OPP_OpportunityNaming.refreshOppNames(updateOppsList);
            if (dmlWrapper != null)
                dmlWrapper.objectsToUpdate.addAll((list<SObject>) updateOppsList);
            else
                update updateOppsList;
        }
        
        
        if (system.isFuture() || RDOppMap.keySet().size() == 1 || system.isBatch() || RD_RecurringDonations_BATCH.isBatchButton){
            updateRecurringDonationOnOppChange(RDOppMap.keySet(), dmlWrapper);
        }          
        else{
            updateRecurringDonationOnOppChangeFuture(RDOppMap.keySet());            
        }
    }
         
    /*******************************************************************************************************
    * @description Trigger AfterUpdate Handler for updates on existing Recurring Donations.  Key scenarios include:
    * - closing an open ended rd, which should close all remaining opps on the rd.
    * - opening a closed rd, which should create new opps on the rd.
    * - any other modification to the rd, which should update the rd's opps.
    * @param recurringDonations The list of updated RD's to process
    * @param oldRecurringDonations A map from an RD's Id to its RD before the update 
    * @param dmlWrapper Object to store the Opps that need updating
    * @return void
    */ 
    public static void handleRecurringDonationUpdate(list<npe03__Recurring_Donation__c> recurringDonations, map<id, npe03__Recurring_Donation__c> oldRecurringDonations, TDTM_Runnable.DmlWrapper dmlWrapper) {

        // list of RDs going from Open-->Closed
        list<npe03__Recurring_Donation__c> newlyClosedDonations = new list<npe03__Recurring_Donation__c>();

        Map<Id, npe03__Recurring_Donation__c> openEndedRDsToRecalculate = new Map<Id, npe03__Recurring_Donation__c>();
        Map<Id, npe03__Recurring_Donation__c> fixedLengthRDsToRecalculate = new Map<Id, npe03__Recurring_Donation__c>();

        String openlabel = System.label.npe03.RecurringDonationOpenStatus;
        String closedlabel = System.label.npe03.RecurringDonationClosedStatus;

        for (npe03__Recurring_Donation__c r : recurringDonations) {

            Boolean needsRecalc = needsRecalculation(r, oldRecurringDonations.get(r.id));

            if (needsRecalc) {

                if (r.npe03__Open_Ended_Status__c == closedlabel
                        && oldRecurringDonations.get(r.id).npe03__Open_Ended_Status__c != r.npe03__Open_Ended_Status__c
                        ) {
                    // closing an open ended donation
                    newlyClosedDonations.add(r);
                } else if (r.npe03__Open_Ended_Status__c == openlabel) {
                    // open-ended
                    openEndedRDsToRecalculate.put(r.Id, r);
                } else {
                    // fixed-length
                    fixedLengthRDsToRecalculate.put(r.Id, r);
                }
            }
        }

        if (!newlyClosedDonations.isEmpty()) {
            runRecurringDonationClosedActions(newlyClosedDonations, dmlWrapper);
        }

        prepRecalcOnRdOpportunities(openEndedRDsToRecalculate,fixedLengthRDsToRecalculate,dmlWrapper);

    }

    /*******************************************************************************************************
    * @description Gathers the relevant Opportunities for the RDs that need recalculating and
    * dispatches them to the appropriate recalculation handler.
    * @param openEndedRDsToRecalculate Map of the Open-Ended RDs that need to be recalculated
    * @param fixedLengthRDsToRecalculate Map of the Fixed-length RDs that need to be recalculated
    * @param dmlWrapper Object to store the Opps that need updating
    * @return void
    */
    public static void prepRecalcOnRdOpportunities(Map<Id, npe03__Recurring_Donation__c> openEndedRDsToRecalculate
            , Map<id, npe03__Recurring_Donation__c> fixedLengthRDsToRecalculate
            , TDTM_Runnable.DmlWrapper dmlWrapper){

        List<Opportunity> oppsFromOpenRDs = new List<Opportunity>();
        List<Opportunity> oppsFromFixedLengthRDs = new List<Opportunity>();

        // get all Opportunities that are:
        // Open or ClosedLost belonging to Open Ended RDs
        // OR
        // any stage belonging to Fixed Length RDs
        List<Opportunity> allOppsToSort = [SELECT Id
                , Amount
                , Name
                , CampaignId
                , AccountID
                , CloseDate
                , StageName
                , isClosed
                , isWon
                , Recurring_Donation_Installment_Number__c
                , npe03__Recurring_Donation__c
        FROM Opportunity
        WHERE (npe03__Recurring_Donation__c IN :openEndedRDsToRecalculate.keySet()
        AND (IsClosed = False OR (IsClosed = True AND IsWon=False)))
        OR npe03__Recurring_Donation__c IN :fixedLengthRDsToRecalculate.keySet()
        ORDER BY CloseDate ASC];

        for (Opportunity o : allOppsToSort) {
            if (openEndedRDsToRecalculate.containsKey(o.npe03__Recurring_Donation__c)
                    && (o.IsClosed == false || (o.IsClosed==True && o.IsWon == False))) {
                oppsFromOpenRDs.add(o);
            } else if (fixedLengthRDsToRecalculate.containsKey(o.npe03__Recurring_Donation__c)) {
                oppsFromFixedLengthRDs.add(o);
            }
        }

        if (!openEndedRDsToRecalculate.isEmpty()) {
            handleOpenEndedScheduleRecalculation(openEndedRDsToRecalculate.values(), oppsFromOpenRDs, dmlWrapper);
        }

        if (!fixedLengthRDsToRecalculate.isEmpty()) {
            handleFixedLengthScheduleRecalculation(fixedLengthRDsToRecalculate.values(), oppsFromFixedLengthRDs, dmlWrapper);
        }
    }

    /*******************************************************************************************************
    * @description Re-evaluates all open Opportunities of an Open-Ended Recurring Donation when it is updated to require schedule recalculation.
    * @param recurringDonations The list of RDs to process
    * @param openOpportunities The list of open Opportunities to process
    * @param dmlWrapper Object to hold the Opps that need deleting or updating
    * @return void
    */
    private static void handleOpenEndedScheduleRecalculation(List<npe03__Recurring_Donation__c> recurringDonations
            , List<Opportunity> openOpportunities
            , TDTM_Runnable.DmlWrapper dmlWrapper) {

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

        //build a map of recurring donation ID and opps
        Map<Id, List<Opportunity>> RDOppMap = new Map<Id, List<Opportunity>>();
        for (Opportunity o : openOpportunities){
            if (RDOppMap.containsKey(o.npe03__Recurring_Donation__c)) {
                List<Opportunity> opps = RDOppMap.get(o.npe03__Recurring_Donation__c);
                opps.add(o);
                RDOppMap.put(o.npe03__Recurring_Donation__c, opps);
            }
            else {
                RDOppMap.put(o.npe03__Recurring_Donation__c, new List<Opportunity>{o});
            }
        }
        // add to the map any RDs that came in with no Opportunities
        for (npe03__Recurring_Donation__c rd : recurringDonations) {
            if (!RDOppMap.containsKey(rd.Id)) {
                RDOppMap.put(rd.Id, new List<Opportunity>());
            }
        }
        
        map<Id,Contact> contactMap = getContactMap(recurringDonations);
        
        List<Opportunity> updateOppsList = new List<Opportunity>();
        List<Opportunity> closeOppsList = new List<Opportunity>();
        List<Opportunity> insertOppsList = new List<Opportunity>();

        Integer forecast_months = (integer)rds.npe03__Opportunity_Forecast_Months__c;
        Date dtForecast =  system.today().toStartOfMonth().addMonths(forecast_months);

        for (npe03__Recurring_Donation__c r : recurringDonations) {

            Date nextDate = getStartDate(r);

            Integer rdcounter = 1;
            if (r.npe03__Total_Paid_Installments__c > 0) {
                rdcounter = (Integer)r.npe03__Total_Paid_Installments__c + 1;
            }

            Contact con;
            if (contactMap != null && contactMap.containsKey(r.npe03__Contact__c)){
                con = contactMap.get(r.npe03__Contact__c);
            }

            // loop the existing opportunities
            for (Opportunity o : RDOppMap.get(r.Id)) {
                if (nextDate <= dtForecast) {

                    o = normalizeOppForRD(o,r,nextDate,r.npe03__Amount__c,con,rdcounter);

                    updateOppsList.add(o);

                    nextDate = getNextDate(nextDate, r);
                    rdcounter++;

                } else {
                    // extras get closed
                    closeOppsList.add(o);
                }
            }

            // didn't have enough, create more
            while (nextDate < dtForecast) {
                Opportunity o = new Opportunity();
                o = normalizeOppForRD(o,r,nextDate,r.npe03__Amount__c,con,rdcounter);
                insertOppsList.add(o);
                nextDate = getNextDate(nextDate, r);
                rdcounter++;
            }
        }

        if (!insertOppsList.isEmpty()) {
            Database.SaveResult[] lsr;
            List<Database.SaveResult> badSRs = new List<Database.SaveResult>();
            List<Opportunity> badOpps = new List<Opportunity>();

            lsr = Database.insert(insertOppsList, false);

            Set<id> updateRecurringDonationSet = new set<id>();

            Integer i = 0;
            for (Database.SaveResult s : lsr){
                if (s.isSuccess() != true){
                    badSRs.add(s);
                    badOpps.add(insertOppsList[i]);
                } else {
                    updateRecurringDonationSet.add(insertOppsList[i].npe03__Recurring_Donation__c);
                }
                i++;
            }

            if (!badSRs.isEmpty()) {
                ERR_Handler.Errors errors = ERR_Handler.getErrors(badSRs, badOpps);
                ERR_Handler.processErrors(errors.errorRecords, ERR_Handler_API.Context.RD.name());
            }

            if (updateRecurringDonationSet.size() > 1 && !system.isBatch() && !system.isFuture() && !RD_RecurringDonations_BATCH.isBatchButton) {
                updateRecurringDonationOnOppChangeFuture(updateRecurringDonationSet);
            } else {
                updateRecurringDonationOnOppChange(updateRecurringDonationSet, null);
            }
        }

        if (!updateOppsList.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll((list<SObject>) updateOppsList);
        }
        if (!closeOppsList.isEmpty()) {
            if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Delete_Open_Opportunities.name()) {
                dmlWrapper.objectsToDelete.addAll((List<SObject>) closeOppsList);
            } else if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()) {
                for (Opportunity o : closeOppsList) {
                    o.StageName = system.label.npe03.RecurringDonationClosedLostOpportunityStage;
                }
                dmlWrapper.objectsToUpdate.addAll((List<SObject>) closeOppsList);
            }
        }
    }

    /*******************************************************************************************************
    * @description Re-evaluates all Opportunities of an Open-Ended Recurring Donation when it is updated to require schedule recalculation.
    * @param recurringDonations The list of RDs to process
    * @param allOpportunities The list of all Opportunities to process
    * @param dmlWrapper Object to hold the Opps that need deleting or updating
    * @return void
    */
    private static void handleFixedLengthScheduleRecalculation(List<npe03__Recurring_Donation__c> recurringDonations
            , List<Opportunity> allOpportunities
            , TDTM_Runnable.DmlWrapper dmlWrapper) {

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

        //build a map of recurring donation ID and opps
        Map<Id, List<Opportunity>> RDOppMap = new Map<Id, List<Opportunity>>();
        for (Opportunity o : allOpportunities){
            if (RDOppMap.containsKey(o.npe03__Recurring_Donation__c)) {
                List<Opportunity> opps = RDOppMap.get(o.npe03__Recurring_Donation__c);
                opps.add(o);
                RDOppMap.put(o.npe03__Recurring_Donation__c, opps);
            }
            else {
                RDOppMap.put(o.npe03__Recurring_Donation__c, new List<Opportunity>{o});
            }
        }

        map<Id,Contact> contactMap = getContactMap(recurringDonations);

        List<Opportunity> updateOppsList = new List<Opportunity>();
        List<Opportunity> closeOppsList = new List<Opportunity>();
        List<Opportunity> insertOppsList = new List<Opportunity>();

        // for each RD
        for (npe03__Recurring_Donation__c r : recurringDonations) {

            Date nextDate = getStartDate(r);

            integer rdcounter = 1;
            if (r.npe03__Total_Paid_Installments__c > 0) {
                rdcounter = (integer)r.npe03__Total_Paid_Installments__c + 1;
            }

            Integer numInstallments = r.npe03__Installments__c.intValue();

            decimal installmentAmount = r.npe03__Installment_Amount__c;

            decimal paidAmount = 0;
            if (r.npe03__Paid_Amount__c != null){
                paidAmount = r.npe03__Paid_Amount__c;
            }

            // deal with already paid installments.
            if (r.npe03__Total_Paid_Installments__c != null) {
                if (r.npe03__Schedule_Type__c != Label.npe03.RecurringDonationMultiplyValue) {
                    Integer remainingInstallments = numInstallments - r.npe03__Total_Paid_Installments__c.intValue();
                    Decimal remainingAmount = r.npe03__Amount__c - paidAmount;
                    if (remainingInstallments > 0)
                        installmentAmount = remainingAmount / remainingInstallments;
                }
            }

            Integer opptyCounter = 1;
            Integer closedOpptyCounter = 0;

            Contact con;
            if (contactMap != null && contactMap.containsKey(r.npe03__Contact__c)) {
                con = contactMap.get(r.npe03__Contact__c);
            }

            for (Opportunity o : RDOppMap.get(r.Id)) {

                // first make sure they don't have more closed opportunities
                // than the number of installments
                if (o.isWon) {
                    closedOpptyCounter++;
                }

                if (numInstallments < closedOpptyCounter) {
                    r.addError(Label.RD_ErrorMoreClosedWonOpportunitiesThanInstallments);
                }

                if (numInstallments == closedOpptyCounter && paidAmount != r.npe03__Amount__c) {
                    r.addError(Label.RD_ErrorNotEnoughClosedValueForFixedLength);
                }

                if (opptyCounter<=numInstallments) {
                    if (o.isWon != true) {

                        o = normalizeOppForRD(o,r,nextDate,installmentAmount,con,opptyCounter);

                        updateOppsList.add(o);

                        nextDate = getNextDate(nextDate, r);
                    }
                    opptyCounter++;
                } else {
                    // extras get closed
                    closeOppsList.add(o);
                }
            }

            for (Integer i=RDOppMap.get(r.Id).size(); i<numInstallments; i++) {
                Opportunity o = new Opportunity();
                o = normalizeOppForRD(o,r,nextDate,installmentAmount,con,rdcounter);
                insertOppsList.add(o);
                nextDate = getNextDate(nextDate, r);
            }

        }

        if (!insertOppsList.isEmpty()) {
            Database.SaveResult[] lsr;
            List<Database.SaveResult> badSRs = new List<Database.SaveResult>();
            List<Opportunity> badOpps = new List<Opportunity>();

            lsr = Database.insert(insertOppsList, false);

            Set<id> updateRecurringDonationSet = new Set<id>();

            Integer i = 0;
            for (Database.SaveResult s : lsr){
                if (s.isSuccess() != true){
                    badSRs.add(s);
                    badOpps.add(insertOppsList[i]);
                } else {
                    updateRecurringDonationSet.add(insertOppsList[i].npe03__Recurring_Donation__c);
                }
                i++;
            }

            if (!badSRs.isEmpty()) {
                ERR_Handler.Errors errors = ERR_Handler.getErrors(badSRs, badOpps);
                ERR_Handler.processErrors(errors.errorRecords, ERR_Handler_API.Context.RD.name());
            }

            if (updateRecurringDonationSet.size() > 1 && !system.isBatch() && !system.isFuture() && !RD_RecurringDonations_BATCH.isBatchButton) {
                updateRecurringDonationOnOppChangeFuture(updateRecurringDonationSet);
            } else {
                updateRecurringDonationOnOppChange(updateRecurringDonationSet, null);
            }
        }

        if (!updateOppsList.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll((list<SObject>) updateOppsList);
        }
        if (!closeOppsList.isEmpty()) {
            if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Delete_Open_Opportunities.name()) {
                dmlWrapper.objectsToDelete.addAll((List<SObject>) closeOppsList);
            } else if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()) {
                for (Opportunity o : closeOppsList) {
                    o.StageName = system.label.npe03.RecurringDonationClosedLostOpportunityStage;
                }
                dmlWrapper.objectsToUpdate.addAll((List<SObject>) closeOppsList);
            }
        }

    }

    /*******************************************************************************************************
    * @description Handles changes to the specified RD's to update/recreate their Opportunities.  
    * Called from the Refresh Opportunities button on both Open and Non-Open RD's, 
    * as well as the Batch process for extending Open Ended RD's (no Non-Open).
    * @param recurringDonationsToEvaluate The list of updated RD's to process
    * @return integer The number of records that failed to be processed.
    */ 
    public static Integer evaluateRecurringDonationsForNewOppInsert(list<npe03__Recurring_Donation__c> recurringDonationsToEvaluate){
    
        String openlabel = System.label.npe03.RecurringDonationOpenStatus;
        String closedlabel = System.label.npe03.RecurringDonationClosedStatus;
    
        Map<Id, npe03__Recurring_Donation__c> openEndedRDsToRecalculate = new Map<Id, npe03__Recurring_Donation__c>();
        Map<Id, npe03__Recurring_Donation__c> fixedLengthRDsToRecalculate = new Map<Id, npe03__Recurring_Donation__c>();

        for (Integer i=0; i<recurringDonationsToEvaluate.size(); i++) {
            npe03__Recurring_Donation__c rd = recurringDonationsToEvaluate[i];

            //don't try to evaluate orphaned recurring donations
            if (rd.npe03__Contact__c == null && rd.npe03__Organization__c == null) {
                recurringDonationsToEvaluate.remove(i);
                //decrement counter after removing value to avoid going over the end of the array
                i--;
                continue;
            }
            if (rd.npe03__Open_Ended_Status__c != openlabel && rd.npe03__Open_Ended_Status__c != closedlabel) {
                fixedLengthRDsToRecalculate.put(rd.Id, rd);
            } else {
                openEndedRDsToRecalculate.put(rd.Id, rd);
            }
        }

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        prepRecalcOnRdOpportunities(openEndedRDsToRecalculate,fixedLengthRDsToRecalculate,dmlWrapper);

        ERR_Handler.Errors errors = TDTM_TriggerHandler.processDMLAllOrNothing(dmlWrapper, false);

        return errors.errorRecords.size();
    }
  
    /*******************************************************************************************************
    * @description When closing an RD, either deletes or closes all of its currently open Opps. 
    * @param closedRDs The list of RD's to process
    * @param dmlWrapper Object to hold the Opps that need deleting or updating
    * @return void
    */ 
    private static void runRecurringDonationClosedActions(list<npe03__Recurring_Donation__c> closedRDs, TDTM_Runnable.DmlWrapper dmlWrapper) {
        // determine the update type - 
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        //UTIL_Debug.debug('IN THE PRIVATE METHOD');
        if (!closedRDs.isEmpty() && rds.npe03__Open_Opportunity_Behavior__c != RecurringDonationCloseOptions.No_Action.name()) {
            Map<Id, Opportunity> mapIdOpp = new Map<Id, Opportunity>([SELECT Id, StageName, npe03__Recurring_Donation__c
                                    FROM Opportunity WHERE npe03__Recurring_Donation__c IN :closedRDs AND isClosed = false]);
         
            if (rds.npe03__Open_Opportunity_Behavior__c == RecurringDonationCloseOptions.Delete_Open_Opportunities.name()){
                //UTIL_Debug.debug('IN THE PRIVATE METHOD3');
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
                    dmlWrapper.objectsToUpdate.addAll((list<SObject>) mapIdOpp.values()); 
                else
                    update mapIdOpp.values();
            }
        }
    }

    /*******************************************************************************************************
    * @description Returns the date to start the installment with based on the period type and dates
    * @param r recurring donation record
    * @return date First date to use for created Donations
    */
    private static date getStartDate(npe03__Recurring_Donation__c r) {
        Date startDt;
        if (r.npe03__Next_Payment_Date__c != null) {
            startDt = r.npe03__Next_Payment_Date__c;
        } else {
            startDt = r.npe03__Date_Established__c;
        }

        if (r.npe03__Installment_Period__c == system.label.npe03.RecurringDonationInstallmentPeriodMonthly
                || r.npe03__Installment_Period__c == system.label.npe03.RecurringDonationInstallmentPeriodQuarterly) {
            // For monthly or quarterly installments only, the initial date needs to be tweaked to be the appropriate
            // start date in the current month
            startDt = dtEndOfMonthFixup(startDt, r); // fix the date to account for end of month
        }
        return startDt;
    }

    /*******************************************************************************************************
    * @description Returns the last day of month for the provided date if the Day of Month is either the
    * the 31st or the Always_Use_Last_Day_Of_Month__c box has been checked. Otherwise, use the specific
    * date they have set.
    * @param dt The date to analyze
    * @return date Either the passed in date, or the last day of the month
    */
    private static date dtEndOfMonthFixup(date dt, npe03__Recurring_Donation__c rd) {
        if (dt.day() == 31 || rd.Always_Use_Last_Day_Of_Month__c == true) {
            dt = date.newInstance(dt.year(), dt.month(), date.daysInMonth(dt.year(), dt.Month()));
        } else if (dt.day() >= 28 && (rd.npe03__Next_Payment_Date__c != null || rd.npe03__Date_Established__c != null)) {
            // To handle a scenario where the NextPayment or DateEstablished is the >= 29 for a Monthly
            // Donation, when the system gets around to February, it'll change the next donation to 28/29
            // which then causes all subsequent months to be set to the 28th (or 29th).
            // This logic ensures that the calculated End Of Month date takes this into account
            // rather than just use the DayOfMonth from the previous installment.
            Date estDate = (rd.npe03__Next_Payment_Date__c != null ? rd.npe03__Next_Payment_Date__c : rd.npe03__Date_Established__c);
            Integer dayOfMonth = (date.daysInMonth(dt.year(), dt.Month()) < estDate.day() ?
                    date.daysInMonth(dt.year(), dt.Month()) : estDate.day());
            dt = date.newInstance(dt.year(), dt.month(), dayOfMonth);
        }
        return dt;
    }

    /*******************************************************************************************************
    * @description Returns the next date in the sequence based on the RD schedule type 
    * @param CalcDate The date to start from
    * @param rd The Recurring Donation.
    * @return date 
    */ 
    private static date getNextDate(Date calcDate, npe03__Recurring_Donation__c rd) {
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        String InstallmentType = rd.npe03__Installment_Period__c;

        if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodYearly){
            calcDate = calcDate.addYears(1);
        } 
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodQuarterly){
            calcDate = calcDate.addMonths(3);
            calcDate = dtEndOfMonthFixup(calcDate, rd);
        } 
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodMonthly){
            calcDate = calcDate.addMonths(1);
            calcDate = dtEndOfMonthFixup(calcDate, rd);
        } 
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodWeekly){
            calcDate = calcDate.addDays(7);
        }
        /*  else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriodCustom){
            CalcDate = CalcDate.addDays((integer)rds.Custom_Days__c);
        }*/
        else if (InstallmentType == system.label.npe03.RecurringDonationInstallmentPeriod1stand15th){
            //increment it by one day until we hit either the 1st or 15th
            do{
                calcDate = calcDate.addDays(1);
            }while (calcDate.day() != 15 && calcDate.day() != 1);
        }
        else{
            map<string, npe03__Custom_Installment_Settings__c> cisMap = UTIL_ListCustomSettingsFacade.getMapCustomInstallmentSettings();
            //handle custom installment types           
            if (cisMap.containsKey(InstallmentType)){
                npe03__Custom_Installment_Settings__c c = cisMap.get(InstallmentType);

                if (c.npe03__Increment__c == 'Days'){
                    calcDate = calcDate.addDays(integer.valueOf(c.npe03__Value__c));
                }
                else if (c.npe03__Increment__c == 'Weeks'){
                    calcDate = calcDate.addDays(integer.valueOf(c.npe03__Value__c * 7));
                }
                else if (c.npe03__Increment__c == 'Months'){
                    calcDate = calcDate.addMonths(integer.valueOf(c.npe03__Value__c));
                    calcDate = dtEndOfMonthFixup(calcDate, rd);
                }
                else if (c.npe03__Increment__c == 'Years'){
                    calcDate = calcDate.addYears(integer.valueOf(c.npe03__Value__c));
                }
            }
            //if its not a valid value, set it to the max last payment date plus the 
            //the open ended value so we only create one opp max
            else{   
                calcDate = calcDate.addMonths((integer)rds.npe03__Opportunity_Forecast_Months__c);
                calcDate = dtEndOfMonthFixup(calcDate, rd);
            }
        }
        return calcDate;
    }

    /*******************************************************************************************************
    * @description Returns true if the RD changes should trigger recalculation of the child opportunities
    * @param new The updated Recurring Donation
    * @param old The original Recurring Donation before updates
    * @return boolean
    */
    @testVisible
    private static Boolean needsRecalculation(npe03__Recurring_Donation__c newRD, npe03__Recurring_Donation__c oldRD) {

        if (newRD.npe03__Organization__c != oldRD.npe03__Organization__c
                || newRD.npe03__Contact__c != oldRD.npe03__Contact__c
                || newRD.npe03__Amount__c != oldRD.npe03__Amount__c
                || newRD.npe03__Installment_Period__c != oldRD.npe03__Installment_Period__c
                || newRD.npe03__Installments__c != oldRD.npe03__Installments__c
                || newRD.Always_Use_Last_Day_Of_Month__c != oldRD.Always_Use_Last_Day_Of_Month__c
                || newRD.npe03__Schedule_Type__c != oldRD.npe03__Schedule_Type__c
                || newRD.npe03__Open_Ended_Status__c != oldRD.npe03__Open_Ended_Status__c
                || newRD.npe03__Next_Payment_Date__c != oldRD.npe03__Next_Payment_Date__c
                || newRD.npe03__Recurring_Donation_Campaign__c != oldRD.npe03__Recurring_Donation_Campaign__c
                ) {
            return true;
        }

        for (String s : customFieldMappingSettings.keySet()) {
            npe03__Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
            if (newRD.get(cfm.npe03__Recurring_Donation_Field__c) != oldRD.get(cfm.npe03__Recurring_Donation_Field__c)) {
                return true;
            }
        }

        return false;
    }

    /*******************************************************************************************************
    * @description Updates an Opportunity with given parameters
    * @param opp The Opportunity to update
    * @param r The parent Recurring Donation
    * @param oppCloseDate The close date for the Opportunity
    * @param amount The Amount of the Opportunity
    * @param con The Contact involved, can be null
    * @param rdcounter Opportunity counter for naming and Recurring_Donation_Installment_Number__c
    * @return Opportunity
    */
    private static Opportunity normalizeOppForRD(Opportunity opp, npe03__Recurring_Donation__c r, Date oppCloseDate, Decimal amount, Contact con, Integer rdcounter) {

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

        opp.CloseDate = oppCloseDate;
        opp.OwnerId = r.OwnerId;
        opp.Amount = amount;
        opp.Primary_Contact__c = r.npe03__Contact__c;
        opp.Recurring_Donation_Installment_Number__c = rdcounter;
        opp.StageName = System.label.npe03.RecurringDonationStageName;
        opp.npe03__Recurring_Donation__c = r.Id;

        if(isMultiCurrency){
            //set the donation currency field to equal the recurring donation currency
            opp.put(OppCurrencyField,r.get(RDCurrencyField));
        }

        if ( r.npe03__Organization__c != null ) {
            opp.AccountId = r.npe03__Organization__c;
        } else if ( con != null ) {
            opp.AccountId = con.AccountId;
            opp.Primary_Contact__c = con.id;
        }

        if (rds.npe03__Record_Type__c != null){
            opp.RecordTypeID = rds.npe03__Record_Type__c;
        }

        if (r.npe03__Recurring_Donation_Campaign__c != null && (rds.npe03__Add_Campaign_to_All_Opportunites__c || rdcounter == 1)){
            opp.CampaignId = r.npe03__Recurring_Donation_Campaign__c;
        }

        //evaluate any custom field mappings
        for (String s : customFieldMappingSettings.keySet()){
            npe03__Custom_Field_Mapping__c cfm = customFieldMappingSettings.get(s);
            opp.put(cfm.npe03__Opportunity_Field__c, r.get(cfm.npe03__Recurring_Donation_Field__c));
        }

        opp.Name = getOpportunityName(opp, r);

        return opp;
    }

    /*******************************************************************************************************
    * @description Passes back the name for a given Opportunity belonging to a given Recurring Donation
    * @param o The Opportunity to name
    * @param r The parent Recurring Donation
    * @return String
    */
    private static String getOpportunityName(Opportunity o, npe03__Recurring_Donation__c r) {

        String oName = '';
        oName += r.npe03__Donor_Name__c;
        oName += ' ';
        oName += System.label.npe03.RecurringDonationPrefix;
        oName += ' (';
        oName += String.valueOf(o.Recurring_Donation_Installment_Number__c);
        if(r.npe03__Open_Ended_Status__c == null) {
            oName += ' of ';
            oName += String.valueOf(r.npe03__Installments__c);
        }
        oName += ') ';
        oName += o.CloseDate.format();

        return oName;

    }

    /*******************************************************************************************************
    * @description Gets a map of Contact IDs to Contacts for a given list of Recurring Donations
    * so the Contacts' Account Ids are available for Opportunities if a Recurring Donation
    * is created with only a Contact defined
    * @param recurringDonations The list of Recurring Donations to get Contact info for
    * @return Map<Id,Contact>
    */
    private static Map<Id,Contact> getContactMap(List<npe03__Recurring_Donation__c> recurringDonations) {
        List<Id> contactIds = new List<Id>();
        for(npe03__Recurring_Donation__c r : recurringDonations){
            if (r.npe03__Contact__c != null){
                contactIds.add(r.npe03__Contact__c);
            }
        }
        Map<Id,Contact> contactMap;
        if (contactIds.size() > 0){
            contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
        }

        return contactMap;
    }
}