/* 
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Settings
* @description The controller for the Relationships panel 
*/
public with sharing class STG_PanelRel_CTRL extends STG_Panel { 

    /*********************************************************************************************************
    * @description Returns the string Id of the Relationships panel. 
    */
    public override string idPanel() { return 'idPanelRel'; }
    
    /*********************************************************************************************************
    * @description The list of SelectOptions for the Gender field 
    */
    public list<SelectOption> listSOGenderFieldOptions {
    	get {
	        if (listSOGenderFieldOptions == null) {
	            listSOGenderFieldOptions = new list<SelectOption>();
	            //add a default option
	            listSOGenderFieldOptions.add(new SelectOption('', Label.stgLabelNone));
	                        
	            map<String, Schema.SObjectField> conFieldTokenList = Schema.SObjectType.Contact.fields.getMap(); 
	           
	            //only get the describe information for custom fields (not from NPSP)
	            for (string fieldName : conFieldTokenList.keyset()) {
	                if (fieldname.endsWith('__c') && !fieldname.startsWith('np')) {
	                    listSOGenderFieldOptions.add(new SelectOption(fieldName, UTIL_Describe.getFieldLabel('Contact', fieldName))); 
	                }               
	            }
	        }               
	        return listSOGenderFieldOptions;
        }
        private set;
    }
    
    /*********************************************************************************************************
    * @description The Gender field's label 
    */
    public string strGenderFieldLabel {
    	get {
    		return getFieldLabel('Contact', STG_Panel.stgService.stgRel.npe4__Gender_Field__c);
    	}
    }

    /*********************************************************************************************************
    * @description The list of SelectOptions for Relationship fields to exclude from sync
    */
    public list<SelectOption> listSOSyncFieldOptions {
        get {
            if (listSOSyncFieldOptions == null) {
                listSOSyncFieldOptions = new list<SelectOption>();
                listSOSyncFieldOptions.add(new SelectOption('', Label.stgLabelNone));             
                map<String, Schema.DescribeFieldResult> relFieldDescMap = UTIL_Describe.getAllFieldsDescribe('npe4__Relationship__c'); 
               
                //only present editable custom fields not from NPSP
                for (string fieldName : relFieldDescMap.keyset()) {
                    if (relFieldDescMap.get(fieldName).isCustom() && !fieldname.startsWith('npe4__')
                        && !relFieldDescMap.get(fieldName).isCalculated() && !relFieldDescMap.get(fieldName).isAutoNumber()) {
                        
                        listSOSyncFieldOptions.add(new SelectOption(fieldName, relFieldDescMap.get(fieldName).getLabel())); 
                    }               
                }
                
                // insert disabled SelectOption if there are no valid fields    
                if (listSOSyncFieldOptions.size() == 1){            
                    listSOSyncFieldOptions.clear();
                    listSOSyncFieldOptions.add(new SelectOption(strNoValidField, strNoValidField, true));
                }
            }               
            return listSOSyncFieldOptions;
        }
        set;
    }
 
    /*********************************************************************************************************
    * @description A localized string to use if there is no valid field
    */
    private static string strNoValidField = System.Label.stgLabelRelationshipSyncNoValidFields;

    
    /*********************************************************************************************************
    * @description A smeicolon-delimited list of field labels exclude from sync for display in read-only 
    */
    public String excludedLabels {
        get {
            if (excludedLabels == null) {
                List<String> excludedLabelList = new List<String>();
                for (string fieldName : new Set<String>(UTIL_ListCustomSettingsFacade.getMapRelationshipFieldSyncSettings().keyset())) {
                    excludedLabelList.add(getFieldLabel('npe4__Relationship__c',fieldName));
                }

                excludedLabels = String.join(excludedLabelList,'; ');
            }
            return excludedLabels;
        }
        set;
    }

    /*********************************************************************************************************
    * @description Set of strings used to hold previous value of listExcludedFields for comparison.
    */
    private Set<String> oldFields {
        get {
            if (oldFields == null) {
                oldFields = new Set<String>(); 
            }
            return oldFields;
        }
        set;
    }

    /*********************************************************************************************************
    * @description The list of string values databound to the multi-select-picklist. 
    */
    public list<string> listExcludedFields {
        get {
            if (listExcludedFields == null) {
                listExcludedFields = new List<String>(UTIL_ListCustomSettingsFacade.getMapRelationshipFieldSyncSettings().keyset());
            }
            return listExcludedFields;
        }
        set {
            oldFields = new Set<String>(listExcludedFields);
            listExcludedFields = value;
        }
    }

    /*******************************************************************************************************
    * @description Override of virtual method from STG_Panel. Creates and/or  deletes Relationship_Sync_Excluded_Fields__c
    * records as needed before saving other settings. 
    * @return void
    */ 
    public override PageReference saveSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        List<Relationship_Sync_Excluded_Fields__c> newFieldRecs = new List<Relationship_Sync_Excluded_Fields__c>();
        List<Relationship_Sync_Excluded_Fields__c> fieldRecsForDelete = new List<Relationship_Sync_Excluded_Fields__c>();        
        
        // if the values changed, then create any new list setting records  
        if (!oldFields.equals(new Set<String>(listExcludedFields))) {
            for (string str : listExcludedFields) {
                if (!oldFields.contains(str) && String.isNotBlank(str)) {
                    newFieldRecs.add(new Relationship_Sync_Excluded_Fields__c(Name = str));
                }
            }
            // delete list settings for any records that had them before but are no longer selected
            oldFields.removeAll(listExcludedFields);
            if (oldFields.size() > 0) {
                fieldRecsForDelete = [SELECT Id, Name FROM Relationship_Sync_Excluded_Fields__c WHERE NAME IN :oldFields];
            } 
        }

        try {
              
            if (newFieldRecs.size() > 0 ) {
                insert newFieldRecs;
            }
            
            if (fieldRecsForDelete.size() > 0 ) {
                delete fieldRecsForDelete;
            }
            
            // null out static variables to force a re-read on next call
            excludedLabels = null;
            UTIL_ListCustomSettingsFacade.mapRelationshipFieldSyncSettings = null;

            stgService.saveAll();
            isEditMode = false;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
        
    }


    /*********************************************************************************************************
    * @description Returns a field's label.  cover over describe call to handle fields that no longer exist.
    * @param strObj The object
    * @param strField The field
    * @return string
    */
    private string getFieldLabel(string strObj, string strField) {
        if (UTIL_Describe.isValidField(strObj, strField)) {
            return UTIL_Describe.getFieldLabel(strObj, strField);
        } else {
            return strField;
        }
    }
        
    
}