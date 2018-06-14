/*
    Copyright (c) 2018 Salesforce.org
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
* @date 2018
* @group Utilities
* @description Unit tests for UTIL_OrderBy class
*/
@isTest(isParallel=true)
private class UTIL_OrderBy_TEST {
    private static final UTIL_OrderBy.SortingOrder SORT_DESC = UTIL_OrderBy.SortingOrder.DESCENDING;
    private static final UTIL_OrderBy.SortingOrder SORT_ASC = UTIL_OrderBy.SortingOrder.ASCENDING;
    private static final UTIL_OrderBy.NullsOrder NULLS_FIRST = UTIL_OrderBy.NullsOrder.FIRST;
    private static final UTIL_OrderBy.NullsOrder NULLS_LAST = UTIL_OrderBy.NullsOrder.LAST;
     
    /*******************************************************************************************************
    * @description Verifies toString() for an ORDER BY field
    */
    @isTest static void toStringReturnsOrderByForAField() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name);

        System.assertEquals('Name', field.toString());
    }

    /*******************************************************************************************************
    * @description Verifies toString() when sorting order is DESC
    */
    @isTest static void toStringReturnsOrderByForFieldAndDescSortOrder() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC);

        System.assertEquals('Name DESC', field.toString());
    }

    /*******************************************************************************************************
    * @description Verifies toString() when sorting order is ASC
    */
    @isTest static void toStringReturnsOrderByForFieldAndAscSortOrder() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_ASC);

        System.assertEquals('Name', field.toString());
    }

    /*******************************************************************************************************
    * @description Verifies toString() when sorting order is DESC and NULLS order is last
    */
    @isTest static void toStringReturnsOrderByForFieldAndSortOrderAndNullOrderLast() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC, NULLS_LAST);

        System.assertEquals('Name DESC NULLS LAST', field.toString());
    }

    /*******************************************************************************************************
    * @description Verifies toString() when sorting order is DESC and NULLS order is first
    */
    @isTest static void toStringReturnsOrderByForFieldAndSortOrderAndNullOrderFirst() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC, NULLS_FIRST);

        System.assertEquals('Name DESC', field.toString());
    }

    /*******************************************************************************************************
    * @description Verifies toString() when field is a reference field (Lookup/M-D)
    */
    @isTest static void toStringReturnsOrderByForRelationshipField() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name).fromRelationship(Contact.AccountId);

        System.assertEquals('Account.Name', field.toString());
    }

    /*******************************************************************************************************
    * @description Verifies the field name is returned
    */
    @isTest static void getFieldNameReturnsName() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name);

        System.assertEquals('Name', field.getFieldName());
    }

    /*******************************************************************************************************
    * @description Verifies correct field name is returned for a relationship field
    */
    @isTest static void getFieldNameReturnsNameForTheRelationshipField() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name).fromRelationship(Contact.AccountId);

        System.assertEquals('Name', field.getFieldName());
    }

    /*******************************************************************************************************
    * @description Verifies isSortDesc() returns true when sorting order is DESC
    */
    @isTest static void isSortDescReturnsTrueForDescSortOrder() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC);

        System.assert(field.isSortDesc());
    }

    /*******************************************************************************************************
    * @description Verifies isSortDesc() returns false when sorting order is ASC
    */
    @isTest static void isSortDescReturnsFalseForAscSortOrder() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_ASC);

        System.assert(!field.isSortDesc());
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() returns zero when sObjects have the same value for a field
    */
    @isTest static void compareToReturnsZeroWhenValuesAreTheSame() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);

        System.assertEquals(0, record.compareTo(other));
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() considers case sensitive same values as equal
    */
    @isTest static void compareToIsCaseInsensitive() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'FOO'), field);

        System.assertEquals(0, record.compareTo(other));
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting is ASC by default
    */
    @isTest static void compareToReturnsNegativeNumberWhenValuePreceedsOther() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'xyz'), field);

        System.assert(record.compareTo(other) < 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting when sort order is DESC
    */
    @isTest static void compareToReturnsPositiveNumberForDescOrder() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'xyz'), field);

        System.assert(record.compareTo(other) > 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting is ASC by default
    */
    @isTest static void compareToReturnsPositiveNumberWhenValueFollowsOther() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'abc'), field);

        System.assert(record.compareTo(other) > 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting when sort order is DESC
    */
    @isTest static void compareToReturnsNegativeNumberForDescOrder() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'abc'), field);

        System.assert(record.compareTo(other) < 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting for the NULLS LAST and ASC order
    */
    @isTest static void compareToReturnsNegativeNumberWhenOtherIsNullAscOrderNullsLast() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_ASC, NULLS_LAST);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

        System.assert(record.compareTo(other) < 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting for the NULLS FIRST and ASC order
    */
    @isTest static void compareToReturnsPostiveNumberWhenOtherIsNullAscOrderNullsFirst() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_ASC, NULLS_FIRST);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

        System.assert(record.compareTo(other) > 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting for the NULLS LAST and DESC order
    */
    @isTest static void compareToReturnsNegativeNumberWhenOtherIsNullDescOrderNullsLast() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC, NULLS_LAST);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

        System.assert(record.compareTo(other) < 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting for the NULLS FIRST and DESC order
    */
    @isTest static void compareToReturnsPositiveNumberWhenOtherIsNullDescOrderNullsFirst() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC, NULLS_FIRST);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(), field);

        System.assert(record.compareTo(other) > 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting for the NULLS LAST and specified ASC order
    */
    @isTest static void compareToReturnsPositiveNumberWhenValueIsNullAscOrderNullsLast() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_ASC, NULLS_LAST);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);

        System.assert(record.compareTo(other) > 0);
    }

    /*******************************************************************************************************
    * @description Verifies compareTo() sorting for the NULLS FIRST and specified ASC order
    */
    @isTest static void compareToReturnsNegativeNumberWhenValueIsNullAscOrderNullsFirst() {
        UTIL_OrderBy.FieldExpression field = new UTIL_OrderBy.FieldExpression(Account.Name, SORT_ASC, NULLS_FIRST);
        UTIL_OrderBy.SortableRecord record = new UTIL_OrderBy.SortableRecord(new Account(), field);
        UTIL_OrderBy.SortableRecord other = new UTIL_OrderBy.SortableRecord(new Account(Name = 'foo'), field);

        System.assert(record.compareTo(other) < 0);
    }

    /*******************************************************************************************************
    * @description Verifies post sorting is applied for the ORDER BY field expression
    */
    @isTest static void sortOrdersRecordsManuallyWhenTheFieldIsNotSortable() {
        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.LastName));
        orderBy.isPostSort = true;

        List<sObject> records = new List<sObject>{
            new Contact(LastName = 'FOO'),
            new Contact(LastName = 'xyz'),
            new Contact(LastName = 'foo'),
            new Contact(LastName = 'abc')
        };

        List<sObject> sortedRecords = orderBy.sort(records);
        System.assertEquals('abc', (String) sortedRecords[0].get('LastName'));
        System.assertEquals('foo', ((String) sortedRecords[1].get('LastName')).toLowerCase());
        System.assertEquals('foo', ((String) sortedRecords[2].get('LastName')).toLowerCase());
        System.assertEquals('xyz', (String) sortedRecords[3].get('LastName'));
    }

    /*******************************************************************************************************
    * @description Verifies post sorting is applied correctly based on the ORDER BY field expressions
    */
    @isTest static void sortOrdersRecordsManuallyWhenFieldsAreNotSortable() {
        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.LastName));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.FirstName));
        orderBy.isPostSort = true;

        List<sObject> records = new List<sObject>{
            new Contact(LastName = 'foo', FirstName = 'zbar'),
            new Contact(LastName = 'xyz', FirstName = 'bar'),
            new Contact(LastName = 'foo', FirstName = 'abar'),
            new Contact(LastName = 'abc', FirstName = 'xbar')
        };

        List<sObject> sortedRecords = orderBy.sort(records);
        System.assertEquals('abc', (String) sortedRecords[0].get('LastName'));
        System.assertEquals('abar', (String) sortedRecords[1].get('FirstName'));
        System.assertEquals('zbar', (String) sortedRecords[2].get('FirstName'));
        System.assertEquals('xyz', (String) sortedRecords[3].get('LastName'));
    }

    /*******************************************************************************************************
    * @description Verifies post sorting when records should be sorted with NULLS FIRST order
    */
    @isTest static void sortOrdersRecordsManuallyWhenTheValueIsNullForNullsFirst() {
        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.LastName, SORT_ASC, NULLS_FIRST));
        orderBy.isPostSort = true;

        List<sObject> records = new List<sObject>{
            new Contact(LastName = 'foo'),
            new Contact(FirstName = 'rafael'),
            new Contact(LastName = 'xyz'),
            new Contact(LastName = 'abc')
        };

        List<sObject> sortedRecords = orderBy.sort(records);
        System.assertEquals('rafael', (String) sortedRecords[0].get('FirstName'));
        System.assertEquals('abc', (String) sortedRecords[1].get('LastName'));
        System.assertEquals('foo', (String) sortedRecords[2].get('LastName'));
        System.assertEquals('xyz', (String) sortedRecords[3].get('LastName'));
    }

    /*******************************************************************************************************
    * @description Verifies post sorting when records should be sorted with NULLS LAST order
    */
    @isTest static void sortOrdersRecordsManuallyWhenTheValueIsNullForNullsLast() {
        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.LastName, SORT_ASC, NULLS_LAST));
        orderBy.isPostSort = true;

        List<sObject> records = new List<sObject>{
            new Contact(LastName = 'foo'),
            new Contact(FirstName = 'rafael'),
            new Contact(LastName = 'xyz'),
            new Contact(LastName = 'abc')
        };

        List<sObject> sortedRecords = orderBy.sort(records);
        System.assertEquals('abc', (String) sortedRecords[0].get('LastName'));
        System.assertEquals('foo', (String) sortedRecords[1].get('LastName'));
        System.assertEquals('xyz', (String) sortedRecords[2].get('LastName'));
        System.assertEquals('rafael', (String) sortedRecords[3].get('FirstName'));
    }

    /*******************************************************************************************************
    * @description Verifies sorting of records is ASC by default
    */
    @isTest static void sortOrdersRecordsOrderAscByDefault() {
        List<Account> records = new List<Account>{
            new Account(Name = 'foo asc'),
            new Account(Name = 'xyz asc'),
            new Account(Name = 'abc asc')
        };
        insert records;

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Account.Name));
        orderBy.isPostSort = true;

        List<sObject> sortedRecords = orderBy.sort(records);
        System.assertEquals(records.size(), sortedRecords.size());

        System.assertEquals(records[2].Name, (String) sortedRecords[0].get('Name'));
        System.assertEquals(records[0].Name, (String) sortedRecords[1].get('Name'));
        System.assertEquals(records[1].Name, (String) sortedRecords[2].get('Name'));
    }

    /*******************************************************************************************************
    * @description Verifies sorting of records when order is DESC
    */
    @isTest static void sortOrdersRecordsOrderDesc() {
        List<Account> records = new List<Account>{
            new Account(Name = 'foo desc'),
            new Account(Name = 'xyz desc'),
            new Account(Name = 'abc desc')
        };
        insert records;

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Account.Name, SORT_DESC));
        orderBy.isPostSort = true;

        List<sObject> sortedRecords = orderBy.sort(records);
        System.assertEquals(records.size(), sortedRecords.size());

        System.assertEquals(records[1].Name, (String) sortedRecords[0].get('Name'));
        System.assertEquals(records[0].Name, (String) sortedRecords[1].get('Name'));
        System.assertEquals(records[2].Name, (String) sortedRecords[2].get('Name'));
    }

    /*******************************************************************************************************
    * @description Verifies sorting when ORDER BY contains multiple field expressions
    */
    @isTest static void sortOrdersRecordsTheSameAsSoqlWithMultipleFields() {
        List<Contact> records = new List<Contact>{
            new Contact(LastName = 'xyz', FirstName = 'John', Title = 'Administrator'),
            new Contact(LastName = 'xyz', FirstName = 'Jane', Title = 'Business Manager'),
            new Contact(LastName = 'abc', FirstName = 'Kent', Title = 'Business Manager'),
            new Contact(LastName = 'abc', FirstName = 'Kent', Title = 'Administrator'),
            new Contact(LastName = 'abc', FirstName = 'Abby', Title = 'Executive')
        };
        insert records;

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.LastName));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.FirstName));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.Title));
        orderBy.isPostSort = true;

        List<sObject> sortedRecords = orderBy.sort(records);
        
        List<Contact> expectedRecords = new List<Contact>{
            records[4], records[3], records[2], records[1], records[0]
        };
        for (Integer i = 0; i < records.size(); i++) {
            System.assertEquals(expectedRecords[i].LastName, (String) sortedRecords[i].get('LastName'));
            System.assertEquals(expectedRecords[i].FirstName, (String) sortedRecords[i].get('FirstName'));
            System.assertEquals(expectedRecords[i].Title, (String) sortedRecords[i].get('Title'));
        }
    }

    /*******************************************************************************************************
    * @description Verifies sorting of records when the ORDER BY field is a reference field
    */
    @isTest static void sortOrdersRecordsTheSameAsSoqlWithRelationshipFields() {
        List<sObject> accounts = new List<sObject>{
            new Account(Name = 'foo related'),
            new Account(Name = 'xyz related'),
            new Account(Name = 'abc related')
        };
        insert accounts;

        List<Contact> records = new List<Contact>{
            new Contact(AccountId = accounts[0].Id, LastName = 'Foo', FirstName = 'John', Title = 'Administrator'),
            new Contact(AccountId = accounts[1].Id, LastName = 'Foo', FirstName = 'Jane', Title = 'Business Manager'),
            new Contact(AccountId = accounts[2].Id, LastName = 'Bar', FirstName = 'Kent', Title = 'Business Manager'),
            new Contact(AccountId = accounts[0].Id, LastName = 'Bar', FirstName = 'Kent', Title = 'Administrator'),
            new Contact(AccountId = accounts[1].Id, LastName = 'Bar', FirstName = 'Abby', Title = 'Executive')
        };
        insert records;
        records = [
            SELECT Name, FirstName, LastName, Title, AccountId, Account.Name
            FROM Contact 
        ];

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(new UTIL_OrderBy.FieldExpression(Account.Name).fromRelationship(Contact.AccountId));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.LastName));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.FirstName));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.Title));
        orderBy.isPostSort = true;

        List<sObject> sortedRecords = orderBy.sort(records);

        List<Contact> expectedRecords = new List<Contact>{
            records[2], records[3], records[0], records[4], records[1]
        };
        for (Integer i = 0; i < expectedRecords.size(); i++) {
            System.assertEquals(expectedRecords[i].LastName, (String) sortedRecords[i].get('LastName'));
            System.assertEquals(expectedRecords[i].FirstName, (String) sortedRecords[i].get('FirstName'));
            System.assertEquals(expectedRecords[i].Title, (String) sortedRecords[i].get('Title'));
            System.assertEquals(expectedRecords[i].AccountId, (Id) sortedRecords[i].get('AccountId'));
        }
    }

    /*******************************************************************************************************
    * @description Verifies empty ORDER BY clause when a field in the ORDER BY is not sortable
    */
    @isTest static void buildReturnsEmptyOrderByClauseWhenAFieldIsNotSortable() {
        UTIL_OrderBy.FieldExpression lNameFieldExp = new UTIL_OrderBy.FieldExpression(Contact.LastName, SORT_DESC);
        lNameFieldExp.isSortable = false;

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        orderBy.add(lNameFieldExp);
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.FirstName, SORT_ASC, NULLS_LAST));
        orderBy.add(new UTIL_OrderBy.FieldExpression(Contact.Title));

        String orderByClause = orderBy.build();

        // if any field is encrypted, then order by clause should be empty and post sort should be applied
        System.assertEquals('', orderByClause);
        System.assert(orderBy.isPostSort, 'The Order By should be post sortable');
    }

    /*******************************************************************************************************
    * @description Verifies the ORDER BY clause when all ORDER BY fields are sortable
    */
    @isTest static void buildReturnsOrderByClauseWhenAllFieldsAreSortable() {
        List<UTIL_OrderBy.FieldExpression> fieldExps = new List<UTIL_OrderBy.FieldExpression>{
            new UTIL_OrderBy.FieldExpression(Contact.LastName, SORT_DESC),
            new UTIL_OrderBy.FieldExpression(Contact.FirstName, SORT_ASC, NULLS_LAST),
            new UTIL_OrderBy.FieldExpression(Contact.Title)
        };

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        for (UTIL_OrderBy.FieldExpression fieldExp : fieldExps) {
            fieldExp.isSortable = true;
            orderBy.add(fieldExp);
        }

        String orderByClause = orderBy.build();

        System.assertEquals('LastName DESC, FirstName NULLS LAST, Title', orderByClause);
        System.assert(!orderBy.isPostSort, 'The Order By should not be post sortable');
    }

    /*******************************************************************************************************
    * @description Verifies empty ORDER BY clause no ORDER BY has no field expression
    */
    @isTest static void buildCreatesEmptyOrderByClauseWhenFieldsAreNotProvided() {
        UTIL_OrderBy orderBy = new UTIL_OrderBy();

        String orderByClause = orderBy.build();
        System.assertEquals('', orderByClause);
    }

    /*******************************************************************************************************
    * @description Verifies getValue() returns the field value on the passed in sObject
    */
    @isTest static void getValueReturnsSObjectFieldValue() {
        Id accountId = UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID;
        Id contactId = Contact.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        Account acc = new Account(Name = 'AccFieldValueTest');
        Contact con = new Contact(LastName = 'Smith', Id = contactId);

        Opportunity opp = new Opportunity(
            Name = 'OppFieldValueTest',
            AccountId = accountId,
            Account = acc,
            Primary_Contact__c = contactId,
            Primary_Contact__r = con
        );

        UTIL_OrderBy orderBy = new UTIL_OrderBy();
        System.assertEquals(opp.Name, new UTIL_OrderBy.FieldExpression(Opportunity.Name).getValue(opp));
        System.assertEquals(accountId, new UTIL_OrderBy.FieldExpression(Opportunity.AccountId).getValue(opp));
        System.assertEquals(acc.Name, new UTIL_OrderBy.FieldExpression(Account.Name).fromRelationship(Opportunity.AccountId).getValue(opp));
        System.assertEquals(contactId, new UTIL_OrderBy.FieldExpression(Opportunity.Primary_Contact__c).getValue(opp));
        System.assertEquals(con.LastName, new UTIL_OrderBy.FieldExpression(Contact.LastName).fromRelationship(Opportunity.Primary_Contact__c).getValue(opp));
    }

}