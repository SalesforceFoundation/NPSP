/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020 (2.x)
* @description Controller for the NPSP DRS contact merge page.
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/

public with sharing class CON_DRSContactMerge_CTRL extends CON_ContactMerge_UTIL {
      
    /*******************************************************************************************************
    * @description To decide whether to show Dupliacate Record Set record list on the page or not
    */ 
    
    public Boolean showDRS { get; set; }
    
    /*******************************************************************************************************
    * @description The contact merge step user is in. (The process has multiple steps.)
    */
    public Integer step { get; private set; }
    
    /*******************************************************************************************************
    * @description Duplicate Record Sets to be displayed on page
    */ 
    public List<DuplicateRecordSet> listDuplicateRecordSets { get; set; }
    
    /*******************************************************************************************************
    * @description List of ContactWrapper objects for display in search results pane.
    */
    public List<ContactWrapper> contactResults { get; private set; }

    /*******************************************************************************************************
     * @description To store the selected DRS recordId 
     */
    public String drsRecordId { get; set; }

    /*******************************************************************************************************
    * @description The rows to merge.
    */ 
    public List<FieldRow> fieldRows { get; set; }
    
    /*******************************************************************************************************
    * @description Custom setting for Query limit for DRS records query to be displayed
    */ 
    
    private Contact_Merge_Page_Settings__c conMergeSetting;

    /*******************************************************************************************************
    * @description Query limit for DRS records query to be displayed
    */ 
    
    private Integer soqlLimit;

    /*******************************************************************************************************
    * @description Standard set controller variables
    */ 
    public ApexPages.StandardSetController stdSetCon {
       get {
           if(stdSetCon == null){ 
               stdSetCon = new ApexPages.StandardSetController
                   (Database.getQueryLocator(constructDRSSOQL())); 
               stdSetCon.setPageSize(pageSize);    
           }
           return stdSetCon;
       }
       set;
    }
    
    /*******************************************************************************************************
    * @description List of DRS fields that need to be displayed on DRS list page
    */
    private List<String> drsFieldNames {
        get {
            if (drsFieldNames == null) {
                drsFieldNames = UTIL_Describe.listStrFromFieldSet
                                        ('DuplicateRecordSet', 
                                        UTIL_Namespace.StrTokenNSPrefix('ContactMergeDRS'));
                Set<String> setStr = new Set<String>(drsfieldNames);
                // now add additional fields we know we need
                setStr.add('Id');
                setStr.add('Name');
                setStr.add('DuplicateRuleId');
                setStr.add('RecordCount');
                setStr.add('LastModifiedDate');
                drsFieldNames.clear();
                drsFieldNames.addAll(setStr);
            }
            return drsFieldNames;
        }
        set;
    }
    
    /*******************************************************************************************************
    * @description List of DRI fields to be queried
    */
    private List<String> driFieldNames {
        get {
            if (driFieldNames == null) {
                driFieldNames = new List<String>();
                driFieldNames.add('RecordId');
            }
            return driFieldNames;
        }
        set;
    }
    /*******************************************************************************************************
    * @description The list of contact field names that are used to display on page.
    */
    private list<string> listStrContactField {
        get {
            if (listStrContactField == null) {
                listStrContactField = UTIL_Describe.listStrFromFieldSet('Contact', 
                    UTIL_Namespace.StrTokenNSPrefix('ContactMergeFoundFS'));
                set<string> setStr = new set<string>(listStrContactField);
                // now add additional fields we know we need
                setStr.add('Id');
                setStr.add('Name');
                listStrContactField.clear();
                listStrContactField.addAll(setStr);
            }
            return listStrContactField;
        }
        set;
    }
    /*******************************************************************************************************
    * @description To decide whether to continue with Contact merge page depending on permissions 
    * for contact object
    */
    public Boolean canContinueWithMerge { get; set; }
    
    /*******************************************************************************************************
    * @description Check whether user has delete permission on Contact
    *@return Boolean Whether user has contact delete permission
    */

    public Boolean hasContactObjectDeletePermission() {
        return UTIL_Describe.getObjectDescribe('Contact').isDeletable();
    }
    
    
    /*******************************************************************************************************
    * @description To decide whether to continue with DRS display page depending on permissions for 
    * Duplicate Reccord Set object
    */
    public Boolean canContinueWithDRSDisplay { get; set; }
    
       
    /*******************************************************************************************************
    * @description Duplicate Record Set diplay page size.
    */
    private Integer pageSize = 10;
    
    /*******************************************************************************************************
    * @description Total number of pages in pagination implemented on Duplicate Record Set 
    * diplay page.
    */
    public Integer totalPages { get; set; }
    
    /*******************************************************************************************************
    * @description First Contact created for each DRS
    */
    public Map<Id,Contact> firstContactOfDRS { get; set; }

            
    /***************************************************************************************************
    * @description Checks whether there are more records to display on next page in pagination  
    * implemented on Duplicate Record Set diplay page.
    */
    
    public Boolean hasNext {
        get {
            return stdSetCon.getHasNext();
        }
        set;
    }
    
    /***************************************************************************************************
    * @description Checks whether there are records prior to the records dislayed on the current  
    * page to be display on the previous page in pagination implemented on Duplicate Record Set 
    * diplay page.
    */
    
    public Boolean hasPrevious {
        get {
            return stdSetCon.getHasPrevious();
        }
        set;
    }
    
    /***************************************************************************************************
    * @description Page number of the current page
    */
    
    public Integer pageNumber {
        get {
            return stdSetCon.getPageNumber();
            }
        set;
    } 
      
    /*******************************************************************************************************
    * @description Constructor for StandardSetController to allow invocation from list views.
    * @param controller The default list controller for Duplicate Record Sets. 
    * It allows us to do pagination on the page.
    */
    public CON_DRSContactMerge_CTRL (ApexPages.StandardSetController controller) {
        showDRS = false;
        totalPages  = 0;
        canContinueWithMerge = true;
        canContinueWithDRSDisplay = true;
        listDuplicateRecordSets = new List<DuplicateRecordSet>();
        contactResults = new List<ContactWrapper>();
        step = 1;
        fieldRows = new List<FieldRow>();
        firstContactOfDRS = new Map<Id,Contact>();
        // Check if user has delete permission on Contact
        if (!hasContactObjectDeletePermission()) {
            canContinueWithMerge = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                System.Label.conMergeErrorNoDeleteObjPermission));
            return;
        }
        //fetch DRS query limit from Contact Merge Setting custom setting
        conMergeSetting = Contact_Merge_Page_Settings__c.getInstance();
        if(conMergeSetting.DRS_count_for_contact_merge_page__c == null) {
            soqlLimit = 5000;
        } else {
            soqlLimit = (Integer)conMergeSetting.DRS_count_for_contact_merge_page__c;
        }
    }

    /*******************************************************************************************************
    * @description Redirects to the NPSP Contact Merge page
    * @return PageReference The page that it redirects to CON_ContactMerge page.
    */
    public PageReference searchByContact() {
        try {
            PageReference pageRef = new PageReference('/apex/CON_ContactMerge');
            pageRef.getParameters().put('showContactSearch','true');
            pageRef.setRedirect(true);
            return pageRef;
                  
        } catch (exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }
    
    /******************************************************************************************************
     * @description Fetches the list of Duplicate Record Sets from standard set controller 
     * for pagination
     * @return List<DuplicateRecordSet> Returns the current list of Duplicate Record Sets
     */
    public List<DuplicateRecordSet> getDuplicateRecordSets() {
        return (List<DuplicateRecordSet>)stdSetCon.getRecords();
    }
    
    /*******************************************************************************************************
    * @description Shows list of Duplicate Record Set records related to contact dupliacte rules
    */
    public void showDuplicateRecordSets() {
        try {
            showDRS = true;
            listDuplicateRecordSets = getDuplicateRecordSets();
            driFieldNames.add('DuplicateRecordSetId');
            System.debug(constructDRSSOQL());
            List<DuplicateRecordSet> duplicateRecordSets = new List<DuplicateRecordSet>(
                (List<DuplicateRecordSet>)Database.query(constructDRSSOQL()));
            driFieldNames.remove(driFieldNames.indexOf('DuplicateRecordSetId'));
            //Fetch the ids of all Duplicate Record Items
            Set<Id> allDRIIds = new Set<Id>();
            List<DuplicateRecordItem> allDRIs = new List<DuplicateRecordItem>();
            for (DuplicateRecordSet dupRecSet : duplicateRecordSets) {
                allDRIIds.addAll(new Map<Id, DuplicateRecordItem>(
                    dupRecSet.DuplicateRecordItems).keySet());
                allDRIs.addAll(new Map<Id, DuplicateRecordItem>(
                    dupRecSet.DuplicateRecordItems).values());
            }
            //Fetch the remaining query row limit to ensure that the page will not 
            //break due to too many query rows error.
            if ((Limits.getLimitQueryRows() -  Limits.getQueryRows()) < allDRIIds.size()) {
                ApexPages.addMessage(new ApexPages.Message
                    (ApexPages.Severity.Error, Label.conMergeTooManyContactError));
                step = 0;
                return;
            }
            // Construct query to fetch all the related contact records 
            // to find the first contact related to the DRS record
            List<String> contactField = new List<String>();
            contactField.add('Id');
            contactField.add('Name');
            contactField.add('createdDate');
             
            String whereString = new UTIL_Query()
                .withFrom('DuplicateRecordItem')
                .withSelectFields(driFieldNames)
                .withWhere('Id IN :allDRIIds')
                .build();
            whereString = 'Id IN (' + whereString + ')'; 
            String contactQueryStr =  new UTIL_Query()
                .withFrom('Contact')
                .withSelectFields(contactField)
                .withWhere(whereString)
                .build();
            Map<Id,Contact> contacts = new Map<Id,Contact>(
                (List<Contact>)Database.query(contactQueryStr));
            for (DuplicateRecordItem dri : allDRIs) {
                Contact con = contacts.get(dri.RecordId);
                if (!(firstContactOfDRS.containsKey(dri.DuplicateRecordSetId))) {
                    firstContactOfDRS.put(dri.DuplicateRecordSetId,con);
                } else {
                    if (con.createdDate < 
                        firstContactOfDRS.get(dri.DuplicateRecordSetId).createdDate) {
                        firstContactOfDRS.put(dri.DuplicateRecordSetId,con);
                    }
                }
            }
            totalPages = getTotalPages(); 
        } catch (exception ex) {
                ApexPages.addMessage(new ApexPages.Message
                    (ApexPages.Severity.Error, ex.getMessage()));
        }
    }
    
    /*******************************************************************************************************
    * @description Construct SOQL query to fetch all the contact related Duplicate Record Sets
    * @return String Returns the query to fetch Duplicate Record Sets
    */
    public String constructDRSSOQL() {
        //build SOQL subquery on Duplicate Record Items
        String subQueryOrderBy = 'CreatedDate ASC';
        
        String subQuery =  new UTIL_Query()
            .withFrom('DuplicateRecordItems')
            .withSelectFields(driFieldNames)                                  
            .build();
        String subQueryStr = '('+subQuery+')';
        drsFieldNames.add(subQueryStr);
        String setOrderBy = 'LastModifiedDate DESC ';
        String setWhereClause = 'RecordCount > 1 AND DuplicateRule.SObjectType = \'Contact\'';
        //build the SOQL query and execute
        String queryStr =  new UTIL_Query()
            .withFrom(DuplicateRecordSet.sObjectType)
            .withSelectFields(drsFieldNames)
            .withWhere(setWhereClause)
            .withOrderBy(setOrderBy)
            .withLimit(soqlLimit)
            .build();
        drsFieldNames.remove(drsFieldNames.indexOf(subQueryStr));
        return queryStr;
    }
    
    /*******************************************************************************************************
    * @description Shows list of Contact records related to selected Duplicate Record Set
    */
    public PageReference showContactRelatedToDRS() {
        //logic to display contacts related to selected DRS
        try {
            step = 2;
            this.contactResults = wrapQueryResults(queryRecords());
        } catch (exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }

    /******************************************************************************************************
    * @description This will query the duplicate contacts related to the DRS which is picked
    * @return the list of contacts
    */
    public List<SObject> queryRecords() {
        contactResults.clear();
        String whereString = new UTIL_Query()
            .withFrom('DuplicateRecordItem')
            .withSelectFields(driFieldNames)
            .withWhere('DuplicateRecordSetId =:drsRecordId')
            .build();
        whereString = 'Id IN ('+ whereString + ')';
        String queryString = new UTIL_Query()
            .withFrom('Contact')
            .withSelectFields(listStrContactField)
            .withWhere(whereString)
            .build();
        return Database.query(queryString);
    }

    /*******************************************************************************************************
    * @description Shows the next step of the wizard where user can see the diff of the records 
    * before merge.
    */
    public void nextStep() {
        fieldRows = nextStep(contactResults);
        // If everything looks good go to "choose winning contact" step
        if(fieldRows != null ) {
            if(fieldRows.size() > 0) {
                this.step = 3;
            }
        }
    }

    /*******************************************************************************************************
    * @description Selects all the values of a certain record. 
    * Used by the "Select All" command link on the page.
    * @return void
    */
    public void selectDefaultRecord() {
        String recordId = Apexpages.currentPage().getParameters().get('recordId');
        fieldRows = selectDefaultRecord(recordId);
    }

    /*******************************************************************************************************
    * @description Merges the winner and losers.
    * @return PageReference The page that it redirects to. Same page user is in.
    */
    public PageReference mergeContacts() {
        Id masterId = mergeContacts(fieldRows); 
        if (masterId != null)
        {
            return new Pagereference('/' + masterId);
        }
        return null;
    }

    /***************************************************************************************************
    * @description Calculates total number of pages of Duplicate Record Sets
    */
    public Integer getTotalPages() {
        return (Integer)Math.ceil(Decimal.valueOf(stdSetCon.getResultSize())/pageSize);
    }

    /***************************************************************************************************
    * @description Fetches the records to be displayed on first page of Duplicate Record Sets
    */    
    public void firstPage() {
        stdSetCon.first();
        listDuplicateRecordSets = getDuplicateRecordSets();
    }
    
    /***************************************************************************************************
    * @description Fetches the records to be displayed on previous page of Duplicate Record Sets
    */ 
    
    public void previousPage() {
        stdSetCon.previous();
        listDuplicateRecordSets = getDuplicateRecordSets();
    }   
        
    /***************************************************************************************************
    * @description Fetches the records to be displayed on next page of Duplicate Record Sets
    */
    
    public void nextPage() {
        stdSetCon.next();
        listDuplicateRecordSets = getDuplicateRecordSets();     
    }
    
    /***************************************************************************************************
    * @description Fetches the records to be displayed on last pages of Duplicate Record Sets
    */ 
    
    public void lastPage() {
        stdSetCon.last();
        listDuplicateRecordSets = getDuplicateRecordSets();    
    }
}
