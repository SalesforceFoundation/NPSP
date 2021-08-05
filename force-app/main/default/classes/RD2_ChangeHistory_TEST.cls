@IsTest
private class RD2_ChangeHistory_TEST {

    static String FAKE_CAMPAIGN_ID = '701P0000000a2OnIAI';
    static String FAKE_CAMPAIGN_ID_2 = '701P0000000a2OsIAI';
    static String FAKE_CAMPAIGN_NAME = 'Fake Campaign Name';
    static String FAKE_CAMPAIGN_NAME_2 = 'Second Fake Campaign';

    @IsTest
    static void settingDisabledRepresentedInView() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new npe03__Recurring_Donations_Settings__c(
                        IsRecurringDonations2Enabled__c = true,
                        EnableChangeHistory__c = false
                )
        );

        RD2_ChangeHistoryService service = new RD2_ChangeHistoryService();
        RD2_ChangeHistoryView view = service.getChangeHistoryView(null, 3, null);
        System.assertEquals(false, view.settingEnabled);
    }

    @IsTest
    static void settingEnabledRepresentedInView() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
                new npe03__Recurring_Donations_Settings__c(
                        IsRecurringDonations2Enabled__c = true,
                        EnableChangeHistory__c = true
                )
        );

        RD2_ChangeHistoryService service = new RD2_ChangeHistoryService();
        RD2_ChangeHistoryView view = service.getChangeHistoryView(null, 3, null);
        System.assertEquals(true, view.settingEnabled);
    }

    @IsTest
    static void unchangedAmountOnlyHasOldValue() {

        RD2_ChangeView view = new RD2_ChangeHistory(getChangeRecord()).getChangeView();

        System.assertEquals(2, view.fields.size());

        // fields should be in a predictable order
        System.assertEquals(5, view.fields[0].oldValue, 'Old Amount value did not match.');
        System.assertEquals(null, view.fields[0].newValue, 'New Amount value should not be populated if unchanged.');
        System.assertEquals(60, view.fields[1].oldValue, 'New yearly value did not match.');
        System.assertEquals(null, view.fields[1].newValue, 'Old yearly value should not be populated if unchanged.');
    }

    @IsTest
    static void rdWithNoChangeRecordsReturnsViewWithEmptyChanges() {
        RD2_ChangeHistorySelectorMock mock =
                new RD2_ChangeHistorySelectorMock(new List<RecurringDonationChangeHistory__c>());
        RD2_ChangeHistoryService service = new RD2_ChangeHistoryService();
        service.changeHistorySelector = stubSelector(mock);

        RD2_ChangeHistoryView view = service.getChangeHistoryView(null, 3, null);

        System.assertEquals(0, view.changes.size());
        System.assertEquals(false, view.hasMore);
    }

    @IsTest
    static void rdWithRecordsBeyondLimitReturnsHasMoreTrue() {
        List<RecurringDonationChangeHistory__c> records = getChangeRecords(4);
        RD2_ChangeHistorySelectorMock mock =
                new RD2_ChangeHistorySelectorMock(records);
        RD2_ChangeHistoryService service = new RD2_ChangeHistoryService();
        service.changeHistorySelector = stubSelector(mock);

        RD2_ChangeHistoryView view = service.getChangeHistoryView(null, 3, null);

        System.assertEquals(3, view.changes.size());
        System.assertEquals(true, view.hasMore);

    }

    @IsTest
    static void rdWithChangedCampaignReturnsFieldChangeWithIdAndValue() {
        RecurringDonationChangeHistory__c record = getCampaignChangeRecord();

        RD2_ChangeView view = new RD2_ChangeHistory(record).getChangeView();

        System.assertEquals(3, view.fields.size());
        RD2_FieldChangeView campaignChangeView = view.fields[2];

        System.assertEquals(campaignChangeView.oldId, FAKE_CAMPAIGN_ID, 'Unexpected old campaign id');
        System.assertEquals(campaignChangeView.newId, FAKE_CAMPAIGN_ID_2, 'Unexpected new campaign id');
        System.assertEquals(campaignChangeView.oldValue, FAKE_CAMPAIGN_NAME, 'Unexpected old campaign name');
        System.assertEquals(campaignChangeView.newValue, FAKE_CAMPAIGN_NAME_2, 'Unexpected new campaign name');

    }

    @IsTest
    static void rdWithOnlyAmountChangeContainsOnlyAnnualValueAndAmount() {
        RecurringDonationChangeHistory__c record = getChangeRecord();
        record.NewAmount__c = 10;
        record.NewAnnualValue__c = 120;

        RD2_ChangeView view = new RD2_ChangeHistory(record).getChangeView();

        System.assertEquals(2, view.fields.size());
        System.assertEquals(10, view.fields[0].newValue);
        System.assertEquals(120, view.fields[1].newValue);
        System.assertEquals(5, view.fields[0].oldValue);
        System.assertEquals(60, view.fields[1].oldValue);
    }


    private class RD2_ChangeHistorySelectorMock implements StubProvider {
        List<RecurringDonationChangeHistory__c> records;

        public RD2_ChangeHistorySelectorMock(List<RecurringDonationChangeHistory__c> records) {
            this.records = records;
        }

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            System.debug(stubbedMethodName);
            System.debug(JSON.serializePretty(listOfArgs));
            if(stubbedMethodName == 'getChangeHistories') {
                return records;
            }
            return null;
        }
    }

    static RD2_ChangeHistorySelector stubSelector(RD2_ChangeHistorySelectorMock mock) {
        return (RD2_ChangeHistorySelector) Test.createStub(
                RD2_ChangeHistorySelector.class,
                mock
        );
    }

    static List<RecurringDonationChangeHistory__c> getChangeRecords(Integer count) {
        List<RecurringDonationChangeHistory__c> changes = new List<RecurringDonationChangeHistory__c>();
        for(Integer i=0; i < count; i++) {
            changes.add(getChangeRecord());
        }
        return changes;
    }

    static RecurringDonationChangeHistory__c getCampaignChangeRecord() {
        RecurringDonationChangeHistory__c record = getChangeRecord();

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

    static RecurringDonationChangeHistory__c getChangeRecord() {
        return new RecurringDonationChangeHistory__c(
                PreviousAmount__c = 5,
                NewAmount__c = 5,
                PreviousAnnualValue__c = 60,
                NewAnnualValue__c = 60,
                EffectiveDate__c = Date.newInstance(2020, 0, 03),
                ChangeType__c = 'Upgrade'
        );
    }
}