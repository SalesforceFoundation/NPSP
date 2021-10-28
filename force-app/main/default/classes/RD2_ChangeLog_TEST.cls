/*
    Copyright (c) 2021 Salesforce.org
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
@IsTest
private class RD2_ChangeLog_TEST {

    static String FAKE_CAMPAIGN_ID = '701P0000000a2OnIAI';
    static String FAKE_CAMPAIGN_ID_2 = '701P0000000a2OsIAI';
    static String FAKE_CAMPAIGN_NAME = 'Fake Campaign Name';
    static String FAKE_CAMPAIGN_NAME_2 = 'Second Fake Campaign';

    @IsTest
    static void settingDisabledRepresentedInView() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new npe03__Recurring_Donations_Settings__c(
                        IsRecurringDonations2Enabled__c = true,
                        EnableChangeLog__c = false
                )
        );

        RD2_ChangeLogService service = new RD2_ChangeLogService();
        RD2_ChangeLogView view = service.getChangeLogView(null, 3, null);
        System.assertEquals(false, view.settingEnabled);
    }

    @IsTest
    static void settingEnabledRepresentedInView() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new npe03__Recurring_Donations_Settings__c(
                        IsRecurringDonations2Enabled__c = true,
                        EnableChangeLog__c = true
                )
        );

        RD2_ChangeLogService service = new RD2_ChangeLogService();
        RD2_ChangeLogView view = service.getChangeLogView(null, 3, null);
        System.assertEquals(true, view.settingEnabled);
    }

    @IsTest
    static void unchangedAmountOnlyHasOldValue() {

        RD2_ChangeView view = new RD2_ChangeLog(getChangeRecord()).getChangeView();

        System.assertEquals(2, view.fields.size());

        // fields should be in a predictable order
        System.assertEquals(5, view.fields[0].oldValue, 'Old Amount value did not match.');
        System.assertEquals(null, view.fields[0].newValue, 'New Amount value should not be populated if unchanged.');
        System.assertEquals(60, view.fields[1].oldValue, 'New yearly value did not match.');
        System.assertEquals(null, view.fields[1].newValue, 'Old yearly value should not be populated if unchanged.');
    }

    @IsTest
    static void rdWithNoChangeRecordsReturnsViewWithEmptyChanges() {
        RD2_ChangeLogSelectorMock mock =
                new RD2_ChangeLogSelectorMock(new List<RecurringDonationChangeLog__c>());
        RD2_ChangeLogService service = new RD2_ChangeLogService();
        service.changeLogSelector = stubSelector(mock);

        RD2_ChangeLogView view = service.getChangeLogView(null, 3, null);

        System.assertEquals(0, view.changes.size());
        System.assertEquals(false, view.hasMore);
    }

    @IsTest
    static void rdWithRecordsBeyondLimitReturnsHasMoreTrue() {
        List<RecurringDonationChangeLog__c> records = getChangeRecords(4);
        RD2_ChangeLogSelectorMock mock =
                new RD2_ChangeLogSelectorMock(records);
        RD2_ChangeLogService service = new RD2_ChangeLogService();
        service.changeLogSelector = stubSelector(mock);

        RD2_ChangeLogView view = service.getChangeLogView(null, 3, null);

        System.assertEquals(3, view.changes.size());
        System.assertEquals(true, view.hasMore);

    }

    @IsTest
    static void rdWithChangedCampaignReturnsFieldChangeWithIdAndValue() {
        RecurringDonationChangeLog__c record = getCampaignChangeRecord();

        RD2_ChangeView view = new RD2_ChangeLog(record).getChangeView();

        System.assertEquals(3, view.fields.size());
        RD2_FieldChangeView campaignChangeView = view.fields[2];

        System.assertEquals(campaignChangeView.oldId, FAKE_CAMPAIGN_ID, 'Unexpected old campaign id');
        System.assertEquals(campaignChangeView.newId, FAKE_CAMPAIGN_ID_2, 'Unexpected new campaign id');
        System.assertEquals(campaignChangeView.oldValue, FAKE_CAMPAIGN_NAME, 'Unexpected old campaign name');
        System.assertEquals(campaignChangeView.newValue, FAKE_CAMPAIGN_NAME_2, 'Unexpected new campaign name');

    }

    @IsTest
    static void rdWithOnlyAmountChangeContainsOnlyAnnualValueAndAmount() {
        RecurringDonationChangeLog__c record = getChangeRecord();
        record.NewAmount__c = 10;
        record.NewAnnualValue__c = 120;

        RD2_ChangeView view = new RD2_ChangeLog(record).getChangeView();

        System.assertEquals(2, view.fields.size());
        System.assertEquals(10, view.fields[0].newValue);
        System.assertEquals(120, view.fields[1].newValue);
        System.assertEquals(5, view.fields[0].oldValue);
        System.assertEquals(60, view.fields[1].oldValue);
    }

    @IsTest
    static void amountContainsIsoCodeWhenMulticurrencyIsEnabled() {
        RecurringDonationChangeLog__c record = getChangeRecord();
        record.NewAmount__c = 10;
        record.NewAnnualValue__c = 120;

        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        String nonDefaultCurrencyCode = null;

        if (isMultiCurrencyEnabled) {
            // If there is no active non-default currency, exit
            if (RD2_ChangeLogService_TEST.nonDefaultCurrencyType == null) {
                return;
            }

            nonDefaultCurrencyCode = 
                (String)RD2_ChangeLogService_TEST.nonDefaultCurrencyType.get('IsoCode');
            
            record.put('CurrencyIsoCode', nonDefaultCurrencyCode);
        }

        RD2_ChangeView view = new RD2_ChangeLog(record).getChangeView();

        System.assertEquals(2, view.fields.size());
        System.assertEquals(10, view.fields[0].newValue);
        System.assertEquals(120, view.fields[1].newValue);
        System.assertEquals(5, view.fields[0].oldValue);
        System.assertEquals(60, view.fields[1].oldValue);
        if (isMultiCurrencyEnabled) {
            System.assertEquals(nonDefaultCurrencyCode, view.fields[0].currencyCode);
            System.assertEquals(nonDefaultCurrencyCode, view.fields[1].currencyCode);
        }
    }

    @IsTest
    static void rdWithTypeChangeFromOpenToFixedHasCorrectValues() {
        RecurringDonationChangeLog__c record = getChangeRecord();
        record.NewExpectedTotalValue__c = 100;
        record.PreviousExpectedTotalValue__c = null;
        record.NewAnnualValue__c = null;

        RD2_ChangeView view = new RD2_ChangeLog(record).getChangeView();

        String changeLogSObjectName = String.valueOf(RecurringDonationChangeLog__c.SObjectType);

        String field1Label = UTIL_Describe.getFieldLabel(
            changeLogSObjectName,
            String.valueOf(RecurringDonationChangeLog__c.PreviousAnnualValue__c)
        );

        String field2Label = UTIL_Describe.getFieldLabel(
            changeLogSObjectName,
            String.valueOf(RecurringDonationChangeLog__c.NewExpectedTotalValue__c)
        );

        System.assertEquals(3, view.fields.size());
        System.assertEquals(field1Label, view.fields[1].label);
        System.assertEquals(null, view.fields[1].newValue);
        System.assertEquals(60, view.fields[1].oldValue);
        System.assertEquals(field2Label, view.fields[2].label);
        System.assertEquals(null, view.fields[2].newValue);
        System.assertEquals(100, view.fields[2].oldValue);
    }

    private class RD2_ChangeLogSelectorMock implements StubProvider {
        List<RecurringDonationChangeLog__c> records;

        public RD2_ChangeLogSelectorMock(List<RecurringDonationChangeLog__c> records) {
            this.records = records;
        }

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            if(stubbedMethodName == 'getChangeLogEntries') {
                return records;
            }
            return null;
        }
    }

    static RD2_ChangeLogSelector stubSelector(RD2_ChangeLogSelectorMock mock) {
        return (RD2_ChangeLogSelector) Test.createStub(
                RD2_ChangeLogSelector.class,
                mock
        );
    }

    static List<RecurringDonationChangeLog__c> getChangeRecords(Integer count) {
        List<RecurringDonationChangeLog__c> changes = new List<RecurringDonationChangeLog__c>();
        for(Integer i=0; i < count; i++) {
            changes.add(getChangeRecord());
        }
        return changes;
    }

    static RecurringDonationChangeLog__c getCampaignChangeRecord() {
        RecurringDonationChangeLog__c record = getChangeRecord();

        Campaign newCampaign = new Campaign(
                Id = FAKE_CAMPAIGN_ID_2,
                Name = FAKE_CAMPAIGN_NAME_2
        );

        Campaign previousCampaign = new Campaign(
                Id = FAKE_CAMPAIGN_ID,
                Name = FAKE_CAMPAIGN_NAME
        );

        record.PreviousCampaign__c = FAKE_CAMPAIGN_ID;
        record.NewCampaign__c = FAKE_CAMPAIGN_ID_2;
        record.NewCampaign__r = newCampaign;
        record.PreviousCampaign__r = previousCampaign;

        return record;
    }

    static RecurringDonationChangeLog__c getChangeRecord() {
        return new RecurringDonationChangeLog__c(
                PreviousAmount__c = 5,
                NewAmount__c = 5,
                PreviousAnnualValue__c = 60,
                NewAnnualValue__c = 60,
                EffectiveDate__c = Date.newInstance(2020, 0, 03),
                ChangeType__c = 'Upgrade'
        );
    }
}