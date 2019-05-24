/*
    Copyright (c) 2018, Salesforce.org
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
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Test class for CAO_Constants_API Class
*/
@istest(IsParallel=True)
private class CAO_Constants_API_TEST {
    
    static testMethod void test_cao_api() {
        System.AssertEquals(CAO_Constants.ONE_TO_ONE_PROCESSOR, CAO_Constants_API.ONE_TO_ONE_PROCESSOR);
        System.AssertEquals(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, CAO_Constants_API.ONE_TO_ONE_ORGANIZATION_TYPE);
        System.AssertEquals(CAO_Constants.BUCKET_PROCESSOR, CAO_Constants_API.BUCKET_PROCESSOR);
        System.AssertEquals(CAO_Constants.BUCKET_ORGANIZATION_TYPE, CAO_Constants_API.BUCKET_ORGANIZATION_TYPE);
        System.AssertEquals(CAO_Constants.BUCKET_ACCOUNT_NAME, CAO_Constants_API.BUCKET_ACCOUNT_NAME);
        System.AssertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, CAO_Constants_API.HH_ACCOUNT_PROCESSOR);
        System.AssertEquals(CAO_Constants.HH_ACCOUNT_TYPE, CAO_Constants_API.HH_ACCOUNT_TYPE);
        System.AssertEquals(CAO_Constants.HH_TYPE, CAO_Constants_API.HH_TYPE);
    }
    
}