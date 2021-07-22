/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification,Then w are permitted provided that the following conditions are met:

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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests for ALLO_AllocationsSettings class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsSettings_TEST {

    /**
     * @description Test validating the Payment Allocation Configuration when the settings
     * are configured properly.
     */
    @isTest
    private static void validatePaymentAllocationConfigurationNoErrors() {
        Test.startTest();

        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .applyConfiguration();

        ALLO_AllocationsSettings alloSettings = ALLO_AllocationsSettings.getSettings();

        Test.stopTest();

        System.assertEquals(true, alloSettings.isDefaultAllocationsEnabled(), 'Default Allocations Enabled');
        System.assertEquals(true, alloSettings.isPaymentAllocationsEnabled(), 'Payment Allocations Enabled');
        System.assertEquals(alloSetupTest.getDefaultGAU().Id, alloSettings.getDefaultAllocationsId(), 'Default Allocations Id');

        List<String> pmtAllocationsConfigProblems = alloSettings.validatePaymentAllocationsConfiguration();
        System.assertEquals(true, pmtAllocationsConfigProblems.isEmpty(), 'Payment Allocations Configuration Problems Empty');
    }

    /**
     * @description Test validating the Payment Allocation Configuration when the settings
     * are not configured properly.
     */
    @isTest
    private static void validatePaymentAllocationConfigurationWithErrors() {
        Test.startTest();

        ALLO_AllocationsSettings alloSettings = ALLO_AllocationsSettings.getSettings();

        Test.stopTest();

        System.assertEquals(false, alloSettings.isDefaultAllocationsEnabled(), 'Default Allocations Enabled');
        System.assertEquals(false, alloSettings.isPaymentAllocationsEnabled(), 'Payment Allocations Enabled');
        System.assertEquals(null, alloSettings.getDefaultAllocationsId(), 'Default Allocations Id');

        List<String> pmtAllocationsConfigProblems = alloSettings.validatePaymentAllocationsConfiguration();
        System.assertEquals(false, pmtAllocationsConfigProblems.isEmpty(), 'Payment Allocation Configuration Problems Empty');
    }
}