@isTest
private class BDI_RecurringDonations_TEST {
    static final String RD_STATUS_CLOSED = 'Closed';

    @TestSetup
    static void setupTestData(){
        Campaign testCampaign = new Campaign(Name = 'TestGroupA Campaign',
                                        IsActive = true,
                                        StartDate = Date.today().addDays(-10), 
                                        EndDate = Date.today().addDays(10));
        insert testCampaign;

        DataImport__c testDataImportA = 
                new DataImport__c(
                    Contact1_Firstname__c = 'Susie',
                    Contact1_Home_Phone__c = '555-321-0001',
                    Contact1_Lastname__c = 'TestGroupA01',
                    Contact1_Other_Phone__c = '555-456-0001',
                    Contact1_Personal_Email__c = 'testgroupAcontact01Personal@fakedata.com',
                    Contact1_Preferred_Email__c = 'testgroupAcontact01Preferred@fakedata.com',
                    Contact1_Preferred_Phone__c = '555-567-0001',
                    Recurring_Donation_Amount__c = 100,
                    Recurring_Donation_Date_Established__c = System.Date.Today(),
                    Recurring_Donation_Day_of_Month__c = '10',
                    Recurring_Donation_Installment_Frequency__c = 1,
                    Recurring_Donation_Installment_Period__c = 'Monthly',	
                    Recurring_Donation_Effective_Date__c = System.Date.Today().addDays(5),
                    Recurring_Donation_End_Date__c = null,
                    Recurring_Donation_Planned_Installments__c = null,
                    Recurring_Donation_Recurring_Type__c = null,
                    Recurring_Donation_Status__c = null,
                    Recurring_Donation_Status_Reason__c = null,	
                    Donation_Donor__c = 'Contact1',
                    Home_City__c = 'Fakeville',
                    Home_Country__c = 'United States',
                    Home_State_Province__c = 'California',
                    Home_Street__c = '100 Fake Blvd',
                    Home_Zip_Postal_Code__c = '94105',
                    Household_Phone__c = '555-789-0001',
                    Payment_Check_Reference_Number__c = '453',
                    Payment_Method__c = 'Check');

        DataImport__c testDataImportB = 
                new DataImport__c(
                    Contact1_Firstname__c = 'Joe',
                    Contact1_Home_Phone__c = '555-321-0001',
                    Contact1_Lastname__c = 'TestGroupB01',
                    Contact1_Other_Phone__c = '555-456-0001',
                    Contact1_Personal_Email__c = 'testgroupBcontact01Personal@fakedata.com',
                    Contact1_Preferred_Email__c = 'testgroupBcontact01Preferred@fakedata.com',
                    Contact1_Preferred_Phone__c = '555-567-0001',
                    Recurring_Donation_Amount__c = 200,
                    Recurring_Donation_Date_Established__c = System.Date.Today(),
                    Recurring_Donation_Day_of_Month__c = '15',
                    Recurring_Donation_Installment_Frequency__c = 1,
                    Recurring_Donation_Installment_Period__c = 'Yearly',	
                    Recurring_Donation_Effective_Date__c = System.Date.Today().addDays(5),
                    Recurring_Donation_End_Date__c = null,
                    Recurring_Donation_Planned_Installments__c = null,
                    Recurring_Donation_Recurring_Type__c = null,
                    Recurring_Donation_Status__c = null,
                    Recurring_Donation_Status_Reason__c = null,	
                    Donation_Donor__c = 'Contact1',
                    Home_City__c = 'Fakeville',
                    Home_Country__c = 'United States',
                    Home_State_Province__c = 'California',
                    Home_Street__c = '500 Fake Blvd',
                    Home_Zip_Postal_Code__c = '94105',
                    Household_Phone__c = '555-789-0001',
                    Payment_Check_Reference_Number__c = '453',
                    Payment_Method__c = 'Check');

        DataImport__c testDataImportC = 
                new DataImport__c(Account1_City__c = 'Faketown',
                    Account1_Country__c = 'United States',
                    Account1_Name__c = 'TestGroupC Org 1',
                    Account1_Phone__c = '554-123-0001',
                    Account1_State_Province__c = 'California',
                    Account1_Street__c = '954 Fakey St',    
                    Account1_Website__c = 'www.groupBfakeorgacct01.com',
                    Account1_Zip_Postal_Code__c = '20000',
                    Recurring_Donation_Amount__c = 300,
                    Recurring_Donation_Date_Established__c = System.Date.Today(),
                    Recurring_Donation_Day_of_Month__c = '12',
                    Recurring_Donation_Installment_Frequency__c = 1,
                    Recurring_Donation_Installment_Period__c = 'Monthly',	
                    Recurring_Donation_Effective_Date__c = System.Date.Today().addDays(5),
                    Recurring_Donation_End_Date__c = null,
                    Recurring_Donation_Planned_Installments__c = null,
                    Recurring_Donation_Recurring_Type__c = null,
                    Recurring_Donation_Status__c = null,
                    Recurring_Donation_Status_Reason__c = null,	
                    Donation_Donor__c = 'Account1',
                    Payment_Check_Reference_Number__c = '453',
                    Payment_Method__c = 'Check');
        insert new DataImport__c[]{testDataImportA,testDataImportB,testDataImportC};
        
    }


