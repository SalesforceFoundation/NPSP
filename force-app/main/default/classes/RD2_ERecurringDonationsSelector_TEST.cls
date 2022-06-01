/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Donation
* @description Unit Test Class for test the recurring donations selector.
*/
@IsTest
public class RD2_ERecurringDonationsSelector_TEST {
    
	private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /**
    * @author Salesforce.org
    * @date 2022
    * @description Method to test that the results are returned correctly
    */
    @IsTest
    private static void testGetRecurringDonations() {
		
		RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        
		Contact con = UTIL_UnitTestData_TEST.getContact();
		insert con;

        npe03__Recurring_Donation__c rDonation01 = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
																				.withContact(con.Id)
																				.withAmount(100)
																				.withDefaultValues()
																				.withInstallmentPeriodMonthly()
																				.withDayOfMonth('23')
																				.withInstallmentFrequency(1)
																				.build();
        insert rDonation01;

        Test.startTest();
        RD2_ERecurringDonationsSelector selector = new RD2_ERecurringDonationsSelector();
        selector.currentContactId = con.Id;
        List<npe03__Recurring_Donation__c> result = selector.getRecurringDonations();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Recurring Donations should not be null');
    }
}
