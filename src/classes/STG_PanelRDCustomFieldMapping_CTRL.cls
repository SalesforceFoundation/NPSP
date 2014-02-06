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
* @description The controller for the Recurring Donations Custom Field Mapping panel 
*/
public with sharing class STG_PanelRDCustomFieldMapping_CTRL extends STG_Panel {
    
    public override string idPanel() { return 'idPanelRDFieldMap'; }
    
    // temporary fm used by the page for creating a new fm.
    public npe03__Custom_Field_Mapping__c fmNew {
        get {
            if (fmNew == null)
              fmNew = new npe03__Custom_Field_Mapping__c();
            return fmNew;
        }
        private set;
    }
    
    // action method for going into edit mode (to create a new fm)
    public PageReference newCustomFieldMapping() {
        isEditMode = true;
        return null;
    }

    // action method to save the new ci to the database.
    public PageReference createCustomFieldMapping() {  
    	
    	// validate first
    	if (!isValidMapping(fmNew.npe03__Recurring_Donation_Field__c, fmNew.npe03__Opportunity_Field__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, system.label.npe03.RecurringDonationBadFieldMapping));
            return null;    		
    	}      
    	
        Savepoint sp = Database.setSavepoint();
        try {
        	fmNew.Name = 'FieldMapping-' + system.now();
            insert fmNew;
            isEditMode = false;
            STG_Panel.stgService.listRDCustomFieldMapping = null;
            listRDCustomFieldMapping = null;
            fmNew = null;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    //checks the compatibility of a recurring donation and opp field
    private boolean isValidMapping(string RDField, string OppField){
        boolean isValid = false;
        
        Schema.Sobjectfield schemaRDField = schema.SObjectType.npe03__Recurring_Donation__c.fields.getMap().get(RDField);
        Schema.Sobjectfield schemaOppField = schema.SobjectType.Opportunity.fields.getMap().get(OppField);
        
        if (schemaRDField != null && schemaOppField != null) {
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

    // action method to cancel out of creating a new fm.
    public PageReference cancelCustomFieldMapping() {
        isEditMode = false;
        fmNew = null;
        return null;
    }
    
    // action method and parameter for deleting an existing fm.
    public string fmIdDelete { get; set; }
    public PageReference deleteFm() {
        Savepoint sp = Database.setSavepoint(); 
        try {
            STG_SettingsManager_CTRL.idPanelCurrent = idPanel();        
            if (fmIdDelete != null) {
                npe03__Custom_Field_Mapping__c fm = new npe03__Custom_Field_Mapping__c(Id = fmIdDelete);
                delete fm;
                // force reload.
                STG_Panel.stgService.listRDCustomFieldMapping = null;
                listRDCustomFieldMapping = null;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, null);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    // we provide our own list so we can replace the dev names with labels
    public list<npe03__Custom_Field_Mapping__c> listRDCustomFieldMapping {
        get {
            if (listRDCustomFieldMapping == null) {
                listRDCustomFieldMapping = new list<npe03__Custom_Field_Mapping__c>();
                for (npe03__Custom_Field_Mapping__c fm : STG_Panel.stgService.listRDCustomFieldMapping) {
                    string strOppField = getFieldLabel('Opportunity', fm.npe03__Opportunity_Field__c);
                    string strRDField = getFieldLabel('npe03__Recurring_Donation__c', fm.npe03__Recurring_Donation_Field__c);
                    npe03__Custom_Field_Mapping__c fm2 = new npe03__Custom_Field_Mapping__c();
                    fm2.Id = fm.Id;
                    fm2.npe03__Opportunity_Field__c = strOppField;
                    fm2.npe03__Recurring_Donation_Field__c = strRDField;
                    listRDCustomFieldMapping.add(fm2);                                      
                }                
            } 
            return listRDCustomFieldMapping;           
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
        
    //invalid fields for opp mappings
    static set<string> setInvalidOppFields = new set<string>{'accountid', 'amount', 'campaignid', 'closedate', 'createdbyid', 
                                                   'createddate', 'fiscal', 'fiscalquarter', 'fiscalyear', 'forecastcategory', 
                                                   'stagename', 'npe03__recurring_donation__c', 'forecastcategoryname',
                                                   'forecastname', 'hasopportunitylineitem', 'id', 'isclosed', 'isdeleted', 'isprivate', 
                                                   'iswon', 'lastactivitydate', 'lastmodifiedbyid', 'lastmodifieddate', 'recordtypeid', 
                                                   'systemmodstamp', 'totalopportunityquantity'};        

    static public list<SelectOption> listSOOppFields {
        get {
            if (listSOOppFields == null) {
                listSOOppFields = new list<SelectOption>();
                listSOOppFields.add(new SelectOption('','- none -'));
            
                // filter out opp fields already used
	            for (npe03__Custom_Field_Mapping__c fm : STG_Panel.stgService.listRDCustomFieldMapping) {   
	                setInvalidOppFields.add(fm.npe03__Opportunity_Field__c);   
	            }                 

                map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.Opportunity.fields.getMap(); 
                for (string fieldName : oppFieldTokenList.keyset()) {                	
                	if (!setInvalidOppFields.contains(fieldName)) {                	
	                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('Opportunity', fieldname);
	                    listSOOppFields.add(new SelectOption(f.getName(), f.getLabel()));
                	}
                }
                listSOOppFields.sort();
            }
            return listSOOppFields;
        }
        private set;
    }

    static public list<SelectOption> listSORDFields {
        get {
            if (listSORDFields == null) {
                listSORDFields = new list<SelectOption>();
                listSORDFields.add(new SelectOption('','- none -'));

                map<String, Schema.SObjectField> oppFieldTokenList = Schema.SObjectType.npe03__Recurring_Donation__c.fields.getMap(); 
                for (string fieldName : oppFieldTokenList.keyset()) {
                    Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', fieldname);                         
                    listSORDFields.add(new SelectOption(f.getName(), f.getLabel()));
                }
                listSORDFields.sort();
            }
            return listSORDFields;
        }
        private set;
    }


}