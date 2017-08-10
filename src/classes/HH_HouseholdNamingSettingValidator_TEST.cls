/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Households
* @description Unit tests for HH_HouseholdNamingSettingValidator class
*/
@isTest
private class HH_HouseholdNamingSettingValidator_TEST {
    /*********************************************************************************************************
    * @description Constant containing invalid Household Name Format 
    */
    private static final String INVALID_HHNAME_FORMAT = 'The {!LastName}, {!{!FirstName}} {!npe01__WorkEmail__c}} Family';
    /*********************************************************************************************************
    * @description Constant containing invalid Formal Greeting Format 
    */
    private static final String INVALID_FORMAL_GREETING_FORMAT = '{!{!Title} {!FirstName}}}{!LastName}';
    /*********************************************************************************************************
    * @description Constant containing invalid Informal Greeting Format 
    */
    private static final String INVALID_INFORMAL_GREETING_FORMAT = '{!{!FirstName}}}';

    /*********************************************************************************************************
    * @description Notification used to store and verify errors (if any) reported during validation
    */
    private static HH_HouseholdNamingSettingValidator.Notification notification;
    /*********************************************************************************************************
    * @description Validator used to validate Household Naming Settings
    */
    private static HH_HouseholdNamingSettingValidator validator;


    /*********************************************************************************************************
    * @description Static method to initialize variables before each unit test
    */
    static {
        validator = new HH_HouseholdNamingSettingValidator();
        notification = new HH_HouseholdNamingSettingValidator.Notification();
    }
    
    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when specified class does not exist
    verify:
        The notification contains an error
    **********************************************************************************************************/  
    private static testMethod void validateImplementingClassShouldAddErrorWhenClassDoesNotExist() {
    Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Implementing_Class__c = 'foo'; 

        HH_INaming hhNaming = validator.validateImplementingClass(settings, notification);

        System.assertEquals(null, hhNaming);

        assertError(Label.stgErrorInvalidClass, notification);
    }
    
    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when specified class does not implement INaming interface
    verify:
        The notification contains an error
    **********************************************************************************************************/  
    private static testMethod void validateImplementingClassShouldAddErrorWhenClassDoesNotImplementINamingInterface() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Implementing_Class__c = 'HH_HouseholdNaming'; 

        HH_INaming hhNaming = validator.validateImplementingClass(settings, notification);

        System.assertEquals(null, hhNaming);
        
