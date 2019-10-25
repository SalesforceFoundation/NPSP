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
* @description Test for Create Opportunities from Recurring Donations
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_OpportunityService_TEST {

    /***
    * @description Verifies if it creates opportunities when an recurring donation
      is inserted with a contact and the stage is pledged.
    */
    @isTest
    private static void shouldCreateOppWhenRDIsInsertedWithContact() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        String stageName = 'Pledged';

        createRdSettingsWithStage(stageName);

        Map<npe03__Recurring_Donation__c,List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c,List<Date>>();
        List<Date> CloseDate = new List<Date> ();
        CloseDate.add(System.today()+2);
        CloseDate.add(System.today()+5);

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(con.Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withCampaign(campaign.id)
            .build();

        insert rd;

        rd.PaymentMethod__c ='Credit Card';
        update rd;

        System.assert([
            SELECT id
            FROM npe03__Recurring_Donation__c].size()>0 );

        rdsWithCloseDates.put(rd, CloseDate);

        RD2_CreateOpportunityService rds = new RD2_CreateOpportunityService();
        rds.createInstallmentOpportunities(rdsWithCloseDates);

        Opportunity opp = [select id,name,npe03__Recurring_Donation__c,amount, campaignid, closedate, accountid, npe01__Contact_Id_For_Role__c from opportunity where createddate=today and campaignid != null limit 1];
        System.debug('Opportunity created:' + opp);

        System.assertEquals(opp.closedate, CloseDate[0]);

    }

    /***
    * @description Verifies if it creates opportunities when an recurring donation
      is inserted with an account and the stage is Promised.
    */
    @isTest
    private static void shouldCreateOppWhenRDIsInsertedWithAccount() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        String stageName = 'Promised';

        createRdSettingsWithStage(stageName);

        Map<npe03__Recurring_Donation__c,List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c,List<Date>>();
        List<Date> CloseDate = new List<Date> ();
        CloseDate.add(System.today()+2);
        CloseDate.add(System.today()+5);

        Account acc = UTIL_UnitTestData_TEST.getOrgAccount();
        insert acc;

        Campaign campaign = new Campaign(Name = 'TeaCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(acc.Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withAmount(415)
            .withCampaign(campaign.id)
            .build();

        insert rd;

        rd.PaymentMethod__c ='Credit Card';
        update rd;

        System.assert([
            SELECT id
            FROM npe03__Recurring_Donation__c].size()>0 );

        rdsWithCloseDates.put(rd, CloseDate);

        RD2_CreateOpportunityService rds = new RD2_CreateOpportunityService();
        rds.createInstallmentOpportunities(rdsWithCloseDates);

        Opportunity opp = [select id,name,npe03__Recurring_Donation__c,amount, campaignid, closedate, accountid, npe01__Contact_Id_For_Role__c from opportunity where createddate=today and campaignid != null limit 1];
        System.debug('Opportunity created:' + opp);

        System.assertEquals(opp.closedate, CloseDate[0]);

    }
    /*******************************************************************************************************
    * @description Creates recurring donation settings
    * @param Installment stagename
    * @return void
    */
    public static void createRdSettingsWithStage(String stageName) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            InstallmentOppStageName__c = stageName,
            npe03__Add_Campaign_to_All_Opportunites__c = true,
            IsRecurringDonations2Enabled__c = true
        ));
    }

}