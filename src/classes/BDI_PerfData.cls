/*
    Copyright (c) 2014 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @description BDI Performance Analysis test data utilities.
*/
public with sharing class BDI_PerfData {

    public static void delExistingData() {
        delete [select Id FROM DataImport__c WHERE Status__c = null];
        delete [select Id FROM DataImport__c WHERE Status__c = 'Failed'];
        delete [select Id FROM Opportunity WHERE CloseDate = 2017-06-04];
        delete [select Id from Account where Name like 'X% Household'];
        delete [select Id from Account where Name like 'CompanyX%'];
        delete [select Id from Campaign where Name = 'LDVTestCampaign'];
    }

    public static DataImportBatch__c createDIBatch(String description) {

        DataImportBatch__c batch = new DataImportBatch__c(
            Name = 'testBatch ' + string.valueOf(system.now()),
            Batch_Description__c = description,
            Batch_Process_Size__c = 100,
            Contact_Custom_Unique_ID__c = null,
            Account_Custom_Unique_ID__c = null,
            Contact_Matching_Rule__c = 'Firstname,Lastname',
            Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' + UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate,
            Donation_Date_Range__c = 3,
            Donation_Matching_Implementing_Class__c = null,
            Post_Process_Implementing_Class__c = null,
            Process_Using_Scheduled_Job__c = false
        );
        insert batch;
        return batch;
    }

    public static void createDIRecords(ID batchId, Integer countRecords, Integer countOpps) {


        list<DataImport__c> listDI = new list<DataImport__c>();
        for (integer i = 1; i <= countRecords; i++) {
            for (integer iOpp = 1; iOpp <= countOpps; iOpp++) {
                DataImport__c di = new DataImport__c();
                di.NPSP_Data_Import_Batch__c = batchId;

                di.Contact1_Firstname__c = 'x' + i;
                di.Contact1_Lastname__c = 'X' + i;
                di.Contact1_Personal_Email__c = 'x@x' + i + '.com';

                di.Contact2_Firstname__c = 'xs' + i;
                di.Contact2_Lastname__c = 'X' + i;
                di.Contact2_Personal_Email__c = 'xs@x' + i + '.com';

                di.Home_Street__c = 'ABC street apt#' + i;
                di.Home_City__c = 'Seattle';
                di.Home_State_Province__c = 'Washington';
                di.Home_Zip_Postal_Code__c = '98005';
                di.Home_Country__c = 'United States';

                di.Account1_Name__c = 'CompanyX' + i;
                di.Account2_Name__c = 'CompanyXS' + i;

                di.Donation_Date__c = date.valueOf('2017-06-04');
                di.Donation_Donor__c = 'Contact1';
                di.Donation_Amount__c = 1000;
                di.Payment_Method__c = 'check';
                di.Donation_Stage__c = 'Pledged';
                di.Donation_Campaign_Name__c = 'LDVTestCampaign';

                listDI.add(di);
            }
        }
        insert listDI;
    }
}

