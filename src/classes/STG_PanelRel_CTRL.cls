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
    * @description The list of SelectOptions for Relationship fields to sync
    */
    public list<SelectOption> listSOSyncFieldOptions {
        get {
            if (listSOSyncFieldOptions == null) {
                listSOSyncFieldOptions = new list<SelectOption>();
                             
                map<String, Schema.SObjectField> relFieldTokenList = Schema.SObjectType.npe4__Relationship__c.fields.getMap(); 
               
                //only get the describe information for custom fields (not from NPSP)
                for (string fieldName : relFieldTokenList.keyset()) {
                    if (fieldname.endsWith('__c') && !fieldname.startsWith('np')) {
                        
                        // disallow formula fields and autonums
                        Schema.DescribeFieldResult f = UTIL_Describe.getFieldDescribe('npe4__Relationship__c', fieldName);
                        if (f.isCalculated() || f.isAutoNumber()) {
                            continue;
                        }

                        listSOSyncFieldOptions.add(new SelectOption(fieldName, UTIL_Describe.getFieldLabel('npe4__Relationship__c', fieldName))); 
                    }               
                }
                
                // insert disabled SelectOption if there are no valid fields    
                if (listSOSyncFieldOptions.size() < 1){            
                    listSOSyncFieldOptions.add(new SelectOption(strNoValidField, strNoValidField, true));
                }
            }               
            System.debug('Select opts: ' + listSOSyncFieldOptions);
            return listSOSyncFieldOptions;
        }
        private set;
    }
 
    /*********************************************************************************************************
    * @description A localized string to use if there is no valid field
    */
    private static string strNoValidField = System.Label.stgLabelRelationshipSyncNoValidFields;

    /*********************************************************************************************************
    * @description The list of strings values databound to the object's field.  Setting this list will
    * save those values into the object's field.
    */
    public list<string> listExcludedFields {
        get {
            if (listExcludedFields == null) {
                //listStrValues = strValues.split(';',0);
                listExcludedFields = new List<String>();
                List<Relationship_Sync_Excluded_Fields__c> listRecs = [SELECT Name, Field_Name__c FROM Relationship_Sync_Excluded_Fields__c];
                if (listRecs.size() > 0) {
                    for (Relationship_Sync_Excluded_Fields__c f : listRecs) {
                        listExcludedFields.add(f.Field_Name__c);
                    }    
                } 
            }
            //have to make the setting record lower case
            System.debug('Excluded fields: ' + listExcludedFields);
            return listExcludedFields;
        }
        set {
            /* listStrValues = value;
            strValues = '';
            for (string str : listStrValues) {
                strValues += str + ';';
            }
            if (strValues != '')
                strValues = strValues.left(strValues.length()-1);
            sobjBinding.put(strField, strValues);   */
        }
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