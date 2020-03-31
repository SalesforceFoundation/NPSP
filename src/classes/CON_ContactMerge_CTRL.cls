/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (2.x)
* @description Controller for the NPSP contact merge page.
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/
public with sharing class CON_ContactMerge_CTRL extends CON_ContactMerge_UTIL {

    /***********************************************************************************************
    * @description Search text entered by user.
    */
    public String searchText { get { return searchText; } set { searchText = value; } }

    /***********************************************************************************************
    * @description List of ContactWrapper objects for display in search results pane.
    */
    public List<ContactWrapper> searchResults {get; private set;}

    /***********************************************************************************************
    * @description Max number of Contacts returned by a query.
    */
    
    private final Integer SOSL_LIMIT = 100;

    /***********************************************************************************************
    * @description The contact merge step user is in. (The process has multiple steps.)
    */
    public Integer step {get; private set;}

    public Boolean canContinueWithMerge { get;set; }

    public Boolean hasContactObjectDeletePermission() {
        return UTIL_Describe.getObjectDescribe('Contact').isDeletable();
    }

    /***********************************************************************************************
    * @description Check read permission on Duplicate Record Sets
    */
    public Boolean hasDSRObjectReadPermission() {
        return UTIL_Describe.getObjectDescribe('DuplicateRecordSet').isAccessible();
    }

    /***********************************************************************************************
    * @description To decide whether to show Search by Contact page or not
    */ 
    
    public Boolean showContactSearch { get; set; }
    
    /***********************************************************************************************
    * @description To decide whether to show the Show Duplicate Record Set button
    */
    public Boolean showDRSButton { get; set; }

    /***********************************************************************************************
    * @description The rows to merge.
    */
    public List<FieldRow> fieldRows {get; private set;}

    /***********************************************************************************************
    * @description Constructor for StandardSetController to allow invocation from list views.
    * @param controller The default list controller for contact. It allows us to do pagination on 
    * the page.
    */
    public CON_ContactMerge_CTRL(ApexPages.StandardSetController controller){
        searchText='';
        searchResults = new List<ContactWrapper>();
        step = 1;
        fieldRows = new List<FieldRow>();
        canContinueWithMerge = true;
        set<Id> mergeIds = new set<Id>();
        showContactSearch = false;
        showDRSButton = true;
        String showContactSearchParameter = System.currentPagereference().getParameters()
            .get('showContactSearch');
        if (showContactSearchParameter == 'true') {
            showContactSearch = true;
        }
        

        if (!hasContactObjectDeletePermission()) {
            canContinueWithMerge = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                System.Label.conMergeErrorNoDeleteObjPermission));
            return;
        }

        //if any selected records were passed the standard set controller show the merge page with 
        // those records
        for(Contact c : (list<Contact>)controller.getSelected()) {
            mergeIds.add(c.Id);
        }

        if(!mergeIds.isEmpty()) {
            loadMergeCandidates(mergeIds);
        }

        //otherwise, check for a search parameter for the SOSL query and use that
        else if(ApexPages.CurrentPage().getParameters().containsKey('srch')) {
            searchText = ApexPages.CurrentPage().getParameters().get('srch');
            search();
        }
        //otherwise, check for a mergeIds parameter, which should contain a comma separated list 
        //of Ids to merge
        else if(ApexPages.CurrentPage().getParameters().containsKey('mergeIds') && 
            ApexPages.CurrentPage().getParameters().get('mergeIds') != '') {
            try {
                //attempt to deserialise the comma separated Ids into a list and then a set
                mergeIds = new set<Id>((list<Id>)ApexPages.CurrentPage().getParameters()
                    .get('mergeIds').split(','));
                //if we got any ids, use to try and enter the merge selected records page
                if (mergeIds != null) {
                    loadMergeCandidates(mergeIds);
                    this.step = 3;
                }
            }
            catch(StringException e){
                ApexPages.addMessages(e);
            }
        }
    }

    /***********************************************************************************************
    * @description Selects all the values of a certain record. Used by the "Select All" 
    * command link on the page.
    * @return void
    */
    public void selectDefaultRecord() {
        String recordId = Apexpages.currentPage().getParameters().get('recordId');
        fieldRows = selectDefaultRecord(recordId);
        //UTIL_Debug.debug('Selected Record: ' + recordId);
    }

    /***********************************************************************************************
    * @description Shows the next step of the wizard where user can see the diff of the records 
    * before merge.
    */
    public void nextStep() {
        fieldRows = nextStep(searchResults);
        // If everything looks good go to "choose winning contact" step
        if(fieldRows != null ) {
            if(fieldRows.size() > 0) {
                this.step = 3;
            }
        }
    }

    /***********************************************************************************************
    * @description Searches for contacts.
    * @return PageReference The page that it redirects to. Same page user is in.
    */
    public PageReference search() {
        Try {
            if(searchText != null && searchText.length()>0){
                step = 2;
                this.searchResults = wrapQueryResults(searchRecords());
            }
        } catch (exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }

    /***********************************************************************************************
    * @description Runs SOSL query to find contacts according to the search text entered by the user
    * @return List<SObject> The list of sObjects returned by the search
    */
    public List<SObject> searchRecords() {
        searchResults.clear();

        //build the SOSL query and execute - NOTE: * wildcard will only have effect at the middle 
        // or end of the search term
        UTIL_Finder finder = new UTIL_Finder(Contact.sObjectType)
            .withSelectFields(listStrContactField)
            .withSearchQuery(searchText)
            .withWildcard()
            .withOrderBy(Contact.LastName)
            .withLimit(SOSL_LIMIT);

        return finder.executeSearch();
    }

    /***********************************************************************************************
    * @description The list of contact field names that are used in search and displayed in Found 
    * Contacts.
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

    /***********************************************************************************************
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
    
    /***********************************************************************************************
     * @description Redirect to Show Duplicate Record Set list page of Contact Merge
     * @return PageReference redirect to CON_DRSContactMerge page.
     */
    public PageReference redirectToShowDRSList() {
        try {
            showContactSearch = false;
            if (!hasDSRObjectReadPermission()) {
                showDRSButton = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                    System.Label.conMergeErrorNoReadDSRObjPermission));
                return null;
            }
            PageReference pageRef = new PageReference('/apex/CON_DRSContactMerge');
            pageRef.setRedirect(true);
            return pageRef;
                  
        } catch (exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }

    /***********************************************************************************************
     * @description Displays the Search by Contact page of Contact Merge
     * 
     */
    public void showContactSearchPage() {
        step = 1;
        searchText='';
        showContactSearch = true; 
        showDRSButton = true;              
    }

}
