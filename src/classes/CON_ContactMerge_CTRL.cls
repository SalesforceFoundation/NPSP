/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @date 2011 (2.x)
* @description Controller for contact merge page 
*/
public with sharing class CON_ContactMerge_CTRL {
    
    public CON_ContactMerge_CTRL(){
        searchText='';
        searchResults = new List<contactWrapper>();
        selectedRecords = new Map<String, Contact>();
        displaySearchResults = false;
        step = 1;
        fieldRows = new List<FieldRow>();
    }
    
    private static final String MASTER_KEY = '$MASTER$';
    
    public boolean displaySearchResults {get; set;} 
     
    //string of search text entered by user
    public String searchText { get { return searchText; } set { searchText = value; } }
    
    //list of contactWrapper objects for display in search results pane
    public List<ContactWrapper> searchResults {get; private set;}
    
    //list of contactWrapper objects for display in search results pane
    private Map<String, Contact> selectedRecords;
    
    public Integer selectedRecordsCount {get; private set;} {this.selectedRecordsCount = 0;}
    
    //max number of Contacts returned by a query
    private final Integer SOSL_LIMIT = 20;
    
    public Integer step {get; private set;}
    
    //class to hold a contact and checkbox so we can select each contact
    public class contactWrapper {
        //the contact
        public Contact con {get; set;}
        //the checkbox variable
        public Boolean selected {get; set;}
        
        //constructor for contactWrapper class
        public contactWrapper(Contact c) {
            con = c;
            selected = false;
        }
    }
    
    public List<FieldRow> fieldRows {get; private set;}
    
    /**
    * The struct to save all the information belonging to each contact field, including values for all the contacts to merge.
    */
    public class FieldRow {
        public String fieldlabel {get; private set;} //Stores the field Label
        public String fieldName {get; private set;} // Stores the field api name
        public boolean showRadio {get; private set;} // Property to tell whether UI must should a radio to select the field value
        public List<Cell> values {get; private set;} // List of values for each contact record
        public String selectedValue {get; set;} // Selected record
        public String styleClass {get; private set;}
        
        public FieldRow() {
            this.values = new List<Cell>();
        }
        public FieldRow(String fieldName, String fieldlabel, boolean showRadio, String styleClass) {
            this();
            this.fieldName = fieldName;
            this.fieldlabel = fieldlabel;
            this.showRadio = showRadio;
            this.styleClass = styleClass;
        }
    }
    
    /**
    * The struct to save value of each cell for a corresponding field row in the UI table.
    */
    public class Cell {
        public String objId {get; private set;} // Id of the record to which this value belongs.
        public String value {get; private set;} // Actual value
        
        public Cell (String objectId, String value) {
            this.objId = objectId;
            this.value = value;
        }
    }
    
    // This is an action method for the "Select All" command link on the page to select all the values of a certain record.
    public void selectDefaultRecord() {
        String recordId = Apexpages.currentPage().getParameters().get('recordId');
        //System.debug('Selected Record: ' + recordId);
        if (recordId != null && selectedRecords.keySet().contains(recordId)) {
            for (FieldRow row : fieldRows) {
                if (row.showRadio) {
                    row.selectedValue = recordId; 
                }
            }
        }
    }
    
    // Action method to show the next step of the wizard where user can see the diff of the records before merge
    public void nextStep() {
        
        String contactIdFilter = ''; // String to create a list of contact Ids to query
        this.selectedRecordsCount = 0;
        for (ContactWrapper c : searchResults) {
            if (c.selected) {
                contactIdFilter += ('\'' + c.con.Id + '\',');
                this.selectedRecordsCount++;
            }
        }
        
        //To avoid out of bounds error if no contact is selected
        if(contactIdFilter.length() > 0) {
            contactIdFilter = contactIdFilter.substring(0, contactIdFilter.length() - 1);
        }
        
        // Check we have at least 2 and not more than 3 records selected for merge. If not throw an error. 
        if (this.selectedRecordsCount <=1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Too_Few_Contacts));
            return;
        }
        
        if (this.selectedRecordsCount >3 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Too_Many_Contacts));
            return;
        }
        
        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        Map<String, Schema.DescribeFieldResult> standardFieldMap = new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.DescribeFieldResult> customFieldMap = new Map<String, Schema.DescribeFieldResult>();
        
        // Construct the query string
        String query = 'Select id, name, ';
        for (String fieldName : contactFields.keySet()) {
            Schema.SobjectField f = contactFields.get(fieldName);
            Schema.DescribeFieldResult fResult = f.getDescribe();
            
            // Only include the fields which are updateable
            if (fResult.isUpdateable()) {
                // If the field is type lookup, select the parent name  
                if (fResult.getRelationshipName() == null) {
                    query += (fieldName + ',');
                } else {
                    query += (fResult.getRelationshipName() + '.name,');
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
        query += ' from Contact where id IN (' + contactIdFilter + ')';
        
        //System.debug('The contact query is: ' + query);
        
        List<Contact> contacts;
        try {
            contacts = Database.query(query); // Query the records
            // Ensure we got back the same number of records as expected. In case any record got deleted/moved since last search.
            if (contacts == null || contacts.size() != this.selectedRecordsCount) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Query_Failed + ' ' + label.npe01.Contact_Merge_Error_please_retry));
                return;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Contact_not_found  + ' Error: ' + e));
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
        List<String> customFieldList = new List<String>();
        customFieldList.addAll(customFieldMap.keySet());
        customFieldList.sort();
        
        // Add the first row of type header with contact names as titles
        FieldRow temp = new FieldRow('', '', false, 'header');
        for (Sobject c: contacts) {
            Contact con = (Contact) c;
            temp.values.add(new Cell(c.id, con.name));  
        }
        fieldRows.add(temp);
        
        // Add second row to select the master record. Select the one which is last modified
        temp = new FieldRow(MASTER_KEY, 'Master Record', true, null);
        {
            DateTime lastModifiedDate;
            for (Sobject c: contacts) {
                temp.values.add(new Cell(c.id, null));
                if (lastModifiedDate == null || 
                    (lastModifiedDate != null && (DateTime)c.get('lastModifiedDate') > lastModifiedDate)) {
                    temp.selectedValue = c.id;
                    lastModifiedDate = (DateTime)c.get('lastModifiedDate');
                }   
            }
        }
        fieldRows.add(temp);
        
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
        for (Sobject c: contacts) {
            SObject createdBy = c.getSObject('createdby');
            SObject modifiedBy = c.getSObject('lastModifiedBy');
            createdByRow.values.add(new Cell(c.id, createdBy.get('name') + ' ' + c.get('createdDate')));
            lastModifiedByRow.values.add(new Cell(c.id, modifiedBy.get('name') + ' ' + c.get('LastModifiedDate'))); 
        }
        fieldRows.add(createdByRow);
        fieldRows.add(lastModifiedByRow);
        
        // If everything looks good go to next step
        this.step++;
        
    }
    
    /**
    * Method to add field information and field values to the list of fieldRow
    */
    private void addFieldComparisonRows(String fieldName, Schema.DescribeFieldResult fieldDesc, List<SObject> objs) {
        // Create a new FieldRow item
        FieldRow row = new FieldRow();
        row.fieldName = fieldName;
        
        // For standrd lookup type fields, use the relationship name as the field label
        if (!fieldDesc.isCustom() && fieldDesc.getRelationshipName() != null) {
            row.fieldlabel = fieldDesc.getRelationshipName();
        } else {
            row.fieldlabel = fieldDesc.getlabel();
        }
        
        row.values = new List<Cell>();
        
        boolean isDifferent = false; // flag to indicate whether atleast one pair of field values is different across all contacts
        boolean isNull = true; // flag to indicate whether all the field values are null
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
                    values.add(String.valueOf(obj.get('name')));
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
                // Check if atleast one of the values is different. If yes then update the isDifferent flag
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
            // Dont let user choose the account as you dont want users to assign a differnt account in One to One case.
            row.showRadio = (isDifferent & !fieldName.equalsIgnoreCase('accountId'));
            fieldRows.add(row);
        }
    }
    
    //search for contacts
    public void search() {
        
        if(searchText != null && searchText.length()>0){
                        
            this.searchResults = wrapSOSLResults(mySOSL());
            if (searchResults.size() > 0) {
                displaySearchResults = true;
            }
        }
    }
    
    //run the SOSL
    public List<List<SObject>> mySOSL()
    {
        searchResults.clear();    
        
        //build the SOSL query and execute - NOTE: * wildcard will only have effect at the middle or end of the search term
        String searchquery = 'FIND \'' + String.escapeSingleQuotes(searchText) + '*\' IN ALL FIELDS RETURNING Contact(id, name, accountId, account.name, title, email, phone, ownerId, owner.name ORDER BY LastName LIMIT ' + SOSL_LIMIT + ')';
        //System.debug('Search Query: ' + searchquery);
        
        return search.query(searchquery);
        //List<List<SObject>> searchList = new List<List<SObject>>();
    }
    
    //wrap the SOSL results
    public List<ContactWrapper> wrapSOSLResults(List<List<SObject>> mySearchList){
        
        List<ContactWrapper> res = new List<ContactWrapper>();
        //loop through the contacts putting them in an array of wrappers
        if(mySearchList.size()>0){
            for (List<SObject> returnedObjects : mySearchList) {
                //System.debug('List size' + returnedObjects.size());
                for (SObject returnedObject : returnedObjects){
                    //if the returned object is a contact, add it to the Contact list
                    if(returnedObject.getSObjectType() == Contact.sObjectType){
                        contactWrapper thisResult = new contactWrapper((Contact) returnedObject);   
                        //System.debug('Contact Id: ' + returnedObject.id);
                        //System.debug('Contact: ' + returnedObject);         
                        res.add(thisResult);   
                    }
                }
            }
        }
        //System.debug('Search Results Map Size: ' + res.size());
        return res;       
    }
    
    //method to merge the winner and losers
    public PageReference mergeContacts() {
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
                if (row.showRadio && !row.fieldName.equals(MASTER_KEY) && row.selectedValue != master.id) {
                    SObject selectedRecord = this.selectedRecords.get(row.selectedValue);
                    
                    //System.debug('Assigning field: ' + row.fieldName);
                    
                    // Sobject.put is not happy when sobject.get returns null. It throws an exception System.SObjectException: Illegal assignment from Object to String.
                    // But instead when you pass a null directly to put, it works fine. And hence, this if statement.
                    if (selectedRecord.get(row.fieldName) == null) {
                        master.put(row.fieldName, null);    
                    } else {
                        Object val = selectedRecord.get(row.fieldName);
                        //System.debug('Setting value: ' + val);
                        master.put(row.fieldName, val);
                        //System.debug('Set value: ' + master.get(row.fieldName));
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
            List<Contact> lock = [Select id from Contact where id IN :allContacts for update];
            
            if (lock == null || lock.size() != allContacts.size()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Lock_failed  + ' ' + label.npe01.Contact_Merge_Error_please_retry) );
                return null;
            }
            
            System.SavePoint sp = Database.setSavepoint();
            try {
            	update master;
            	CON_ContactMerge.mergeContacts((Contact)master, losers);
            	// Update the master with the selected values
            	return new PageReference('/' + master.id);
            } catch (Exception e) {
                Database.rollback(sp);
                ERR_Handler.processError(e, ERR_Handler.Context.CON);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_Merge_Failed + ' Error: ' + e));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, label.npe01.Contact_Merge_Error_No_Master));
        }
        
        return null;
    }
}