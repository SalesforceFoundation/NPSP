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
* @author Nick Bailey 
* @date 2011 (2.1)
* @description Controller for the payment mapping wizard
*/
public with sharing class STG_PanelPaymentMapping_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelPaymentMapping'; }
    
    //controls which types to display
    map<string, Schema.Displaytype> mapFieldTypes = new map<string, Schema.Displaytype>();
        
    //pickers for setting values   
    public list<SelectOption> sourcefields = new list<SelectOption>();
    public list<SelectOption> targetfields = new list<SelectOption>();
           
    //called on load of the page
    public PageReference checkSettings(){
        //if there are invalid rollups defined, display an error 
        if (!paymentMappingsValid()){
            showMsg('INVALID USER SETTINGS DETECTED - Some payment mappings have been disabled',ApexPages.Severity.ERROR);
            showMsg('Custom Payment Field Mappings reference target or source fields which do not exist.  Please update or delete the invalid mappings to re-enable.', ApexPages.Severity.WARNING);
        }       
        return null;
    }

    //reset all instance variable and return to initial screen
    public pageReference cancelPfmEdit() {       
        this.sourcefields.clear();
        this.mapFieldTypes.clear();
        this.targetfields.clear();
        pfmNew = null;
        isEditMode = false;
        return null;
    }
    
    //retrieve possible target fields for the selected object
    public list<SelectOption> getTargetFields(){ 
        
        targetfields.clear();
        set<string> knownfields;    
        map<string, Schema.Sobjectfield> targetTokenMap = new map<string, Schema.Sobjectfield>();
        
        targetTokenMap = Schema.SObjectType.npe01__OppPayment__c.fields.getMap().clone();
        knownfields = new set<string>{
            'npe01__Opportunity__c', 'npe01__Paid__c', 'npe01__Payment_Amount__c', 'npe01__Payment_Date__c',
            'npe01__Written_Off__c'};
        
        //pop out the known fields
        for (string s : knownfields){
            s = s.toLowerCase();
            targetTokenMap.remove(s);
        }
        
        if ((targettokenMap.size() < 75) && (targettokenMap.size() > 0)){
        
            Schema.DisplayType oppType = mapFieldTypes.get(pfmNew.npe01__Opportunity_Field__c);  
            for (string s : targetTokenMap.keyset()){
                if (s.contains('__c')){
			        Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('npe01__OppPayment__c', s);     
                    Schema.DisplayType payType = f.getType();
                    if(payType == oppType){
                        targetfields.add(new SelectOption(f.getName(), f.getLabel()));
                    }                
                }
                
            }
        
        targetfields.sort();
        }
        
        if (targetfields.size() < 1){            
            targetfields.add(new SelectOption(strNoValidField, strNoValidField));
        }
        return targetfields;    
    }
    
    private static string strNoValidField = 'NO VALID FIELD AVAILABLE';
    
    //retrieve valid source fields from opportunity object
    public list<SelectOption> getSourceFields(){
        
        // sets of strings are case sensitive, so use lower case in our set for the contains() against knownopptyFields.
        set<string> knownOpptyFields = new set<string>{'amount', 'closedate', 'expectedrevenue', 
            'probability', 'totalopportunityquantity', 'npe01__membership_start_date__c', 'npe01__membership_end_date__c'};
        
        if (sourcefields.isEmpty()){
                       
            map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap(); 
           
            //loop through the map, only get the describe information for fields we don't
            //already recognize, including our own and non-custom fields, we'll add those in a moment
            for(string fieldName : oppFieldTokenList.keyset()){
                if (fieldname.contains('__c') || knownopptyFields.contains(fieldName)){
                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('Opportunity', fieldname);                         
                    Schema.Displaytype dt = f.getType();
                    sourcefields.add(new SelectOption(f.getName(),f.getLabel()));
                    mapFieldTypes.put(f.getName(), dt);
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

           sourcefields.sort();           
        }
       
        return sourceFields;
    }

    //utility to check that existing user defined rollups are valid - called onpageload
    //NOTE: Only checks that target/source fields exist, not operation validity
    private boolean paymentMappingsValid(){
        boolean isValid = true;
        
        map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappings = npe01__Payment_Field_Mapping_Settings__c.getAll(); 
    
        for (string s : paymentMappings.keySet()){
            npe01__Payment_Field_Mapping_Settings__c pfms = paymentMappings.get(s);
            SobjectField paymentField;
            SobjectField opportunityField;
            
            //check source field
            opportunityField = Schema.sObjectType.Opportunity.fields.getMap().get(pfms.npe01__Opportunity_Field__c);
            if (opportunityField == null) isValid = false;
                      
            //check target fields            
            paymentField = Schema.sObjectType.npe01__OppPayment__c.fields.getMap().get(pfms.npe01__Payment_Field__c);
            if (paymentField == null) isValid = false;
            
            //only if the other checks succeed, get the describe type
            if (isValid == true){
                //check Field Types
                string payF = UTIL_Describe.getFieldType('npe01__OppPayment__c', pfms.npe01__Payment_Field__c);
                string oppF = UTIL_Describe.getFieldType('Opportunity', pfms.npe01__Opportunity_Field__c);
                if (payF != oppF) isValid = false;
            }                
        }    
    
    return isValid;
    }           
        
    //used to render error messages on the VF interface
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }     
    
    public string pfmIdDelete { get; set; }
    public PageReference deletePfm() {
    	STG_SettingsManager_CTRL.idPanelCurrent = idPanel();    	
    	if (pfmIdDelete != null) {
    	   npe01__Payment_Field_Mapping_Settings__c pfm = new npe01__Payment_Field_Mapping_Settings__c(Id = pfmIdDelete);
    	   delete pfm;
    	   // force reload.
    	   STG_Panel.stgService.listPMTFieldMapping = null;
    	   listPMTFieldMapping = null;
    	}
        return null;
    }
    
    public npe01__Payment_Field_Mapping_Settings__c pfmNew {
    	get {
    		if (pfmNew == null) pfmNew = new npe01__Payment_Field_Mapping_Settings__c();
    		return pfmNew;
    	}
    	private set;
    }
    
    public boolean isPfmNewValid {
    	get {
	    	return pfmNew != null &&
	    	   pfmNew.npe01__Opportunity_Field__c != null &&
	    	   pfmNew.npe01__Payment_Field__c != null &&
	    	   pfmNew.npe01__Payment_Field__c != strNoValidField;
    	}
    }
    
    public PageReference newPfm() {
    	isEditMode = true;
    	return null;
    }
    
    public PageReference savePfm() {
        if (!isPfmNewValid) {
            showMsg('No valid Payment field was found for the chosen Opportunity field.', ApexPages.Severity.FATAL);
            return null;                
        }
   
        Try {
	        isEditMode = false;
	        map<string, npe01__Payment_Field_Mapping_Settings__c> paymentMappings = npe01__Payment_Field_Mapping_Settings__c.getAll();
	        	        
	        // make sure we have a unique name
	        integer nameNumber;
	        for (nameNumber = paymentMappings.size(); ; nameNumber++) {
	        	if (paymentMappings.get('CustomMapping' + nameNumber) == null)
	        	  break;
	        }    
            pfmNew.Name = 'CustomMapping' + nameNumber;   
	        
	        insert pfmNew;
	        pfmNew = null;
	        STG_Panel.stgService.listPMTFieldMapping = null;
	        listPMTFieldMapping = null;
	    } catch(Exception e) {
	       ERR_Handler.processError(e, null);	
	       showMsg('An unhandled exception has occurred. Please try again.',ApexPages.Severity.FATAL);
	       showMsg('Exception type' + e, ApexPages.Severity.INFO);            
        }
    	return null;
    }
   
    public PageReference onSelectSourceField() {
        // refresh target fields
        targetfields.clear();    
        return null;    
    }
  
    // we provide our own list so we can replace the dev names with labels
    public list<npe01__Payment_Field_Mapping_Settings__c> listPMTFieldMapping {
        get {
            if (listPMTFieldMapping == null) {
            	listPMTFieldMapping = new list<npe01__Payment_Field_Mapping_Settings__c>();
                for (npe01__Payment_Field_Mapping_Settings__c pfm : STG_Panel.stgService.listPMTFieldMapping) {
                    string strOppField = getFieldLabel('Opportunity', pfm.npe01__Opportunity_Field__c);
                    string strPmtField = getFieldLabel('npe01__OppPayment__c', pfm.npe01__Payment_Field__c);
                    npe01__Payment_Field_Mapping_Settings__c pfm2 = new npe01__Payment_Field_Mapping_Settings__c();
                    pfm2.Id = pfm.Id;
                    pfm2.npe01__Opportunity_Field__c = strOppField;
                    pfm2.npe01__Payment_Field__c = strPmtField;
                    listPMTFieldMapping.add(pfm2);                                   	
                }                
            } 
            return listPMTFieldMapping;           
        }
        private set;     
    }
    
    // cover over describe call to handle fields that no longer exist.
    private string getFieldLabel(string strObj, string strField) {
        try {
            return UTIL_Describe.getFieldLabel(strObj, strField);                	
        } catch (Exception e) {
        	return strField;
        }       
    }
        
}