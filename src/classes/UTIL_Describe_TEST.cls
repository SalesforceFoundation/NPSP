/*
    Copyright (c) 2014 Salesforce.org
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
/**
* @author Salesforce.org
* @date 2014
* @group Utilities
* @description This class allows easy access to object and field description information from within other classes.
*
* It is called statically, and therefore will supply the same information to all calls made from
* within one transaction, or set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient.
*/
@isTest
public with sharing class UTIL_Describe_TEST {

    // TEST
    static testmethod void testDescribe() {
        
        string s;
        
        Schema.DescribeSObjectResult res = UTIL_Describe.getObjectDescribe('Contact');        
        system.assertEquals(res.getName(), 'Contact');
        s = UTIL_Describe.getObjectLabel('Contact');
        system.assertEquals (s, res.getLabel());

        account a = new account(name='Test');
        insert a;
        system.assert(UTIL_Describe.isObjectIdThisType(a.id, 'Account'));
        
        s = UTIL_Describe.getFieldLabel('Account', 'LastModifiedDate');
        
        Schema.DescribeFieldResult fr = UTIL_Describe.getFieldDescribe('Account', 'CreatedDate');     
        s = UTIL_Describe.getFieldLabel('Account', 'CreatedDate');
        system.assertEquals (s, fr.getLabel());

        Map<String, Schema.DescribeFieldResult> afd = UTIL_Describe.getAllFieldsDescribe('Account');
        system.assertEquals ('BillingCity', afd.get('billingcity').getName());
        afd = UTIL_Describe.getAllFieldsDescribe('Account');

        SObject acctObj = UTIL_Describe.getPrototypeObject('Account');
        // should be able to cast to account
        account acct = (account)(acctObj);

        s = UTIL_Describe.getFieldType('Account', 'CreatedDate');
        system.assertEquals('DATETIME', s);
        
        s = UTIL_Describe.getNameField('Account');
        system.assertEquals('name', s);

        try {
            s = UTIL_Describe.getObjectLabel('sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            system.assertEquals('Invalid object name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
        try {
            s = UTIL_Describe.getFieldLabel('Opportunity', 'sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (exception e) {
            system.assertEquals('Invalid field name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        } 
    }  

    /*********************************************************************************************************
    @description
        Test getFieldResultsByName() for an Sobject
    verify:
        The method returns field results by the field name or relationship name for the specified Sobject
    **********************************************************************************************************/ 
    private static testMethod void getFieldResultsByNameShouldReturnFieldResultsForAnSobject() {
        Map<String, Schema.DescribeFieldResult> fieldResultsByName = UTIL_Describe.getFieldResultsByName(Contact.SObjectType);

        for (String fieldName : new String[] {
            'firstname', 'accountid', 'account', 'ownerid', 'owner'
        }) {
            System.assert(fieldResultsByName.containsKey(fieldName), fieldName + ' should be in Contact fields: ' + fieldResultsByName.keySet());
        }
        
        fieldResultsByName = UTIL_Describe.getFieldResultsByName(Opportunity.SObjectType);

        for (String fieldName : new String[] {
            'name', 'stagename', 'accountid', 'account'
        }) {
            System.assert(fieldResultsByName.containsKey(fieldName), fieldName + ' should be in Opportunity fields: ' + fieldResultsByName.keySet());
        }
    }

    /*********************************************************************************************************
    @description
        Test isValidField() when a field name is valid field for the Sobject
    verify:
        The method returns true
    **********************************************************************************************************/ 
    private static testMethod void isValidFieldShouldReturnTrueWhenFieldNameIsValid() {
        Map<String, Schema.DescribeFieldResult> contactFieldResultsByName = UTIL_Describe.getFieldResultsByName(Contact.SObjectType);

        for (String fieldName : new String[] {
            'Name', 'FirstName', 'LastName',
            'NaMe', 'FIRSTname', 'lastNAME',
            'AccountId', 'AccountID', 'Account.Id', 'Account.Name', 
            'Account.BillingCity', 'Account.npe01__One2OneContact__c',
            'Account.npe01__One2OneContact__r.LastName',
            'OwnerId', 'Owner.Name', 
            'Account.npe01__One2OneContact__r.Primary_Affiliation__r.Name',
            'ACCOUNT.npe01__ONE2ONECONTACT__R.PRIMARY_AFFILIATION__r.NAME'
        }) {
            System.assert(UTIL_Describe.isValidField(fieldName, contactFieldResultsByName), fieldName + ' should be valid');
        }
    }

    /*********************************************************************************************************
    @description
        Test isValidField() when a field name is invalid field for the Sobject
    verify:
        The method returns false
    **********************************************************************************************************/ 
    private static testMethod void isValidFieldShouldReturnFalseWhenFieldNameIsInvalid() {
        Map<String, Schema.DescribeFieldResult> contactFieldResultsByName = UTIL_Describe.getFieldResultsByName(Contact.SObjectType);

        for (String fieldName : new String[] {
            null, '', ' ',
            'FirstName__c', 'foo', 'Account.foo', 
            'Account.npe01__One2OneContact__r.foo',
            'Account.npe01__One2OneContact__r.',
            'Account.npe01__One2OneContact__c.foo',
            'Owner.foo'
        }) {
            System.assert(!UTIL_Describe.isValidField(fieldName, contactFieldResultsByName), fieldName + ' should be invalid');
        }
    }  

    /*********************************************************************************************************
    @description
        Test getFieldApiName() 
    verify:
        The method returns API Name for valid field name; otherwise, a null for invalid field name
    **********************************************************************************************************/ 
    private static testMethod void getFieldApiNameShouldReturnFieldApiName() {
        Map<String, Schema.DescribeFieldResult> contactFieldResultsByName = UTIL_Describe.getFieldResultsByName(Contact.SObjectType);

        Map<String, String> expectedNamesByInputName = new Map<String, String>{
            'nAMe' => 'Name',
            'FirstName' => 'FirstName',
            'lastNAME' => 'LastName',
            'LastName' => 'LastName',
            'AccountID' => 'AccountId',
            'ACCOUNT.id' => 'Account.Id',
            'accounT.npe01__One2OneContact__C' => 'Account.npe01__One2OneContact__c',
            'ACCOUNT.npe01__One2OneContact__R.lastName' => 'Account.npe01__One2OneContact__r.LastName',
            'OWNERId' => 'OwnerId',
            'OwneR.NAME' => 'Owner.Name',
            'ACCOUNT.npe01__ONE2ONECONTACT__R.PRIMARY_AFFILIATION__r.NAME' => 'Account.npe01__One2OneContact__r.Primary_Affiliation__r.Name',
            null => null,
            '' => null,
            ' ' => null,
            'foo' => null,
            'Account.npe01__One2OneContact__r.' => null,
            'Account.npe01__One2OneContact__c.foo' => null
        };

        for (String fieldName : expectedNamesByInputName.keySet()) {
            System.assertEquals(expectedNamesByInputName.get(fieldName), UTIL_Describe.getFieldApiName(fieldName, contactFieldResultsByName));
        }
    }   

}