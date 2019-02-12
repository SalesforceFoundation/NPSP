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
* @group API 
* @group-content ../../ApexDocContent/API.htm
* @description Tests specific to Callable API. 
*/
@IsTest(isParallel=true)
private with sharing class CallableApi_TEST {

    private static final String TDTM_TRIGGER_ACTION = 'TDTM.disableAllTriggers';
    
    /*******************************************************************************************************
    * @description verify the TDTM Callable action returns an Object
    ********************************************************************************************************/
    @IsTest
    private static void verifyCallableReturnsAnObject() {
       
        Test.startTest();

        // Call the API to disable All TDTM Triggers
        Callable npspApi = (Callable) Type.forName('CallableApi').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Object result = npspApi.call(TDTM_TRIGGER_ACTION, triggerArgs);

        Test.stopTest();

        Object callResult = result;
        System.assertNotEquals(null, callResult, 'No result was returned from call');
    }


    /*******************************************************************************************************
    * @description Call the API with an invalid action text and make sure an exception is thrown
    ********************************************************************************************************/
    @IsTest
    private static void callableApiThrowsExceptionWhenActionIsInvalid() {
       
        Test.startTest();

        Callable npspApi = (Callable) Type.forName('CallableApi').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();

        try {
            Object result = npspApi.call('InvalidAction', triggerArgs);
            System.assert(false, 'The exception was not thrown');
        } catch (CallableApi.MalformedMethodInvocationException apiException) {
            System.assert(apiException.getMessage().contains(' is not implemented'));
        }

        Test.stopTest();
    }

}
