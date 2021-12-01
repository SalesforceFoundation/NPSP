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
* @description Unit Test Setup and Helper Methods
*/
@IsTest(isParallel=true)
public class ALLO_UnitTestHelper_TEST {

    // Number of Contacts and Opportunities to Create In the Main Create Test Data Method
    private static final Integer NUMBER_OF_CONTACTS_AND_OPPORTUNITIES = 14;

     /**
     * @description Finds an Allocation in a List of Allocations by GAU
     * @param allocs The list of Allocations to search through
     * @param gau The gau to look for
     * @return Allocation__c The first matching Allocation By GAU, or null
     */
    public static Allocation__c findByGAU(List<Allocation__c> allocs, General_Accounting_Unit__c gau) {

        if (allocs != null) {
            for (Allocation__c alloc :allocs) {
                if (alloc.General_Accounting_Unit__c == gau.Id) {
                    return alloc;
                }
            }
        }
        // Didn't find any, return null
        return null;
    }

    /**
     * @description Test Data Set for batch/bulk testing of the Allocations Service classes.  Allocation Triggers
     *              are disabled during setup of this data, so the Allocations Service classes will get the Allocations
     *              in various states, and can be confirmed to test/react accordingly.
     *              Payment Allocations are only created for tests when Payment Allocations are enabled.
     *
     *              Parent Allocation Data:
     *              Recurring Donation - Allocations (GAU0, 50%), (GAU1, $10)
     *              Campaign - Allocations (GAU1, $10)
     *
     *              Test Data:
     *              Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
     *                               Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *              Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
     *              Opportunity 2  - $20, No Allocations present
     *              Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
     *                               Opportunity Allocations (GAU1, $10)
     *              Opportunity 4  - $20, Allocation has percent but not amount
     *                               Opportunity Allocations (GAU1, 100%, (null))
     *              Opportunity 5  - $0, Percent Allocation with non zero amount
     *                               Opportunity Allocations (GAU1, 50%, $20)
     *              Opportunity 6  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *              Opportunity 7  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *              Opportunity 8  - (null), If Default Allocations Enabled, Allocation (Default GAU, $20)
     *                                      Else Allocation (GAU2, 100%, $20)
     *              Opportunity 9  - $20, Campaign Parent, No Allocations Present
     *              Opportunity 10 - $20, Allocations need resizing
     *                               Opportunity Allocations (GAU1, 50%, $40),
     *                               If Default Allocations Enabled (Default GAU, $40)
     *              Opportunity 11 - $20, Invalid Allocation that cannot be corrected
     *                               Opportunity Allocations (GAU1, $40)
     *              Opportunity 12 - $0, no Allocations
     *              Opportunity 13 - $20, no Allocations
     *              *** If Payment Allocations Are Enabled ***
     *              Opportunity 6, Payment 0 - No Allocations are present
     *              Opportunity 6, Payment 1 - $10, Allocations Need Resizing
     *                                         Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU $10)
     *              Opportunity 6, Payment 2 - $10, Needs Default Allocation
     *                                         Payment Allocations (GAU0, $1)
     *              Opportunity 6, Payment 3 - $10, Remove Default Allocation Because Fully Allocated
     *                                         Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
     *              Opportunity 6, Payment 4 - $0, Default Allocation needs resizing
     *                                         Payment Allocations (Default GAU, $10)
     *              Opportunity 6, Payment 5 - (null), Default Allocation needs resizing
     *                                         Payment Allocations (Default GAU, $10)
     *              Opportunity 6, Payment 6 - $0, Percent Allocation to update
     *                                         Payment Allocations (GAU0, 10%, $1)
     *              Opportunity 6, Payment 7 - (null), Percent Allocation to update
     *                                         Payment Allocations (GAU0, 10%, $1)
     *              Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
     *                                          Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
     *              Opportunity 6, Payment 9  - (null), Percent Allocation to update, Default Allocation to remove
     *                                          Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
     *              Opportunity 6, Payment 10 - $0, Needs Allocations
     *              Opportunity 6, Payment 11 - (null), Needs Allocations
     *              Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
     *                                          Payment Allocations (GAU1)
     *              Opportunity 7, Payment 0 - $10, Fully allocated
     *
     * @param alloSetupTest - Instance of an Allocation Setup Test object, with config, GAUs, etc. in it.
     * @return List<Id> List of Opportunities Ids, in the order they were inserted
     */
    public static List<Id> createTestDataAndReturnOppIds(AllocationSetupTest alloSetupTest) {
        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = (alloSetupTest.isDefaultAllocationsEnabled()) ? alloSetupTest.getDefaultGAU() : null;

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(1984,01,29))
            .withAccount(accs[0].Id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        Campaign cam = new Campaign(Name='Test Campaign: ' + UTIL_UnitTestData_TEST.getUniqueString(), IsActive=true);
        insert cam;

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(NUMBER_OF_CONTACTS_AND_OPPORTUNITIES);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 20, null, null);
        opps[0].npe03__Recurring_Donation__c = rd.Id;
        opps[1].npe03__Recurring_Donation__c = rd.Id;
        opps[5].Amount = 0;
        opps[8].Amount = null;
        opps[9].CampaignId = cam.Id;
        opps[12].Amount = 0;

