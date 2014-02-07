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
* @description The controller for the Reciprocal Relationships panel 
*/
public with sharing class STG_PanelRelReciprocal_CTRL extends STG_Panel {
    
    public override string idPanel() { return 'idPanelRelReciprocal'; }
    
    // temporary rl used by the page for creating a new rl.
    public npe4__Relationship_Lookup__c rlNew {
        get {
            if (rlNew == null)
              rlNew = new npe4__Relationship_Lookup__c();
            return rlNew;
        }
        private set;
    }
    
    // action method for going into edit mode (to create a new rl)
    public PageReference newRelLookup() {
        isEditMode = true;
        return null;
    }

    // action method to save the new rl to the database.
    public PageReference createRelLookup() {        
        Savepoint sp = Database.setSavepoint();
        try {
            insert rlNew;
            isEditMode = false;
            listRelLookup = null;
            rlNew = null;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    // action method to cancel out of creating a new rl.
    public PageReference cancelRelLookup() {
        isEditMode = false;
        rlNew = null;
        return null;
    }
    
    // action method and parameter for deleting an existing rl.
    public string rlIdDelete { get; set; }
    public PageReference deleteRl() {
        Savepoint sp = Database.setSavepoint();
        try {
            STG_SettingsManager_CTRL.idPanelCurrent = idPanel();        
            if (rlIdDelete != null) {
                npe4__Relationship_Lookup__c rl = new npe4__Relationship_Lookup__c(Id = rlIdDelete);
                delete rl;
                // force reload.
                listRelLookup = null;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public list<npe4__Relationship_Lookup__c> listRelLookup {
        get {
            if (listRelLookup == null) {
                
                map<string, npe4__Relationship_Lookup__c> mapRL = new map<string, npe4__Relationship_Lookup__c>();
                mapRL = npe4__Relationship_Lookup__c.getAll();
                
	            // Sort them by name
	            list<string> rlNames = new list<string>();
	            rlNames.addAll(mapRL.keySet());
	            rlNames.sort(); 
	            
	            listRelLookup = new list<npe4__Relationship_Lookup__c>();
	            for (string str : rlNames) {
	                listRelLookup.add(mapRL.get(str));
	            }     
            } 
            return listRelLookup;           
        }
        private set;     
    }
    
}