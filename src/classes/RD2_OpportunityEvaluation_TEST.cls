/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Unit tests for the Enhanced RD Batch Job
*
*/
@IsTest(IsParallel=true)
private class RD2_OpportunityEvaluation_TEST {
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /**
     * @description Verify that when Enhanced RD is NOT enabled in an org, attempting to execute the new RD2 batch
     * job throws an exception
     */
    @IsTest
    private static void shouldThrowExceptionForEnhancedRDJobIfEnhancedRDIsNotEnabled() {

        Exception actuaException;
        try {
            Test.startTest();
            Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
            Test.stopTest();
        } catch (Exception ex) {
            actuaException = ex;
        }
        System.assert(actuaException != null, 'An exception should have been thrown because Enhanced RD is not enabled');
        System.assert(actuaException.getMessage().containsIgnoreCase(System.Label.RD2_ErrorEnhancedRDBatchJobCannotBeRun),
            'The exception should have indicated that the job cannot be executed because Enhanced RD is not enabled ' + actuaException.getMessage());
    }

    /**
     * @description Verify that when RD2 is enabled in an org, executing the new Enhanced RD batch job does not
     * throw an exception
     */
    @IsTest
    private static void shouldNotThrowExceptionForEnhancedRDJobIfEnhancedRDIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Exception actuaException;
        try {
            Test.startTest();
            Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
            Test.stopTest();
        } catch (Exception ex) {
            actuaException = ex;
        }
        System.assert(actuaException == null, 'An exception should not have been thrown because Enhanced RD is enabled');
    }

    /**
     * @description Verify that when Enhanced RD is NOT enabled in an org, executing the new Legacy RD
     * batch job does not throw an exception
     */
    @IsTest
    private static void shouldNotThrowExceptionForLegacyRDJobIfEnhancedRDIsNotEnabled() {

        Exception actuaException;
        try {
            Test.startTest();
            Database.executeBatch(new RD_RecurringDonations_BATCH());
            Test.stopTest();
        } catch (Exception ex) {
            actuaException = ex;
        }
        System.assert(actuaException == null, 'An exception should not have been thrown because Enhanced RD is not enabled');
    }

}