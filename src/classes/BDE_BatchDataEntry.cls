/*
Copyright (c) 2011, salesforce.com foundation, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com foundation. nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
/**
* @author Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
* @date 04/27/2011
* @description base class for the batch data entry, supports all the custom settings you might have.
*/

public with sharing class BDE_BatchDataEntry {

    private String objectName;
    private List<String> entryFieldList;
    private List<String> listFieldList;
    private Boolean saveBatch;
    private String statusMessage;
    private String batchLookupFieldName;
    private Set<String> fieldSet;
    private String queryString;

    private final String SUCCESS = 'Success';
    private final String FAIL = 'Failure: ';
    private final String CREATED_CUSTOM_SETTING = 'You did not have a default custom setting so we are passing one to you in memory';
    private final String DEFAULT_NAME = 'opportunity';
    private final String DEFAULT_ENTRY_FS = 'AccountID,Name,StageName,Amount,CloseDate';
    private final String DEFAULT_LIST_FS = 'AccountID,Name,StageName,Amount,CloseDate';
    private final Boolean DEFAULT_SAVE_BATCH = true;

    public String getObjectName(){return this.objectName;}
    public List<String> getEntryFieldList(){return this.entryFieldList;}
    public List<String> getListFieldList(){return this.listFieldList;}
    public Boolean getSaveBatch(){return this.saveBatch;}
    public String getStatusMessage(){return this.statusMessage;}
    public String getFailureMessage(){return this.FAIL;}
    public String getBatchLookupFieldName() {return this.batchLookupFieldName;}
    public Set<String> getFieldSet(){return this.fieldSet;}
    public String getQueryString(){return this.queryString;}

    public BDE_BatchDataEntry(String pObjectName){
        this.queryString = 'select Id';
        boolean isValidObject=false;

        try{
            if(pObjectName != null){
                try {
                    String s = UTIL_Describe.getObjectLabel(pObjectName);
                    isValidObject=true;
                } catch (exception e) {
                    isValidObject=false;
                    this.statusMessage = this.FAIL + 'You are attempting to perform batch entry on an object that does not exist: ' + pObjectName;
                }
            } else {
            	this.statusMessage = this.SUCCESS;
            }

            if(isValidObject) {
                this.objectName = pObjectName;
                this.saveBatch = true; // DJH: did not port this setting due to lack of use.

                if(this.saveBatch && !checkLookupExists()) {
                    this.statusMessage = this.FAIL + this.objectName + ' does not have a lookup field to the ' + String.valueOf(Batch__c.sObjectType) + ' object. If this is a standard object, you can go to Setup->Customize-><objectname>->Fields to create a lookup field to the Batch. For custom object, please go to Setup->Create->Objects-><objectname> and click \'New\' under the Fields section.';
                } else {
                    this.entryFieldList = UTIL_Describe.listStrFromFieldSet(pObjectName, UTIL_Namespace.StrTokenNSPrefix('BDE_Entry_FS'));
                    if(this.entryFieldList == null) //The original fieldsets for opportunity got deleted by mistake. New name required.
                        this.entryFieldList = UTIL_Describe.listStrFromFieldSet(pObjectName, UTIL_Namespace.StrTokenNSPrefix('BDE_Entry_FS_v2'));

                    this.listFieldList = UTIL_Describe.listStrFromFieldSet(pObjectName, UTIL_Namespace.StrTokenNSPrefix('BDE_List_FS'));
                    if(this.listFieldList == null) //The original fieldsets for opportunity got deleted by mistake. New name required.
                        this.listFieldList = UTIL_Describe.listStrFromFieldSet(pObjectName, UTIL_Namespace.StrTokenNSPrefix('BDE_List_FS_v2'));

                    buildFieldSet();
                    buildQueryString();
					this.statusMessage = this.SUCCESS;
                }
            }
        }catch(Exception e){
            this.statusMessage = this.FAIL + e.getMessage();
        }
    }

    private void buildFieldSet(){
        this.fieldSet = new Set<String>();

        for(String str : this.entryFieldList){
            this.fieldSet.add(str);
        }

        for(String str : this.listFieldList){
            this.fieldSet.add(str);
        }
    }

    private void buildQueryString(){
        if(this.fieldSet != null){
            for(String str : this.fieldSet){
                this.queryString += ', ' + str;
            }
        this.queryString += ' from ' + this.objectName + ' ';
        }
    }

    private boolean checkLookupExists() {
        Map<String, Schema.DescribeFieldResult> allFieldsMap = UTIL_Describe.getAllFieldsDescribe(this.objectName);
        for(Schema.DescribeFieldResult fr: allFieldsMap.values()) {
            if(fr.getType() == Schema.Displaytype.Reference) {
                Schema.sObjectType parent = fr.getReferenceTo()[0];
                if(parent.getDescribe().getName()==String.valueOf(Batch__c.sObjectType)) {
                    batchLookupFieldName = fr.getName();
                    return true;
                }
            }
        }
        return false;
    }

    // return a map of all objects that support Batch Data Entry
    // key is the object devName, value is the object label
    public static map<string, string> mapDevNameToLabelBDEObjects() {
    	//return new string[]{'Opportunity','Contact','Lead','Account'};
    	map<string, string> mapBDE = new map<string, string>();
    	Schema.Describesobjectresult dor = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrTokenNSPrefix('Batch__c'));
    	for (Schema.ChildRelationship cr : dor.getChildRelationships()) {
    		// first see if they have a batch__c field
    		Schema.SObjectField sfld = cr.getField();
    		if (sfld.getDescribe().getLocalName() == 'Batch__c') {
	    		Schema.DescribeSObjectResult dr = cr.getChildSObject().getDescribe();
	            mapBDE.put(dr.getName(), dr.getLabel());
    		}
    	}
    	return mapBDE;
    }
}