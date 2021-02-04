/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group ErrorHandling
* @description Tests exception wrapper
*/
@IsTest
public with sharing class ERR_ExceptionData_TEST {

    /*********************************************************************************************************
    * @description Tests to make sure DML Exceptions have the correct wrapper created. The DML Exception
    * related fields should be filled in properly and the other fields should not be used. 
    */
    @IsTest
    static void testExceptionWrapperCreationForDMLException() {
        try {

            // Do something that will throw a DML exception. 
            Account newAccount = new Account();

            insert newAccount;
        } catch (Exception e) {
            String JSONString = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            ERR_ExceptionData deserializedWrapper = (ERR_ExceptionData)JSON.deserialize(JSONString, ERR_ExceptionData.class);
            System.assertEquals(null, deserializedWrapper.errorMessage);
            System.assertEquals(1, deserializedWrapper.DMLErrorFieldNameMapping.size());
            System.assertEquals(1, deserializedWrapper.DMLErrorMessageMapping.size());
            System.assertEquals(Label.exceptionRequiredField + ' [Name]', deserializedWrapper.DMLErrorMessageMapping.values()[0]);
            System.assertEquals('Name', deserializedWrapper.DMLErrorFieldNameMapping.values()[0][0]);

        }
    }

    /*********************************************************************************************************
    * @description Tests to make sure that non-DML Exceptions have the error message recorded in the correct
    * variable and the DML Exception variables are not set. 
    */
    @IsTest
    static void testExceptionWrapperCreationForNonDMLException() {
        String divideByZeroError = 'Divide by 0';
        try {

            Decimal divideException = 1/0;
        } catch (Exception e) {
            String JSONString = ERR_ExceptionData.createExceptionWrapperJSONString(e);

            ERR_ExceptionData deserializedWrapper = (ERR_ExceptionData)JSON.deserialize(JSONString, ERR_ExceptionData.class);

            System.assertEquals(divideByZeroError, deserializedWrapper.errorMessage);
            System.assertEquals(0, deserializedWrapper.DMLErrorFieldNameMapping.size());
            System.assertEquals(0, deserializedWrapper.DMLErrorMessageMapping.size());
        }
    }

    /*********************************************************************************************************
    * @description Tests to make sure that a correct wrapper is created for situations where the 
    * wrapper is not created with an Exception. This is used for displaying BDI Processing failures. 
    */
    @IsTest
    static void testExceptionWrapperCreationForErrorMessage() {
        String errorMessage = 'This is a test error string.';

        String JSONString = ERR_ExceptionData.createExceptionWrapperJSONString(errorMessage);
        ERR_ExceptionData deserializedWrapper = (ERR_ExceptionData)JSON.deserialize(JSONString, ERR_ExceptionData.class);

        System.assertEquals(errorMessage, deserializedWrapper.errorMessage, 'The error message does not match.');
    }
}
