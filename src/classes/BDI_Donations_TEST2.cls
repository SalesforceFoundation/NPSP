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
* @group Batch Data Import
* @description Second part of tests specific to the Batch Data Importer Donations batch processing and record creation.
*/

@isTest
public with sharing class BDI_Donations_TEST2 {
    @isTest
    private static void shouldCreatePaymentsForElevateDI () {
        Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();
        dis.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dis.Default_Data_Import_Field_Mapping_Set__c = 
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dis);

        DataImport__c testDI1 = new DataImport__c(Contact1_FirstName__c = 'Testy',
                                                Contact1_LastName__c = 'TestCont1',
                                                Contact1_Personal_Email__c = 'testDI1@fakeDI.com',
                                                Donation_Amount__c = 100,
                                                Payment_Elevate_ID__c = '123',
                                                Payment_ACH_Last_4__c = '4567',
                                                Payment_Type__c = 'ACH',
                                                Payment_Status__c = 'SUBMITTED');

        insert testDI1;

        
        BDI_DataImport_API.processDataImportRecords(dis, new DataImport__c[]{testDI1},false);


        System.debug('Post Run');

        DataImport__c[] resultDis = [SELECT Id,
                                    FailureInformation__c,
                                    Status__c,
                                    DonationCampaignImported__c,
                                    Contact1Imported__c,
                                    PaymentImported__c,
                                    DonationImported__c,
                                    HouseholdAccountImported__c,
                                    Home_Zip_Postal_Code__c,
                                    Home_Street__c,
                                    HomeAddressImported__c,
                                    Contact1_Personal_Email__c,
                                    Donation_Date__c
                                FROM DataImport__c];
        /*
        //There should only be 3 Data import records
        System.assertEquals(4, dis.size(),'There should only be 4 DIs because one should have been duplicate');

        DataImport__c di1;
        DataImport__c di2;
        DataImport__c di3;
        DataImport__c di4;
        */

        for (DataImport__c di : resultDis) {
            System.debug('Post Process DI is: ' + di);
            /*
            if (di.Contact1_Personal_Email__c	 == 'tim@fake.com') {
            di1 = di;
            } else if (di.Contact1_Personal_Email__c	 == 'jane@fake.com') {
            di2 = di;
            } else if (di.Contact1_Personal_Email__c	 == 'jimmy@fake.com') {
            di3 = di;
            } else if (di.Contact1_Personal_Email__c	 == 'steve@fake.com') {
            di4 = di;
            }
            */
        }

        npe01__OppPayment__c pmt1;

        npe01__OppPayment__c[] paymentResults = [SELECT Id, 
                                                        npe01__Payment_Amount__c, 
                                                        npe01__Opportunity__c,
                                                        Elevate_Payment_Id__c,
                                                        //Elevate_API_Status__c,
                                                        ACH_Last_4__c
                                                FROM npe01__OppPayment__c];

        
        for (npe01__OppPayment__c pmt : paymentResults) {
            if (pmt.Elevate_Payment_Id__c == '123') {
                pmt1 = pmt;
            }
            System.debug('Payment is: ' + pmt);
        }

        System.assertEquals(1,paymentResults.size());

        System.assertNotEquals(null, pmt1);
        System.assertEquals(100,pmt1.npe01__Payment_Amount__c);
        //System.assertEquals('SUBMITTED',pmt1.Elevate_API_Status__c);
        System.assertEquals('4567', pmt1.ACH_Last_4__c);
   
    }

}