    @isTest
    static void shouldCreateRecurringDonation() {
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c = 
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        //DataImport__c[] disForProcessing = [SELECT Id FROM DataImport__c LIMIT 10];

        Test.StartTest();

        //npsp.BDI_DataImport_API.processDataImportRecords(dis, disForProcessing, false);
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        DataImport__c testDataImportAResult;
        DataImport__c testDataImportBResult;
        DataImport__c testDataImportCResult;

        for (DataImport__c di : [SELECT Id,
                                        Status__c,
                                        FailureInformation__c,
                                        Contact1_Lastname__c,
                                        Account1_Name__c,
                                        Recurring_Donation_Day_of_Month__c,
                                        Account1ImportStatus__c,
                                        Account1Imported__c, 
                                        Account2ImportStatus__c,
                                        Account2Imported__c,
                                        Contact1ImportStatus__c,
                                        Contact1Imported__c,
                                        Contact2ImportStatus__c,
                                        Contact2Imported__c,
                                        DonationCampaignImportStatus__c,
                                        DonationCampaignImported__c,
                                        DonationImportStatus__c,
                                        DonationImported__c,
                                        RecurringDonationImported__c,
                                        HomeAddressImportStatus__c,
                                        HomeAddressImported__c,
                                        HouseholdAccountImported__c,
                                        PaymentImportStatus__c,
                                        PaymentImported__c
                                    FROM DataImport__c]) {
            if (di.Contact1_Lastname__c == 'TestGroupA01') {
                testDataImportAResult = di;
            } else if (di.Contact1_Lastname__c == 'TestGroupB01') {
                testDataImportBResult = di;
            } else if (di.Account1_Name__c == 'TestGroupC Org 1') {
                testDataImportCResult = di;
            }
        }

        System.assertEquals(null,testDataImportAResult.FailureInformation__c);
        System.assertEquals(BDI_DataImport_API.bdiImported,testDataImportAResult.Status__c);
        System.assertNotEquals(null,testDataImportAResult.Contact1Imported__c);
        System.assertEquals(System.label.bdiCreated,testDataImportAResult.Contact1ImportStatus__c);
        //System.assertNotEquals(null,testDataImportAResult.DonationCampaignImported__c);
        //System.assertEquals(System.label.bdiMatched,testDataImportAResult.DonationCampaignImportStatus__c);
        //System.assertNotEquals(null,testDataImportAResult.DonationImported__c);
        System.assertEquals(System.label.bdiCreated,testDataImportAResult.DonationImportStatus__c);
        System.assertNotEquals(null,testDataImportAResult.HouseholdAccountImported__c);
        System.assertNotEquals(null,testDataImportAResult.HomeAddressImported__c);


        npe03__Recurring_Donation__c rdA;
        npe03__Recurring_Donation__c rdB;
        npe03__Recurring_Donation__c rdC;

        npe03__Recurring_Donation__c[] rdResults = [SELECT Id, 
                                                        npe03__Amount__c,
                                                        npe03__Contact__c,
                                                        npe03__Organization__c,
                                                        InstallmentFrequency__c,
                                                        npe03__Installment_Period__c,
                                                        RecurringType__c,
                                                        CommitmentId__c,
                                                        StartDate__c,
                                                        npe03__Date_Established__c,
                                                        Day_of_Month__c,
                                                        Status__c,
                                                        npe03__Installments__c,
                                                        npe03__Total__c
                                                    FROM npe03__Recurring_Donation__c];
        System.assertEquals(3,rdResults.size());

        for (npe03__Recurring_Donation__c rd : rdResults){
            System.debug('recurring donation: ' + rd);
            if (rd.Id == testDataImportAResult.RecurringDonationImported__c) {
                rdA = rd;
            } else if (rd.Id == testDataImportBResult.RecurringDonationImported__c) {
                rdB = rd;
            } else if (rd.Id == testDataImportCResult.RecurringDonationImported__c) {
                rdC = rd;
            }
        }

        System.assertNotEquals(null,rdA);
        System.assertEquals(testDataImportAResult.Contact1Imported__c, rdA.npe03__Contact__c);
        System.assertEquals(100, rdA.npe03__Amount__c);
        System.assertEquals(null,rdA.CommitmentId__c);
        System.assertEquals(null,rdA.npe03__Organization__c);
        System.assertEquals('Active',rdA.Status__c);
        System.assertEquals('Monthly',rdA.npe03__Installment_Period__c);
        System.assertEquals(testDataImportAResult.Recurring_Donation_Day_Of_Month__c,rdA.Day_Of_Month__c);
        System.assertEquals(1,rdA.InstallmentFrequency__c);

        System.assertNotEquals(null,rdB);
        System.assertEquals(testDataImportBResult.Contact1Imported__c, rdB.npe03__Contact__c);
        System.assertEquals(200, rdB.npe03__Amount__c);
        System.assertEquals(null,rdB.CommitmentId__c);
        System.assertEquals(null,rdB.npe03__Organization__c);
        System.assertEquals('Active',rdB.Status__c);
        System.assertEquals('Yearly',rdB.npe03__Installment_Period__c);
        System.assertEquals(testDataImportBResult.Recurring_Donation_Day_Of_Month__c,rdB.Day_Of_Month__c);
        System.assertEquals(1,rdB.InstallmentFrequency__c);

        System.assertNotEquals(null,rdC);
        System.assertEquals(null, rdC.npe03__Contact__c);
        System.assertEquals(300, rdC.npe03__Amount__c);
        System.assertEquals(null,rdC.CommitmentId__c);
        System.assertEquals(testDataImportCResult.Account1Imported__c,rdC.npe03__Organization__c);
        System.assertEquals('Active',rdC.Status__c);
        System.assertEquals('Monthly',rdC.npe03__Installment_Period__c);
        System.assertEquals(testDataImportCResult.Recurring_Donation_Day_Of_Month__c,rdC.Day_Of_Month__c);
        System.assertEquals(1,rdC.InstallmentFrequency__c);

        Opportunity[] opptResults = [SELECT Id, 
                                            Name,
                                            Amount,
                                            CloseDate,
                                            StageName,
                                            Account.Name,
                                            npe03__Recurring_Donation__c,
                                            RecordtypeId
                                        FROM Opportunity];
        
        for (Opportunity oppt : opptResults) {
            System.debug('Opportunity is: ' + oppt);
        }

        //Updating this DI to close RD
        DataImport__c diAUpdate = 
            new DataImport__c(
                            Contact1Imported__c = testDataImportAResult.Contact1Imported__c,
                            RecurringDonationImported__c = testDataImportAResult.RecurringDonationImported__c,
                            Recurring_Donation_Status__c = RD_STATUS_CLOSED,
                            Recurring_Donation_Status_Reason__c = 'No Longer Interested');

        DataImport__c[] disForUpdate = new DataImport__c[]{diAUpdate};
        insert disForUpdate;

        //Process updated DIs
        BDI_DataImport_API.processDataImportRecords(dis, disForUpdate, false);

        DataImport__c testDataImportAResult2;
        DataImport__c testDataImportBResult2;
        DataImport__c testDataImportCResult2;

        for (DataImport__c di : [SELECT Id,
                                        Status__c,
                                        FailureInformation__c,
                                        Contact1_Lastname__c,
                                        Account1_Name__c,
                                        Recurring_Donation_Day_of_Month__c,
                                        Account1ImportStatus__c,
                                        Account1Imported__c, 
                                        Account2ImportStatus__c,
                                        Account2Imported__c,
                                        Contact1ImportStatus__c,
                                        Contact1Imported__c,
                                        Contact2ImportStatus__c,
                                        Contact2Imported__c,
                                        DonationCampaignImportStatus__c,
                                        DonationCampaignImported__c,
                                        DonationImportStatus__c,
                                        DonationImported__c,
                                        RecurringDonationImported__c,
                                        HomeAddressImportStatus__c,
                                        HomeAddressImported__c,
                                        HouseholdAccountImported__c,
                                        PaymentImportStatus__c,
                                        PaymentImported__c
                                    FROM DataImport__c]) {
            System.debug('2nd pass Data Import records: ' + di);
            if (di.RecurringDonationImported__c == testDataImportAResult.RecurringDonationImported__c) {
                testDataImportAResult2 = di;
            } else if (di.Contact1_Lastname__c == 'TestGroupB01') {
                testDataImportBResult2 = di;
            } else if (di.Account1_Name__c == 'TestGroupC Org 1') {
                testDataImportCResult2 = di;
            }
        }

        npe03__Recurring_Donation__c rdA2;
        npe03__Recurring_Donation__c rdB2;
        npe03__Recurring_Donation__c rdC2;

        npe03__Recurring_Donation__c[] rdResults2 = [SELECT Id, 
                                                        npe03__Amount__c,
                                                        npe03__Contact__c,
                                                        npe03__Organization__c,
                                                        InstallmentFrequency__c,
                                                        npe03__Installment_Period__c,
                                                        RecurringType__c,
                                                        CommitmentId__c,
                                                        ClosedReason__c,
                                                        StartDate__c,
                                                        npe03__Date_Established__c,
                                                        Day_of_Month__c,
                                                        Status__c,
                                                        npe03__Installments__c,
                                                        npe03__Total__c
                                                    FROM npe03__Recurring_Donation__c];
        System.assertEquals(3,rdResults2.size());

        for (npe03__Recurring_Donation__c rd : rdResults2){
            System.debug('2nd pass Recurring Donations records: ' + rd);
            if (rd.Id == testDataImportAResult.RecurringDonationImported__c) {
                rdA2 = rd;
            } else if (rd.Id == testDataImportBResult.RecurringDonationImported__c) {
                rdB2 = rd;
            } else if (rd.Id == testDataImportCResult.RecurringDonationImported__c) {
                rdC2 = rd;
            }
        }
        
        System.assertNotEquals(null,rdA2);
        System.assertEquals(RD_STATUS_CLOSED, rdA2.Status__c);
        System.assertEquals('No Longer Interested',rdA2.ClosedReason__c);
        System.assertEquals(testDataImportAResult.Contact1Imported__c, rdA2.npe03__Contact__c);
        System.assertEquals(100, rdA2.npe03__Amount__c);
        
    }

    @isTest
    static void shouldUpdateRecurringDonation() {
        
    }
}