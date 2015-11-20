/* 
    Copyright (c) 2015, Salesforce.com Foundation
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
* @date 2015
* @group Settings
* @description The controller for the Reciprocal Associations panel 
*/
public with sharing class STG_PanelAssocReciprocal_CTRL extends STG_Panel {
    
    /*********************************************************************************************************
    * @description Returns the string Id of the Reciprocal Associations panel. 
    */
    public override string idPanel() { return 'idPanelAssocReciprocal'; }
    
    /*********************************************************************************************************
    * @description temporary rl used by the page for creating a new rl.
    */
    public Reciprocal_Account_Association_Types__c aNew {
        get {
            if (aNew == null)
              aNew = new Reciprocal_Account_Association_Types__c();
            return aNew;
        }
        private set;
    }
    
    /*********************************************************************************************************
    * @description Action Method for going into edit mode (to create a new record)
    * @return null
    */
    public PageReference newAssocLookup() {
        isEditMode = true;
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to save the new setting to the database.  Any errors are added as page messages.
    * @return null
    */
    public PageReference createAssocLookup() {        
        Savepoint sp = Database.setSavepoint();
        try {
            insert aNew;
            isEditMode = false;
            listAssocLookup = null;
            aNew = null;
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to cancel out of creating a new setting.
    * @return null
    */
    public PageReference cancelAssocLookup() {
        isEditMode = false;
        aNew = null;
        return null;
    }
    
    /*********************************************************************************************************
    * @description String to hold the Id of an existing setting to be deleted. 
    */
    public string assocIdDelete { get; set; }

    /*********************************************************************************************************
    * @description Action Method for deleting an existing setting.
    * @return null
    */
    public PageReference deleteAssocLookup() {
        Savepoint sp = Database.setSavepoint();
        try {
            STG_SettingsManager_CTRL.idPanelCurrent = idPanel();        
            if (assocIdDelete != null) {
                Reciprocal_Account_Association_Types__c a = new Reciprocal_Account_Association_Types__c(Id = assocIdDelete);
                delete a;
                // force reload.
                listAssocLookup = null;
            }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*********************************************************************************************************
    * @description The list of Relationship Lookup records
    */
    public list<Reciprocal_Account_Association_Types__c> listAssocLookup {
        get {
            if (listAssocLookup == null) {
                
                map<string, Reciprocal_Account_Association_Types__c> mapA = Reciprocal_Account_Association_Types__c.getAll();
                
	            // Sort them by name
	            list<string> aNames = new list<string>();
	            aNames.addAll(mapA.keySet());
	            aNames.sort(); 
	            
	            listAssocLookup = new list<Reciprocal_Account_Association_Types__c>();
	            for (string str : aNames) {
	                listAssocLookup.add(mapA.get(str));
	            }     
            } 
            return listAssocLookup;
        }
        private set;     
    }
    
}