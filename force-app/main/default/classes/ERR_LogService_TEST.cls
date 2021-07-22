/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group ErrorHandling
* @description Unit tests for the Error Log service
*
*/
@IsTest(IsParallel=false)
private with sharing class ERR_LogService_TEST {
    private static final Id MOCK_RECORD_ID = UTIL_UnitTestData_TEST.mockId(Contact.getSObjectType());
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();


    /****
    * @description Verifies an error log is created by the service
    */
    @isTest
    private static void shouldCreateErrorLog() { 
        ERR_LogService.Logger logger = new ERR_LogService.Logger(
            ERR_Handler_API.Context.Elevate,
            Contact.SObjectType
        );

        logger.addError(MOCK_RECORD_ID, 'Test Message', 'error type');
        logger.processErrors();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be created: ' + errors);
    }

    /****
    * @description Verifies created error logs are returned by the service
    */
    @isTest
    private static void shouldReturnErrorLog() {         
        insert new List<Error__c>{
            new Error__c(
                Datetime__c = System.now(),
                Related_Record_ID__c = MOCK_RECORD_ID,
                Full_Message__c = 'test error message 1'
            ),
            new Error__c(
                Datetime__c = System.now(),
                Related_Record_ID__c = MOCK_RECORD_ID,
                Full_Message__c = 'test error message 2'
            ),
            new Error__c(
                Datetime__c = System.now(),
                Related_Record_ID__c = UTIL_UnitTestData_TEST.mockId(Contact.getSObjectType()),
                Full_Message__c = 'test error message another record'
            )
        };

        ERR_LogService service = new ERR_LogService();
        List<Error__c> errors = service.getErrors(MOCK_RECORD_ID);
        System.assertEquals(2, errors.size(), 
            'Errors should be returned for the specified record: ' + errors);

        Error__c error = service.getLatestError(MOCK_RECORD_ID);
        System.assertNotEquals(null, error, 
            'One error should be returned as the latest: ' + error);
        System.assertEquals(MOCK_RECORD_ID, error.Related_Record_ID__c, 
            'The error should be returned for the specified record: ' + error);

    }
}
