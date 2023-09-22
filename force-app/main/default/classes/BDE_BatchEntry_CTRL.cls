/*
    Copyright (c) 2015 Salesforce.org
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
* @author Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
* @date 04/27/2011
* @group BatchDataEntry
* @description controller for the batch entry page.
*/
public with sharing class BDE_BatchEntry_CTRL {
    /** @description Batch record being modified or created. */
    public batch__c batch { get; set; }
    /** @description Set to true if batch section should be displayed. */
    public boolean displayBatchSection { get; set; }   // could be transient?
    /** @description Set to true if record info section should be displayed. */
    public boolean displayRecInfoSection { get; set; }     // could be transient?
    /** @description Set to true if settings section should be displayed. */
    public boolean displaySettingsSection { get; set; }     // could be transient?
    /** @description List of all objects that support Batch Data Entry. */
    public List<SelectOption> objectSettingsList { get; private set; }
    /** @description Represents the current batch item being created or edited. */
    public BatchItem currentItem { get; set; }   // could be transient - already getting it on edit, otherwise should be clear (what about errors?)
    /** @description List of related batch items. */
    public list<BatchItem> itemList { get; set; }   // could be transient - would need list of ids instead
    /** @description Object for batch data entry. */
    public string objname { get; set; } // could get all this every time, but not a lot of viewstate
    /** @description The field that is a lookup to the batch object on the selected object. */
    public string batchLookupField { get; private set; }
    /** @description Dynamically set page subtitle. */
    public string pageSubtitle { get; private set; }
    /** @description Fields to include for batch data entry, based on entry field set. */
    public list<EntryField> entryFieldList { get; private set; }
    /** @description Fields to list for batch data entry, based on list field set. */
    public list<string> listFieldList { get; private set; }
    /** @description Batch data entry custom settings. */
    public Batch_Data_Entry_Settings__c bdec {get; set;}
    /** @description Total number of items in the related items list. */
    public integer itemCount { get { return (itemList != null) ? itemList.size() : 0; } }
    /** @description Opportunity Id mapped to the Primary Opportunity Contact Role. */
    public map<id, OpportunityContactRole> ocrlookup;

    /*******************************************************************************************************
    * @description constructor for the page
    * @param controller the StandardController for the page
    * @return nothing
    */ 
    public BDE_BatchEntry_CTRL(ApexPages.StandardController stdController) {
            
        if (stdController.getId() == null)
            batch = new Batch__c();
        
        //query dynamically to retrieve any custom fields from the field set
        else{
        /*  batch = [select SystemModstamp, OwnerId, Object_Name__c, 
                    Number_of_Items__c, Name, LastModifiedDate, 
                    LastModifiedById, IsDeleted, Id, Description__c,
                    CreatedDate, CreatedById, Batch_Status__c  
                    from batch__c where id =: stdController.getId()]; */
            
            String q = 'select ';
            Map<String, Schema.SObjectField> batchObjMap = schema.SObjectType.Batch__c.fields.getMap();
            List<Schema.SObjectField> batchFldList = batchObjMap.values();
                                        
            for(Schema.SObjectField s : batchFldList){
                q += s.getDescribe().getName() + ', ';   
            }

            q = q.subString(0, q.length() - 2);
            UTIL_Debug.debug('Q IS: ' + q);
            q += ' from ' + UTIL_Namespace.StrTokenNSPrefix('Batch__c') + ' where id = \'' + stdController.getId() + '\' limit 1';
            batch = Database.query(q);        
        }
                            
        if (batch.id != null) {
            objName = batch.object_name__c;
        } else {
            string param = ApexPages.currentPage().getParameters().get('obj');
            if (!string.isBlank(param))
                objName = string.escapeSingleQuotes(param);
        } 
    }
    /*********************************************************************************************************
    * @description Initializes the batch data entry page
    * @return void
    */
    public void initializeBatchEntry(){
        BDE_BatchDataEntry bde = new BDE_BatchDataEntry(objname);
        if (!bde.getStatusMessage().contains(bde.getFailureMessage())){
            objname = bde.getObjectName();
            if(objname!=null) {
                String pluralName = UTIL_Describe.getObjectDescribe(objname).getLabelPlural();
                pageSubtitle = pluralName;
            }
            else{
                pageSubtitle = 'Batch Data Entry Home';
            }
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, bde.getStatusMessage()));
        }
    }

    private void requeryItem(BatchItem item)  {
    
        BDE_BatchDataEntry bde = new BDE_BatchDataEntry(objname);                          
        string q = bde.getQueryString();
        q += ' where Id=' +  '\'' + item.sobj.id + '\'';
        list<sobject> existingsobjs = database.query(q);
        if (existingsobjs.size() > 0) {
            item.sobj = existingsobjs[0];
        } 
    } 
    
    /********** CLASSES ****************/

    /*********************************************************************************************************
    * @description Entry Field Class
    */ 
    public class EntryField {
            public string fieldName { get; private set; }
            public string fieldLabel { get; private set; }
                    
            public entryField(string obj, string fld) {
                fieldName = fld;
                fieldLabel = UTIL_Describe.getFieldLabel(obj, fld);
                if(fieldName.toUpperCase().endsWith('ID') && fieldLabel.toUpperCase().endsWith('ID'))     
                    fieldLabel=fieldLabel.substring(0, fieldLabel.length()-2);               
            }
    }
    /*
    public class BatchObject{
        public Batch__c myBatch{get; set;}
        BDE_BatchEntry_CTRL mydad;
        
        public BatchObject(BDE_BatchEntry_CTRL parentClass, Batch__c theBatch){
            mydad = parentClass;
            myBatch = theBatch;
        }
        
        public pageReference loadBatch(){
            
            mydad.batch = myBatch;
            string objname = myBatch.Object_Name__c;
            string myid = myBatch.id;
            PageReference pageRef = Page.BDE_BatchEntry;
            pageRef.getParameters().put('id', myid);
            pageRef.setRedirect(true);
            return pageRef;         
        }
    } */
    /*********************************************************************************************************
    * @description Batch Item Class
    */        
    public class BatchItem {
            
            BDE_BatchEntry_CTRL mydad;
            public integer itemNum { get; private set; }
            public sobject sobj { get; set; }
            public boolean renderNPSPContact{get; set;} 
            
            //empty object for using the 
            //ocr ContactID lookup field for NPSP donations
            public OpportunityContactRole npspocr {get; set;}
          
            
                            
            public BatchItem(BDE_BatchEntry_CTRL parentClass) {
                    mydad = parentClass;       
                    sobj = UTIL_Describe.getPrototypeObject(mydad.objname); //this line needs to be outside the check for displayBatchSection or we get an error on page load for any object where !displayBatchSection          
                    renderNPSPContact = false;
                    if (mydad.displayBatchSection) {
                        sobj.put(mydad.batchLookupField, parentClass.batch.id);
                    }
                    
                    //generate a 'dummy' ocr for npsp donation entry
                    if (mydad.objname == 'opportunity'){
                        npspocr = new OpportunityContactRole();
                        renderNPSPContact = true;
                    }                        
            }
            
            public BatchItem(BDE_BatchEntry_CTRL parentClass, sobject existingItem) {
                mydad = parentClass;
                sobj = existingItem;
                renderNPSPContact = false;
                //get the actual primary ocr for this npsp opp
                if(sobj.getSObjectType() == Opportunity.Sobjecttype && mydad.ocrlookup != null){
                    npspocr = mydad.ocrlookup.get(sobj.id);
                    renderNPSPContact = true;
                }                                                
            }
            
            public pageReference editItem() {
                // load this item into data entry section
                myDad.currentItem = this;
                return null;
            }

            //automatic donation naming 
            public string createName(){
                string namestring = '';
                
                //if we have an NPSP Contact, start there, else, use the account name
                if (npspocr != null && npspocr.ContactID != null){
                    namestring += [select Name from Contact where id = :npspocr.ContactID].Name;
                }
                else{
                    id accid = (id)sobj.get('AccountID');
                    if (accid != null){
                       namestring += [select Name from Account where id = :accid].Name;
                    }
                }
                
                date oppdate = (date)sobj.get('CloseDate');
                namestring += ' ' + oppdate.format();
                
                if (sobj.get('RecordTypeID') != null){
                    id recid = (id)sobj.get('RecordTypeID');
                    namestring += ' ' + [select Name from RecordType where id = :recid].Name;
                }
                                                        
                return namestring; 
            }
    }
    
    /***** OTHER CONTROLLER METHODS ******/


    /*******************************************************************************************************
    * @description actionMethod to clear the current batch item
    * @return null
    */
    public pageReference clear() {
            currentItem = new BatchItem(this);
            return null;
    }

    /*******************************************************************************************************
    * @description actionMethod to open the batch entry page with selected object
    * @return pageReference (Batch Entry Page)
    */
    public pageReference openBatchEnterPage() {
        PageReference pageRef = Page.BDE_BatchEntry;
        pageRef.getParameters().put('obj', objName);
        pageRef.setRedirect(true);
        return pageRef;         
    }

   /*********************************************************************************************************
    * @description Retrieves the namespace string for the visualforce page
     * @return {String}
     */
    public String getNamespace() {
        return UTIL_Namespace.getComponentNamespace();
    }

   /*********************************************************************************************************
   * @description Method that retrieves the batch data entry custom setting based on the currently logged in
    * user
   * @return Batch_Data_Entry_Settings__c
   */
   @AuraEnabled
   public static Batch_Data_Entry_Settings__c getBatchDataEntrySettings () {
      Batch_Data_Entry_Settings__c settings = Batch_Data_Entry_Settings__c.getInstance(UserInfo.getUserId());
      return settings;
   }

   /*********************************************************************************************************
    * @description Method that upserts the retirement alert custom setting if the alert
    * gets dismissed
    * @param hasViewedAlert Flag that indicates the alert dismissal
    */
   @AuraEnabled
   public static void upsertRetirementAlert (Boolean hasViewedAlert) {
      Batch_Data_Entry_Settings__c settings = getBatchDataEntrySettings();
      if (!settings.Viewed_Retirement_Alert__c) {
         settings.Viewed_Retirement_Alert__c = hasViewedAlert;
         upsert settings;
      }
   }

}