        for (Opportunity opp : opps) {
            opp.npe01__Do_Not_Automatically_Create_Payment__c = true;
        }
        insert opps;

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>();

        // Each Payment is on a different date in ascending order, so they can be selected in a specific order
        List<List<Object>> paymentData = new List<List<Object>> {
            new List<Object> {10,   opps[6].Id, System.today()},
            new List<Object> {10,   opps[7].Id, System.today()},
            new List<Object> {10,   opps[6].Id, System.today().addDays(1)},
            new List<Object> {10,   opps[6].Id, System.today().addDays(2)},
            new List<Object> {10,   opps[6].Id, System.today().addDays(3)},
            new List<Object> {0,    opps[6].Id, System.today().addDays(4)},
            new List<Object> {null, opps[6].Id, System.today().addDays(5)},
            new List<Object> {0,    opps[6].Id, System.today().addDays(6)},
            new List<Object> {null, opps[6].Id, System.today().addDays(7)},
            new List<Object> {0,    opps[6].Id, System.today().addDays(8)},
            new List<Object> {null, opps[6].Id, System.today().addDays(9)},
            new List<Object> {0,    opps[6].Id, System.today().addDays(10)},
            new List<Object> {null, opps[6].Id, System.today().addDays(11)},
            new List<Object> {10,   opps[6].Id, System.today().addDays(12)}
        };

        for (List<Object> paymentInfo : paymentData) {
            pmts.add(
                new npe01__OppPayment__c(
                    npe01__Payment_Amount__c = (Decimal)paymentInfo[0],
                    npe01__Opportunity__c = (Id)paymentInfo[1],
                    npe01__Scheduled_Date__c = (Date) paymentInfo[2]
                )
            );
        }

        insert pmts;

        List<Allocation__c> allosForInsert = new list<Allocation__c>();

        // Recurring Donation Allocations
        allosForInsert.add(
            new Allocation__c(
                Recurring_Donation__c = rd.id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id
            )
        );

        allosForInsert.add(
            new Allocation__c(
                Recurring_Donation__c = rd.id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id
            )
        );

        // Campaign Allocation
        allosForInsert.add(
            new Allocation__c(
                Campaign__c = cam.id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id
            )
        );

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
           allosForInsert.add(
            new Allocation__c(
                Opportunity__c = opps[0].Id, Amount__c = 10, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id
            )
        );

        allosForInsert.add(
            new Allocation__c(
                Opportunity__c = opps[0].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id
            )
        );

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present

