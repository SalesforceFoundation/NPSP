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
* @date 2012 (2.4) 
* @description set of utility methods and values used in opportunity rollups
*/
public without sharing class RLLP_OppRollup_UTIL {

    /*** Settings ***/       
    public static boolean useFiscalYear = false;
    public static set<id> recordTypesToExcludeAccts = new set<id>();
    public static set<id> recordTypesToExcludeCons = new set<id>();
    public static set<id> mbrRecordTypes = new set<id>(); 
    public static set<string> oppTypesToExcludeAccts = new set<string>();
    public static set<string> oppTypesToExcludeCons = new set<string>();  
    public static set<string> softCreditRoles = new set<string>();
    public static npo02__Households_Settings__c hh_settings;
    public static integer BATCH_SIZE = 200;
    private static boolean recordTypesOnOpps;
    private static boolean useSoftCredits;
    private static set<id> IndividualAccountIds;
    
    /*** FY ***/
    private static integer fiscal_year;
    
    /*** Multicurrency ***/
    //set when multicurrency check is called, holds the field string/sobject mapping
    public static Map<String, SObjectField> mcFieldValues = new Map<String, SObjectField>();
    public static boolean multiCurrency;
    //exchangerate store
    static map<string, decimal> exchangeRates = new map<string,decimal>();
    //corporate currency
    static string currCorporate; 
    
    /*** User Rollups ***/
    //map of object and rollup field 
    public static map<string, string> objectRollUpFieldMap;
    public static map<string, npo02__User_Rollup_Field_Settings__c> urfsMap = new map<string, npo02__User_Rollup_Field_Settings__c>();
    
    /*** Query Strings ***/
    private static string AccountQuery;
    private static string ContactQuery;
    private static string HouseholdQuery;
    private static string OpportunityContactRoleQuery;
    private static string HouseholdRollupQuery;
    private static string ContactRollupQuery;
    private static string AccountRollupQuery;    
    private static string HouseholdNDayQuery;
    private static string ContactNDayQuery;
    private static string AccountNDayQuery;    
    private static string HouseholdMembershipQuery;
    private static string ContactMembershipQuery;
    private static string AccountMembershipQuery;    
    private static string SoftCreditQuery;
    private static string ContactNDaySoftCreditQuery;
         
    /*** Field Lists ***/
    private static set<string> AccountFields = new set<string>{'npo02__TotalOppAmount__c', 'npo02__OppsClosedThisYear__c', 'npo02__OppsClosedLastYear__c', 
                                                        'npo02__OppsClosedLastNDays__c', 'npo02__OppsClosed2YearsAgo__c', 'npo02__OppAmountLastYear__c', 
                                                        'npo02__OppAmount2YearsAgo__c', 'npo02__OppAmountThisYear__c', 'npo02__OppAmountLastNDays__c', 
                                                        'npo02__FirstCloseDate__c', 'npo02__LastCloseDate__c', 'npo02__TotalMembershipOppAmount__c', 
                                                        'npo02__LastMembershipLevel__c', 'npo02__LastMembershipDate__c', 'npo02__MembershipJoinDate__c', 
                                                        'npo02__MembershipEndDate__c', 'npo02__Best_Gift_Year__c', 'npo02__Best_Gift_Year_Total__c', 'npo02__LastMembershipOrigin__c',
                                                        'npo02__AverageAmount__c', 'npo02__LargestAmount__c', 'npo02__SmallestAmount__c', 'npo02__LastMembershipAmount__c'
                                                        };


    private static set<string> OpportunityContactRoleFields = new set<string>{'ContactId', 'Contact.npo02__household__c', 
                                                        'Contact.npo02__AverageAmount__c', 'Contact.npo02__household__r.npo02__AverageAmount__c', 
                                                        'Contact.npo02__Best_Gift_Year__c', 'Contact.npo02__household__r.npo02__Best_Gift_Year__c', 
                                                        'Contact.npo02__Best_Gift_Year_Total__c', 'Contact.npo02__household__r.npo02__Best_Gift_Year_Total__c', 
                                                        'Contact.npo02__FirstCloseDate__c', 'Contact.npo02__household__r.npo02__FirstCloseDate__c', 
                                                        'Contact.npo02__LargestAmount__c', 'Contact.npo02__household__r.npo02__LargestAmount__c', 
                                                        'Contact.npo02__LastCloseDate__c', 'Contact.npo02__household__r.npo02__LastCloseDate__c', 
                                                        'Contact.npo02__LastMembershipDate__c', 'Contact.npo02__household__r.npo02__LastMembershipDate__c', 
                                                        'Contact.npo02__LastMembershipLevel__c', 'Contact.npo02__Household__r.npo02__LastMembershipLevel__c', 
                                                        'Contact.npo02__LastOppAmount__c', 'Contact.npo02__Household__r.npo02__LastOppAmount__c', 
                                                        'Contact.npo02__MembershipEndDate__c', 'Contact.npo02__household__r.npo02__MembershipEndDate__c', 
                                                        'Contact.npo02__MembershipJoinDate__c', 'Contact.npo02__household__r.npo02__MembershipJoinDate__c', 
                                                        'Contact.npo02__NumberOfClosedOpps__c', 'Contact.npo02__household__r.npo02__NumberOfClosedOpps__c', 
                                                        'Contact.npo02__OppAmount2YearsAgo__c', 'Contact.npo02__household__r.npo02__OppAmount2YearsAgo__c', 
                                                        'Contact.npo02__OppAmountLastNDays__c', 'Contact.npo02__household__r.npo02__OppAmountLastNDays__c', 
                                                        'Contact.npo02__OppAmountLastYear__c', 'Contact.npo02__household__r.npo02__OppAmountLastYear__c', 
                                                        'Contact.npo02__OppAmountThisYear__c', 'Contact.npo02__household__r.npo02__OppAmountThisYear__c', 
                                                        'Contact.npo02__OppsClosedThisYear__c', 'Contact.npo02__household__r.npo02__OppsClosedThisYear__c', 
                                                        'Contact.npo02__OppsClosed2YearsAgo__c', 'Contact.npo02__household__r.npo02__OppsClosed2YearsAgo__c', 
                                                        'Contact.npo02__OppsClosedLastNDays__c', 'Contact.npo02__household__r.npo02__OppsClosedLastNDays__c', 
                                                        'Contact.npo02__OppsClosedLastYear__c', 'Contact.npo02__household__r.npo02__OppsClosedLastYear__c', 
                                                        'Contact.npo02__SmallestAmount__c', 'Contact.npo02__household__r.npo02__SmallestAmount__c', 
                                                        'Contact.npo02__TotalMembershipOppAmount__c', 'Contact.npo02__household__r.npo02__TotalMembershipOppAmount__c', 
                                                        'Contact.npo02__TotalOppAmount__c', 'Contact.npo02__household__r.npo02__TotalOppAmount__c'
                                                        }; 
        
    private static set<string> ContactFields = new set<string>{'npo02__TotalOppAmount__c', 'npo02__OppsClosedThisYear__c', 'npo02__OppsClosedLastYear__c', 
                                                        'npo02__OppsClosedLastNDays__c', 'npo02__OppsClosed2YearsAgo__c', 'npo02__OppAmountLastYear__c', 
                                                        'npo02__OppAmount2YearsAgo__c', 'npo02__OppAmountThisYear__c', 'npo02__OppAmountLastNDays__c', 
                                                        'npo02__FirstCloseDate__c', 'npo02__LastCloseDate__c', 'npo02__TotalMembershipOppAmount__c', 
                                                        'npo02__LastMembershipLevel__c', 'npo02__LastMembershipDate__c', 'npo02__MembershipJoinDate__c', 
                                                        'npo02__MembershipEndDate__c', 'npo02__Best_Gift_Year__c', 'npo02__Best_Gift_Year_Total__c', 
                                                        'npo02__AverageAmount__c', 'npo02__LargestAmount__c', 'npo02__SmallestAmount__c', 
                                                        'npo02__Soft_Credit_Two_Years_Ago__c', 'npo02__Soft_Credit_Total__c', 'Soft_Credit_Last_N_Days__c',
                                                        'npo02__Soft_Credit_Last_Year__c', 'npo02__Best_Gift_Year__c', 'npo02__Best_Gift_Year_Total__c',
                                                        'npo02__Household__c', 'npo02__Soft_Credit_This_Year__c'
                                                        };
    
    private static set<string> HouseholdFields = new set<string>{'npo02__TotalOppAmount__c', 'npo02__OppsClosedThisYear__c', 'npo02__OppsClosedLastYear__c', 
                                                        'npo02__OppsClosedLastNDays__c', 'npo02__OppsClosed2YearsAgo__c', 'npo02__OppAmountLastYear__c', 
                                                        'npo02__OppAmount2YearsAgo__c', 'npo02__OppAmountThisYear__c', 'npo02__OppAmountLastNDays__c', 
                                                        'npo02__FirstCloseDate__c', 'npo02__LastCloseDate__c', 'npo02__TotalMembershipOppAmount__c', 
                                                        'npo02__LastMembershipLevel__c', 'npo02__LastMembershipDate__c', 'npo02__MembershipJoinDate__c', 
                                                        'npo02__MembershipEndDate__c', 'npo02__Best_Gift_Year__c', 'npo02__Best_Gift_Year_Total__c', 
                                                        'npo02__AverageAmount__c', 'npo02__LargestAmount__c', 'npo02__SmallestAmount__c'
                                                        };

    /*** Constructor ***/
	public RLLP_OppRollup_UTIL(){
	    // setup households settings
	    setupRollupVars(UTIL_CustomSettingsFacade.getHouseholdsSettings());
	    // setup user rollups
	    setupUserRollupVars();
	}
	
    /*** Settings Methods ***/ 
    //configures and sets up static vars for OppRollups
    public static void setupRollupVars(npo02__Households_Settings__c household_settings){
        
        if (household_settings.npo02__Excluded_Contact_Opp_Rectypes__c != null) {
            set<string> rtNamesToExclude = new set<string>(household_settings.npo02__Excluded_Contact_Opp_Rectypes__c.split(';'));
            recordTypesToExcludeCons = UTIL_RecordTypes.GetRecordTypeIdSet('Opportunity', rtNamesToExclude);
        }
        if (household_settings.npo02__Excluded_Account_Opp_Rectypes__c != null) {
            set<string> rtNamesToExclude = new set<string>(household_settings.npo02__Excluded_Account_Opp_Rectypes__c.split(';'));
            recordTypesToExcludeAccts = UTIL_RecordTypes.GetRecordTypeIdSet('Opportunity', rtNamesToExclude);
        }
        if (household_settings.npo02__Excluded_Contact_Opp_Types__c != null) {
            oppTypesToExcludeCons = new set<string>(household_settings.npo02__Excluded_Contact_Opp_Types__c.split(';'));
        }
        if (household_settings.npo02__Excluded_Account_Opp_Types__c != null) {
            oppTypesToExcludeAccts = new set<string>(household_settings.npo02__Excluded_Account_Opp_Types__c.split(';'));
        }    
        if (household_settings.npo02__Membership_Record_Types__c != null) {
            set<string> mbrRecordTypeNames = new set<string>(household_settings.npo02__Membership_Record_Types__c.split(';'));
            mbrRecordTypes = UTIL_RecordTypes.GetRecordTypeIdSet('Opportunity', mbrRecordTypeNames);
        }  
        if (household_settings.npo02__Soft_Credit_Roles__c != null){
            softCreditRoles = new set<string>(household_Settings.npo02__Soft_Credit_Roles__c.split(';'));
        }
        
        if (household_settings.npo02__Rollup_N_Day_Value__c == null){
            household_settings.npo02__Rollup_N_Day_Value__c = 365;
        }
        //check the settings, if they have the fiscal year set
        //we still need to query to make sure its not a custom fiscal year
        //or else we'll throw errors when calling Fiscal_Year in queries
        if (household_settings.npo02__Use_Fiscal_Year_for_Rollups__c == true){
            String fyQuery = 'select id from FiscalYearSettings  where IsStandardYear = false';            
            List<SObject> fySettings = new List<SObject>();
            fySettings = Database.query(fyQuery);
            integer hasCustomFYRecord = fySettings.size();
                
            //if org has customFY records, disable FY settings
            if (hasCustomFYRecord > 0 && !household_settings.npo02__Force_Fiscal_Year__c)
                useFiscalYear = false;
            else
                useFiscalYear = true;
        }        
        
        if (household_settings.npo02__Batch_Size__c != null)
            BATCH_SIZE = household_settings.npo02__Batch_Size__c.intValue();
        
        //set the static var
        hh_settings = household_settings;
    }
    
    public static void setupUserRollupVars(){
        if (objectRollupFieldMap == null){
            urfsMap = npo02__User_Rollup_Field_Settings__c.getAll().clone();
            objectRollupFieldMap = new map<string, string>();
        
            //build the object delineated query string for use later
            for (string s : urfsMap.keySet()){
               npo02__User_Rollup_Field_Settings__c urfs = urfsMap.get(s);
            
               if (objectRollUpFieldMap.containsKey(urfs.npo02__Object_Name__c)){
                  String qString = objectRollupFieldMap.get(urfs.npo02__Object_Name__c);
                  qString += urfs.npo02__Field_Action__c + '(Opportunity.' + urfs.npo02__Source_Field__c + ') ' + urfs.Name + ', ';
                  objectRollupFieldMap.put(urfs.npo02__Object_Name__c, qString);
               }
               else{
                  objectRollupFieldMap.put(urfs.npo02__Object_Name__c, urfs.npo02__Field_Action__c + '(Opportunity.' + urfs.npo02__Source_Field__c + ') ' + urfs.Name + ', ');
               }
               
               if (urfs.npo02__Object_Name__c == npo02__Household__c.getSObjectType().getDescribe().getName()){
                   RLLP_OppRollup_UTIL.HouseholdFields.add(urfs.npo02__Target_Field__c);              
                   RLLP_OppRollup_UTIL.OpportunityContactRoleFields.add('Contact.npo02__household__r.' + urfs.npo02__Target_Field__c);   
               }
               else if (urfs.npo02__Object_Name__c == Contact.getSObjectType().getDescribe().getName()){
                   RLLP_OppRollup_UTIL.ContactFields.add(urfs.npo02__Target_Field__c);            
                   RLLP_OppRollup_UTIL.OpportunityContactRoleFields.add('Contact.' + urfs.npo02__Target_Field__c);
               }
               else if (urfs.npo02__Object_Name__c == Account.getSObjectType().getDescribe().getName()){
                   RLLP_OppRollup_UTIL.AccountFields.add(urfs.npo02__Target_Field__c);             
               }               
            }
        }
    }
    
    //determines if record types are enabled on opportunities 
    public static boolean areRecordTypesOnOpps(){
        if (recordTypesOnOpps==null){
            String giftRt = UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
            if (giftRt!=null&&giftRt!=''){
                recordTypesOnOpps = true;
            } 
            else{
                recordTypesOnOpps = false;  
            }
        }
        return recordTypesOnOpps;
    }
    
    public static boolean useSoftCredits(){
        if (useSoftCredits == null){
            if(!softCreditRoles.isEmpty() && hh_settings.npo02__Enable_Soft_Credit_Rollups__c)
                useSoftCredits = true;
            else
                useSoftCredits = false;
        }       
        return useSoftCredits;
    }  
    
    public static set<id> getIndividualAccountIds(){
        if (IndividualAccountIds == null){         
            IndividualAccountIds = new set<id>();                       
            if (CAO_Constants.getIndividualAccountId() != null)
                IndividualAccountIds.add(CAO_Constants.getIndividualAccountId());        
        }
        return IndividualAccountIds;        
    }    
    
    /****************************************/
    
    /*** Multicurrency Support Methods ***/
    
    //returns a boolean if we are in a multi-currency org or not.
    //on first execution sets up static variables etc
    public static boolean isMultiCurrency(){                    
        if (multiCurrency==null){
            //create currency field handles for later dynamic dml
            mcFieldValues.put('Opportunity', Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('Account', Schema.sObjectType.Account.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('Contact', Schema.sObjectType.Contact.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('npo02__Household__c', Schema.sObjectType.npo02__Household__c.fields.getMap().get('CurrencyIsoCode'));

            String queryExchangeRates = 'select IsoCode,ConversionRate,IsCorporate from CurrencyType';
            SObjectType soCurrencyType = Schema.getGlobalDescribe().get('CurrencyType'); 

            //are we in a multi-currency org?
            if (mcFieldValues.get('Opportunity') != null && mcFieldValues.get('Account') != null && 
                mcFieldValues.get('npo02__Household__c') != null && mcFieldValues.get('Contact') != null && soCurrencyType != null){
                multiCurrency = true;
 
                map<string,SObjectField> ctFields = soCurrencyType.getDescribe().fields.getMap();
                SObjectField ctIsoCode = ctFields.get('IsoCode');
                SObjectField ctConversionRate = ctFields.get('ConversionRate');
                SObjectField ctCorporate = ctFields.get('IsCorporate');

                //iterate over all the currencies in the org (inc. inactive ones as they may have been used previously)
                //this allows us to put them in a map and use the ISO code as key and also set the corporate
                for(sObject ct: Database.query(queryExchangeRates)){
                    exchangeRates.put((string)ct.get(ctIsoCode),(decimal)ct.get(ctConversionRate));
                    if((boolean)ct.get(ctCorporate))currCorporate=(string)ct.get(ctIsoCode);
                }
            }
            else
                multiCurrency = false; 
        }        
        return multiCurrency;
    }

    //do a conversion from amount in corporate currency to the currency specified by the ISO code
    public static decimal convertFromCorporate(String ISO,Decimal amt){
        if(currCorporate == ISO || currCorporate == null) // no need to convert
            return amt;
        else //return value to 2DP
            return (amt * exchangeRates.get(ISO)).setScale(2,System.RoundingMode.UP);
    }

    public static decimal convertCurrency(String fromISO, String toISO, Decimal amt){
        if(fromISO == toISO) // no need to convert
            return amt;
        else //return value to 2DP
            return ((amt / exchangeRates.get(fromISO)) * exchangeRates.get(toISO)).setScale(2,System.RoundingMode.UP);
    }
 
    //takes the Ids of opptys in the npo02__CombinedRollupFieldset__c field, and looks up the currency of that record
    //only used in multi currency orgs
    //returns a map of those Ids and the associated oppty
    public static map<Id,Opportunity> rcfFindCurrency(list<sobject> objectList){
        //new set to hold the opptys we need to query for
        set<Id> opptysForCurrency = new set<Id>();

        //iterate over objects provided to us
        for (sobject r : objectList){
            //pull Id from rollup field and add to set
            string[] rcf = ((string)(r.get('RollupFieldset'))).split(';\\|;',-4);
            if(rcf.size() > 1 && rcf[1] != '')
                opptysForCurrency.add((Id)rcf[4]);
        }
        
        if (!objectlist.isEmpty()){
            //query for oppty and currencycode for all Ids in set.
            string soqlStatement = 'SELECT Id,CurrencyIsoCode FROM Opportunity WHERE Id in :opptysForCurrency';
            map<Id,Opportunity> opptyCurrencies = new map<Id,Opportunity>((list<Opportunity>)Database.query(soqlStatement));
            return opptyCurrencies;
        }
        else
            return null; 
    }
    /****************************************/
    
    /*** Opportunity Evaluation Methods ***/
    //evaluates a single Opportunity to see if it needs to be rolled up    
    public static boolean oppForRollup(Opportunity o){
        boolean needsRollup = false;
        if (o.isWon && o.Amount != null)
           needsRollup = true;
        return needsRollup;
    }
    //evaluates if an Opp will need a contact-based rollup
    public static boolean needsContactRollup(Opportunity o){
        boolean needsRollup = false;
        //if its from an individual account or has a null account ID OR alwaysRollupToPrimary is set AND
        //its the membership rectype or the rectype isn't exclused AND
        //the opp type isn't excluded        
        if (((o.npe01__Is_Opp_From_Individual__c == 'true' || o.accountid == null) || hh_settings.npo02__Always_Rollup_to_Primary_Contact__c) &&
                (mbrRecordTypes.contains((id)o.get('recordTypeId')) || !recordTypesToExcludeCons.contains((id)o.get('recordTypeId'))) &&
                (!oppTypesToExcludeCons.contains(o.type))){
            needsRollup = true;
        }
        return needsRollup;
    }
    //evaluates if an Opp belongs to a valid Account needing a rollup
    public static boolean needsAccountRollup(Opportunity o){
        boolean needsRollup = false;    
        //if the account id is not null and its not the individual/bucket account AND
        //its the membership rectype or the rectype isn't exclused AND
        //the opp type isn't excluded
        if (o.AccountId != null && !getIndividualAccountIds().contains(o.AccountId) && 
        (mbrRecordTypes.contains((id)o.get('recordTypeId')) || !recordTypesToExcludeAccts.contains((id)o.get('recordTypeId'))) && 
        !oppTypesToExcludeAccts.contains(o.type)){
            needsRollup = true;                
        }                                    
        return needsRollup;
    }
    //evaluates two opps for changes that would require a rollup
    public static boolean oppForRollup (Opportunity newOpp, Opportunity oldOpp){
        boolean needsRollup = false;          
        //if the iswon stage has changed, or its iswon and the amount has changed
        //or the recordtype has changed, or the type has changed, or the account id has changed
        //or its won and any of the membership fields have changed
        if (newOpp.isWon != oldOpp.isWon ||
            (newOpp.isWon && (newOpp.Amount != oldOpp.Amount)) ||
            (id)newOpp.get('recordTypeId') != (id)oldOpp.get('recordTypeId') ||                                            
            newOpp.type != oldOpp.type ||
            newOpp.closeDate != oldOpp.closeDate ||
            newOpp.accountId != oldOpp.accountId ||
            (newOpp.isWon && (newOpp.npe01__Membership_Start_Date__c != oldOpp.npe01__Membership_Start_Date__c || 
                              newOpp.npe01__Membership_End_Date__c != oldOpp.npe01__Membership_End_Date__c ||                                            
                              newOpp.npe01__Member_Level__c != oldOpp.npe01__Member_Level__c))){
            needsRollup = true;                                      
        }        
        return needsRollup;
    }    
    
    /****************************************/
    
    /*** Query Building Methods ***/    
    
    public string buildAccountQuery(){
        if (AccountQuery == null){
            AccountQuery = 'select id';
            for (string s : AccountFields){
                AccountQuery += ', ' + s;
            }           
            //multicurrency?
            AccountQuery += (isMultiCurrency() ? ', CurrencyIsoCode ' : '');  
            AccountQuery += ' from Account ';
        }
        return AccountQuery;
    }
    public string buildOpportunityContactRoleQuery(){
        if (OpportunityContactRoleQuery == null){
            OpportunityContactRoleQuery = 'select id';
            for (string s : OpportunityContactRoleFields){
                OpportunityContactRoleQuery += ', ' + s;
            }           
            OpportunityContactRoleQuery += (isMultiCurrency() ? ', Contact.CurrencyIsoCode, Contact.npo02__Household__r.CurrencyIsoCode ' : ''); 
            OpportunityContactRoleQuery += ' from OpportunityContactRole ';
        }
        return OpportunityContactRoleQuery;     
    }
    public string buildContactQuery(){    
        if (ContactQuery == null){
            ContactQuery = 'select id';
            for (string s : ContactFields){
                ContactQuery += ', ' + s;               
            }   
            ContactQuery += (isMultiCurrency() ? ', CurrencyIsoCode ' : '');  
            ContactQuery += ' from Contact ';           
        }    
        return ContactQuery;
    }
    public string buildHouseholdQuery(){
        if (HouseholdQuery == null){
            HouseholdQuery = 'select id';
            for (string s : HouseholdFields){
                HouseholdQuery += ', ' + s;               
            }   
            HouseholdQuery += (isMultiCurrency() ? ', CurrencyIsoCode ' : '');  
            HouseholdQuery += ' from npo02__Household__c ';           
        }
        return HouseholdQuery;    
    }
    
    public string buildAccountRollupQuery(){
        if (AccountRollupQuery == null){
            if (useFiscalYear)
                AccountRollupQuery = 'SELECT AccountId, Fiscal_Year(CloseDate) CalendarYr, ';
            else
                AccountRollupQuery = 'SELECT AccountId, Calendar_Year(CloseDate) CalendarYr, ';        
            AccountRollupQuery += 'SUM(Amount) TotalOppAmount, AVG(Amount) AverageAmount, MIN(Amount) SmallestAmount, ';
            AccountRollupQuery += 'MAX(Amount) LargestAmount, MIN(CloseDate) FirstCloseDate, MAX(CloseDate) LastCloseDate, ';
            if (objectRollupFieldMap.containsKey('Account'))
                AccountRollupQuery += objectRollupFieldMap.get('Account');        
            AccountRollupQuery += ' COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(npo02__CombinedRollupFieldset__c) RollupFieldset ';
            AccountRollupQuery += 'FROM Opportunity ';
            AccountRollupQuery += 'WHERE isWon=true '; 
            AccountRollupQuery += 'AND Amount != null '; 
            if (!getIndividualAccountIds().isEmpty()){
                AccountRollupQuery += 'AND AccountID NOT IN (';
                for (id i : getIndividualAccountIds()){                 
                    AccountRollupQuery += '\'' + i + '\',';
                }
                //drop the trailing comma
                AccountRollupQuery = AccountRollupQuery.substring(0, AccountRollupQuery.length() - 1);
                AccountRollupQuery += ') ';
            }         
            if(areRecordTypesOnOpps()){
                AccountRollupQuery += 'AND RecordTypeId NOT IN :rectypeset ';
            }
            AccountRollupQuery += 'AND Type NOT IN :typeset ';
            AccountRollupQuery += 'AND AccountId IN :aset ';
            if (useFiscalYear){
                AccountRollupQuery += 'GROUP BY ROLLUP (AccountId, Fiscal_Year(CloseDate)) ';                
            }
            else{
                AccountRollupQuery += 'GROUP BY ROLLUP (AccountId, Calendar_Year(CloseDate)) ';                
            }
            AccountRollupQuery += ' HAVING AccountId != null ';
        }
        return AccountRollupQuery;
    }
    
    public string buildAccountNDayQuery(){
        if (AccountNDayQuery == null){
            AccountNDayQuery = 'SELECT AccountId, ';
            AccountNDayQuery += 'SUM(Amount) TotalOppAmount, COUNT_DISTINCT(Id) NumberOfClosedOpps '; 
            AccountNDayQuery += 'FROM Opportunity  '; 
            AccountNDayQuery += 'WHERE isWon=true  '; 
            AccountNDayQuery += 'AND Amount != null '; 
            if (!getIndividualAccountIds().isEmpty()){
                AccountRollupQuery += 'AND AccountID NOT IN (';
                for (id i : getIndividualAccountIds()){                 
                    AccountRollupQuery += '\'' + i + '\',';
                }
                //drop the trailing comma
                AccountRollupQuery = AccountRollupQuery.substring(0, AccountRollupQuery.length() - 1);
                AccountRollupQuery += ') ';
            }   
            if(areRecordTypesOnOpps()){ 
                AccountNDayQuery += 'AND RecordTypeId NOT IN :rectypeset '; 
            }
            AccountNDayQuery += 'AND Type NOT IN :typeset '; 
            AccountNDayQuery += 'AND AccountId IN :aset '; 
            AccountNDayQuery += 'AND closeDate >= LAST_N_DAYS:' + hh_settings.npo02__Rollup_N_Day_Value__c.intValue() + ' '; 
            AccountNDayQuery += 'GROUP BY AccountId '; 
            AccountNDayQuery += 'HAVING AccountId != null ';
        }       
        return AccountNDayQuery;
    }
    
    public string buildAccountMembershipQuery(){
        if (AccountMembershipQuery == null){
            AccountMembershipQuery = 'SELECT AccountId, ';
            AccountMembershipQuery += 'SUM(Amount) TotalOppAmount, '; 
            AccountMembershipQuery += 'MAX(CloseDate) LastCloseDate, ';
            AccountMembershipQuery += 'MIN(npe01__membership_start_date__c) FirstStartDate, MAX(npe01__membership_end_date__c) LastEndDate,  ';
            AccountMembershipQuery += 'COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(npo02__CombinedRollupFieldset__c) RollupFieldset  ';
            AccountMembershipQuery += 'FROM Opportunity ';
            AccountMembershipQuery += 'WHERE isWon=true  ';
            AccountMembershipQuery += 'AND Amount != null  ';         
            if (!getIndividualAccountIds().isEmpty()){
                AccountRollupQuery += 'AND AccountID NOT IN (';
                for (id i : getIndividualAccountIds()){                 
                    AccountRollupQuery += '\'' + i + '\',';
                }
                //drop the trailing comma
                AccountRollupQuery = AccountRollupQuery.substring(0, AccountRollupQuery.length()-1);
                AccountRollupQuery += ') ';
            }             
            if(areRecordTypesOnOpps()){
                AccountMembershipQuery += 'AND RecordTypeId IN :memberset ';
            }
            AccountMembershipQuery += 'AND Type NOT IN :typeset ';
            AccountMembershipQuery += 'AND AccountId IN :aset ';            
            if (useFiscalYear)
                AccountMembershipQuery += 'GROUP BY ROLLUP (AccountId, Fiscal_Year(closeDate)) ';
            else
                AccountMembershipQuery += 'GROUP BY ROLLUP (AccountId, Calendar_Year(closeDate)) ';
            AccountMembershipQuery += 'HAVING AccountId != null ';
        }
        return AccountMembershipQuery;
    }
    
    public string buildContactRollupQuery(){
        if (ContactRollupQuery == null){
            if (useFiscalYear)
                ContactRollupQuery = 'SELECT ContactId, Fiscal_Year(Opportunity.CloseDate) CalendarYr, ';
            else
                ContactRollupQuery = 'SELECT ContactId, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';            
            ContactRollupQuery += 'SUM(Opportunity.Amount) TotalOppAmount, ';                        
            ContactRollupQuery += 'AVG(Opportunity.Amount) AverageAmount, MIN(Opportunity.Amount) SmallestAmount, ';
            ContactRollupQuery += 'MAX(Opportunity.Amount) LargestAmount, MIN(Opportunity.CloseDate) FirstCloseDate, '; 
            ContactRollupQuery += 'MAX(Opportunity.CloseDate) LastCloseDate, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
            if (objectRollupFieldMap.containsKey('Contact'))
                ContactRollupQuery += objectRollupFieldMap.get('Contact');         
            ContactRollupQuery += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
            ContactRollupQuery += 'FROM OpportunityContactRole ';
            ContactRollupQuery += 'WHERE isPrimary=true AND Opportunity.isWon=true '; 
            ContactRollupQuery += 'AND Opportunity.Amount != null '; 
            if(areRecordTypesOnOpps()){
                ContactRollupQuery += 'AND Opportunity.RecordTypeId NOT IN :rectypeset ';
            }
            ContactRollupQuery += 'AND Opportunity.Type NOT IN :typeset '; 
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                 ContactRollupQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }                    
            ContactRollupQuery += 'AND ContactId IN :cset ';            
            if (useFiscalYear)
                ContactRollupQuery += 'GROUP BY ROLLUP(ContactId, Fiscal_Year(Opportunity.CloseDate)) ';
            else
                ContactRollupQuery += 'GROUP BY ROLLUP(ContactId, Calendar_Year(Opportunity.CloseDate)) ';              
        }        
        return ContactRollupQuery;
    }
    
    public string buildContactNDayQuery(){
        if (ContactNDayQuery == null){
            ContactNDayQuery = 'SELECT ContactId, ';
            ContactNDayQuery += 'SUM(Opportunity.Amount) TotalOppAmount, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps ';
            ContactNDayQuery += 'FROM OpportunityContactRole  ';
            ContactNDayQuery += 'WHERE isPrimary=true AND opportunity.isWon=true  ';
            ContactNDayQuery += 'AND Opportunity.Amount != null '; 
            if(areRecordTypesOnOpps()){
                ContactNDayQuery += 'AND Opportunity.RecordTypeId NOT IN :rectypeset ';
            }
            ContactNDayQuery += 'AND Opportunity.Type NOT IN :typeset ';
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                ContactNDayQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }  
            ContactNDayQuery += 'AND ContactId IN :cset ';
            ContactNDayQuery += 'AND Opportunity.CloseDate >= LAST_N_DAYS:' + hh_settings.npo02__Rollup_N_Day_Value__c.intValue() + ' ';
            ContactNDayQuery += 'GROUP BY ROLLUP(ContactId) ';
        }       
        return ContactNDayQuery;
    }
    
    public string buildContactMembershipQuery(){ 
        if (ContactMembershipQuery == null){
            ContactMembershipQuery = 'SELECT ContactId, ';
            ContactMembershipQuery += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
            ContactMembershipQuery += 'MAX(Opportunity.CloseDate) LastCloseDate,  ';
            ContactMembershipQuery += 'MIN(Opportunity.npe01__Membership_start_date__c) FirstStartDate, '; 
            ContactMembershipQuery += 'MAX(Opportunity.npe01__Membership_End_Date__c) LastEndDate,  ';                
            ContactMembershipQuery += 'COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
            ContactMembershipQuery += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
            ContactMembershipQuery += 'FROM OpportunityContactRole  ';
            ContactMembershipQuery += 'WHERE isPrimary=true AND Opportunity.isWon=true '; 
            ContactMembershipQuery += 'AND Opportunity.Amount != null '; 
            if(areRecordTypesOnOpps()){
                ContactMembershipQuery += 'AND Opportunity.RecordTypeId IN :memberset ';
            }
            ContactMembershipQuery += 'AND Opportunity.Type NOT IN :typeset ';
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                ContactMembershipQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }
            ContactMembershipQuery += 'AND Contactid IN :cset ';
            ContactMembershipQuery += 'GROUP BY ROLLUP(ContactId) ';
        }   
        return ContactMembershipQuery;      
    }
    
    
    public string buildHouseholdRollupQuery(){
        if (HouseholdRollupQuery == null){
            if (useFiscalYear)
                HouseholdRollupQuery = 'SELECT Contact.npo02__Household__c hhid, Fiscal_Year(Opportunity.CloseDate) CalendarYr, ';
            else
                HouseholdRollupQuery = 'SELECT Contact.npo02__Household__c hhid, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';            
            HouseholdRollupQuery += 'SUM(Opportunity.Amount) TotalOppAmount, ';
            HouseholdRollupQuery += 'AVG(Opportunity.Amount) AverageAmount, MIN(Opportunity.Amount) SmallestAmount, ';
            HouseholdRollupQuery += 'MAX(Opportunity.Amount) LargestAmount, MIN(Opportunity.CloseDate) FirstCloseDate, '; 
            HouseholdRollupQuery += 'MAX(Opportunity.CloseDate) LastCloseDate, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
            if (objectRollupFieldMap.containsKey('npo02__Household__c'))
                HouseholdRollupQuery += objectRollupFieldMap.get('npo02__Household__c');         
            HouseholdRollupQuery += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
            HouseholdRollupQuery += 'FROM OpportunityContactRole ';
            HouseholdRollupQuery += 'WHERE isPrimary=true AND Opportunity.isWon=true '; 
            HouseholdRollupQuery += 'AND Opportunity.Amount != null '; 
            if(areRecordTypesOnOpps()){
                HouseholdRollupQuery += 'AND Opportunity.RecordTypeId NOT IN :rectypeset ';
            }
            HouseholdRollupQuery += 'AND Opportunity.Type NOT IN :typeset '; 
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                 HouseholdRollupQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }                    
            HouseholdRollupQuery += 'AND Contact.npo02__Household__c IN :hhset ';
            if (useFiscalYear)
                HouseholdRollupQuery += 'GROUP BY ROLLUP(Contact.npo02__Household__c, Fiscal_Year(Opportunity.CloseDate)) ';
            else
                HouseholdRollupQuery += 'GROUP BY ROLLUP(Contact.npo02__Household__c, Calendar_Year(Opportunity.CloseDate)) ';              
        }
        return HouseholdRollupQuery;        
    }
    
    public string buildHouseholdNDayQuery(){
        if (HouseholdNDayQuery == null){
            HouseholdNDayQuery = 'SELECT Contact.npo02__Household__c hhid, ';
            HouseholdNDayQuery += 'SUM(Opportunity.Amount) TotalOppAmount, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps ';
            HouseholdNDayQuery += 'FROM OpportunityContactRole  ';
            HouseholdNDayQuery += 'WHERE isPrimary=true AND opportunity.isWon=true  ';
            HouseholdNDayQuery += 'AND Opportunity.Amount != null '; 
            if(areRecordTypesOnOpps()){
                HouseholdNDayQuery += 'AND Opportunity.RecordTypeId NOT IN :rectypeset ';
            }
            HouseholdNDayQuery += 'AND Opportunity.Type NOT IN :typeset ';
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                HouseholdNDayQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }  
            HouseholdNDayQuery += 'AND Contact.npo02__Household__c IN :hhset ';
            HouseholdNDayQuery += 'AND Opportunity.CloseDate >= LAST_N_DAYS:' + hh_settings.npo02__Rollup_N_Day_Value__c.intValue() + ' ';
            HouseholdNDayQuery += 'GROUP BY ROLLUP(Contact.npo02__Household__c) ';          
        }
        return HouseholdNDayQuery;      
    }
    
    public string buildHouseholdMembershipQuery(){
        if (HouseholdMembershipQuery == null){
            HouseholdMembershipQuery = 'SELECT Contact.npo02__Household__c hhid, ';
            HouseholdMembershipQuery += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
            HouseholdMembershipQuery += 'MAX(Opportunity.CloseDate) LastCloseDate,  ';
            HouseholdMembershipQuery += 'MIN(Opportunity.npe01__Membership_start_date__c) FirstStartDate, '; 
            HouseholdMembershipQuery += 'MAX(Opportunity.npe01__Membership_End_Date__c) LastEndDate,  ';                
            HouseholdMembershipQuery += 'COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
            HouseholdMembershipQuery += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
            HouseholdMembershipQuery += 'FROM OpportunityContactRole  ';
            HouseholdMembershipQuery += 'WHERE isPrimary=true AND Opportunity.isWon=true '; 
            HouseholdMembershipQuery += 'AND Opportunity.Amount != null '; 
            if(areRecordTypesOnOpps()){
                HouseholdMembershipQuery += 'AND Opportunity.RecordTypeId IN :memberset ';
            }
            HouseholdMembershipQuery += 'AND Opportunity.Type NOT IN :typeset ';
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                HouseholdMembershipQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }
            HouseholdMembershipQuery += 'AND Contact.npo02__Household__c IN :hhset ';
            HouseholdMembershipQuery += 'GROUP BY ROLLUP(Contact.npo02__Household__c) ';
        }
        return HouseholdMembershipQuery;
    }
    
    public string buildSoftCreditQuery(){
        if (SoftCreditQuery == null){           
            if (useFiscalYear)
                SoftCreditQuery = 'SELECT ContactId, Fiscal_Year(Opportunity.CloseDate) CalendarYr, ';
            else
                SoftCreditQuery = 'SELECT ContactId, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';            
            SoftCreditQuery += 'SUM(Opportunity.Amount) TotalOppAmount, ';
            SoftCreditQuery += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
            SoftCreditQuery += 'FROM OpportunityContactRole ';
            SoftCreditQuery += 'WHERE Opportunity.isWon=true '; 
            SoftCreditQuery += 'AND Opportunity.Amount != null ';   
            SoftCreditQuery += 'AND Role IN :softCreditRoles ';                                         
            if (areRecordTypesOnOpps()){
                SoftCreditQuery += 'AND Opportunity.RecordTypeId NOT IN :rectypeset ';
            }
            SoftCreditQuery += 'AND Opportunity.Type NOT IN :typeset ';
            /** soft credits should always roll up to contacts with those OCR's regardless of the tpe of account. 
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                SoftCreditQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }
            */
            SoftCreditQuery += 'AND ContactId IN :cset ';            
            if (useFiscalYear)
                SoftCreditQuery += 'GROUP BY ROLLUP(ContactId, Fiscal_Year(Opportunity.CloseDate)) ';
            else
                SoftCreditQuery += 'GROUP BY ROLLUP(ContactId, Calendar_Year(Opportunity.CloseDate)) ';
        }           
        return SoftCreditQuery;  
    }
    
    public string buildContactNDaySoftCreditQuery(){
        if (ContactNDaySoftCreditQuery == null){
            ContactNDaySoftCreditQuery = 'SELECT ContactId, ';
            ContactNDaySoftCreditQuery += 'SUM(Opportunity.Amount) TotalOppAmount ';
            ContactNDaySoftCreditQuery += 'FROM OpportunityContactRole  ';
            ContactNDaySoftCreditQuery += 'WHERE opportunity.isWon=true  ';
            ContactNDaySoftCreditQuery += 'AND Opportunity.Amount != null '; 
            ContactNDaySoftCreditQuery += 'AND Role IN :softCreditRoles ';        
            if (areRecordTypesOnOpps()){
                ContactNDaySoftCreditQuery += 'AND Opportunity.RecordTypeId NOT IN :rectypeset ';
            }
            ContactNDaySoftCreditQuery += 'AND Opportunity.Type NOT IN :typeset ';
            if (!hh_settings.npo02__Always_Rollup_to_Primary_Contact__c){
                ContactNDaySoftCreditQuery += 'AND (Opportunity.AccountId = null OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = true) ';
            }
            ContactNDaySoftCreditQuery += 'AND ContactId IN :cset ';
            ContactNDaySoftCreditQuery += 'AND Opportunity.CloseDate >= LAST_N_DAYS:' + hh_settings.npo02__Rollup_N_Day_Value__c.intValue() + ' ';
            ContactNDaySoftCreditQuery += 'GROUP BY ROLLUP(ContactId) ';
        }       
        return ContactNDaySoftCreditQuery;
    }
    
    /****************************************/
     
    /*** Utility Methods ***/    
    
    public static integer getCurrentFY() {        
        if (fiscal_year == null){
            Organization orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                                    FROM Organization
                                    WHERE id=:Userinfo.getOrganizationId()];
            Date today = system.today();
            
            if (today.month() >= orgInfo.FiscalYearStartMonth){
                if (orgInfo.UsesStartDateAsFiscalYearName){
                    fiscal_year = today.year();
                } 
                else{
                    fiscal_year = today.year() + 1;
                }
            }
            else{
                if (orgInfo.UsesStartDateAsFiscalYearName){
                    fiscal_year = today.year() - 1;
                }
                else{
                    fiscal_year = today.year();
                }
            }
        }               
    return fiscal_year;
    }
}