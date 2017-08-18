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
    * @description Notification used to store and verify errors (if any) reported during validation
    */
    private static HH_HouseholdNamingSettingValidator.Notification notification = new HH_HouseholdNamingSettingValidator.Notification();
    /*********************************************************************************************************
    * @description Validator used to validate Household Naming Settings
    */
    private static HH_HouseholdNamingSettingValidator validator = new HH_HouseholdNamingSettingValidator();

    
    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when specified class does not exist
    verify:
        The notification contains an error
    **********************************************************************************************************/  
    private static testMethod void testErrorWhenClassDoesNotExist() {
    Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Implementing_Class__c = 'foo'; 

        HH_INaming hhNaming = validator.validateImplementingClass(settings, notification);

        System.assertEquals(null, hhNaming, 'HH_INaming should be null');

        assertError(Label.stgErrorInvalidClass, notification);
    }
    
    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when specified class does not implement INaming interface
    verify:
        The notification contains an error
    **********************************************************************************************************/  
    private static testMethod void testErrorWhenClassDoesNotImplementINamingInterface() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Implementing_Class__c = 'HH_HouseholdNaming'; 

        HH_INaming hhNaming = validator.validateImplementingClass(settings, notification);

        System.assertEquals(null, hhNaming, 'HH_INaming should be null');
        
        assertError(Label.stgErrorINaming, notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when it is empty
    verify:
        The notification does not contain any error. Returned object is a HH_NameSpec instance.
    **********************************************************************************************************/  
    private static testMethod void testSuccessWhenClassIsNotSpecified() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Implementing_Class__c = null; 

        HH_NameSpec hhNaming = (HH_NameSpec) validator.validateImplementingClass(settings, notification);

        System.assertNotEquals(null, hhNaming, 'HH_INaming should be an HH_NameSpec instance');

        assertSuccess(notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Implementing Class when specified class implements INaming interface
    verify:
        The notification does not contain any error
    **********************************************************************************************************/  
    private static testMethod void testSuccessWhenClassImplementsINamingInterface() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings(); 

        HH_INaming hhNaming = validator.validateImplementingClass(settings, notification);

        System.assertNotEquals(null, hhNaming, 'HH_INaming instance should be returned');
    
        assertSuccess(notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Household Name Format field when the value is invalid
    verify:
        The notification contains an error
    **********************************************************************************************************/  
    private static testMethod void testErrorWhenHHNameFormatIsInvalid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Household_Name_Format__c = 'The {!LastName}, {!{!FirstName}} {!npe01__WorkEmail__c}} Family'; 

        notification = validator.validate(settings);

        assertErrorContainsInvalidFieldMessage('Household_Name_Format__c', notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Formal Greeting Format field when the value is invalid
    verify:
        The notification contains an error
    **********************************************************************************************************/ 
    private static testMethod void testErrorWhenFormalGreetingFormatIsInvalid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Formal_Greeting_Format__c = '{!{!Title} {!FirstName}}}{!LastName}'; 

        notification = validator.validate(settings);

        assertErrorContainsInvalidFieldMessage('Formal_Greeting_Format__c', notification);
    }

    /*********************************************************************************************************
    @description
        Test validation of Informal Greeting Format field when the value is invalid
    verify:
        The notification contains an error
    **********************************************************************************************************/ 
    private static testMethod void testErrorWhenInformalGreetingFormatIsInvalid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
        settings.Informal_Greeting_Format__c = '{!{!FirstName}}}'; 

        notification = validator.validate(settings);

        assertErrorContainsInvalidFieldMessage('Informal_Greeting_Format__c', notification);
    }

    /*********************************************************************************************************
    @description
        Test validation when a format field is empty
    verify:
        The notification does not contain any error
    **********************************************************************************************************/ 
    private static testMethod void testSuccessWhenFormatFieldIsNull() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings();
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
    private static testMethod void testInvalidClassErrorWhenClassAndFormatFieldsAreInvalid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupInvalidHHNamingSettings(); 
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
    private static testMethod void testErrorsWhenAllFormatFieldsAreInvalid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupInvalidHHNamingSettings();

        notification = validator.validate(settings);

        System.assert(!notification.isSuccess(), 'Notification should contain validation errors');

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
    private static testMethod void testSuccessWhenAllHHSettingsFieldsAreValid() {
        Household_Naming_Settings__c settings = UTIL_UnitTestData_TEST.setupHHNamingSettings(); 

        notification = validator.validate(settings);
        
        assertSuccess(notification);
    }


    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Asserts the notification does not contain any error
    * @param n Notification
    * @return void
    **********************************************************************************************************/
    private static void assertSuccess(HH_HouseholdNamingSettingValidator.Notification n) {
        System.assert(n.isSuccess(), n.getErrors());
    
        System.assert(n.getErrors().isEmpty(), 'Notification should not contain any error: ' + n.getErrors());
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

        System.assertEquals(expectedErrors.size(), actualErrors.size(), 'Expected and actual errors size should be the same. Expected: ' + expectedErrors + '; Actual: ' + actualErrors);

        Set<String> expected = new Set<String>(expectedErrors);
        Set<String> actual = new Set<String>(actualErrors);

        System.assertEquals(expected.size(), actual.size(), 'Expected and actual unique errors size should be the same. Expected: ' + expected + '; Actual: ' + actual);
        System.assert(expected.containsAll(actual), 'Expected and actual errors should be the same. Expected: ' + expected + '; Actual: ' + actual);
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

        System.assertEquals(1, actualErrors.size(), 'Only one error should exist in: ' + actualErrors);
    
        for (String error : actualErrors) {
            if (error.contains(fieldLabel) && error.contains('Invalid field')) {
                return;
            }
        }

        System.assert(false, fieldName + ' should be in: ' + actualErrors);
    }
}