        // Opportunity 2  - $20, No Allocations present

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Opportunity Allocations (GAU1, $10)
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[3].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].Id
                )
        );

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[4].Id, Percent__c = 100, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                      Opportunity Allocations (GAU1, 50%, $20)
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[5].Id, Amount__c = 20, Percent__c = 50, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[6].Id, Amount__c = 20, Percent__c = 100, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        if (alloSetupTest.isPaymentAllocationsEnabled()) { // Only if Payment Allocations are Enabled

            // Opportunity 6, Payment 0 - No Allocations are present

            // Opportunity 6, Payment 1 - $10, Allocations Need Resizing
            //                Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU $10)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[2].Id, Amount__c = 10, General_Accounting_Unit__c = defaultGau.Id
                )
            );

            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[2].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[2].Id, Amount__c = 1, General_Accounting_Unit__c = gaus[1].Id
                )
            );

            // Opportunity 6, Payment 2 - $10, Needs Default Allocation
            //                            Payment Allocations (GAU0, $1)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[3].Id, Amount__c = 1, General_Accounting_Unit__c = gaus[0].Id
                )
            );

            // Opportunity 6, Payment 3 - $10, Remove Default Allocation Because Fully Allocated
            //                            Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[4].Id, Amount__c = 10, Percent__c = 100, General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[4].Id, Amount__c = 10, General_Accounting_Unit__c = defaultGau.Id
                )
            );

            // Opportunity 6, Payment 4 - $0, Default Allocation needs resizing
            //                            Payment Allocations (Default GAU, $10)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[5].Id, Amount__c = 10, General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6, Payment 5 - (null), Default Allocation needs resizing
            //                            Payment Allocations (Default GAU, $10)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[6].Id, Amount__c = 10, General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6, Payment 6 - $0, Percent Allocation to update
            //                            Payment Allocations (GAU0, 10%, $1)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[7].Id, Amount__c = 1, Percent__c = 10, General_Accounting_Unit__c = gaus[0].Id
                )
            );

            // Opportunity 6, Payment 7 - (null), Percent Allocation to update
            //                            Payment Allocations (GAU0, 10%, $1)
            allosForInsert.add(
                new Allocation__c(Payment__c = pmts[8].Id, Amount__c = 1, Percent__c = 10, General_Accounting_Unit__c = gaus[0].Id
                )
            );

            // Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
            //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[9].Id, Amount__c = 1, Percent__c = 10, General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[9].Id, Amount__c = 10, Percent__c = null, General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6, Payment 9  - (null), Percent Allocation to update, Default Allocation to remove
            //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[10].Id, Amount__c = 1, Percent__c = 10, General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[10].Id, Amount__c = 10, Percent__c = null, General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6, Payment 10 - $0, Needs Allocations

            // Opportunity 6, Payment 11 - (null), Needs Allocations

            // Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
            //                             Payment Allocations (GAU1)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[13].Id, Amount__c = null, Percent__c = null, General_Accounting_Unit__c = gaus[1].Id
                )
            );

            // Opportunity 7, Payment 0 - $10, Fully allocated
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[1].Id, Amount__c = 10, Percent__c = 100,General_Accounting_Unit__c = gaus[1].Id
                )
            );
        }

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[7].Id, Amount__c = 20, Percent__c = 100, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 8  - (null), If Default Allocations Enabled, Allocation (Default GAU, $20)
        //                          Else Allocation (GAU2, 100%, $20)
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[8].Id,
                Amount__c = 20,
                Percent__c = (defaultGau != null) ? null : 100,
                General_Accounting_Unit__c = (alloSetupTest.isDefaultAllocationsEnabled()) ? defaultGau.Id : gaus[2].Id
            )
        );

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40),
        //                  If Default Allocations Enabled (Default GAU, $40)
        if (alloSetupTest.isDefaultAllocationsEnabled()) { // Only if defaults enabled...
            allosForInsert.add(
                new Allocation__c(
                    Opportunity__c=opps[10].Id, Amount__c = 40, Percent__c = null, General_Accounting_Unit__c = defaultGau.Id
                )
            );
        }
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[10].Id, Amount__c = 40, Percent__c = 50, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[11].Id, Amount__c = 40, Percent__c = null, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 12 - $0, no Allocations

        // Opportunity 13 - $20, no Allocations

        insert allosForInsert;

        // Need to query data so critical fields like LastModifiedDate are populated
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }

        return oppIds;
    }

    /**
     * @description Asserts the various expected field values of an Opportunity Allocation__c record
     * @param alloc The allocation to assert
     * @param opportunityId Expected Opportunity__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertOpportunityAllocation(Allocation__c alloc, Id opportunityId, Decimal amount, Double percentage, Id gauId, String message) {
        assertAllocation(alloc, opportunityId, null, null, null, amount, percentage, null, gauId, message);
    }

    /**
     * @description Asserts the various expected field values of an Opportunity Allocation__c record
     * @param alloc The allocation to assert
     * @param opportunityId Expected Opportunity__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertOpportunityAllocation(Allocation__c alloc, Id opportunityId, Decimal amount, Double percentage, String gauName, String message) {
        assertAllocation(alloc, opportunityId, null, null, null, amount, percentage, gauName, null, message);
    }

    /**
     * @description Asserts the various expected field values of a Payment Allocation__c record
     * @param alloc The allocation to assert
     * @param paymentId Expected Payment__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertPaymentAllocation(Allocation__c alloc, Id paymentId, Decimal amount, Double percentage, String gauName, String message) {
        assertAllocation(alloc, null, paymentId, null, null, amount, percentage, gauName, null, message);
    }

    /**
     * @description Asserts the various expected field values of a Payment Allocation__c record
     * @param alloc The allocation to assert
     * @param paymentId Expected Payment__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertPaymentAllocation(Allocation__c alloc, Id paymentId, Decimal amount, Double percentage, Id gauId, String message) {
        assertAllocation(alloc, null, paymentId, null, null, amount, percentage, null, gauId, message);
    }

    /**
     * @description Asserts the various expected field values of a Recurring Donation Allocation__c record
     * @param alloc The allocation to assert
     * @param recurringDonationId Expected Recurring_Donation__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertRecurringDonationAllocation(Allocation__c alloc, Id recurringDonationId, Decimal amount, Double percentage, String gauName, String message) {
        assertAllocation(alloc, null, null, recurringDonationId, null, amount, percentage, gauName, null, message);
    }

    /**
     * @description Asserts the various expected field values of a Recurring Donations Allocation__c record
     * @param alloc The allocation to assert
     * @param recurringDonationId Expected Recurring_Donation__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertRecurringDonationAllocation(Allocation__c alloc, Id recurringDonationId, Decimal amount, Double percentage, Id gauId, String message) {
        assertAllocation(alloc, null, null, recurringDonationId, null, amount, percentage, null, gauId, message);
    }

    /**
     * @description Asserts the various expected field values of a Campaign Allocation__c record
     * @param alloc The allocation to assert
     * @param campaignId Expected Campaign__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertCampaignAllocation(Allocation__c alloc, Id campaignId, Decimal amount, Double percentage, String gauName, String message) {
        assertAllocation(alloc, null, null, null, campaignId, amount, percentage, gauName, null, message);
    }

    /**
     * @description Asserts the various expected field values of a Campaign Allocation__c record
     * @param alloc The allocation to assert
     * @param campaignId Expected Campaign__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertCampaignAllocation(Allocation__c alloc, Id campaignId, Decimal amount, Double percentage, Id gauId, String message) {
        assertAllocation(alloc, null, null, null, campaignId, amount, percentage, null, gauId, message);
    }

    /**
     * @description Asserts the various expected field values of an Allocation__c record
     * @param alloc The allocation to assert
     * @param opportunityId Expected Opportunity__c value
     * @param paymentId Expected Payment__c value
     * @param recurringDonationId Expected Recurring_Donation__c value
     * @param campaignId Expected Campaign__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName If not null, will assert value against General_Accounting_Unit__r.Name
     * @param gauId If not null, will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertAllocation(Allocation__c alloc, Id opportunityId, Id paymentId, Id recurringDonationId, Id campaignId, Decimal amount, Double percentage, String gauName, Id gauId, String message) {
        System.assertNotEquals(null, alloc, message + ' - Not Null');
        System.assertEquals(opportunityId, alloc.Opportunity__c, message + ' - Opportunity' );
        System.assertEquals(paymentId, alloc.Payment__c, message + ' - Payment');
        System.assertEquals(recurringDonationId, alloc.Recurring_Donation__c, message + ' - Recurring Donation');
        System.assertEquals(campaignId, alloc.Campaign__c, message + ' - Campaign');
        System.assertEquals(amount, alloc.Amount__c, message + ' - Amount');
        System.assertEquals(percentage, alloc.Percent__c, message + ' - Percent');
        if (gauName != null) {
            System.assertEquals(gauName, alloc.General_Accounting_Unit__r.Name, message + ' - GAU (Name)');
        }
        if (gauId != null) {
            System.assertEquals(gauId, alloc.General_Accounting_Unit__c, message + ' - GAU (Id)');
        }
    }

    /**
     * @description Asserts basic characteristics of a List of SObjects, including whether or not it is
     *              null, and the size
     * @param sObjs The List of SObjects to assert
     * @param expectedCount The number of expected records, or null, if the list should be null
     * @param message The text to put on the front on the assertion message text
     */
    public static void assertSObjectList(List<SObject> sObjs, Integer expectedCount, String message) {
        if (expectedCount == null) {
            System.assertEquals(null, sObjs, message + ' - List');
        } else {
            System.assertNotEquals(null, sObjs, message + ' - List');
            System.assertEquals(expectedCount, sObjs.size(), message + ' - List size');
        }
    }

    /**
     * @description Builds a map of a List of Recurring Donation Allocation__c records, keyed by
     *              Recurring Donation Id
     * @param allocs The list of allocs to process into a Map of a List of Recurring Donation Allocations,
     *        By Recurring Donation Id
     * @return Map of a List of Recurring Donations Allocations By Recurring Donations Id
     */
    public static Map<Id, List<Allocation__c>> buildMapOfAllocationsByRecurringDonationId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByRDId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Recurring_Donation__c != null) {
                List<Allocation__c> allocs2 = allocsByRDId.containsKey(alloc.Recurring_Donation__c) ? allocsByRDId.get(alloc.Recurring_Donation__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByRDId.put(alloc.Recurring_Donation__c, allocs2);
            }
        }

        return allocsByRDId;
    }

    /**
     * @description Builds a map of a List of Campaign Allocation__c records, keyed by Campaign Id
     * @param allocs The list of allocs to process into a Map of a List of Campaign Allocations,
     *        By Campaign Id
     * @return Map of a List of Campaign Allocations By Campaign Id
     */
    public static Map<Id, List<Allocation__c>> buildMapOfAllocationsByCampaignId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByCampaignId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Campaign__c != null) {
                List<Allocation__c> allocs2 = allocsByCampaignId.containsKey(alloc.Campaign__c) ? allocsByCampaignId.get(alloc.Campaign__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByCampaignId.put(alloc.Campaign__c, allocs2);
            }
        }

        return allocsByCampaignId;
    }

    /**
     * @description Builds a map of a List of Opportunity Allocation__c records, keyed by Opportunity Id
     * @param allocs The list of allocs to process into a Map of a List of Opportunity Allocations,
     *        By Opportunity Id
     * @return Map of a List of Opportunity Allocations By Opportunity Id
     */
    public static Map<Id, List<Allocation__c>> buildMapOfAllocationsByOpportunityId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByOppId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Opportunity__c != null) {
                List<Allocation__c> allocs2 = allocsByOppId.containsKey(alloc.Opportunity__c) ? allocsByOppId.get(alloc.Opportunity__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByOppId.put(alloc.Opportunity__c, allocs2);
            }
        }

        return allocsByOppId;
    }

    /**
     * @description Builds a map of a List of Payment Allocation__c records, keyed by Payment Id
     * @param allocs The list of allocs to process into a Map of a List of Payment Allocations,
     *        By Payment Id
     * @return Map of a List of Payment Allocations By Payment Id
     */
    public static Map<Id, List<Allocation__c>> buildMapOfAllocationsByPaymentId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByPmtId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Payment__c != null) {
                List<Allocation__c> allocs2 = allocsByPmtId.containsKey(alloc.Payment__c) ? allocsByPmtId.get(alloc.Payment__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByPmtId.put(alloc.Payment__c, allocs2);
            }
        }

        return allocsByPmtId;
    }

    /**
     * @description Helper method to retrieve all error records into a Map by Salesforce Id
     * @return Map of Error__c records by Related Record ID
     */
    public static Map<Id, Error__c> getErrorsByRecordId() {
        List<Error__c> errs = new TEST_SObjectGateway.ErrorGateway().getRecords();

        Map<Id, Error__c> errsByRecordId = new Map<Id, Error__c>();

        for (Error__c err : errs) {
            errsByRecordId.put (err.Related_Record_ID__c, err);
        }

        return errsByRecordId;
    }

    /**
     * @description Inner class to facilitate applying different configuration/environmental options for
     *              Test execution
     */
    public class AllocationSetupTest {

        private List<General_Accounting_Unit__c> gaus = null;
        private General_Accounting_Unit__c defaultGAU = null;
        private Allocations_Settings__c allocationSettings = null;

        private Boolean defaultAllocations = false;
        private Boolean paymentAllocations = false;
        private Boolean disableAllocationTriggers = false;
        private Boolean multiCurrencyEnabled = false;
        private String defaultIsoCode = null;
        private String nonDefaultIsoCode = null;

        /**
         * @description Default constructor for AllocationSetupTest class
         */
        public AllocationSetupTest() {

        }

        /**
         * @description Pass in existing allocation settings for use in configuration
         * @param allocationSettings An instance of Allocation_Settings__c
         * @return class instance
         */
        public AllocationSetupTest withAllocationSettings(Allocations_Settings__c allocationSettings) {
            this.allocationSettings = allocationSettings;
            return this;
        }

        /**
         * @description Sets Disable Allocations Triggers Configuration to true
         * @return class instance
         */
        public AllocationSetupTest disableAllocationTriggers() {
            this.disableAllocationTriggers = true;
            return this;
        }

        /**
         * @description Sets Payment Allocations Configuration and Default Allocations Configuration to true
         * @return class instance
         */
        public AllocationSetupTest enablePaymentAllocations() {
            this.paymentAllocations = true;
            this.defaultAllocations = true;
            return this;
        }

        /**
         * @description Sets Default Allocations Configuration to true
         * @return class instance
         */
        public AllocationSetupTest enableDefaultAllocations() {
            this.defaultAllocations = true;
            return this;
        }

        /**
         * @description Apply setup for test from configuration of member variables
         * @return class instance
         */
        public AllocationSetupTest applyConfiguration() {
            setupGAUs();

            if (this.allocationSettings == null) {
                this.allocationSettings = new Allocations_Settings__c();
            }

            this.allocationSettings.Payment_Allocations_Enabled__c = paymentAllocations;
            this.allocationSettings.Default_Allocations_Enabled__c = defaultAllocations;
            this.allocationSettings.Default__c = defaultAllocations ? defaultGAU.Id : null;

            setupSettings(allocationSettings);

            configureForMultiCurrencyIfPossible();

            if (this.disableAllocationTriggers) {
                // Turn Off Allocation Triggers
                ALLO_AllocationsUtil.disableAllocationTriggers();
            }

            return this;
        }

        /**
         * @description Configures some additional local variables if in a MultiCurrency Enabled Org
         */
        private void configureForMultiCurrencyIfPossible() {
            if (UserInfo.isMultiCurrencyOrganization()) {

                ALLO_Multicurrency_TEST.setupISOCodes();
                this.multiCurrencyEnabled = (ALLO_Multicurrency_TEST.nonDefaultCurrencyType != null && ALLO_Multicurrency_TEST.defaultCurrencyType != null);
                if (this.multiCurrencyEnabled) {
                    this.defaultIsoCode = (String) ALLO_Multicurrency_TEST.defaultCurrencyType.get('IsoCode');
                    this.nonDefaultIsoCode = (String) ALLO_Multicurrency_TEST.nonDefaultCurrencyType.get('IsoCode');
                }
            }
        }

        /**
         * @description Setup of GAUs for testing
         */
        private void setupGAUs() {
            if (this.gaus == null) {
                this.gaus = UTIL_UnitTestData_TEST.createGAUs(3);
                this.gaus[0].Name = 'GAU 1';
                this.gaus[1].Name = 'GAU 2';
                if (this.defaultAllocations) {
                    this.gaus[2].Name = 'Default GAU';
                    this.defaultGAU = gaus[2];
                } else {
                    this.gaus[2].Name = 'GAU 3';
                }
                insert gaus;
            } else {
                if (this.defaultAllocations) {
                    this.gaus[2].Name = 'Default GAU';
                    this.defaultGAU = gaus[2];
                } else {
                    this.gaus[2].Name = 'GAU 3';
                    this.defaultGAU = null;
                }
                update gaus;
            }
        }

        /**
         * @description Setup of allocations settings.
         * @param alloset An instance of Allocations_Settings__c custom setting. Calling this method with a null
         * parameter uses default settings.
         */
        private void setupSettings (Allocations_Settings__c alloset) {
            //set running user to avoid dml issue
            System.runAs(new User(id = UserInfo.getUserId())){
                if (alloset!=null)
                    UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloset);
                else
                    UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c());

            }
        }

        /**
         * @description Returns the list of General_Accounting_Unit__c records created during configuration for
         *              use in the tests
         * @return List of General_Accounting_Unit__c records created while applying the AllocationSetupTest
         */
        public List<General_Accounting_Unit__c> getGAUs() {
            return this.gaus;
        }

        /**
         * @description Returns the General_Accounting_Unit__C record assigned to be the "Default GAU", if
         *              Default Allocations were enabled
         * @return Default General_Accounting_Unit__c record, if default allocations are enabled and one was
         *         assigned
         */
        public General_Accounting_Unit__c getDefaultGAU() {
            return this.defaultGAU;
        }

        /**
         * @description Returns whether Default Allocations were enabled
         * @return true if enabled
         */
        public Boolean isDefaultAllocationsEnabled() {
            return this.defaultAllocations == true;
        }

        /**
         * @description Returns whether Payment Allocations were enabled
         * @return true if enabled
         */
        public Boolean isPaymentAllocationsEnabled() {
            return this.paymentAllocations == true;
        }

        /**
         * @description Returns whether MultiCurrency Tests can be executed or not
         * @return true if MultiCurrency is Enabled in the Org with a Corporate Currency and at least one other
         *         Currency enabled
         */
        public Boolean isMultiCurrencyConfiguredForTesting() {
            return this.multiCurrencyEnabled;
        }

        /**
         * @description Returns the Corporate (Default) Currency ISO Code (if possible)
         * @return String either null or the ISO Code associated with the Corporate Currency
         */
        public String getDefaultIsoCode() {
            return this.defaultIsoCode;
        }

        /**
         * @description Returns the Non Default (Not Corporate) Currency ISO Code (if possible)
         * @return String either null or the ISO Code associated with an enabled Currency other than the
         *         Corporate (Default) Currency
         */
        public String getNonDefaultIsoCode() {
            return this.nonDefaultIsoCode;
        }
    }
}