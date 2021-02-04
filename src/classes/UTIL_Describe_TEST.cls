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
private with sharing class UTIL_Describe_TEST {

    @IsTest
    private static void shouldReturnExpectedDescribes() {
        String s;

        Schema.DescribeSObjectResult res = UTIL_Describe.getObjectDescribe('Contact');
        System.assertEquals(res.getName(), 'Contact');
        s = UTIL_Describe.getObjectLabel('Contact');
        System.assertEquals (s, res.getLabel());

        Account a = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        a.Id = UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID;
        System.assert(UTIL_Describe.isObjectIdThisType(a.Id, 'Account'));

        s = UTIL_Describe.getFieldLabel('Account', 'LastModifiedDate');

        Schema.DescribeFieldResult fr = UTIL_Describe.getFieldDescribe('Account', 'CreatedDate');
        s = UTIL_Describe.getFieldLabel('Account', 'CreatedDate');
        System.assertEquals (s, fr.getLabel());

        Map<String, Schema.DescribeFieldResult> afd = UTIL_Describe.getAllFieldsDescribe('Account');
        System.assertEquals ('BillingCity', afd.get('billingcity').getName());
        afd = UTIL_Describe.getAllFieldsDescribe('Account');

        SObject acctObj = UTIL_Describe.getPrototypeObject('Account');
        // should be able to cast to Account
        Account acct = (Account)(acctObj);

        s = UTIL_Describe.getFieldType('Account', 'CreatedDate');
        System.assertEquals('DATETIME', s);

        s = UTIL_Describe.getNameField('Account');
        System.assertEquals('name', s);

        try {
            s = UTIL_Describe.getObjectLabel('sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (Exception e) {
            System.assertEquals('Invalid object name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        }
        try {
            s = UTIL_Describe.getFieldLabel('Opportunity', 'sdlkfjsdlkfjsldkfjlsdkfj');
        } catch (Exception e) {
            System.assertEquals('Invalid field name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
        }
    }

    /**
    * @description Validate that the Picklist value for "Open" is returned as the English value.
    */
    @IsTest
    private static void shouldReturnEnglishPicklist() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withDefaultValues()
            .withOpenEndedStatusOpen()
            .build();

        System.assertEquals(RD_Constants.OPEN_ENDED_STATUS_OPEN, rd.npe03__Open_Ended_Status__c);
        User englishUser = buildEnglishUser();
        System.runAs(englishUser) {
            System.assertEquals(RD_Constants.OPEN_ENDED_STATUS_OPEN,
                UTIL_Describe.getTranslatedPicklistLabel(npe03__Recurring_Donation__c.SObjectType,
                    npe03__Recurring_Donation__c.npe03__Open_Ended_Status__c,
                    rd.npe03__Open_Ended_Status__c),
                'The English translation for Open should be Open');
        }
    }

    /**
    * @description Validate that active picklist options are identified.
    */
    @IsTest
    private static void shouldIdentifyValidPicklistOptions() {
        final String objectName = 'Opportunity';
        final String fieldName = 'StageName';
        final String bogusValue = 'slfdkjlsdfj';

        Schema.DescribeFieldResult describeField =
            UTIL_Describe.getFieldDescribe('Opportunity', 'StageName');
        String picklistValue;
        for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
            if (entry.isActive()) {
                picklistValue = entry.getValue();
                break;
            }
        }

        System.assertEquals(true,
            UTIL_Describe.isValidPicklistOption(objectName, fieldName, picklistValue),
            'isValidPicklistOption() should return true for an active picklist value');
        System.assertEquals(false,
            UTIL_Describe.isValidPicklistOption(objectName, fieldName, bogusValue),
            'isValidPicklistOption() should return false for a picklist value that does not exist');
    }

    /**
    * @description Validate that the translated Spanish Picklist value for "Open" is returned.
    * This npe03__Open_Ended_Status__c field is translated in the RD underlying package. Due to how
    * translations are working in unit tests, this can only work if Spanish language is enabled in
    * Translation Language Settings.
    *
    * NOTE: This will always fail unless the Spanish language is enabled in Translation Workbench.
    * Since it's not possible to enable a language in apex or through the scratch org definition file,
    * this test is commented until it's possible in the future.
    */
    // @IsTest
    private static void shouldReturnSpanishPicklist() {

        if (UserInfo.getLanguage() != 'es') {
            return;
        }

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withDefaultValues()
            .withOpenEndedStatusOpen()
            .build();

        System.assertEquals(RD_Constants.OPEN_ENDED_STATUS_OPEN, rd.npe03__Open_Ended_Status__c);

        System.assertEquals('Abierto',
            UTIL_Describe.getTranslatedPicklistLabel(npe03__Recurring_Donation__c.SObjectType,
                npe03__Recurring_Donation__c.npe03__Open_Ended_Status__c,
                rd.npe03__Open_Ended_Status__c),
            'The Spanish translation for Open should be Abierto');
    }

    // Helpers
    //////////////

    /***
     * @description Builds a user using English language and locale
     * @return User
     */
    private static User buildEnglishUser() {
        User usr = UTIL_UnitTestData_Test.createUserWithoutInsert(UTIL_Profile.PROFILE_STANDARD_USER);

        usr.LanguageLocaleKey = 'en_US';
        return usr;
    }
}