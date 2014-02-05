/* 
    Copyright (c) 2014, Salesforce.com Foundation
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
* @date 2014
* @description The controller for the Error Log panel 
*/
public with sharing class STG_PanelErrorLog_CTRL extends STG_Panel implements UTIL_iSoqlListViewConsumer  { 
	
    private UTIL_SoqlListView_CTRL ctrlSoqlListView;
	
    public void setComponentController(UTIL_SoqlListView_CTRL compController){
    	if (ctrlSoqlListView == null) {
	        ctrlSoqlListView = compController;
	        ctrlSoqlListView.sortItemField = 'Datetime__c';
	        ctrlSoqlListView.SortItemAsc = false;
	        ctrlSoqlListView.showCheckboxes = false;
    	}
    }

    public string getStrSoql() {    
        string strSoql = 'select Id, Context_Type__c, Datetime__c, Error_Type__c, Full_Message__c, ' +
                    ' Module_Type__c, Object_Type__c, Record_URL__c, Stack_Trace__c, CreatedBy.Name from Error__c ';
        if (ctrlSoqlListView.strAlphaFilter != null && ctrlSoqlListView.sortItemField != 'Datetime__c' && ctrlSoqlListView.strAlphaFilter != '%') {
            strSoql += ' Where ' + ctrlSoqlListView.sortItemField + ' like \'' + ctrlSoqlListView.strAlphaFilter + '%\'';
        } 
        // SoqlListView adds the order by clause.
                                      
        return strSoql;         
    }
    public list<string> getstrFields()
        { 
    	   return new list<string> { 'Context_Type__c', 'Datetime__c', 'Error_Type__c', 'Full_Message__c', 
                    'Module_Type__c', 'Object_Type__c', 'Record_URL__c', 'Stack_Trace__c' };  // can't include  ', CreatedBy.Name'  unfortunately!
        } 
    
    public string getstrNameField(){ return 'Datetime__c';  }
    
    public string getstrObjectType() { return 'Error__c';  }

    public PageReference NewItem(){ return null;  }
    
    public PageReference EditItem(ID idItem) {
        return new PageReference('/' + idItem + '/e?retURL=' + ApexPages.currentPage().getURL());
    }   
	
	public UTIL_iSoqlListViewConsumer getslvConsumer() { return this; }
    
    public override string idPanel() { return 'idPanelErrorLog'; }

/****************************************    
    public list<Error__c> listError {
        get {
            if (listError == null) {
                listError = new list<Error__c>();
                listError = [select Id, Context_Type__c, Datetime__c, Error_Type__c, Full_Message__c, 
                    Module_Type__c, Object_Type__c, Record_URL__c, Stack_Trace__c, CreatedBy.Name from Error__c order by Datetime__c desc limit 50];
            } 
            return listError;           
        }
        private set;     
    }
    
    public boolean hasErrors {
    	get {
    		return listError.size() > 0;
    	}
    }
**************************************/

    public PageReference clearErrorLog() {
    	delete [select Id from Error__c];
    	//listError = null;
    	ctrlSoqlListView.setCon = null;
    	return null;
    }
  
}