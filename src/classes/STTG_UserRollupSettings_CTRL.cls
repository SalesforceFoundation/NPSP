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
* @date 2011 (2.3)
* @description Controller class for the User Rollup Settings wizard  
*/
public with sharing class STTG_UserRollupSettings_CTRL{ 
    
    /*** Properties and Fields ***/
    
    //controls which types to display
    map<string, Schema.Displaytype> mapFieldTypes = new map<string, Schema.Displaytype>();
    map<string, Schema.Displaytype> targetFieldTypes = new map<string, Schema.Displaytype>();
        
    //pickers for setting values   
    public list<SelectOption> sourcefields = new list<SelectOption>();
    public list<SelectOption> validoperators = new list<SelectOption>();
    public list<SelectOption> targetfields = new list<SelectOption>();    
    public list<SelectOption> targetobjects = new list<SelectOption>{
        new SelectOption('Account', 'Account'),
        new SelectOption('Contact', 'Contact'),
        new SelectOption('npo02__Household__c', 'npo02__Household__c')    
    }; 
    
    public list<UDR> udrList;
    public list<UDR> getudrList(){
        list<User_Rollup_Field_Settings__c> thisList = User_Rollup_Field_Settings__c.getAll().values(); 
        udrlist = new list<UDR>();
        for (User_Rollup_Field_Settings__c udr : thisList){
            udrList.add(new UDR(udr, this));
        }
        udrlistsize = udrList.size();
        return udrList;
    }
    
    public integer udrlistsize{get;set;}
    public UDR activeUDR{get; set;}
    public boolean isBuildingRollup{get; set;}    
    public boolean isValidRollup{get; set;}
    private boolean hasRollupInsert = false;
    
    /*** Constructor ***/
    
    public STTG_UserRollupSettings_CTRL(){        
        isValidRollup = false;
        isBuildingRollup = false;        
    }    
    
    /*** Page Operations ***/
    
    public void startBuild(){    
        activeUDR = new UDR(this);
        isBuildingRollup = true;
    }
        
    //called on load of the page
    public PageReference checkSettings(){
        //if there are invalid rollups defined, display an error 
        if (!userRollupsValid()){
            showMsg('INVALID USER SETTINGS DETECTED - Some user defined rollups have been disabled',ApexPages.Severity.ERROR);
            showMsg('User defined rollups reference target or source fields which do not exist.  Please update or delete the invalid rollups to re-enable.', ApexPages.Severity.WARNING);
        }       
        return null;
    }
    
    //reset all instance variable and return to initial screen
    public void cancel(){       
        this.sourcefields.clear();
        this.mapFieldTypes.clear();
        this.validoperators.clear();
        this.targetfields.clear();     
        this.isBuildingRollup = false;    
        this.activeUDR = null;
    }    
    
    /*** Getters for Field Selectors ***/
    
    //retrieve target objects
    public list<SelectOption> getTargetObjects(){
        return this.targetobjects;
    }
    
    //retrieve valid operators
    public list<SelectOption> getValidOperators(){
        validoperators.clear();        
        if (mapFieldTypes.containsKey(activeUDR.SourceField)){
           validoperators.add(new SelectOption('MIN', 'MIN'));
           validoperators.add(new SelectOption('MAX', 'MAX'));  
           
            if ((mapFieldTypes.get(activeUDR.SourceField) != Schema.Displaytype.Date) && (mapFieldTypes.get(activeUDR.SourceField) != Schema.Displaytype.Datetime)){  
                validoperators.add(new SelectOption('AVG', 'AVG'));
                validoperators.add(new SelectOption('SUM', 'SUM'));                
            }
        }    
        return validoperators; 
    }
    
    //retrieve possible target fields for the selected object
    public list<SelectOption> getTargetFields(){ 
        
        targetfields.clear();
        set<string> knownfields;    
        map<string, Schema.Sobjectfield> targetTokenMap = new map<string, Schema.Sobjectfield>();        
        //need to load current settings to not allow the user to point to the same target field
        //twice
        map<string, User_Rollup_Field_Settings__c> currentURFSMap = User_Rollup_Field_Settings__c.getAll();
        set<string> currentTargetFieldSet = new set<string>();
        for (string s : currentURFSMap.keySet()){
            if (currentURFSMap.get(s).Object_Name__c == activeUDR.TargetObject && currentURFSMap.get(s).Target_Field__c != activeUDR.TargetField){
               string fieldname = (currentURFSMap.get(s).Target_Field__c).toLowerCase();
               //we need to strip out the namespace
               if (fieldname.contains('npo02')){
                   fieldname = fieldname.replace('npo02__', '');
                
               }
               else if (fieldname.contains('npe01')){
                   fieldname = fieldname.replace('npe01__', '');
               }
               currentTargetFieldSet.add(fieldname);
            }
        }  
         
        if (activeUDR.TargetObject == 'Contact'){
            targetTokenMap = Schema.SObjectType.Contact.fields.getMap().clone();
            knownfields = new set<string>{
                'averageamount__c', 'donor__c', 'donor_this_year__c',                
                'firstclosedate__c', 'household__c', 'formula_householdmailingaddress__c',
                'formula_householdphone__c', 'languages__c', 'largestamount__c', 
                'lastoppamount__c', 'lastclosedate__c', 'lastclosedatehh__c',
                'lastmembershipdate__c', 'lastmembershiplevel__c', 'lastmembershipamount__c',
                'lastmembershiporigin__c', 'last_donation_date__c', 'level__c',
                'membershipenddate__c', 'membershipjoindate__c', 'membership_span__c',
                'membership_status__c', 'new_donor_this_year__c', 'oppsclosedlastndays__c',
                'oppsclosedlastyear__c', 'oppsclosedthisyear__c', 'oppsclosed2yearsago__c',
                'numberofmembershipopps__c', 'smallestamount__c', 'totaloppamount__c',
                'oppamountlastndays__c', 'oppamountlastyear__c', 'oppamountthisyear__c',
                'oppamount2yearsago__c', 'total_household_gifts__c', 'oppamountlastndayshh__c',
                'oppamountlastyearhh__c', 'oppamountthisyearhh__c', 'totalmembershipoppamount__c',
                'numberofclosedopps__c', 'systemhouseholdprocessor__c', 'naming_exclusions__c',
                'best_gift_year__c', 'best_gift_year_total__c', 'household_naming_order__c',
                'soft_credit_last_year__c', 'soft_credit_this_year__c', 'soft_credit_total__c',
                'soft_credit_two_years_ago__c'
                };
        }
        else if(activeUDR.TargetObject == 'Account'){
            targetTokenMap = Schema.SobjectType.Account.fields.getMap().clone();
            knownfields = new set<string>{
                'active__c', 'averageamount__c', 'customer_priority__c', 'customerpriority__c',
                'upsellopportunity__c', 'firstclosedate__c', 'largestamount__c', 'lastoppamount__c',
                'lastclosedate__c', 'lastmembershipdate__c', 'lastmembershipamount__c',
                'lastmembershiplevel__c', 'lastmembershiporigin__c', 'membershipenddate__c',
                'membershipjoindate__c', 'membership_span__c', 'membership_status__c',
                'oppsclosedlastndays__c', 'oppsclosedlastyear__c', 'oppsclosedthisyear__c',
                'oppsclosed2yearsago__c', 'numberoflocations__c', 'numberofmembershipopps__c',
                'sla__c', 'slaexpirationdate__c', 'slaserialnumber__c', 'smallestamount__c',
                'totaloppamount__c', 'oppamountlastndays__c', 'oppamountlastyear__c', 'oppamountthisyear__c',
                'oppamount2yearsago__c', 'totalmembershipoppamount__c', 'numberofclosedopps__c',
                'best_gift_year__c', 'best_gift_year_total__c'
           };
        }
        else if(activeUDR.TargetObject == 'Household__c' || activeUDR.TargetObject == 'npo02__Household__c'){
            targetTokenMap = Schema.SobjectType.Household__c.fields.getMap().clone();
            knownfields = new set<string>{
                'addressee__c', 'always_anonymous__c', 'averagemount__c', 'firstclosedate__c',   
                'householdemail__c','household_id__c','householdphone__c','largestamount__c',
                'lastoppamount__c','lastclosedate__c','lastmembershipamount__c','lastmembershipdate__c',       
                'lastmembershiplevel__c','lastmembershiporigin__c','formula_mailingaddress__c',    
                'mailingcity__c','mailingcountry__c','mailingstate__c','mailingstreet__c',     
                'mailingpostalcode__c','membershipenddate__c','membershipjoindate__c','membership_span__c',      
                'membership_status__c','oppsclosedlastndays__c','oppsclosedlastyear__c',       
                'oppsclosedthisyear__c','oppsclosed2yearsago__c','numberOfmembershipopps__c',   
                'smallestamount__c','totaloppamount__c','oppamountlastndays__c','oppamountlastyear__c',    
                'oppamountthisyear__c','oppamount2yearsago__c','totalmembershipoppamount__c',    
                'numberofclosedopps__c', 'formal_greeting__c', 'informal_greeting__c', 'averageamount__c',
                'system_custom_naming__c', 'best_gift_year__c', 'best_gift_year_total__c'
           };     
        }
        //set knownfield to an empty set
        else{
            knownfields = new set<string>();            
        }
        
        
        if(!currentTargetFieldSet.isEmpty())
            knownfields.addAll(currentTargetFieldSet);
        
        //pop out the known fields
        for (string s : knownfields){
            s = s.toLowerCase();
            targetTokenMap.remove(s);
        }
        
        if (targettokenMap.size() > 0){        
            for (string s : targetTokenMap.keyset()){            
                if (s.contains('__c') && (!s.startswith('npe01__'))){
                    Schema.DescribeFieldResult F = targetTokenMap.get(s).getDescribe();                  
                    targetfields.add(new SelectOption(f.getName(), s));    
                }
            }
        }
        
        if (targetfields.size() < 1){            
            targetfields.clear();
            targetfields.add(new SelectOption('', 'No Valid ' + activeUDR.TargetObject + ' Field Available'));                            
        }
        return sortOptionList(targetfields);    
    }
    
    //retrieve valid source fields from opportunity object
    public list<SelectOption> getSourceFields(){
        
        set<string> knownOpptyFields = new set<string>{'Amount', 'CloseDate', 'ExpectedRevenue', 
            'Probability', 'TotalOpportunityQuantity', 'npe01__membership_start_date__c', 'npe01__membership_end_date__c'};
        
        if (sourcefields.isEmpty()){                       
            map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap(); 
           
            //loop through the map, only get the describe information for fields we don't
            //already recognize, including our own and non-custom fields, we'll add those in a moment
            for(string fieldName : oppFieldTokenList.keyset()){
                if (fieldname.contains('__c') && (!knownopptyFields.contains(fieldName))){
                    Schema.DescribeFieldResult F = oppFieldTokenList.get(fieldName).getDescribe();                  
                    
                    Schema.Displaytype dt = f.getType();
                    if ((dt == Schema.Displaytype.Currency) ||
                        (dt == Schema.Displaytype.Date) ||
                        (dt == Schema.Displaytype.Datetime) ||
                        (dt == Schema.Displaytype.Double) ||
                        (dt == Schema.Displaytype.Integer) ||
                        (dt == Schema.Displaytype.Percent)){                                
                        
                        sourcefields.add(new SelectOption(f.getName(),fieldname));
                        mapFieldTypes.put(f.getName(), dt);                    
                    }
                }
           }           
           
           //now add our known field types
           for(string knownField : knownopptyFields){
                sourcefields.add(new SelectOption(knownField, knownField));
           
                if((knownfield == 'Amount') || (knownfield == 'ExpectedRevenue'))
                    mapFieldTypes.put(knownfield, Schema.Displaytype.Currency);         
                else if((knownfield == 'CloseDate')||(knownfield == 'npe01__membership_start_date__c') || (knownfield == 'npe01__membership_end_date__c'))                  
                    mapFieldTypes.put(knownfield, Schema.Displaytype.Date);
                else
                    mapFieldTypes.put(knownfield, Schema.Displaytype.Double);   
            }
            sourceFields = sortOptionList(sourceFields);               
        }
         
        return sourceFields;
    }
    
    /*** Handle Clearing Potentially Invalid Data OnChange ***/
    
    public void clearForSourceField(){
        activeUDR.Operation = null;     
        activeUDR.TargetObject = null;
        activeUDR.TargetField = null;       
    }    
    public void clearForOperation(){
        activeUDR.TargetObject = null;
        activeUDR.TargetField = null;
        
    }
    public void clearForTargetObject(){
        activeUDR.TargetField = null;       
    }    
    
    /*** Private Methods **/

    //utility to check that existing user defined rollups are valid - called onpageload
    //NOTE: Only checks that target/source fields exist, not operation validity
    private boolean userRollupsValid(){
        boolean isValid = true;
        
        map<string, User_Rollup_Field_Settings__c> userRollups = User_Rollup_Field_Settings__c.getAll(); 
    
        for (string s : userRollups.keySet()){
            User_Rollup_Field_Settings__c urfs = userRollups.get(s);
            SobjectField targetField;
            SobjectField sourceField;
            
            //check source field
            sourceField = Schema.sObjectType.Opportunity.fields.getMap().get(urfs.Source_Field__c);
            if (sourceField == null) isValid = false;
                      
            //check target fields            
            if (urfs.Object_Name__c == 'Contact'){
                targetField = Schema.sObjectType.Contact.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) isValid = false;
            }
            else if (urfs.Object_Name__c == 'Account'){
                targetField = Schema.sObjectType.Account.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) isValid = false;               
            }
            else if (urfs.Object_Name__c == 'Household__c' || urfs.Object_Name__c == 'npo02__Household__c'){
                targetField = Schema.sObjectType.Household__c.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) isValid = false;
            }
            else isValid = false;
        }    
    
    return isValid;
    }           
        
    //used to render error messages on the VF interface
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }    
    
     //http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
    private list<SelectOption> sortOptionList(list<SelectOption> ListToSort){
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
        List<SelectOption> returnList = new List<SelectOption>();
        returnList.addAll(SortOptionList(Less));
        returnList.add(pivotValue);
        returnList.addAll(SortOptionList(Greater));
        return returnList; 
    }
    
    /*** Class **/
    
    public class UDR{
        
        public User_Rollup_Field_Settings__c myUDR{get;set;}
        public String SourceField{get;set;}
        public String TargetField{get;set;}
        public String TargetObject{get;set;}
        public String Operation{get;set;}
        public Boolean isValid{set;}
        STTG_UserRollupSettings_CTRL mydad;
        
        public UDR(STTG_UserRollupSettings_CTRL parentclass){
            mydad = parentclass;  
            myUDR = new User_Rollup_Field_Settings__c();        
        }
        public UDR(User_Rollup_Field_Settings__c thisUDR, STTG_UserRollupSettings_CTRL parentclass){
            this.SourceField = thisUDR.Source_Field__c;
            this.TargetField = thisUDR.Target_Field__c;
            this.TargetOBject = thisUDR.Object_Name__c;
            this.Operation = thisUDR.Field_Action__c;
            myUDR = thisUDR;        
            mydad = parentclass;    
        }       
        public UDR(String SourceField, String TargetField, String TargetObject, String Operation, STTG_UserRollupSettings_CTRL parentclass){
            this.SourceField = SourceField;
            this.TargetField = TargetField;
            this.TargetObject = TargetObject;
            this.Operation = Operation;
            myUDR = new User_Rollup_Field_Settings__c();
            mydad = parentclass;
        }
        
        public void save(){
            
            if (myUDR.id == null){
                map<string, User_Rollup_Field_Settings__c> userRollups = User_Rollup_Field_Settings__c.getAll();
                integer nameNumber = userRollups.size();             
                myUDR.Name = 'CustomRollup' + nameNumber; 
                myUDR.Object_Name__c = TargetObject;
                myUDR.Target_Field__c = TargetField;
                myUDR.Field_Action__c = Operation;
                myUDR.Source_Field__c = SourceField;                
            }
            
            try{
                upsert myUDR;                        
                mydad.udrList.add(this);                
                mydad.activeUDR = null;
                mydad.isBuildingRollup = false;
            }
        
            catch(Exception e){
                mydad.showMsg('An unhandled exception has occurred. Please try again.',ApexPages.Severity.FATAL);
                mydad.showMsg('Exception type' + e, ApexPages.Severity.INFO);          
            }           
        }       
        public void loadMe(){
            mydad.activeUDR = this;
            mydad.isBuildingRollup = true;
        }
        public void deleteMe(){         
            if (myUDR.id != null)
              delete myUDR;
            mydad.activeUDR = null;
            mydad.isBuildingRollup = false;
        }       
        
        public boolean getisValid(){
            if (SourceField != null && TargetField != null && TargetObject != null && Operation != null && TargetField != '')
                return true;
            else
                return false;           
        }       
    }
    
}