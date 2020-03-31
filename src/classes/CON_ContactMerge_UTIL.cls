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
* @description Controller for the NPSP contact merge page.
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/

public virtual with sharing class CON_ContactMerge_UTIL {

    private static final String MASTER_KEY = '$MASTER$';
    /***********************************************************************************************
    * @description Number of selected records.
    */
    public Integer selectedRecordsCount { get; private set; } { this.selectedRecordsCount = 0; }
    
    /***********************************************************************************************
     * @description The rows to merge.
     */
    public List<FieldRow> fieldRows;

    /***********************************************************************************************
     * @description Map of the contacts selected for merge.
     */ 
    private Map<String, Contact> selectedRecords;

    /***********************************************************************************************
    * @description we have to maintain our own set of readonly fields, because 
    * RLLP_OppRollup_UTIL.ContactFields doesn't include them all
    */
    private static List<String> listStrField = new List<String>{
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
        'Soft_Credit_Last_N_Days__c',
        'npo02__Soft_Credit_Last_Year__c',
        'npo02__Soft_Credit_This_Year__c',
        'npo02__Soft_Credit_Total__c',
        'npo02__Soft_Credit_Two_Years_Ago__c',
        'First_Soft_Credit_Amount__c',
        'First_Soft_Credit_Date__c',
        'Largest_Soft_Credit_Amount__c',
        'Largest_Soft_Credit_Date__c',
        'Last_Soft_Credit_Amount__c',
        'Last_Soft_Credit_Date__c',
        'Number_of_Soft_Credits__c',
        'Number_of_Soft_Credits_Last_N_Days__c',
        'Number_of_Soft_Credits_Last_Year__c',
        'Number_of_Soft_Credits_This_Year__c',
        'Number_of_Soft_Credits_Two_Years_Ago__c'
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
        * @param contactObj The contact to wrap.
        */
        public ContactWrapper(Contact contactObj) {
            contactRecord = contactObj;
            selected = false;
        }
    }

    /***********************************************************************************************
    * @description The struct to save all the information belonging to each contact field, 
    * including values for all the contacts to merge.
    */
    public class FieldRow {
        /*******************************************************************************************
        * @description Stores the field Label.
        */
        public String fieldLabel { get; private set; }
        /*******************************************************************************************
        * @description Stores the field api name.
        */
        public String fieldName { get; private set; }
        /*******************************************************************************************
        * @description Property to tell whether UI must should a radio to select the field value.
        */
        public boolean showRadio { get; private set; }
        /*******************************************************************************************
        * @description  List of values for each contact record.
        */
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
        * @param showRadio Wether a radio button should be displayed for the row.
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
    
    public CON_ContactMerge_UTIL() {

        fieldRows = new List<FieldRow>();
        selectedRecords = new Map<String, Contact>();
    }
    
    /***********************************************************************************************
    * @description Wraps the SOQL results.
    * @param contactResults The list of SObjects to wrap.
    * @return List<ContactWrapper> Those records from the passed parameter that are of type 
    * Contact are returned in this list, inside wrappers.
    */
    public List<ContactWrapper> wrapQueryResults(List<SObject> contactResults) {
        List<ContactWrapper> res = new List<ContactWrapper>();
        for (SObject returnedObject : contactResults) {
            ContactWrapper thisResult = new ContactWrapper((Contact) returnedObject);
            res.add(thisResult);
        }
        return res;
    }

    /***********************************************************************************************
    * @description Shows the next step of the wizard where user can see the diff of the records 
    * before merge.
    * @param searchResults The list of ContactWrapper from which the contacts are selected to merge.
    * @return List<FieldRow> List of the fields and field values of the selected contacts to merge.
    */
    public List<FieldRow> nextStep(List<ContactWrapper> searchResults) {

        Set<Id> mergeIds = new Set<Id>();
        for (ContactWrapper con : searchResults) {
            if (con.selected) {
                mergeIds.add(con.contactRecord.Id);
            }
        }
        return loadMergeCandidates(mergeIds);
    }

    /***********************************************************************************************
    * @description Shows the next step of the wizard where user can see the diff of the records 
    * before merge.
    * @param mergeCandidates Selected contacts to merge.
    * @return List<FieldRow> List of the fields and field values of the selected contacts to merge.
    */
    public List<FieldRow> loadMergeCandidates(Set<Id> mergeCandidates) {

        // Check we have atleast 2 and not more than 3 records selected for merge. 
        //If not throw an error.
        if (mergeCandidates.size() <= 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                Label.npe01.Contact_Merge_Error_Too_Few_Contacts));
            return null;
        }

        if (mergeCandidates.size() > 3 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                Label.npe01.Contact_Merge_Error_Too_Many_Contacts));
            return null;
        }

        selectedRecordsCount = mergeCandidates.size();

        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        Map<String, Schema.DescribeFieldResult> standardFieldMap = 
            new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.DescribeFieldResult> customFieldMap = 
            new Map<String, Schema.DescribeFieldResult>();

        // Construct the query string
        String query = 'SELECT Id, Name, ';
        for (String fieldName : contactFields.keySet()) {
            Schema.SobjectField field = contactFields.get(fieldName);
            Schema.DescribeFieldResult fieldResult = field.getDescribe();

            // Ignore fields that have an identical API name as 
            //an npsp prefixed field
            // This is due to a bug in dynamic SOQL,
            // quich causes querying for two real fields,
            // e.g. npsp__foo__c and foo__c, to throw a 
            // duplicate field selected error.
            // Only select the NPSP namespaced field and ignore 
            // the same field without namespace
            if (!String.isBlank(UTIL_Namespace.getNamespace()) && 
                !fieldName.startsWith(UTIL_Namespace.getNamespace()+'__') &&
                contactFields.containsKey(UTIL_Namespace.StrTokenNSPrefix(fieldName))) {

                continue;
            }

            // Only include the fields which are updateable and accessible
            if (fieldResult.isUpdateable() && fieldResult.isAccessible() && 
                !isNPSPHiddenField(fieldname)) {
                // If the field is type lookup, select the parent name
                String relName = fieldResult.getRelationshipName();
                if (String.isBlank(relName)) {
                    query += (fieldName + ',');
                } else {
                    //find the Name field for the related object
                    String nameField = getRelatedObjNameField(fieldResult);

                    if (nameField != null) {
                        query += (relName + '.' + nameField + ',');
                    }
                }
                // Collect the standard and custom fields separately for sorting
                if(fieldResult.isCustom()) {
                    customFieldMap.put(fieldName, fieldResult);
                } else {
                    standardFieldMap.put(fieldName, fieldResult);
                }
            }
        }
        // Adding some non-updateable system fields which we need to add to the record diff table.
        query +=  'Createdby.Name, Createddate, LastModifiedBy.Name, LastModifiedDate';
        // Finally completing the query by appending the table name and the filter clause
        query += ' FROM Contact WHERE Id IN :mergeCandidates';
        List<Contact> contacts;
        try {
            contacts = Database.query(query); // Query the records
            // Ensure we got back the same number of records as expected. 
            // In case any record got deleted/moved since last search.
            if (contacts == null || contacts.size() != mergeCandidates.size()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    Label.npe01.Contact_Merge_Error_Query_Failed + ' ' + 
                    Label.npe01.Contact_Merge_Error_please_retry));
                return null;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                Label.npe01.Contact_Merge_Error_Contact_not_found + ' Error: ' + e));
            return null;
        }

        if (!canUserDeleteSelectedContacts(mergeCandidates)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                System.Label.conMergeErrorNoDeleteRecAccess));
            return null;
        }

        // Update the list of searched records with only the ones selected
        for (Contact con : contacts) {
            this.selectedRecords.put(con.id, con);
        }

        // Sort the standard fields list by name before creating the list of FieldRow for merge UI
        List<String> standardFieldList = new List<String>();
        standardFieldList.addAll(standardFieldMap.keySet());
        standardFieldList.sort();

        // Sort the custom fields list by name before creating the list of FieldRow for merge UI
        List<String> customFieldList = new List<String>();
        customFieldList.addAll(customFieldMap.keySet());
        customFieldList.sort();

        // Add the first row of type header with contact names as titles
        FieldRow temp = new FieldRow('', '', false, 'header');
        for (Contact c: contacts) {
            Contact con = (Contact) c;
            temp.values.add(new Cell(c.id, con.name));
        }
        fieldRows.add(temp);

        // Add second row to select the master record. Select the one which is last modified
        temp = new FieldRow(MASTER_KEY, 'Master Record', true, null);
        DateTime lastModifiedDate;
        for (Contact con: contacts) {
            temp.values.add(new Cell(con.id, null));
            if (lastModifiedDate == null ||
                (lastModifiedDate != null && 
                 (DateTime)con.get('lastModifiedDate') > lastModifiedDate)) {
                temp.selectedValue = con.id;
                lastModifiedDate = (DateTime)con.get('lastModifiedDate');
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
            addFieldComparisonRows(standardFieldMap.get(fieldName), contacts);
        }

        // Add a dummy row to add a 'Custom Fields' header before the list of custom fields
        fieldRows.add(new FieldRow('Custom Fields', 'Custom Fields', false, 'separator'));

        // Add all custom fields to the list of FieldRow in sorted manner
        for (String fieldName: customFieldList) {
            addFieldComparisonRows(customFieldMap.get(fieldName), contacts);
        }

        // Add a dummy row to add a 'System Fields' header before the list of system fields
        fieldRows.add(new FieldRow('System Fields', 'System Fields', false, 'separator'));

        // Add created by and last modified by system fields to the list of FieldRow
        FieldRow createdByRow = new FieldRow('CreatedById', 'Created By', false, null),
            lastModifiedByRow = new FieldRow('LastModifiedById', 'Last Modified By', false, null);
        for (Contact con: contacts) {
            SObject createdBy = con.getSObject('createdby');
            SObject modifiedBy = con.getSObject('lastModifiedBy');
            createdByRow.values.add(new Cell(con.id, 
                (createdBy != null ? createdBy.get('name') : '')
                + ' ' + con.get('createdDate')));
            lastModifiedByRow.values.add(new Cell(con.id, 
                (modifiedBy != null ? modifiedBy.get('name') : '') 
                + ' ' + con.get('LastModifiedDate')));
        }
        fieldRows.add(createdByRow);
        fieldRows.add(lastModifiedByRow);

        return fieldRows;

    }

    /***********************************************************************************************
    * @description Adds field information and field values to the list of field rows.
    * @param fieldDesc Field of the selected contacts to be merged
    * @param objs Object to which the field belong
    */
    private void addFieldComparisonRows(Schema.DescribeFieldResult fieldDesc, List<SObject> objs) {
        String fieldName = String.valueOf(fieldDesc.getName());
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
        
        // flag to indicate whether atleast one pair of field values is different across all contacts
        Boolean isDifferent = false; 
        // flag to indicate whether all the field values are null
        Boolean isNull = true; 
        Integer idx = 0;

        List<String> values = new List<String>();
        DateTime lastModifiedDate = null;
        String prev;

        // Iterate over all contacts to find the field values and add them to row values
        for (SObject c : objs) {
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
                // Check if atleast one of the values is different. If yes then update the 
                // isDifferent flag
                String current = String.valueOf(c.get(fieldName));
                if ((prev != null && !prev.equals(current)) ||
                    (current != null && !current.equals(prev))) {
                    isDifferent = true;
                }
                prev = current;
            }

            // Select the default value for the field.A non-null value on the latest modified record
            if (c.get(fieldName) != null && (lastModifiedDate == null ||
                (lastModifiedDate != null && 
                 (DateTime)c.get('lastModifiedDate') > lastModifiedDate))) {
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
            // Show the select radio only if the field 
            // values are different.
            // Dont let user choose the account as you dont want users to 
            // assign a differnt account in One to One case.
            row.showRadio = (isDifferent && 
                !fieldName.equalsIgnoreCase('accountId') && 
                !isNPSPReadOnly(fieldName));
            fieldRows.add(row);
        }
    }

    /***********************************************************************************************
    * @description returns whether the field should be treated as an NPSP read only field,
    * typically one of our rollup fields that get automatically populated by rollups, 
    * and users should not direclty modify.
    * @param strField Field name
    * @return boolean true if should be treated as readonly, false if not.
    */
    private Boolean isNPSPReadOnly(String strField) {
        for (String strF : listStrField) {
           if (strField.equalsIgnoreCase(strF))
               return true;
        }
        return false;
    }

    /***********************************************************************************************
    * @description returns whether the field should be treated as an NPSP hidden field, typically 
    * one of our deprecated or system fields
    * @param strField Field name
    * @return boolean true if should be treated as hidden, false if not.
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
    * @description Returns a referenced object's name field.
    * @param Schema.DescribeFieldResult Object fields 
    * @return string The name of the name field, or null if we couldn't find one.
    */
    private String getRelatedObjNameField(Schema.DescribeFieldResult fieldDesc) {
        String nameField = 'Name';
        Map<String, Schema.SObjectField> mapRelatedObjectFields = fieldDesc
            .getReferenceTo()[0]
            .getDescribe()
            .fields.getMap();

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
    * @description checks if the logged in user have delete permission for the selected records.
    * @param ContactIds list of contacts
    * @return Boolean  true if delete access is allowed.
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
    * @description Merges the winner and losers.
    * @param fieldRows List of field and field values of the contacts to be merged
    * @return Id Winning record Id
    */
    public Id mergeContacts(List<FieldRow> fieldRows) {
        SObject master;
        // Find the master record based the selected value of the Master FieldRow
        for (FieldRow row : fieldRows) {
            if (row.showRadio && row.fieldName.equals(MASTER_KEY)) {
                master = new Contact(id = row.selectedValue);
                break;
            }
        }

        if (master != null) {
            // Update the field values of master record based on the selected value for each field.
            for (FieldRow row : fieldRows) {
                if (row.showRadio && 
                    !row.fieldName.equals(MASTER_KEY) && 
                    row.selectedValue != master.id) {
                    SObject selectedRecord = this.selectedRecords
                        .get(row.selectedValue);
                    // Sobject.put is not happy when sobject.get returns null. 
                    // It throws an exception System.SObjectException: Illegal 
                    // assignment from Object to String.
                    // But instead when you pass a null directly to put, it works fine. 
                    // And hence, this if statement.
                    if (selectedRecord.get(row.fieldName) == null) {
                        master.put(row.fieldName, null);
                    } else {
                        Object val = selectedRecord.get(row.fieldName);
                        master.put(row.fieldName, val);
                    }
                }
            }

            // Group all the loosing records separately.
            List<Contact> losers = new List<Contact>();

            for (Contact c : this.selectedRecords.values()) {
                if (c.id != master.id) {
                    losers.add(c);
                }
            }

            // before proceeding further first lock the records for change
            List<Contact> allContacts = new List<Contact>();
            allContacts.add((Contact)master);
            allContacts.addAll(losers);
            List<Contact> lock = [
                SELECT Id 
                FROM Contact 
                WHERE Id IN :allContacts for update];

            if (lock == null || lock.size() != allContacts.size()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    label.npe01.Contact_Merge_Error_Lock_failed  + ' ' + 
                    label.npe01.Contact_Merge_Error_please_retry) );
                return null;
            }

            System.SavePoint sp = Database.setSavepoint();
            try {
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.AllowSave = true;
                // We need to turn off Affiliation processing or there will be duplicate 
                // affiliates created after the merge.  
                // As merge transactions do not fire child triggers
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.AFFL_doNotRunForContacts, true);

                Database.SaveResult sr = UTIL_DMLService.updateRecord(master, dml);
                if (!sr.isSuccess()) {
                    String strErr = label.npe01.Contact_Merge_Error_Merge_Failed + ' Error: ';
                    for (Database.Error err : sr.getErrors()) {
                        strErr += err.getMessage() + '\n';
                    }
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, strErr));
                    return null;
                }

                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.AFFL_doNotRunForContacts, false);

                CON_ContactMerge.mergeContacts((Contact)master, losers);
                // Update the master with the selected values
                return master.id;
            } catch (Exception e) {
                Database.rollback(sp);
                ERR_Handler.processError(e, ERR_Handler_API.Context.CON);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                    label.npe01.Contact_Merge_Error_Merge_Failed + ' Error: ' + e));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 
                label.npe01.Contact_Merge_Error_No_Master));
        }

        return null;
    }

    /***********************************************************************************************
    * @description Selects all the values of a certain record. Used by the "Select All" command link 
    * on the page.
    * @param recordId Id of the record for which 'Select All' is clicked
    * @return FieldRow Fields and fieldvalues of the record for which 'Select All' is clicked 
    */

    public List<FieldRow> selectDefaultRecord(Id recordId) {
        if (recordId != null && selectedRecords.keySet().contains(recordId)) {
            for (FieldRow row : fieldRows) {
                if (row.showRadio) {
                    row.selectedValue = recordId;
                }
            }
        }
        return fieldRows;
    }
}
