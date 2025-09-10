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
public with sharing class CON_ContactMerge_CTRL {

    @TestVisible
    private ContactMergeSelector mergeSelector {
        get {
            if (mergeSelector == null) {
                mergeSelector = new ContactMergeSelector();
            }
            return mergeSelector;
        }
        set;
    }

    /***********************************************************************************************
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

    @TestVisible
    private static final String MASTER_KEY = '$MASTER$';

    /***********************************************************************************************
    * @description To decide whether to show Dupliacate Record Set record list on the page or not
    */ 
    public Boolean showDRS { get; set; }

    /***********************************************************************************************
    * @description Search text entered by user.
    */
    public String searchText { get { return searchText; } set { searchText = value; } }

    /***********************************************************************************************
    * @description List of ContactWrapper objects for display in search results pane.
    */
    public List<ContactWrapper> searchResults { get; private set; }

    /***********************************************************************************************
    * @description Map of the contacts selected for merge.
    */
    @TestVisible
    private Map<String, Contact> selectedRecords;

    /***********************************************************************************************
    * @description Number of selected records.
    */
    public Integer selectedRecordsCount { get; private set; } { this.selectedRecordsCount = 0; }

    /***********************************************************************************************
    * @description Query limit for DRS records query to be displayed
    */ 
    
    private final Integer SOQL_LIMIT = 5000;

    /***********************************************************************************************
    * @description Duplicate Record Sets to be displayed on page
    */ 
    public List<DuplicateRecordSet> listDuplicateRecordSets { get; set; }

    /***********************************************************************************************
    * @description The contact merge step user is in. (The process has multiple steps.)
    */
    public Integer step { get; private set; }

    public Boolean canContinueWithMerge { get;set; }

    public List<FieldSetMember> fieldSetMembers {
        get {
            if (fieldSetMembers == null) {
                fieldSetMembers = SObjectType.Contact.fieldSets.ContactMergeFoundFS.getFields();
            }
            return fieldSetMembers;
        }
        set;
    }

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
    * @description To decide whether to show the merge page
    */
    public Boolean loadMergePage { get; set; }

    /***********************************************************************************************
    * @description Standard set controller variables
    */ 
    public ApexPages.StandardSetController drsSetController {
        get {
            if(drsSetController == null){
                drsSetController = new ApexPages.StandardSetController
                    (Database.getQueryLocator(constructDRSSOQL())); 
                drsSetController.setPageSize(pageSize);    
            }
            return drsSetController;
        }
        set;
     }

     /**********************************************************************************************
    * @description Duplicate Record Set diplay page size.
    */
    @TestVisible
    private Integer pageSize = 10;
    
    /***********************************************************************************************
    * @description Total number of pages in pagination implemented on Duplicate Record Set 
    * diplay page.
    */
    public Integer totalPages { get; set; }
    
    /***********************************************************************************************
    * @description First Contact created for each DRS
    */
    public Map<Id,Contact> firstContactOfDRS { get; set; }

    /***********************************************************************************************
     * @description To store the selected DRS recordId 
     */
    public String drsRecordId { get; set; }

    /***********************************************************************************************
     * @description Set of DRS records that include a single Contact
     * with one or more other SObject types
     */
    @TestVisible
    private Set<Id> unactionableDuplicateRecordSets;

    /***********************************************************************************************
     * @description Map of DRS record Ids to count of Contacts in that set
     */
    public Map<Id, Integer> contactCountByDuplicateRecordSetId { get; set; }

    /***********************************************************************************************
     * @description A Set of Contact Ids passed into Contact Merge that can be used to 
     * return search results
     */
    private Set<Id> contactIdsToSearch;

    /***********************************************************************************************
    * @description Checks whether there are more records to display on next page in pagination  
    * implemented on Duplicate Record Set diplay page.
    */
    
    public Boolean hasNext {
        get {
            return drsSetController.getHasNext();
        }
        set;
    }
    
    /***********************************************************************************************
    * @description Checks whether there are records prior to the records dislayed on the current  
    * page to be display on the previous page in pagination implemented on Duplicate Record Set 
    * diplay page.
    */
    
    public Boolean hasPrevious {
        get {
            return drsSetController.getHasPrevious();
        }
        set;
    }
    
    /***********************************************************************************************
    * @description Page number of the current page
    */
    
    public Integer pageNumber {
        get {
            return drsSetController.getPageNumber();
        }
        set;
    }

    /***********************************************************************************************
    * @description List of DRS fields that need to be displayed on DRS list page
    */
    private List<String> drsFieldNames {
        get {
            if (drsFieldNames == null) {
                drsFieldNames = UTIL_Describe.listStrFromFieldSet
                    ('DuplicateRecordSet', UTIL_Namespace.StrTokenNSPrefix('ContactMergeDRS'));
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

    /***********************************************************************************************
    * @description Aria Column heading map
    */
    public Map<Id, String> ariaNameMap { get; private set; }

    /***********************************************************************************************
    * @description List of readonly fields
    */
    public static List<String> readOnlyFields = new List<String>{
        'npo02__TotalOppAmount__c',
        'npo02__AverageAmount__c',
        'npo02__SmallestAmount__c',
        'npo02__LargestAmount__c',
        'npo02__FirstCloseDate__c',
        'npo02__LastCloseDate__c',
        'npo02__NumberOfClosedOpps__c',
        'npo02__OppAmountThisYear__c',
        'npo02__OppsClosedThisYear__c',
        'npo02__OppAmountLastYear__c',
        'npo02__OppsClosedLastYear__c',
        'npo02__OppsClosed2YearsAgo__c',
        'npo02__OppAmount2YearsAgo__c',
        'npo02__OppsClosedLastNDays__c',
        'npo02__OppAmountLastNDays__c',
        'npo02__TotalMembershipOppAmount__c',
        'npo02__NumberOfMembershipOpps__c',
        'npo02__LastMembershipDate__c',
        'npo02__LastMembershipAmount__c',
        'npo02__LastMembershipLevel__c',
        'npo02__LastMembershipOrigin__c',
        'npo02__MembershipJoinDate__c',
        'npo02__MembershipEndDate__c',
        'npo02__LastOppAmount__c',
        'npo02__Best_Gift_Year__c',
        'npo02__Best_Gift_Year_Total__c',
        String.valueOf(Contact.Soft_Credit_Last_N_Days__c),
        'npo02__Soft_Credit_Last_Year__c',
        'npo02__Soft_Credit_This_Year__c',
        'npo02__Soft_Credit_Total__c',
        'npo02__Soft_Credit_Two_Years_Ago__c',
        String.valueOf(Contact.First_Soft_Credit_Amount__c),
        String.valueOf(Contact.First_Soft_Credit_Date__c),
        String.valueOf(Contact.Largest_Soft_Credit_Amount__c),
        String.valueOf(Contact.Largest_Soft_Credit_Date__c),
        String.valueOf(Contact.Last_Soft_Credit_Amount__c),
        String.valueOf(Contact.Last_Soft_Credit_Date__c),
        String.valueOf(Contact.Number_of_Soft_Credits__c),
        String.valueOf(Contact.Number_of_Soft_Credits_Last_N_Days__c),
        String.valueOf(Contact.Number_of_Soft_Credits_Last_Year__c),
        String.valueOf(Contact.Number_of_Soft_Credits_This_Year__c),
        String.valueOf(Contact.Number_of_Soft_Credits_Two_Years_Ago__c),
        String.valueOf(Contact.Sustainer__c)
    };

    /***********************************************************************************************
    * @description Wraps a contact together with a checkbox, to allow contact selection.
    */
    public class ContactWrapper {
        /*******************************************************************************************
        * @description The contact.
        */
        public Contact contactRecord { get; set; }
        /*******************************************************************************************
        * @description The checkbox.
        */
        public Boolean selected { get; set; }

        /*******************************************************************************************
        * @description Constructor that initializes instance properties.
        * @c The contact to wrap.
        */
        public ContactWrapper(Contact c) {
            contactRecord = c;
            selected = false;
        }
    }

    /***********************************************************************************************
    * @description The rows to merge.
    */
    @TestVisible
    public List<FieldRow> fieldRows { get; private set; }

    /***********************************************************************************************
    * @description The struct to save all the information belonging to each contact field, including
    * values for all the contacts to merge.
    */
    public class FieldRow {
        /*******************************************************************************************
        * @description Stores the field Label.
        */
        @TestVisible
        public String fieldLabel { get; private set; }
        /*******************************************************************************************
        * @description Stores the field api name.
        */
        @TestVisible
        public String fieldName { get; private set; }
        /*******************************************************************************************
        * @description Property to tell whether UI must should a radio to select the field value.
        */
        @TestVisible
        public Boolean showRadio { get; private set; }
        /*******************************************************************************************
        * @description  List of values for each contact record.
        */
        @TestVisible
        public List<Cell> values { get; private set; }
        /*******************************************************************************************
        * @description Selected record.
        */
        public String selectedValue { get; set; }
        /*******************************************************************************************
        * @description The class style.
        */
        public String styleClass { get; private set; }

        /*******************************************************************************************
        * @description Constructor that initializes the values property.
        */
        public FieldRow() {
            this.values = new List<Cell>();
        }

        /*******************************************************************************************
        * @description Constructor that initializes the values property.
        * @param fieldName The name of the field.
        * @param fieldLabel The field label.
        * @param showRadio Whether a radio button should be displayed for the row.
        * @param styleClass The style class.
        */
        public FieldRow(String fieldName, String fieldLabel, Boolean showRadio, String styleClass) {
            this();
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.showRadio = showRadio;
            this.styleClass = styleClass;
        }
    }

    /***********************************************************************************************
    * @description The cell for a corresponding field row in the UI table.
    */
    public class Cell {
        /*******************************************************************************************
        * @description Id of the record to which this value belongs.
        */
        public String objId { get; private set; }
        /*******************************************************************************************
        * @description The actual value.
        */
        public String value { get; private set; }

        /*******************************************************************************************
        * @description Constructor that sets instance properties.
        * @param objectId The ID of the object whose field represented by the cell.
        * @param value The value of the field represented by the cell.
        */
        public Cell(String objectId, String value) {
            this.objId = objectId;
            this.value = value;
        }
    }

    /***********************************************************************************************
    * @description Constructor for StandardSetController to allow invocation from list views.
    * @param controller The default list controller for contact. It allows us to do pagination on 
    * the page.
    */
    public CON_ContactMerge_CTRL(ApexPages.StandardSetController controller){
        searchText='';
        searchResults = new List<ContactWrapper>();
        listDuplicateRecordSets = new List<DuplicateRecordSet>();
        step = 1;
        fieldRows = new List<FieldRow>();
        canContinueWithMerge = true;
        Set<Id> mergeIds = new Set<Id>();
        selectedRecords = new Map<String, Contact>();
        firstContactOfDRS = new Map<Id,Contact>();
        showContactSearch = false;
        showDRSButton = true;
        loadMergePage = false;
        showDRS = false;

        if (!hasContactObjectDeletePermission()) {
            canContinueWithMerge = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                System.Label.conMergeErrorNoDeleteObjPermission));
            return;
        }

        //if any selected records were passed the standard set controller show the merge page with 
        // those records
        for(Contact c : (List<Contact>)controller.getSelected()) {
            mergeIds.add(c.Id);
        }

        if(!mergeIds.isEmpty()) {
            loadMergeCandidates(mergeIds);
            if(!ApexPages.hasMessages()) {
                showDRSButton = false;
                showContactSearch = true;
            }
        }

        //otherwise, check for a search parameter for the SOSL query and use that
        else if(ApexPages.CurrentPage().getParameters().containsKey('srch')) {
            searchText = ApexPages.CurrentPage().getParameters().get('srch');
            showDRSButton = false;
            showContactSearch = true;
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
                    if(!ApexPages.hasMessages()) {
                        showDRSButton = false;
                        showContactSearch = true;
                    }
                }
            }
            catch(StringException e){
                ApexPages.addMessages(e);
            }
        }
        //otherwise, check for a searchIds parameter, which should contain a comma separated list 
        //of Ids to search
        else if(ApexPages.CurrentPage().getParameters().containsKey('searchIds') && 
            ApexPages.CurrentPage().getParameters().get('searchIds') != '') {
            try {
                contactIdsToSearch = new set<Id>((list<Id>)ApexPages.CurrentPage().getParameters()
                    .get('searchIds').split(','));
                if (contactIdsToSearch != null) {
                    loadMergePage = true;
                    search();
                    if(!ApexPages.hasMessages()) {
                        showContactSearch = true;
                    }
                }
            }
            catch(StringException e){
                ApexPages.addMessages(e);
            }
        }
    }

    /***********************************************************************************************
    * @description Selects all the values of a certain record. Used by the "Select All" command link
    * on the page.
    * @return void
    */
    public void selectDefaultRecord() {
        String recordId = Apexpages.currentPage().getParameters().get('recordId');
        if (recordId != null && selectedRecords.keySet().contains(recordId)) {
            for (FieldRow row : fieldRows) {
                if (row.showRadio) {
                    row.selectedValue = recordId;
                }
            }
        }
    }

    /***********************************************************************************************
    * @description Shows the next step of the wizard where user can see the diff of the records 
    * before merge.
    */
    public void nextStep() {

        Set<Id> mergeIds = new Set<Id>();
        for (ContactWrapper c : searchResults) {
            if (c.selected) {
                mergeIds.add(c.contactRecord.Id);
            }
        }
        loadMergeCandidates(mergeIds);
    }

    /***********************************************************************************************
    * @description Shows the next step of the wizard where user can see the diff of the records 
    * before merge.
    */
    @TestVisible
    private void loadMergeCandidates(Set<Id> mergeCandidates) {

        // Check we have atleast 2 and not more than 3 records selected for merge. 
        // If not throw an error.
        if (mergeCandidates.size() <=1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
                Label.npe01.Contact_Merge_Error_Too_Few_Contacts));
            return;
        }

        if (mergeCandidates.size() >3 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                Label.npe01.Contact_Merge_Error_Too_Many_Contacts));
            return;
        }

        selectedRecordsCount = mergeCandidates.size();
        fieldRows.clear();
        selectedRecords.clear();

        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        Map<String, Schema.DescribeFieldResult> standardFieldMap = 
            new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.DescribeFieldResult> customFieldMap = 
            new Map<String, Schema.DescribeFieldResult>();

        // Construct the query string
        String query = 'SELECT Id, Name, ';
        for (String fieldName : contactFields.keySet()) {
            Schema.SobjectField field = contactFields.get(fieldName);
            Schema.DescribeFieldResult fResult = field.getDescribe();

            // Ignore fields that have an identical API name as an npsp prefixed field
            // This is due to a bug in dynamic SOQL, quich causes querying for two real fields,
            // e.g. npsp__foo__c and foo__c, to throw a duplicate field selected error.
            // Only select the NPSP namespaced field and ignore the same field without namespace
            if (!String.isBlank(UTIL_Namespace.getNamespace()) && 
                !fieldName.startsWith(UTIL_Namespace.getNamespace()+'__') &&
                contactFields.containsKey(UTIL_Namespace.StrTokenNSPrefix(fieldName))) {

                continue;
            }

            // Only include the fields which are updateable and accessible
            if (fResult.isUpdateable() && fResult.isAccessible() && !isNPSPHiddenField(fieldname)) {
                // If the field is type lookup, select the parent name
                String relName = fResult.getRelationshipName();
                if (string.isBlank(relName)) {
                    query += (fieldName + ',');
                } else {
                    //find the Name field for the related object
                    String nameField = getRelatedObjNameField(fResult);

                    if (nameField!=null) {
                        query += (relName + '.' + nameField + ',');
                    }
                }
                // Collect the standard and custom fields separately for sorting
                if(fResult.isCustom()) {
                    customFieldMap.put(fieldName, fResult);
                } else {
                    standardFieldMap.put(fieldName, fResult);
                }
            }
        }
        // Adding some non-updateable system fields which we need to add to the record diff table.
        query +=  'createdby.name, createddate, LastModifiedBy.name, LastModifiedDate';
        // Finally completing the query by appending the table name and the filter clause
        query += ' from Contact where id IN :mergeCandidates';

        List<Contact> contacts;
        try {
            contacts = Database.query(query); // Query the records
            // Ensure we got back the same number of records as expected. 
            // In case any record got deleted/moved since last search.
            if (contacts == null || contacts.size() != mergeCandidates.size()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    Label.npe01.Contact_Merge_Error_Query_Failed + ' ' + 
                    Label.npe01.Contact_Merge_Error_please_retry));
                return;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                Label.npe01.Contact_Merge_Error_Contact_not_found + ' Error: ' + e));
            return;
        }

        if (!canUserDeleteSelectedContacts(mergeCandidates)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                System.Label.conMergeErrorNoDeleteRecAccess));
            return;
        }
        
        // Update the list of searched records with only the ones selected
        searchResults.clear();
        for (Contact c : contacts) {
            this.selectedRecords.put(c.id, c);
        }

        // Sort the standard fields list by name before creating the list of FieldRow for merge UI
        List<String> standardFieldList = new List<String>();
        standardFieldList.addAll(standardFieldMap.keySet());
        standardFieldList.sort();

        // Sort the custom fields list by name before creating the list of FieldRow for merge UI
        List<String> customFieldList = buildSortedCustomFieldList(customFieldMap);

        // Add the first row of type header with contact names as titles
        FieldRow temp = new FieldRow('', '', false, 'header');
        for (Contact c: contacts) {
            Contact con = (Contact) c;
            temp.values.add(new Cell(c.id, con.name));
        }
        fieldRows.add(temp);

        // Add second row to select the master record. Select the one which is last modified
        temp = new FieldRow(MASTER_KEY, 'Master Record', true, null);
        {
            DateTime lastModifiedDate;
            for (Contact c: contacts) {
                temp.values.add(new Cell(c.id, null));
                if (lastModifiedDate == null ||
                    (lastModifiedDate != null && 
                    (DateTime)c.get('lastModifiedDate') > lastModifiedDate)) {
                    temp.selectedValue = c.id;
                    lastModifiedDate = (DateTime)c.get('lastModifiedDate');
                }
            }
        }
        fieldRows.add(temp);

        // Add the portal row if any of the contacts have a user record
        List<User> portalUsers = new List<User>([
            SELECT Id, ContactId 
            FROM User 
            WHERE ContactId IN :contacts]);
        if (!portalUsers.isEmpty()) {
            Map<Id, Boolean> hasUserRecordByContactId = new Map<Id, Boolean>();
            for (User portalUser : portalUsers) {
                hasUserRecordByContactId.put(portalUser.ContactId, true);
            }
            temp = new FieldRow(System.Label.conMergePortalUser, 
                System.Label.conMergePortalUser, false, null);
            for (Contact c: contacts) {
                Contact con = (Contact) c;
                temp.values.add(new Cell(c.id, 
                    String.valueOf(hasUserRecordByContactId.containsKey(c.Id))));
            }
            fieldRows.add(temp);
        }

        // Add a dummy row to add a 'Standard Fields' header before the list of standard fields
        fieldRows.add(new FieldRow('Standard Fields', 'Standard Fields', false, 'separator'));

        // Add all standard fields to the list of FieldRow in sorted manner
        for (String fieldName: standardFieldList) {
            addFieldComparisonRows(fieldName, standardFieldMap.get(fieldName), contacts);
        }

        // Add a dummy row to add a 'Custom Fields' header before the list of custom fields
        fieldRows.add(new FieldRow('Custom Fields', 'Custom Fields', false, 'separator'));

        // Add all custom fields to the list of FieldRow in sorted manner
        for (String fieldName: customFieldList) {
            addFieldComparisonRows(fieldName, customFieldMap.get(fieldName), contacts);
        }

        // Add a dummy row to add a 'System Fields' header before the list of system fields
        fieldRows.add(new FieldRow('System Fields', 'System Fields', false, 'separator'));

        // Add created by and last modified by system fields to the list of FieldRow
        FieldRow createdByRow = new FieldRow('CreatedById', 'Created By', false, null),
            lastModifiedByRow = new FieldRow('LastModifiedById', 'Last Modified By', false, null);
        for (Contact c: contacts) {
            SObject createdBy = c.getSObject('createdby');
            SObject modifiedBy = c.getSObject('lastModifiedBy');
            createdByRow.values.add(new Cell(c.id, 
                (createdBy != null ? createdBy.get('name') : '') + ' ' + c.get('createdDate')));
            lastModifiedByRow.values.add(new Cell(c.id, 
                (modifiedBy != null ? modifiedBy.get('name') : '') + ' ' + c.get('LastModifiedDate')));
        }
        fieldRows.add(createdByRow);
        fieldRows.add(lastModifiedByRow);

        // If everything looks good go to "choose winning contact" step
        this.step = 3;

    }

    private List<String> buildSortedCustomFieldList(Map<String, DescribeFieldResult> customFieldMap) {
        List<String> customFields = new List<String>();
        DescribeFieldResult undeliverableFieldDescribeResult = Contact.Undeliverable_Address__c.getDescribe();

        for (String fieldName : customFieldMap.keySet()) {
            if (fieldName == undeliverableFieldDescribeResult.getName()) {
                continue;
            }
            customFields.add(fieldName);
        }

        customFields.sort();
        if (UTIL_Permissions.canRead(undeliverableFieldDescribeResult, false) &&
                UTIL_Permissions.canUpdate(undeliverableFieldDescribeResult, false)) {
            customFields.add(0, undeliverableFieldDescribeResult.getName().toLowerCase());
        }

        return customFields;
    }

    /***********************************************************************************************
    * @description Returns a referenced object's name field.
    * @param controller The default list controller for contact. It allows us to do pagination 
    * on the page.
    * @return string The name of the name field, or null if we couldn't find one.
    */
    private String getRelatedObjNameField(Schema.DescribeFieldResult fieldDesc) {
        String nameField = 'Name';
        Map<String, Schema.SObjectField> mapRelatedObjectFields = 
            fieldDesc.getReferenceTo()[0].getDescribe().fields.getMap();

        //if Name isn't the correct name field, find it
        if (!mapRelatedObjectFields.containsKey(nameField)) {
            nameField = null;
            for (String relatedFieldName : mapRelatedObjectFields.keySet()) {
                if (mapRelatedObjectFields.get(relatedFieldName).getDescribe().isNameField())
                    return relatedFieldName;
            }
        }
        return nameField;
    }

    /***********************************************************************************************
    * @description Adds field information and field values to the list of field rows.
    */
    private void addFieldComparisonRows(String fieldName, 
        Schema.DescribeFieldResult fieldDesc, 
        List<SObject> objs) {
        // Create a new FieldRow item
        FieldRow row = new FieldRow();
        row.fieldName = fieldName;

        // For standrd lookup type fields, use the relationship name as the field label
        if (!fieldDesc.isCustom() && fieldDesc.getRelationshipName() != null) {
            row.fieldLabel = fieldDesc.getRelationshipName();
        } else {
            row.fieldLabel = fieldDesc.getLabel();
        }

        row.values = new List<Cell>();
        //flag to indicate whether atleast one pair of field values is different across all contacts
        Boolean isDifferent = false; 
        // flag to indicate whether all the field values are null
        Boolean isNull = true; 
        Integer idx = 0;

        List<String> values = new List<String>();
        DateTime lastModifiedDate = null;
        String prev;
        ariaNameMap = new Map<Id, String>();

        // Iterate over all contacts to find the field values and add them to row values
        for (SObject c : objs) {
            // Add name to aria name map
            ariaNameMap.put(c.Id, String.valueOf(c.get('Name')));

            // For lookup fields set the name as the values
            if (fieldDesc.getRelationshipName() != null) {
                Sobject obj = c.getSObject(fieldDesc.getRelationshipName());
                if (obj != null) {
                    values.add(String.valueOf(obj.get(getRelatedObjNameField(fieldDesc))));
                } else {
                    values.add(null);
                }
            } else {
                values.add(String.valueOf(c.get(fieldName)));
            }

            isNull &= (c.get(fieldName) == null); // Check if the value is null

            if (idx == 0) {
                prev = String.valueOf(c.get(fieldName));
            }
            if (idx > 0 && !isNull) {
                // Check if atleast one of the values is different. 
                // If yes then update the isDifferent flag
                String current = String.valueOf(c.get(fieldName));
                if ((prev != null && !prev.equals(current)) ||
                    (current != null && !current.equals(prev))) {
                    isDifferent = true;
                }
                prev = current;
            }

            // Select the default value for the field. A non-null value on the latest modified record
            if (c.get(fieldName) != null && (lastModifiedDate == null ||
                (lastModifiedDate != null && (DateTime)c.get('lastModifiedDate') > lastModifiedDate))) {
                row.selectedValue = c.id;
                lastModifiedDate = (DateTime)c.get('lastModifiedDate');
            }

            idx++;
        }

        // If atleast one record has a non-null field value, then add it to the list of fieldRows.
        if (!isNull) {
            for (Integer i=0; i < values.size(); i++) {
                String val = values[i];
                if (val != null && val.length() > 255) {
                    val = val.substring(0, 251) + ' ...';
                }
                row.values.add(new Cell(objs[i].id, val));
            }
            // Show the select radio only if the field values are different.
            // Dont let user choose the account as you dont want users to assign a differnt
            // account in One to One case.
            row.showRadio = (isDifferent && !fieldName.equalsIgnoreCase('accountId') && 
                !isNPSPReadOnly(fieldName));
            fieldRows.add(row);
        }
    }

    /***********************************************************************************************
    * @description returns whether the field should be treated as an NPSP read only field, typically
    * one of our rollup fields that get automatically populated by rollups, and users should 
    * not direclty modify.
    * @return Boolean true if should be treated as readonly, false if not.
    */
    private Boolean isNPSPReadOnly(String strField) {
        for (String strF : readOnlyFields) {
            if (strField.equalsIgnoreCase(strF)) {
                return true;
            }
        }
        return false;
    }


    /***********************************************************************************************
    * @description returns whether the field should be treated as an NPSP hidden field, typically
    * one of our deprecated or system fields
    * @return Boolean true if should be treated as hidden, false if not.
    */
    private Boolean isNPSPHiddenField(String strField) {
        List<String> listStrField = new List<String>{
            'npe01__SystemAccountProcessor__c',
            'npo02__SystemHouseholdProcessor__c',
            'npe01__SystemIsIndividual__c',
            'Current_Address__c'
        };

        for (String strF : listStrField) {
            if (strField.equalsIgnoreCase(strF))
                return true;
        }
        return false;
    }

    /***********************************************************************************************
    * @description checks if the logged in user have delete permission for the selected records.
    * @param ContactIds list of contacts
    * @return Boolean.  true if delete access is allowed.
    */
    private Boolean canUserDeleteSelectedContacts(Set<Id> contactIds) {
        List <UserRecordAccess> userAccess = [
            SELECT RecordId, HasEditAccess, HasDeleteAccess, MaxAccessLevel
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId()
            And RecordId IN :contactIds
        ];
        for (UserRecordAccess user: userAccess) {
            if (!user.HasDeleteAccess ) {
                return false;
            }
        }
        return true;
    }

    /***********************************************************************************************
    * @description Searches for contacts.
    * @return PageReference The page that it redirects to. Same page user is in.
    */
    public PageReference search() {
        try {
            step = 2;
            this.searchResults = wrapQueryResults(stripInaccessibleResultFields(searchRecords()));
            
 
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
        if(showContactSearch == true && searchText != null && searchText.length() > 0) {
            //build the SOSL query and execute - NOTE: * wildcard will only have effect at the
            //middle or end of the search term
            return mergeSelector.selectContactsByName(searchText);
        } else if(contactIdsToSearch != null) {
            return mergeSelector.selectContactsById(contactIdsToSearch);
        } else {
            return mergeSelector.selectDuplicateRecordSetById(drsRecordId, driFieldNames);
        }
    }

    private List<SObject> stripInaccessibleResultFields(List<SObject> searchResults) {
        SObjectAccessDecision accessDecision =
                Security.stripInaccessible(AccessType.READABLE, searchResults);

        Map<String, Set<String>> removedFields = accessDecision.getRemovedFields();
        if (!removedFields.isEmpty()) {
            List<FieldSetMember> strippedFieldSetMembers = new List<FieldSetMember>();
            for (FieldSetMember fsMember:fieldSetMembers) {
                Boolean fieldRemoved = false;
                for (String field:removedFields.get('Contact')) {
                    if (fieldRemoved) {
                        continue;
                    }
                    if (fsMember.getFieldPath().contains(field)) {
                        fieldRemoved = true;
                    }
                }
                if (!fieldRemoved) {
                    strippedFieldSetMembers.add(fsMember);
                }
            }
            fieldSetMembers = strippedFieldSetMembers;
        }

        return accessDecision.getRecords();
    }

    /***********************************************************************************************
    * @description Wraps the Query(SOSL and SOQL) results.
    * @param searchResults The list of SObjects to wrap.
    * @return List<ContactWrapper> Those records from the passed parameter that are of type Contact
    * are returned in this list, inside wrappers.
    */
    public List<ContactWrapper> wrapQueryResults(List<SObject> searchResults) {
        List<ContactWrapper> res = new List<ContactWrapper>();

        for (SObject returnedObject : searchResults) {
            ContactWrapper thisResult = new ContactWrapper((Contact) returnedObject);
            res.add(thisResult);
        }

        return res;
    }

    /***********************************************************************************************
    * @description Merges the winner and losers.
    * @return PageReference The page that it redirects to. Same page user is in.
    */
    public PageReference mergeContacts() {
        if (!(Contact.SObjectType.getDescribe().isMergeable()) && Account.SObjectType.getDescribe().isMergeable()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.Label.commonAccessErrorMessage));
            return null;
        }

        Contact winningContact = getWinningContact();
        
        if (winningContact == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_No_Master));
            return null;
        }

        populateContactWithNonUniqueFields(winningContact);

        List<Contact> losingContacts = groupLosingContacts(winningContact);
        
        // before proceeding further first lock the records for change
        List<Contact> allContacts = new List<Contact>();
        allContacts.add((Contact)winningContact);
        allContacts.addAll(losingContacts);

        List<Contact> lockedContacts = lockAllContacts(allContacts);

        if (lockedContacts == null || lockedContacts.size() != allContacts.size()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                label.npe01.Contact_Merge_Error_Lock_failed  + ' ' + 
                label.npe01.Contact_Merge_Error_please_retry) );
            return null;
        }

        System.SavePoint sp = Database.setSavepoint();
        try {
            // We need to turn off Affiliation processing or there will be duplicate affiliates
            // created after the merge.  As merge transactions do not fire child triggers
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.AFFL_doNotRunForContacts, true);
            updateAndHandleWinningContact(winningContact);
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.AFFL_doNotRunForContacts, false);

            ContactMergeService contactMerge = new ContactMergeService();
            contactMerge.mergeContacts(winningContact, losingContacts);

            updateContactAfterMerge(winningContact.Id);


        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.CON);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Merge_Failed + ' Error: ' + e));

            return null;
        }

        return new PageReference('/' + winningContact.id);
    }

    // Find the winningContact record based the selected value of the winningContact FieldRow
    private Contact getWinningContact() {
        for (FieldRow row : fieldRows) {
            if (row.showRadio && row.fieldName.equals(MASTER_KEY)) {
                return new Contact(Id = row.selectedValue);
            }
        }
        
        return null;
    }

    private List<Contact> groupLosingContacts(Contact winningContact) {
        List<Contact> losingContacts = new List<Contact>();
        for (Contact contact : this.selectedRecords.values()) {
            if (contact.Id != winningContact.Id) {
                losingContacts.add(contact);
            }
        }

        return losingContacts;
    }

    private List<Contact> lockAllContacts(List<Contact> toLock) {
        return [
            SELECT Id 
            FROM Contact 
            WHERE Id IN :toLock FOR UPDATE];
    }

    // Update the field values of master record based on the selected value for each field.
    private void populateContactWithNonUniqueFields(Contact winningContact) {
        populateContactWithFields(winningContact, false);
    }

    private void updateContactAfterMerge(Id winningContactId) {
        Contact winningContact = new Contact(Id = winningContactId);

        Boolean hasFieldChange = populateContactWithOnlyUniqueFields(winningContact);
        hasFieldChange = hasFieldChange || evaluateContactForSustainerChange(winningContact);

        if (hasFieldChange) {
            updateAndHandleWinningContact(winningContact);
        }
        
    }

    private Boolean populateContactWithOnlyUniqueFields(Contact winningContact) {
        Boolean hasUniqueFieldChange = populateContactWithFields(winningContact, true);
        return hasUniqueFieldChange;
    }

    private Boolean evaluateContactForSustainerChange(Contact winningContact) {
        DescribeFieldResult sustainerFieldDescribeResult = Contact.Sustainer__c.getDescribe();

        if (!UTIL_Permissions.canRead(sustainerFieldDescribeResult, false)
            || !UTIL_Permissions.canUpdate(sustainerFieldDescribeResult, false)) {
            return false;
        }

        List<Contact> contactWithSustainerChanged = new RD2_SustainerEvaluationService()
        .withContacts(new List<Contact>{winningContact})
        .getContactsWithSustainerChanged();

        Boolean needSustainerUpdate = contactWithSustainerChanged.size() != 0;
        if (needSustainerUpdate) {
            winningContact.Sustainer__c = contactWithSustainerChanged[0].Sustainer__c;
        }

        return needSustainerUpdate;
    }

    private Boolean populateContactWithFields(Contact winningContact, Boolean isUniqueField) {
        Boolean hasFieldChange = false;

        for (FieldRow row : fieldRows) {
            if (row.showRadio
                && !row.fieldName.equals(MASTER_KEY)
                && row.selectedValue != winningContact.Id
                && UTIL_Describe.isFieldUnique('Contact', row.fieldName) == isUniqueField)
            {
                SObject selectedRecord = this.selectedRecords.get(row.selectedValue);
                Object val = selectedRecord.get(row.fieldName);
                winningContact.put(row.fieldName, val);     
                hasFieldChange = true;
            }
        }

        return hasFieldChange;
    }

    private void updateAndHandleWinningContact(Contact winningContact) {
        RD2_SustainerEvaluationService.setSustainerUpdateEnabled(true);

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;

        Database.SaveResult saveResult = UTIL_DMLService.updateRecord(winningContact, dml);
        handleDMLError(saveResult);

        RD2_SustainerEvaluationService.setSustainerUpdateEnabled(false);
    }

    private void handleDMLError(Database.SaveResult saveResult) {
        if (saveResult.isSuccess()) {
            return;
        }

        String errorMessage = '';
        for (Database.Error err : saveResult.getErrors()) {
            errorMessage += err.getMessage() + '\n';
        }
        throw new ConMergeException(errorMessage);
    }

    public class ConMergeException extends Exception {} 

    /***********************************************************************************************
    * @description Shows list of Duplicate Record Set records related to contact dupliacte rules
    */
    public void showDuplicateRecordSets() {
        try {
            showDRSButton = false;
            showContactSearch = false;
            showDRS = true;
            loadMergePage = true;
            step = 1;
            listDuplicateRecordSets = getDuplicateRecordSets();
            getDuplicateRecordItemDetails();
            totalPages = getTotalPages();
        } catch (exception ex) {
                ApexPages.addMessage(new ApexPages.Message
                    (ApexPages.Severity.Error, ex.getMessage()));
        }
    }

    private void getDuplicateRecordItemDetails() {
        List<DuplicateRecordSet> duplicateRecordSets = queryAllDuplicateRecordSets();

        Set<Id> allDuplicateRecordItemIds = new Set<Id>();
        List<DuplicateRecordItem> allDuplicateRecordItems = new List<DuplicateRecordItem>();
        contactCountByDuplicateRecordSetId = new Map<Id, Integer>();
        for (DuplicateRecordSet dupRecSet : duplicateRecordSets) {
            allDuplicateRecordItemIds.addAll(new Map<Id, DuplicateRecordItem>(
                dupRecSet.DuplicateRecordItems).keySet());
            allDuplicateRecordItems.addAll(new Map<Id, DuplicateRecordItem>(
                dupRecSet.DuplicateRecordItems).values());
            contactCountByDuplicateRecordSetId.put(dupRecSet.Id, dupRecSet.RecordCount);
        }

        getDuplicateRecordSetFirstContacts(allDuplicateRecordItemIds, allDuplicateRecordItems);
    }

    private List<DuplicateRecordSet> queryAllDuplicateRecordSets() {
        driFieldNames.add('DuplicateRecordSetId');
        driFieldNames.add('Record.Type');
        List<DuplicateRecordSet> duplicateRecordSets = new List<DuplicateRecordSet>(
            (List<DuplicateRecordSet>) Database.query(constructDRSSOQL()));
        driFieldNames.remove(driFieldNames.indexOf('DuplicateRecordSetId'));
        driFieldNames.remove(driFieldNames.indexOf('Record.Type'));

        return duplicateRecordSets;
    }

    private void getDuplicateRecordSetFirstContacts(Set<Id> allDRIIds, List<DuplicateRecordItem> allDRIs) {
        if ((Limits.getLimitQueryRows() -  Limits.getQueryRows()) < allDRIIds.size()) {
            ApexPages.addMessage(new ApexPages.Message
                (ApexPages.Severity.Error, Label.conMergeTooManyContactError));
            step = 0;
            return;
        }

        Map<Id, Contact> contacts = getDRSRelatedContacts(allDRIIds);
        populateFirstContacts(allDRIs, contacts);
    }

    private void populateFirstContacts(List<DuplicateRecordItem> allDRIs, Map<Id, Contact> contacts) {
        for (DuplicateRecordItem dri : allDRIs) {
            if (dri.Record.Type != 'Contact') {
                contactCountByDuplicateRecordSetId.put(dri.DuplicateRecordSetId,
                    contactCountByDuplicateRecordSetId.get(dri.DuplicateRecordSetId) - 1);
                continue;
            }
            Contact con = contacts.get(dri.RecordId);
            if (!(firstContactOfDRS.containsKey(dri.DuplicateRecordSetId))) {
                firstContactOfDRS.put(dri.DuplicateRecordSetId, con);
            } else {
                if (con.createdDate <
                    firstContactOfDRS.get(dri.DuplicateRecordSetId).createdDate) {
                    firstContactOfDRS.put(dri.DuplicateRecordSetId, con);
                }
            }
        }
    }

    private Map<Id, Contact> getDRSRelatedContacts(Set<Id> allDRIIds) {
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
        String contactQueryStr = new UTIL_Query()
            .withFrom('Contact')
            .withSelectFields(contactField)
            .withWhere(whereString)
            .build();

        return new Map<Id, Contact>((List<Contact>) Database.query(contactQueryStr));
    }

    /**********************************************************************************************
    * @description Construct SOQL query to fetch all the contact related Duplicate Record Sets
    * @return String Returns the query to fetch Duplicate Record Sets
    */
    public String constructDRSSOQL() {
        getUnactionableDuplicateRecordSets();

        List<String> forDuplicateRecordSet = getDuplicateRuleSetQuerySelectClause();
        String forDuplicateRecordSetsRelatedToAtLeastOneContact = getDuplicateRuleSetQueryWhereClause();

        String duplicateRecordSetsQuery =  new UTIL_Query()
            .withFrom(DuplicateRecordSet.sObjectType)
            .withSelectFields(forDuplicateRecordSet)
            .withWhere(forDuplicateRecordSetsRelatedToAtLeastOneContact)
            .withOrderBy('LastModifiedDate DESC ')
            .withLimit(SOQL_LIMIT)
            .build();

        return duplicateRecordSetsQuery;
    }

    @TestVisible
    private void getUnactionableDuplicateRecordSets() {
        if (unactionableDuplicateRecordSets != null) {
            return;
        }
        unactionableDuplicateRecordSets = new Set<Id>();

        List<DuplicateRecordSet> mixedDRS = getMixedRecordTypeDuplicateRecordSetIds();
        if (mixedDRS.isEmpty()) {
            return;
        }

        List<AggregateResult> leadTotals = [
            SELECT DuplicateRecordSetId DRSId, COUNT(Id) ContactTotal
            FROM DuplicateRecordItem
            WHERE Record.Type = 'Contact'
            AND DuplicateRecordSetId IN :mixedDRS
            GROUP BY DuplicateRecordSetId, DuplicateRecordSet.RecordCount
        ];

        for (AggregateResult result : leadTotals) {
            if ((Integer) result.get('ContactTotal') <= 1) {
                unactionableDuplicateRecordSets.add((Id) result.get('DRSId'));
            }
        }
    }

    /**********************************************************************************************
    * @description Queries for mixed record type Duplicate Record Sets with at least one Contact.
    * @return List<DuplicateRecordSet>
    */
    private List<DuplicateRecordSet> getMixedRecordTypeDuplicateRecordSetIds() {
        String duplicateRecordSetsQuery =  new UTIL_Query()
            .withFrom(DuplicateRecordSet.sObjectType)
            .withSelectFields(new List<String>{'Id'})
            .withWhere(getMixedDuplicateRuleSetQueryWhereClause())
            .build();

        return (List<DuplicateRecordSet>) Database.query(duplicateRecordSetsQuery);
    }

    /**********************************************************************************************
    * @description Builds a where string used to query for Duplicate Record Sets.
    * Limits the query to Duplicate Record Sets that have both a Contact Duplicate Record Item
    * and a non-Contact Duplicate Record Item.
    * @return String Returns a where clause string
    */
    private String getMixedDuplicateRuleSetQueryWhereClause() {
        String duplicateRecordItemsForContacts = new UTIL_Query()
            .withFrom(DuplicateRecordItem.sObjectType)
            .withSelectFields(new List<String>{'DuplicateRecordSetId'})
            .withWhere('Record.Type = \'Contact\'')
            .build();
        String duplicateRecordItemsForNonContacts = new UTIL_Query()
            .withFrom(DuplicateRecordItem.sObjectType)
            .withSelectFields(new List<String>{'DuplicateRecordSetId'})
            .withWhere('Record.Type != \'Contact\'')
            .build();
        return 'Id IN (' + duplicateRecordItemsForContacts + ') AND ' +
            'Id IN (' + duplicateRecordItemsForNonContacts + ')';
    }

    /**********************************************************************************************
    * @description Builds a select string used to query for Duplicate Record Sets.
    * Includes a subquery for child Duplicate Record Items.
    * @return String Returns a select clause string
    */
    private List<String> getDuplicateRuleSetQuerySelectClause() {
        List<String> selectedFields = new List<String>();
        selectedFields.addAll(drsFieldNames);

        String subquery =  new UTIL_Query()
            .withFrom('DuplicateRecordItems')
            .withSelectFields(driFieldNames)
            .build();
        String subqueryStr = '(' + subquery + ')';

        selectedFields.add(subqueryStr);
        return selectedFields;
    }

    /**********************************************************************************************
    * @description Builds a where string used to query for Duplicate Record Sets.
    * Limits the query to Duplicate Record Sets that have more than 1 child Duplicate Record Item
    * and where all child Duplicate Record Items relate to a Contact.
    * @return String Returns a where clause string
    */
    private String getDuplicateRuleSetQueryWhereClause() {
        String duplicateRecordItemsForContacts = new UTIL_Query()
            .withFrom(DuplicateRecordItem.sObjectType)
            .withSelectFields(new List<String>{'DuplicateRecordSetId'})
            .withWhere('Record.Type = \'Contact\'')
            .build();
        return 'RecordCount > 1 AND Id IN ('
                + duplicateRecordItemsForContacts
                + ') AND Id NOT IN :unactionableDuplicateRecordSets';
    }

    /***********************************************************************************************
     * @description Displays the Search by Contact page of Contact Merge
     * 
     */
    public void showContactSearchPage() {
        loadMergePage = true;
        step = 1;
        searchText='';
        showContactSearch = true; 
        showDRSButton = true;
        showDRS = false;              
    }

    /***********************************************************************************************
     * @description Fetches the list of Duplicate Record Sets from standard set controller 
     * for pagination
     * @return List<DuplicateRecordSet> Returns the current list of Duplicate Record Sets
     */
    public List<DuplicateRecordSet> getDuplicateRecordSets() {
        return (List<DuplicateRecordSet>)drsSetController.getRecords();
    }

    /***********************************************************************************************
    * @description Calculates total number of pages of Duplicate Record Sets
    */
    public Integer getTotalPages() {
        return (Integer)Math.ceil(Decimal.valueOf(drsSetController.getResultSize())/pageSize);
    }

    /***********************************************************************************************
    * @description Fetches the records to be displayed on first page of Duplicate Record Sets
    */    
    public void firstPage() {
        drsSetController.first();
        listDuplicateRecordSets = getDuplicateRecordSets();
    }
    
    /***********************************************************************************************
    * @description Fetches the records to be displayed on previous page of Duplicate Record Sets
    */ 
    
    public void previousPage() {
        drsSetController.previous();
        listDuplicateRecordSets = getDuplicateRecordSets();
    }   
        
    /***********************************************************************************************
    * @description Fetches the records to be displayed on next page of Duplicate Record Sets
    */
    
    public void nextPage() {
        drsSetController.next();
        listDuplicateRecordSets = getDuplicateRecordSets();     
    }
    
    /***********************************************************************************************
    * @description Fetches the records to be displayed on last pages of Duplicate Record Sets
    */ 
    
    public void lastPage() {
        drsSetController.last();
        listDuplicateRecordSets = getDuplicateRecordSets();    
    }

}
