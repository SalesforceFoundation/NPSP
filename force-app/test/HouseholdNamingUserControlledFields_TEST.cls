/*
    Copyright (c) 2025, Salesforce.org
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
* @date 2021
* @description Test class for HouseholdNamingUserControlledFields
*/
@isTest
public class HouseholdNamingUserControlledFields_TEST {
    
    /*********************************************************************************************************
    @description
        Test that genuine user changes are correctly marked as user-controlled
    verify:
        When a user actually changes a field value, it should be marked as user-controlled
    **********************************************************************************************************/
    @isTest
    private static void testUserControlledChangesMarkedCorrectly() {
        // Create old record representing auto-generated state
        Account oldRecord = new Account(
            Name = 'Smith Family',
            npo02__Formal_Greeting__c = 'John Smith',
            npo02__Informal_Greeting__c = 'John'
        );
        
        // Create household with user-modified name
        Account household = new Account(
            Name = 'My Custom Family Name', // User changed this
            npo02__Formal_Greeting__c = 'John Smith',
            npo02__Informal_Greeting__c = 'John'
        );
        
        Test.startTest();
        HouseholdNamingUserControlledFields userControlledFields = 
            new HouseholdNamingUserControlledFields(household, oldRecord);
        Test.stopTest();
        
        // The name should be marked as user controlled
        System.assertEquals(';Name;', userControlledFields.asConcatenatedString(), 
                     'User changed name should be marked as user controlled: ' + userControlledFields.asConcatenatedString());
        System.assertEquals(true, userControlledFields.isNameControlledByUser(),
                          'Name should be marked as user controlled');
        System.assertEquals(false, userControlledFields.isFormalGreetingControlledByUser(),
                          'Formal greeting should not be marked as user controlled');
        System.assertEquals(false, userControlledFields.isInformalGreetingControlledByUser(),
                          'Informal greeting should not be marked as user controlled');
    }

    /*********************************************************************************************************
    @description
        Test string concatenation functionality
    verify:
        String concatenation and parsing works correctly
    **********************************************************************************************************/
    @isTest
    private static void testStringConcatenationFunctionality() {
        Test.startTest();
        
        // Test with null input
        HouseholdNamingUserControlledFields fields1 = new HouseholdNamingUserControlledFields(null);
        System.assertEquals(';', fields1.asConcatenatedString(), 'Null input should result in ";"');
        
        // Test with existing string
        HouseholdNamingUserControlledFields fields2 = new HouseholdNamingUserControlledFields(';Name;Formal_Greeting__c;');
        System.assertEquals(';Name;Formal_Greeting__c;', fields2.asConcatenatedString(), 
                          'Existing string should be preserved with single trailing semicolon');
        System.assertEquals(true, fields2.isNameControlledByUser(), 'Name should be detected as user controlled');
        System.assertEquals(true, fields2.isFormalGreetingControlledByUser(), 'Formal greeting should be detected as user controlled');
        System.assertEquals(false, fields2.isInformalGreetingControlledByUser(), 'Informal greeting should not be detected as user controlled');
        
        Test.stopTest();
    }

    /*********************************************************************************************************
    @description
        Test edge cases with replacement text
    verify:
        With simplified logic, field changes are treated as user-controlled unless the field is replaceable
    **********************************************************************************************************/
    @isTest
    private static void testReplacementTextHandling() {
        String replacementText = 'To Be Determined';
        
        // Create old record with replacement text
        Account oldRecord = new Account(
            Name = replacementText,
            npo02__Formal_Greeting__c = replacementText,
            npo02__Informal_Greeting__c = replacementText
        );
        
        // Create household with actual values 
        Account household = new Account(
            Name = 'Smith Family',
            npo02__Formal_Greeting__c = 'John Smith',
            npo02__Informal_Greeting__c = 'John'
        );
        
        Test.startTest();
        HouseholdNamingUserControlledFields userControlledFields = 
            new HouseholdNamingUserControlledFields(household, oldRecord);
        Test.stopTest();
        
        // With simplified logic, field changes are detected as changes and marked as user-controlled
        // This is the safer approach - better to preserve user intent than risk losing it
        String result = userControlledFields.asConcatenatedString();
        System.assertEquals(';Name;Informal_Greeting__c;Formal_Greeting__c;', result, 
                     'All field changes should be detected and marked as user-controlled: ' + result);
        System.assertEquals(true, userControlledFields.isNameControlledByUser(),
                          'Name change should be marked as user controlled with simplified logic');
        System.assertEquals(true, userControlledFields.isFormalGreetingControlledByUser(),
                          'Formal greeting change should be marked as user controlled with simplified logic');
        System.assertEquals(true, userControlledFields.isInformalGreetingControlledByUser(),
                          'Informal greeting change should be marked as user controlled with simplified logic');
    }

    /*********************************************************************************************************
    @description
        Test asConcatenatedString() method handles double semicolons and edge cases correctly
    verify:
        The method should clean up double semicolons and ensure proper formatting
    **********************************************************************************************************/
    @isTest
    private static void testAsConcatenatedStringCleanup() {
        Test.startTest();
        
        // Test double semicolon cleanup - this simulates the bug scenario
        HouseholdNamingUserControlledFields fields1 = new HouseholdNamingUserControlledFields(';;Name;;Formal_Greeting__c;;');
        String result1 = fields1.asConcatenatedString();
        System.assertEquals(';Name;Formal_Greeting__c;', result1, 
                          'Double semicolons should be cleaned up: ' + result1);
        
        // Test triple semicolon cleanup
        HouseholdNamingUserControlledFields fields2 = new HouseholdNamingUserControlledFields(';;;Name;;;');
        String result2 = fields2.asConcatenatedString();
        System.assertEquals(';Name;', result2, 
                          'Triple semicolons should be cleaned up: ' + result2);
        
        // Test string without trailing semicolon gets one added
        HouseholdNamingUserControlledFields fields3 = new HouseholdNamingUserControlledFields('Name;Formal_Greeting__c');
        String result3 = fields3.asConcatenatedString();
        System.assertEquals('Name;Formal_Greeting__c;', result3, 
                          'Missing trailing semicolon should be added: ' + result3);
        
        // Test empty string handling
        HouseholdNamingUserControlledFields fields4 = new HouseholdNamingUserControlledFields('');
        String result4 = fields4.asConcatenatedString();
        System.assertEquals(';', result4, 
                          'Empty string should result in single semicolon: ' + result4);
        
        // Test already properly formatted string remains unchanged
        HouseholdNamingUserControlledFields fields5 = new HouseholdNamingUserControlledFields(';Name;Formal_Greeting__c;');
        String result5 = fields5.asConcatenatedString();
        System.assertEquals(';Name;Formal_Greeting__c;', result5, 
                          'Properly formatted string should remain unchanged: ' + result5);
        
        Test.stopTest();
    }
} 