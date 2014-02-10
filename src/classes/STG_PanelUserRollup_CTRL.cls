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
* @description Controller class for the User Rollup Settings panel  
*/
public with sharing class STG_PanelUserRollup_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelUserRollup'; }
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
    
    public list<UDR> udrList {
    	get {
    		if (udrList == null) {
		        list<npo02__User_Rollup_Field_Settings__c> thisList = npo02__User_Rollup_Field_Settings__c.getAll().values(); 
		        udrList = new list<UDR>();
		        for (npo02__User_Rollup_Field_Settings__c udr : thisList) {
		            udrList.add(new UDR(udr, this));
		        }
		        udrlistsize = udrList.size();
    		}
            return udrList;
    	}
    	private set;
    }
    
    public integer udrlistsize{get;set;}
    public UDR activeUDR{get; set;}
    public boolean isValidRollup{get; set;}
    private boolean hasRollupInsert = false;
    
    /*** Constructor ***/
    
    public STG_PanelUserRollup_CTRL(){        
        isValidRollup = false;
        isEditMode = false;        
    }    
    
    /*** Page Operations ***/
    
    public void startBuild(){    
        activeUDR = new UDR(this);
        isEditMode = true;
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
        this.isEditMode = false;    
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
        map<string, npo02__User_Rollup_Field_Settings__c> currentURFSMap = npo02__User_Rollup_Field_Settings__c.getAll();
        set<string> currentTargetFieldSet = new set<string>();
        for (string s : currentURFSMap.keySet()){
            if (currentURFSMap.get(s).npo02__Object_Name__c == activeUDR.TargetObject && currentURFSMap.get(s).npo02__Target_Field__c != activeUDR.TargetField){
               string fieldname = (currentURFSMap.get(s).npo02__Target_Field__c).toLowerCase();
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
                'npo02__averageamount__c', 'npo02__donor__c', 'npo02__donor_this_year__c',                
                'npo02__firstclosedate__c', 'npo02__household__c', 'npo02__formula_householdmailingaddress__c',
                'npo02__formula_householdphone__c', 'npo02__languages__c', 'npo02__largestamount__c', 
                'npo02__lastoppamount__c', 'npo02__lastclosedate__c', 'npo02__lastclosedatehh__c',
                'npo02__lastmembershipdate__c', 'npo02__lastmembershiplevel__c', 'npo02__lastmembershipamount__c',
                'npo02__lastmembershiporigin__c', 'npo02__last_donation_date__c', 'npo02__level__c',
                'npo02__membershipenddate__c', 'npo02__membershipjoindate__c', 'npo02__membership_span__c',
                'npo02__membership_status__c', 'npo02__new_donor_this_year__c', 'npo02__oppsclosedlastndays__c',
                'npo02__oppsclosedlastyear__c', 'npo02__oppsclosedthisyear__c', 'npo02__oppsclosed2yearsago__c',
                'npo02__numberofmembershipopps__c', 'npo02__smallestamount__c', 'npo02__totaloppamount__c',
                'npo02__oppamountlastndays__c', 'npo02__oppamountlastyear__c', 'npo02__oppamountthisyear__c',
                'npo02__oppamount2yearsago__c', 'npo02__total_household_gifts__c', 'npo02__oppamountlastndayshh__c',
                'npo02__oppamountlastyearhh__c', 'npo02__oppamountthisyearhh__c', 'npo02__totalmembershipoppamount__c',
                'npo02__numberofclosedopps__c', 'npo02__systemhouseholdprocessor__c', 'npo02__naming_exclusions__c',
                'npo02__best_gift_year__c', 'npo02__best_gift_year_total__c', 'npo02__household_naming_order__c',
                'npo02__soft_credit_last_year__c', 'npo02__soft_credit_this_year__c', 'npo02__soft_credit_total__c',
                'npo02__soft_credit_two_years_ago__c'
                };
        }
        else if(activeUDR.TargetObject == 'Account'){
            targetTokenMap = Schema.SobjectType.Account.fields.getMap().clone();
            knownfields = new set<string>{
                'npo02__active__c', 'npo02__averageamount__c', 'npo02__customer_priority__c', 'npo02__customerpriority__c',
                'npo02__upsellopportunity__c', 'npo02__firstclosedate__c', 'npo02__largestamount__c', 'npo02__lastoppamount__c',
                'npo02__lastclosedate__c', 'npo02__lastmembershipdate__c', 'npo02__lastmembershipamount__c',
                'npo02__lastmembershiplevel__c', 'npo02__lastmembershiporigin__c', 'npo02__membershipenddate__c',
                'npo02__membershipjoindate__c', 'npo02__membership_span__c', 'npo02__membership_status__c',
                'npo02__oppsclosedlastndays__c', 'npo02__oppsclosedlastyear__c', 'npo02__oppsclosedthisyear__c',
                'npo02__oppsclosed2yearsago__c', 'npo02__numberoflocations__c', 'npo02__numberofmembershipopps__c',
                'npo02__sla__c', 'npo02__slaexpirationdate__c', 'npo02__slaserialnumber__c', 'npo02__smallestamount__c',
                'npo02__totaloppamount__c', 'npo02__oppamountlastndays__c', 'npo02__oppamountlastyear__c', 'npo02__oppamountthisyear__c',
                'npo02__oppamount2yearsago__c', 'npo02__totalmembershipoppamount__c', 'npo02__numberofclosedopps__c',
                'npo02__best_gift_year__c', 'npo02__best_gift_year_total__c'
           };
        }
        else if(activeUDR.TargetObject == 'npo02__Household__c' || activeUDR.TargetObject == 'npo02__Household__c'){
            targetTokenMap = Schema.SobjectType.npo02__household__c.fields.getMap().clone();
            knownfields = new set<string>{
                'npo02__addressee__c', 'npo02__always_anonymous__c', 'npo02__averagemount__c', 'npo02__firstclosedate__c',   
                'npo02__householdemail__c','npo02__household_id__c','npo02__householdphone__c','npo02__largestamount__c',
                'npo02__lastoppamount__c','npo02__lastclosedate__c','npo02__lastmembershipamount__c','npo02__lastmembershipdate__c',       
                'npo02__lastmembershiplevel__c','npo02__lastmembershiporigin__c','npo02__formula_mailingaddress__c',    
                'npo02__mailingcity__c','npo02__mailingcountry__c','npo02__mailingstate__c','npo02__mailingstreet__c',     
                'npo02__mailingpostalcode__c','npo02__membershipenddate__c','npo02__membershipjoindate__c','npo02__membership_span__c',      
                'npo02__membership_status__c','npo02__oppsclosedlastndays__c','npo02__oppsclosedlastyear__c',       
                'npo02__oppsclosedthisyear__c','npo02__oppsclosed2yearsago__c','npo02__numberOfmembershipopps__c',   
                'npo02__smallestamount__c','npo02__totaloppamount__c','npo02__oppamountlastndays__c','npo02__oppamountlastyear__c',    
                'npo02__oppamountthisyear__c','npo02__oppamount2yearsago__c','npo02__totalmembershipoppamount__c',    
                'npo02__numberofclosedopps__c', 'npo02__formal_greeting__c', 'npo02__informal_greeting__c', 'npo02__averageamount__c',
                'npo02__system_custom_naming__c', 'npo02__best_gift_year__c', 'npo02__best_gift_year_total__c'
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
                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe(activeUDR.TargetObject, s);                                             
                    targetfields.add(new SelectOption(f.getName(), f.getLabel()));    
                }
            }
        }
        
        if (targetfields.size() < 1){            
            targetfields.clear();
            targetfields.add(new SelectOption('', 'No Valid Field Available'));                            
        }
        return sortOptionList(targetfields);    
    }
    
    //retrieve valid source fields from opportunity object
    public list<SelectOption> getSourceFields(){
        
        // sets of strings are case sensitive, so use lower case in our set for the contains() against knownopptyFields.
        set<string> knownOpptyFields = new set<string>{'amount', 'closedate', 'expectedrevenue', 
            'probability', 'totalopportunityquantity', 'npe01__membership_start_date__c', 'npe01__membership_end_date__c'};
        
        if (sourcefields.isEmpty()){                       
            map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap(); 
            
            system.debug('***** oppFieldTokenList: ' + oppFieldTokenList);
            system.debug('***** knownopptyFields: ' + knownopptyFields);
           
            //loop through the map, only get the describe information for fields we don't
            //already recognize, including our own and non-custom fields, we'll add those in a moment
            for(string fieldName : oppFieldTokenList.keyset()){
                if (fieldname.contains('__c') || knownopptyFields.contains(fieldName)){
                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('Opportunity', fieldname);                         
                    
                    Schema.Displaytype dt = f.getType();
                    if ((dt == Schema.Displaytype.Currency) ||
                        (dt == Schema.Displaytype.Date) ||
                        (dt == Schema.Displaytype.Datetime) ||
                        (dt == Schema.Displaytype.Double) ||
                        (dt == Schema.Displaytype.Integer) ||
                        (dt == Schema.Displaytype.Percent)){                                
                        
                        sourcefields.add(new SelectOption(f.getName(), f.getLabel()));
                        mapFieldTypes.put(f.getName(), dt);                    
                    }
                }
           }           
           
           /********** used the loop above so we could have labels in the picklist *************           
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
            ****************/
            
            //sourceFields = sortOptionList(sourceFields);
            sourceFields.sort();               
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
    public boolean userRollupsValid(){
        boolean isValid = true;
        
        map<string, npo02__User_Rollup_Field_Settings__c> userRollups = npo02__User_Rollup_Field_Settings__c.getAll(); 
    
        for (string s : userRollups.keySet()){
            npo02__User_Rollup_Field_Settings__c urfs = userRollups.get(s);
            SobjectField targetField;
            SobjectField sourceField;
            
            //check source field
            sourceField = Schema.sObjectType.Opportunity.fields.getMap().get(urfs.npo02__Source_Field__c);
            if (sourceField == null) isValid = false;
                      
            //check target fields            
            if (urfs.npo02__Object_Name__c == 'Contact'){
                targetField = Schema.sObjectType.Contact.fields.getMap().get(urfs.npo02__Target_Field__c); 
                if (targetField == null) isValid = false;
            }
            else if (urfs.npo02__Object_Name__c == 'Account'){
                targetField = Schema.sObjectType.Account.fields.getMap().get(urfs.npo02__Target_Field__c); 
                if (targetField == null) isValid = false;               
            }
            else if (urfs.npo02__Object_Name__c == 'npo02__Household__c' || urfs.npo02__Object_Name__c == 'npo02__Household__c'){
                targetField = Schema.sObjectType.npo02__household__c.fields.getMap().get(urfs.npo02__Target_Field__c); 
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
        
        public npo02__User_Rollup_Field_Settings__c myUDR{get;set;}
        public String SourceField{get;set;}
        public String TargetField{get;set;}
        public String TargetObject{get;set;}
        public String Operation{get;set;}
        public Boolean isValid{set;}
        STG_PanelUserRollup_CTRL mydad;
        
        public string SourceFieldLabel {
        	get {
        		return UTIL_Describe.getFieldLabel('Opportunity', SourceField);
        	}
        }
        
        public string TargetFieldLabel {
            get {
                return UTIL_Describe.getFieldLabel(TargetObject, TargetField);
            }
        }
        
        public UDR(STG_PanelUserRollup_CTRL parentclass){
            mydad = parentclass;  
            myUDR = new npo02__User_Rollup_Field_Settings__c();        
        }
        public UDR(npo02__User_Rollup_Field_Settings__c thisUDR, STG_PanelUserRollup_CTRL parentclass){
            this.SourceField = thisUDR.npo02__Source_Field__c;
            this.TargetField = thisUDR.npo02__Target_Field__c;
            this.TargetOBject = thisUDR.npo02__Object_Name__c;
            this.Operation = thisUDR.npo02__Field_Action__c;
            myUDR = thisUDR;        
            mydad = parentclass;    
        }       
        public UDR(String SourceField, String TargetField, String TargetObject, String Operation, STG_PanelUserRollup_CTRL parentclass){
            this.SourceField = SourceField;
            this.TargetField = TargetField;
            this.TargetObject = TargetObject;
            this.Operation = Operation;
            myUDR = new npo02__User_Rollup_Field_Settings__c();
            mydad = parentclass;
        }
        
        public void save(){
            
            if (myUDR.id == null){
                myUDR.Name = 'CustomRollup-' + system.Now(); 
                myUDR.npo02__Object_Name__c = TargetObject;
                myUDR.npo02__Target_Field__c = TargetField;
                myUDR.npo02__Field_Action__c = Operation;
                myUDR.npo02__Source_Field__c = SourceField;                
            }
            
            try{
                upsert myUDR;                        
                mydad.udrList = null;                
                mydad.activeUDR = null;
                mydad.isEditMode = false;
            }
        
            catch(Exception e){
            	ERR_Handler.processError(e, ERR_Handler.Context.STTG);            	
                mydad.showMsg('An unhandled exception has occurred. Please try again.',ApexPages.Severity.FATAL);
                mydad.showMsg('Exception type' + e, ApexPages.Severity.INFO);          
            }           
        }       
        public void loadMe(){
            mydad.activeUDR = this;
            mydad.isEditMode = true;
        }
        public void deleteMe(){         
            if (myUDR.id != null)
              delete myUDR;
            mydad.udrList = null;                
            mydad.activeUDR = null;
            mydad.isEditMode = false;
        }       
        
        public boolean getisValid(){
            if (SourceField != null && TargetField != null && TargetObject != null && Operation != null && TargetField != '')
                return true;
            else
                return false;           
        }       
    }
    
}