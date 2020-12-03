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
 * @date 2020
 * @group Get Started Page
 * @description TestClass for GS_ApplicationStatusController.
 */
@IsTest(isParallel=true)
public with sharing class GS_ApplicationStatusController_TEST {
    /**
     * @description Test returning data when trial Org and no application submitted
     */
    @IsTest 
    private static void testGetApplicationStatusTrialOrgNonApplicated() {
        
        // This test relies on mocked org information data in the Controller class. That class will only apply mocked data
        // when the current org is a Sandbox org (by checking the Organization object) and there is no package 
        // namespace. As a result, this test has to be skipped for other types of orgs to avoid an error.
        if (!UTIL_Namespace.isScratchOrg() || String.isBlank(UTIL_Namespace.getNamespace())) {
            return;
        }

        GS_NonprofitTrialOrgService.TestingConfig testingConfiguration = new GS_NonprofitTrialOrgService.TestingConfig(null, false, Date.newInstance(2020,10,15));
        GS_NonprofitTrialOrgService.testingConfiguration = testingConfiguration;
        
        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assertNotEquals(null, status, 'Status should not be null');
        System.assertEquals(false, status.isSandbox, 'Status should not be sandbox');
        System.assertEquals(Date.newInstance(2020,10,15), date.newInstance(status.trialExpirationDate.year(), status.trialExpirationDate.month(), status.trialExpirationDate.dayGMT()), 'Trial expiration date not equal');
        System.assertEquals(null, status.applicationDate, 'application date should be null');
    }
    /**
     * @description Test returning data when trial Org and application submitted
     */
    @IsTest 
    private static void testGetApplicationStatusTrialOrgApplicated() {
       
        // This test relies on mocked org information data in the Controller class. That class will only apply mocked data
        // when the current org is a Sandbox org (by checking the Organization object) and there is no package 
        // namespace. As a result, this test has to be skipped for other types of orgs to avoid an error.
        if (!UTIL_Namespace.isScratchOrg() || !String.isBlank(UTIL_Namespace.getNamespace())) {
            return;
        }

        GS_NonprofitTrialOrgService.TestingConfig testingConfiguration = new GS_NonprofitTrialOrgService.TestingConfig(Date.newInstance(2020,10,02), false, Date.newInstance(2020,10,15));
        GS_NonprofitTrialOrgService.testingConfiguration = testingConfiguration;
       
        GS_ApplicationStatusController.ApplicationStatus status = GS_ApplicationStatusController.getApplicationStatus();
        System.assertNotEquals(null, status, 'Status should not be null');
        System.assertEquals(false, status.isSandbox, 'Status should not be sandbox');
        System.assertEquals(Date.newInstance(2020,10,15), Date.newInstance(status.trialExpirationDate.year(), status.trialExpirationDate.month(), status.trialExpirationDate.dayGMT()), 'Trial expiration date not equal');
        System.assertEquals(Date.newInstance(2020,10,02), status.applicationDate, 'ApplicationDate is not equals to 10/02/2020');
    }
}