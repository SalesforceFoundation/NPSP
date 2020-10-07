/*
    Copyright (c) 2020, Salesforce.org
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
 * @description TestClass for GS_ApplicationStatusController.
 */
@IsTest
public with sharing class GS_ApplicationStatusControllerTest {
    /**
     * @description Test returning data when trial Org and no application submitted
     */
    @IsTest 
    public static void testGetApplicationStatusTrialOrgNonApplicated() {
        Testing_Configuration__c tc = new Testing_Configuration__c(Configuration__c = '{"Sandbox":false,"TrialExpiration":"10/15/2020, 00:01 AM"}');
        insert tc; 

        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assert(status != null, 'Status should not be null');
        System.assert(!status.isSandbox, 'Status should not be sandbox');
        System.assertEquals(Date.parse('10/15/2020'), date.newInstance(status.trialExpirationDate.year(), status.trialExpirationDate.month(), status.trialExpirationDate.day()), 'Trial expiration date not equal');
        System.assert(status.applicationDate == null, 'application date should be null');
    }
    /**
     * @description Test returning data when trial Org and application submitted
     */
    @IsTest 
    public static void testGetApplicationStatusTrialOrgApplicated() {
        Testing_Configuration__c tc = new Testing_Configuration__c(Configuration__c = '{"Sandbox":false,"TrialExpiration":"10/15/2020, 00:01 AM", "Application":"10/02/2020"}');
        insert tc; 

        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assert(status != null, 'Status should not be null');
        System.assert(!status.isSandbox, 'Status should not be sandbox');
        System.assertEquals(Date.parse('10/15/2020'), date.newInstance(status.trialExpirationDate.year(), status.trialExpirationDate.month(), status.trialExpirationDate.day()), 'Trial expiration date not equal');
        System.assertEquals(Date.parse('10/02/2020'), status.applicationDate, 'ApplicationDate is not equals to 10/02/2020');
    }
}