        assertError(Label.stgErrorINaming, notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when it is empty
    verify:
        The notification does not contain any error. Returned object is a HH_NameSpec instance.
    **********************************************************************************************************/  
    private static testMethod void validateImplementingClassShouldNotAddErrorWhenClassIsNotSpecified() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Implementing_Class__c = null; 

        HH_NameSpec hhNaming = (HH_NameSpec) validator.validateImplementingClass(settings, notification);

        System.assertNotEquals(null, hhNaming);

        assertSuccess(notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when specified class implements INaming interface
    verify:
        The notification does not contain any error
    **********************************************************************************************************/  
    private static testMethod void validateImplementingClassShouldNotAddErrorWhenClassImplementsINamingInterface() {
        Household_Naming_Settings__c settings = setupHHNamingSettings(); 

        HH_INaming hhNaming = validator.validateImplementingClass(settings, notification);

        System.assertNotEquals(null, hhNaming);
    
        assertSuccess(notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Household Name Format field when the value is invalid
    verify:
        The notification contains an error
    **********************************************************************************************************/  
    private static testMethod void validateShouldAddErrorWhenHHNameFormatIsInvalid() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Household_Name_Format__c = INVALID_HHNAME_FORMAT; 

        notification = validator.validate(settings);

        assertErrorContainsInvalidFieldMessage('Household_Name_Format__c', notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Formal Greeting Format field when the value is invalid
    verify:
        The notification contains an error
    **********************************************************************************************************/ 
    private static testMethod void validateShouldAddErrorWhenFormalGreetingFormatIsInvalid() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Formal_Greeting_Format__c = INVALID_FORMAL_GREETING_FORMAT; 

        notification = validator.validate(settings);

        assertErrorContainsInvalidFieldMessage('Formal_Greeting_Format__c', notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Informal Greeting Format field when the value is invalid
    verify:
        The notification contains an error
    **********************************************************************************************************/ 
    private static testMethod void validateShouldAddErrorWhenInformalGreetingFormatIsInvalid() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Informal_Greeting_Format__c = INVALID_INFORMAL_GREETING_FORMAT; 

        notification = validator.validate(settings);

        assertErrorContainsInvalidFieldMessage('Informal_Greeting_Format__c', notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of API Names for Contact fields specified in all format fields. 
    verify:
        The notification contains an error for each field that is not correct case-sensitive API Name
    **********************************************************************************************************/ 
    private static testMethod void validateShouldAddErrorWhenContactFieldsApiNameIsInvalid() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Household_Name_Format__c = 'The {!lastname}, {!{!FirstName} {!npe01__workemail__c}} Family'; 

        notification = validator.validate(settings);

        String[] expectedErrors = new String[] {
            String.format(Label.stgErrorInvalidApiName, new String[]{ 'lastname' }),
            String.format(Label.stgErrorInvalidApiName, new String[]{ 'npe01__workemail__c' })
        };
        assertErrors(expectedErrors, notification); 
    }

    /*********************************************************************************************************
    @description
        Test validation when a format field is empty
    verify:
        The notification does not contain any error
    **********************************************************************************************************/ 
    private static testMethod void validateShouldNotAddErrorWhenAFormatFieldIsNull() {
        Household_Naming_Settings__c settings = setupHHNamingSettings();
        settings.Household_Name_Format__c = null;

        notification = validator.validate(settings);
    
        assertSuccess(notification);
    }

    /*********************************************************************************************************
    @description
        Test validation when Implementing Class cannot be instantiated. Ensure no exception is raised when 
        format fields, expecting the Implementing Class instance, are validated.
    verify:
        The notification contains an error
    **********************************************************************************************************/ 
    private static testMethod void validateShouldAddInvalidClassErrorWhenClassAndFormatFieldsAreInvalid() {
        Household_Naming_Settings__c settings = setupInvalidHHNamingSettings(); 
        settings.Implementing_Class__c = 'foo';

        notification = validator.validate(settings);

        assertError(Label.stgErrorInvalidClass, notification);
    }

    /*********************************************************************************************************
    @description
        Test validation when all Household Naming Settings format fields are invalid
    verify:
        The notification contains errors for all format fields
    **********************************************************************************************************/ 
    private static testMethod void validateShouldAddErrorsWhenAllThreeFormatFieldsAreInvalid() {
        Household_Naming_Settings__c settings = setupInvalidHHNamingSettings();

        notification = validator.validate(settings);

        System.assert(!notification.isSuccess());

        String[] actualErrors = notification.getErrors();

        System.assertEquals(3, actualErrors.size(), actualErrors);
        System.assertEquals(3, new Set<String>(actualErrors).size());
    }

    /*********************************************************************************************************
    @description
        Test validation when all fields are valid
    verify:
        The notification does not contain any error
    **********************************************************************************************************/ 
    private static testMethod void validateShouldNotAddErrorWhenAllHHSettingsFieldsAreValid() {
        Household_Naming_Settings__c settings = setupHHNamingSettings(); 

        notification = validator.validate(settings);
        
        assertSuccess(notification);
    }

    /*********************************************************************************************************
    @description
        Test isValidApiName() when a field is valid case sensitive API Name for the Sobject
    verify:
        The method returns true
    **********************************************************************************************************/ 
    private static testMethod void isValidApiNameShouldReturnTrueWhenFieldNameIsValid() {
        Map<String, Schema.DescribeFieldResult> contactFieldResultsByName = validator.getFieldResultsByName(Contact.SObjectType);

        for (String fieldName : new String[] {
            'Name', 'FirstName', 'LastName',
            'AccountId', 'Account.Id', 'Account.Name', 
            'Account.BillingCity', 'Account.npe01__One2OneContact__c',
            'Account.npe01__One2OneContact__r.LastName',
            'OwnerId', 'Owner.Name'
        }) {
            System.assert(validator.isValidApiName(fieldName, contactFieldResultsByName), 'Expected valid field result: ' + fieldName);
        }
    }

    /*********************************************************************************************************
    @description
        Test isValidApiName() when a field name is invalid case sensitive API Name for the Sobject
    verify:
        The method returns false
    **********************************************************************************************************/ 
    private static testMethod void isValidApiNameShouldReturnFalseWhenFieldNameIsInvalid() {
        Map<String, Schema.DescribeFieldResult> contactFieldResultsByName = validator.getFieldResultsByName(Contact.SObjectType);

        for (String fieldName : new String[] {
            null, '', ' ',
            'firstname', 'Firstname', 'FirstName__c',
            'foo', 'Account.foo', 
            'Account.npe01__One2OneContact__r.foo',
            'Account.npe01__One2OneContact__r.',
            'Account.npe01__One2OneContact__c.foo',
            'Owner.foo'
        }) {
            System.assert(!validator.isValidApiName(fieldName, contactFieldResultsByName), 'Expected invalid field result: ' + fieldName);
        }
    }

    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Configures Household Naming Settings with invalid Name and Greetings formats
    * @return Household_Naming_Settings__c Household Naming Settings
    **********************************************************************************************************/
    private static Household_Naming_Settings__c setupInvalidHHNamingSettings() {
        return setupHHNamingSettings(
            INVALID_HHNAME_FORMAT,
            INVALID_FORMAL_GREETING_FORMAT,
            INVALID_INFORMAL_GREETING_FORMAT
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings with valid Name and Greetings formats
    * @return Household_Naming_Settings__c Household Naming Settings
    **********************************************************************************************************/
    private static Household_Naming_Settings__c setupHHNamingSettings() {
        return setupHHNamingSettings(            
            'The {!LastName}, {!{!FirstName} {!npe01__WorkEmail__c}} Family',
            '{!{!Title} {!FirstName}}{!LastName}',
            '{!{!FirstName}}'
        );
    }

    /*********************************************************************************************************
    * @description Configures Household Naming Settings 
    * @param hhNameFormat Household Name Format
    * @param formalGreetingFormat Formal Greeting Format
    * @param informalGreetingFormat Informal Greeting Format
    * @return Household_Naming_Settings__c Household Naming Settings
    **********************************************************************************************************/
    private static Household_Naming_Settings__c setupHHNamingSettings(String hhNameFormat, String formalGreetingFormat, String informalGreetingFormat) {
        return UTIL_CustomSettingsFacade.getHouseholdNamingSettingsForTests(
            new Household_Naming_Settings__c(
                Household_Name_Format__c = hhNameFormat,
                Formal_Greeting_Format__c = formalGreetingFormat,
                Informal_Greeting_Format__c = informalGreetingFormat,
                Name_Connector__c = label.npo02.HouseholdNameConnector,
                Name_Overrun__c = label.npo02.HouseholdNameOverrun,
                Contact_Overrun_Count__c = 9,
                Implementing_Class__c = 'HH_NameSpec'
            )
        );
    }

    /*********************************************************************************************************
    * @description Asserts the notification does not contain any error
    * @param n Notification
    * @return void
    **********************************************************************************************************/
    private static void assertSuccess(HH_HouseholdNamingSettingValidator.Notification n) {
        System.assert(n.isSuccess(), n.getErrors());
    
        System.assert(n.getErrors().isEmpty(), n.getErrors());
    }

    /*********************************************************************************************************
    * @description Asserts the notification contains expected error only
    * @param expectedError Expected error
    * @param n Notification
    * @return void
    **********************************************************************************************************/
    private static void assertError(String expectedError, HH_HouseholdNamingSettingValidator.Notification n) {
        assertErrors(new String[]{ expectedError }, n);
    }

    /*********************************************************************************************************
    * @description Asserts the notification contains expected errors 
    * @param expectedErrors List of expected errors
    * @param n Notification
    * @return void
    **********************************************************************************************************/
    private static void assertErrors(String[] expectedErrors, HH_HouseholdNamingSettingValidator.Notification n) {
        System.assert(!n.isSuccess());
    
        String[] actualErrors = n.getErrors();

        System.assertEquals(expectedErrors.size(), actualErrors.size(), actualErrors);

        Set<String> expected = new Set<String>(expectedErrors);
        Set<String> actual = new Set<String>(actualErrors);

        System.assertEquals(expected.size(), actual.size(), actual);
        System.assert(expected.containsAll(actual), actual);
    }

    /*********************************************************************************************************
    * @description Asserts the notification contains an "Invalid field" error message for the specified field  
    * @param fieldName Household Naming Settings field name
    * @param n Notification
    * @return void
    **********************************************************************************************************/
    private static void assertErrorContainsInvalidFieldMessage(String fieldName, HH_HouseholdNamingSettingValidator.Notification n) {
        String fieldLabel = UTIL_Describe.getFieldLabel(
            UTIL_Namespace.StrTokenNSPrefix('Household_Naming_Settings__c'), 
            UTIL_Namespace.StrTokenNSPrefix(fieldName)
        );

        System.assert(!n.isSuccess());

        String[] actualErrors = n.getErrors();

        System.assertEquals(1, actualErrors.size(), actualErrors);
    
        for (String error : actualErrors) {
            if (error.contains(fieldLabel) && error.contains('Invalid field')) {
                return;
            }
        }

        System.assert(false, actualErrors);
    }
}