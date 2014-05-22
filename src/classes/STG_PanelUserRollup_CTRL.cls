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
    public list<SelectOption> getTargetFields() { 
        
        if (targetfields.isEmpty()) {
	        set<string> knownfields;    
	        map<string, Schema.Sobjectfield> targetTokenMap = new map<string, Schema.Sobjectfield>();        
	        //need to load current settings to not allow the user to point to the same target field
	        //twice
	        map<string, npo02__User_Rollup_Field_Settings__c> currentURFSMap = npo02__User_Rollup_Field_Settings__c.getAll();
	        set<string> currentTargetFieldSet = new set<string>();
	        for (string s : currentURFSMap.keySet()){
	            if (currentURFSMap.get(s).npo02__Object_Name__c == activeUDR.TargetObject && currentURFSMap.get(s).npo02__Target_Field__c != activeUDR.TargetField) {
	               string fieldname = (currentURFSMap.get(s).npo02__Target_Field__c).toLowerCase();
	               currentTargetFieldSet.add(fieldname);
	            }
	        }  
	         
	        if (activeUDR.TargetObject == 'Contact') {
	            targetTokenMap = Schema.SObjectType.Contact.fields.getMap().clone();
	        }
	        else if (activeUDR.TargetObject == 'Account') {
	            targetTokenMap = Schema.SobjectType.Account.fields.getMap().clone();
	        }
	        else if (activeUDR.TargetObject == 'npo02__Household__c') {
	            targetTokenMap = Schema.SobjectType.npo02__household__c.fields.getMap().clone();
	        }
	                
	        // remove any field already used in a UDR
	        for (string s : currentTargetFieldSet){
	            s = s.toLowerCase();
	            targetTokenMap.remove(s);
	        }
	        
	        // get datatype of current Source field
	        Schema.Displaytype dtSrc = mapFieldTypes.get(activeUDR.SourceField);
	        
	        // valid target fields must:
	        // - be a custom field
	        // - not from any NPSP package
	        // - not be a formula field
	        // - support the source field datatype         
	        if (targettokenMap.size() > 0) {        
	            for (string s : targetTokenMap.keyset()) {            
	                if (s.contains('__c') && 
	                    !s.startswith('npsp__') && 
	                    !s.startswith('npe01__') && 
	                    !s.startswith('npo02__') && 
	                    !s.startswith('npe03__') && 
	                    !s.startswith('npe4__') &&
	                    !s.startswith('npe5__')) {
	                    
	                    // check datatype                                             
	                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe(activeUDR.TargetObject, s);
	                    
	                    // disallow formula fields and autonums
	                    if (f.isCalculated() || f.isAutoNumber())
	                        continue;
	                        
	                    Schema.Displaytype dtTgt = f.getType();
	                    if (UTIL_Describe.canDisplaytypesCopy(dtSrc, dtTgt)) {
	                        targetfields.add(new SelectOption(f.getName(), f.getLabel()));
	                    }    
	                }
	            }
	        }
	        
	        if (targetfields.size() < 1){            
	            targetfields.clear();
	            targetfields.add(new SelectOption('', 'No Valid Field Available'));                            
	        }
	        targetfields.sort();
        }
        return targetfields;    
    }
    
    
    //retrieve valid source fields from opportunity object
    public list<SelectOption> getSourceFields(){
        
        if (sourcefields.isEmpty()) {                       

	        // sets of strings are case sensitive, so use lower case in our set for the contains() against knownopptyFields.
	        set<string> knownOpptyFields = new set<string>{'amount', 'closedate', 'expectedrevenue', 
	            'probability', 'totalopportunityquantity', 'npe01__membership_start_date__c', 'npe01__membership_end_date__c'};
        
            map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap(); 
            
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
           sourceFields.sort();               
        }         
        return sourceFields;
    }
    
    /*** Handle Clearing Potentially Invalid Data OnChange ***/
    
    public void clearForSourceField(){
        activeUDR.Operation = null;     
        activeUDR.TargetObject = null;
        activeUDR.TargetField = null;  
        targetfields.clear();
             
    }    
    public void clearForOperation(){
        // the targets are dependent on the source datatype, not the aggregating op.
        //activeUDR.TargetObject = null;
        //activeUDR.TargetField = null;
        
    }
    public void clearForTargetObject(){
        activeUDR.TargetField = null;       
        targetfields.clear();
    }    
    
    //utility to check that existing user defined rollups are valid - called by Health Check
    public static void verifyUserRollups(STG_PanelHealthCheck_CTRL ctrl) {
        boolean isValid = true;
        boolean isValidAll = true;
        
        map<string, npo02__User_Rollup_Field_Settings__c> userRollups = npo02__User_Rollup_Field_Settings__c.getAll(); 
        string strSetting = Schema.Sobjecttype.npo02__User_Rollup_Field_Settings__c.getLabel(); 
    
        for (string s : userRollups.keySet()) {
            npo02__User_Rollup_Field_Settings__c urfs = userRollups.get(s);
            SobjectField targetField;
            SobjectField sourceField;
            isValid = true;
                        
            //check source field
            sourceField = Schema.sObjectType.Opportunity.fields.getMap().get(urfs.npo02__Source_Field__c);
            if (sourceField == null) {
                isValid = false;
                ctrl.createDR(strSetting, 'Error', 
                    string.format(label.healthDetailsInvalidOppField, new string[]{urfs.npo02__Source_Field__c}), 
                    string.format(label.healthSolutionUDFOppField, new string[]{label.stgNavDonations, label.stgNavUserDefinedRollups}));
            }               
                      
            //check target fields  
            boolean isValidTarget = true;          
            if (urfs.npo02__Object_Name__c == 'Contact'){
                targetField = Schema.sObjectType.Contact.fields.getMap().get(urfs.npo02__Target_Field__c); 
                if (targetField == null) isValidTarget = false;
            }
            else if (urfs.npo02__Object_Name__c == 'Account'){
                targetField = Schema.sObjectType.Account.fields.getMap().get(urfs.npo02__Target_Field__c); 
                if (targetField == null) isValidTarget = false;               
            }
            else if (urfs.npo02__Object_Name__c == 'npo02__Household__c' || urfs.npo02__Object_Name__c == 'npo02__Household__c'){
                targetField = Schema.sObjectType.npo02__household__c.fields.getMap().get(urfs.npo02__Target_Field__c); 
                if (targetField == null) isValidTarget = false;
            }
            else isValidTarget = false;
            
            if (!isValidTarget) {
            	isValid = false;
                ctrl.createDR(strSetting, 'Error', 
                    string.format(label.healthDetailsInvalidObjectField, new string[]{urfs.npo02__Object_Name__c, urfs.npo02__Target_Field__c}), 
                    string.format(label.healthSolutionInvalidUDFObjectField, new string[]{label.stgNavDonations, label.stgNavUserDefinedRollups}));
            }

            //only if the other checks succeed, check displaytypes
            if (isValid) {
                //check Field Types
                Schema.Displaytype dtSrc = UTIL_Describe.getFieldDisplaytype('Opportunity', urfs.npo02__Source_Field__c);
                Schema.Displaytype dtTgt = UTIL_Describe.getFieldDisplaytype(urfs.npo02__Object_Name__c, urfs.npo02__Target_Field__c);
                if (!UTIL_Describe.canDisplaytypesCopy(dtSrc, dtTgt)) { 
                    isValid = false;
                    ctrl.createDR(strSetting, 'Error', 
                        string.format(label.healthDetailsUDFBadDatatypes, new string[]{urfs.npo02__Source_Field__c, urfs.npo02__Object_Name__c, urfs.npo02__Target_Field__c}), 
                        string.format(label.healthSolutionUDFBadDatatypes, new string[]{label.stgNavDonations, label.stgNavUserDefinedRollups}));
                }               
            }
            
            if (!isValid)
                isValidAll = false;            
            
        }    
        if (isValidAll) {
            ctrl.createDR(strSetting, 'Success', null, label.healthLabelUDFValid);                    	
        }
    }           
    
    
    /*** Private Methods **/
        
    //used to render error messages on the VF interface
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
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
        		return UTIL_Describe.getFieldLabelSafe('Opportunity', SourceField);
        	}
        }
        
        public string TargetFieldLabel {
            get {
                return UTIL_Describe.getFieldLabelSafe(TargetObject, TargetField);
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
            	// the udr's name needs to be a valid field alias when we construct the rollup query.
                string strName = 'CR_' + system.Now();
                strName = strName.replace(' ','');
                strName = strName.replace(':',''); 
                strName = strName.replace('-',''); 
                myUDR.Name = strName;
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