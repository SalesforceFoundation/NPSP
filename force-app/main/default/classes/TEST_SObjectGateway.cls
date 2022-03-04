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
* @group Test API
* @description Classes used to retrieve specific SObjects created in tests
*
*/
@isTest
public class TEST_SObjectGateway {

    /***
    * @description Retrieves Recurring Donation record(s)
    */
    public class RecurringDonationGateway {

        /***
        * @description Retrieves Recurring Donation record for the specified Id
        * @param rdId Id of the recurring donation
        * @return npe03__Recurring_Donation__c
        */
        public npe03__Recurring_Donation__c getRecord(Id rdId) {
            return getRecords(new Set<Id>{ rdId })[0];
        }

        /***
        * @description Retrieves Recurring Donation records for the specified records
        * @param List<npe03__Recurring_Donation__c> Recurring donations
        * @return List<npe03__Recurring_Donation__c>
        */
        public List<npe03__Recurring_Donation__c> getRecords(List<npe03__Recurring_Donation__c> rds) {
            if (rds == null || rds.isEmpty()) {
                return new List<npe03__Recurring_Donation__c>();
            }

            return getRecords(new Map<Id, npe03__Recurring_Donation__c>(rds).keySet());
        }

        /***
        * @description Retrieves Recurring Donation records for the specified Ids
        * @param rdIds Ids of the recurring donations
        * @return List<npe03__Recurring_Donation__c>
        */
        public List<npe03__Recurring_Donation__c> getRecords(Set<Id> rdIds) {
            List<npe03__Recurring_Donation__c> records = new List<npe03__Recurring_Donation__c>();

            for (npe03__Recurring_Donation__c rd : getRecords()) {
                if (rdIds.contains(rd.Id)) {
                    records.add(rd);
                }
            }

            return records;
        }

        /***
        * @description Retrieves Recurring Donation records
        * @return List<npe03__Recurring_Donation__c>
        */
        public List<npe03__Recurring_Donation__c> getRecords() {
            return [
                SELECT
                    Name,
                    npe03__Recurring_Donation_Campaign__c,
                    npe03__Organization__c,
                    npe03__Contact__c,
                    npe03__Donor_Name__c,
                    npe03__Amount__c,
                    npe03__Paid_Amount__c,
                    npe03__Date_Established__c,
                    Day_of_Month__c,
                    DisableFirstInstallment__c,
                    StartDate__c,
                    EndDate__c,
                    npe03__Next_Payment_Date__c,
                    npe03__Last_Payment_Date__c,
                    npe03__Installment_Period__c,
                    InstallmentFrequency__c,
                    npe03__Total_Paid_Installments__c,
                    npe03__Installments__c,
                    PaymentMethod__c,
                    RecurringType__c,
                    Status__c,
                    ClosedReason__c,
                    CurrentYearValue__c,
                    NextYearValue__c,
                    CommitmentId__c,
                    CardExpirationMonth__c,
                    CardExpirationYear__c,
                    CardLast4__c,
                    ChangeType__c
                FROM npe03__Recurring_Donation__c
            ];
        }
    }


    /***
    * @description Retrieves Recurring Donation Schedule record(s)
    */
    public class RecurringDonationScheduleGateway {

        /***
        * @description Retrieves Recurring Donation Schedule records for the specified RD record
        * @param npe03__Recurring_Donation__c Recurring donation
        * @return List<RecurringDonationSchedule__c>
        */
        public List<RecurringDonationSchedule__c> getRecords(npe03__Recurring_Donation__c rd) {
            return getRecords(new List<npe03__Recurring_Donation__c>{rd});
        }

        /***
        * @description Retrieves Recurring Donation Schedule records for the specified RD records
        * @param List<npe03__Recurring_Donation__c> Recurring donations
        * @return List<RecurringDonationSchedule__c>
        */
        public List<RecurringDonationSchedule__c> getRecords(List<npe03__Recurring_Donation__c> rds) {
            if (rds == null || rds.isEmpty()) {
                return new List<RecurringDonationSchedule__c>();
            }

            return [
                SELECT
                    Campaign__c,
                    Campaign__r.Name,
                    DayOfMonth__c,
                    StartDate__c,
                    EndDate__c,
                    InstallmentAmount__c,
                    InstallmentFrequency__c,
                    InstallmentPeriod__c,
                    PaymentMethod__c,
                    RecurringDonation__c,
                    IsPause__c,
                    StatusReason__c,
                    Active__c
                FROM RecurringDonationSchedule__c
                WHERE RecurringDonation__c IN :rds
            ];
        }
    }

    /***
    * @description Retrieves Opportunities
    */
    public class OpportunityGateway {
        private Set<String> fields = new Set<String>{
            'Name',
            'Description',
            'AccountId',
            'RecordTypeId',
            'Amount',
            'CampaignId',
            'CloseDate',
            'StageName',
            'IsClosed',
            'IsWon',
            'Closed_Lost_Reason__c',
            'npe03__Recurring_Donation__c',
            'Recurring_Donation_Installment_Number__c',
            'npe01__Contact_Id_for_Role__c',
            'Primary_Contact__c',
            'CommitmentId__c'
        };


        /***
        * @description Constructor adding the CurrencyIsoCode into the output fields set
        */
        public OpportunityGateway() {
            if (UserInfo.isMultiCurrencyOrganization()) {
                fields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
            }
        }

        /***
        * @description Retrieves Opportunities for the related Recurring Donation
        * @param rd Recurring donation
        * @return List<Opportunity>
        */
        public List<Opportunity> getRecords(npe03__Recurring_Donation__c rd) {
            return getRecords(new List<npe03__Recurring_Donation__c>{ rd });
        }

        /***
        * @description Retrieves Opportunities for related Recurring Donations
        * @param rds Recurring donations
        * @return List<Opportunity>
        */
        public List<Opportunity> getRecords(List<npe03__Recurring_Donation__c> rds) {
            String soql = new UTIL_Query()
                .withFrom(Opportunity.SObjectType)
                .withSelectFields(fields)
                .withWhere('npe03__Recurring_Donation__c IN :rds')
                .build();

            return (List<Opportunity>) Database.query(soql);
        }

        /***
        * @description Retrieves Opportunities sorted by Closedate for the related Recurring Donation
        * @param rd Recurring donation
        * @return List<Opportunity>
        */
        public List<Opportunity> getRecordsByCloseDate(npe03__Recurring_Donation__c rd) {
            return getRecordsByCloseDate(new List<npe03__Recurring_Donation__c>{ rd });
        }

        /***
        * @description Retrieves Opportunities sorted by CloseDate for related Recurring Donations
        * @param rds Recurring donations
        * @return List<Opportunity>
        */
        public List<Opportunity> getRecordsByCloseDate(List<npe03__Recurring_Donation__c> rds) {
            String soql = new UTIL_Query()
                .withFrom(Opportunity.SObjectType)
                .withSelectFields(fields)
                .withWhere('npe03__Recurring_Donation__c IN :rds')
                .withOrderBy('CloseDate ASC')
                .build();

            return (List<Opportunity>) Database.query(soql);
        }

        /***
        * @description Retrieves Opportunity for specified Opportunity Id
        * @param oppId An Opportunity Id
        * @return Opportunity
        */
        public Opportunity getRecord(Id oppId) {
            List<Opportunity> opps = getRecords(new Set<Id>{ oppId });

            return opps == null || opps.isEmpty() ? null : opps[0];
        }

        /***
        * @description Retrieves Opportunities for specified Opportunity Ids
        * @param oppIds Opportunity Ids
        * @return List<Opportunity>
        */
        public List<Opportunity> getRecords(Set<Id> oppIds) {
            String soql = new UTIL_Query()
                .withFrom(Opportunity.SObjectType)
                .withSelectFields(fields)
                .withWhere('Id IN :oppIds')
                .build();

            return (List<Opportunity>) Database.query(soql);
        }
    }

    /***
    * @description Retrieves payments
    */
    public class PaymentGateway {
        private Set<String> fields = new Set<String>{
            'Name',
            'npe01__Payment_Method__c',
            'npe01__Payment_Amount__c',
            'npe01__Opportunity__c'
        };

        /***
        * @description Constructor adding the CurrencyIsoCode into the output fields set
        */
        public PaymentGateway() {
            if (UserInfo.isMultiCurrencyOrganization()) {
                fields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
            }
        }

        /***
        * @description Retrieves payments for the related Opportunity
        * @param opp Opportunity
        * @return List<npe01__OppPayment__c>
        */
        public List<npe01__OppPayment__c> getRecords(Opportunity opp) {
            return getRecords(new List<Opportunity>{ opp });
        }

        /***
        * @description Retrieves payments for related Opportunities
        * @param opps Opportunity records
        * @return List<npe01__OppPayment__c>
        */
        public List<npe01__OppPayment__c> getRecords(List<Opportunity> opps) {
            String soql = new UTIL_Query()
                .withFrom(npe01__OppPayment__c.SObjectType)
                .withSelectFields(fields)
                .withWhere('npe01__Opportunity__c IN :opps')
                .build();

            return (List<npe01__OppPayment__c>) Database.query(soql);
        }
    }

    /***
    * @description Retrieves Error record(s)
    */
    public class ErrorGateway {

        /***
        * @description Retrieves Error records
        * @return List<Error__c>
        */
        public List<Error__c> getRecords() {
            return [
                SELECT
                    Context_Type__c,
                    Datetime__c,
                    Error_Type__c,
                    Full_Message__c,
                    Object_Type__c,
                    Related_Record_ID__c,
                    Record_URL__c,
                    Retry_Pending__c,
                    Email_Sent__c,
                    Posted_In_Chatter__c
                FROM Error__c
            ];
        }

        /***
        * @description Returns number of Error__c records
        * @return Integer
        */
        public Integer getErrorCount() {
            return Database.countQuery('SELECT Count() FROM Error__c');
        }
    }

    /***
    * @description Retrieves AsyncApexJob record(s)
    */
    public class AsyncApexJobGateway {
        private Set<String> fields = new Set<String>{
            'CreatedDate',
            'CompletedDate',
            'ExtendedStatus',
            'JobItemsProcessed',
            'TotalJobItems',
            'NumberOfErrors',
            'JobType',
            'ApexClass.NamespacePrefix',
            'ApexClass.Name',
            'MethodName'
        };

        /***
        * @description Retrieves AsyncApexJob record for the specified class name
        * @param className Class Name
        * @return AsyncApexJob
        */
        public AsyncApexJob getRecord(String className) {
            String soql = new UTIL_Query()
                .withFrom(AsyncApexJob.SObjectType)
                .withSelectFields(fields)
                .withWhere('ApexClass.Name = :className')
                .withLimit(1)
                .build();

            List<SObject> records = Database.query(soql);
            return records == null  || records.isEmpty() ? null : (AsyncApexJob) records[0];
        }

        /***
        * @description Retrieves AsyncApexJob record for the specified job Id
        * @param jobId Async Apex Job Id
        * @return AsyncApexJob
        */
        public AsyncApexJob getRecord(Id jobId) {
            String soql = new UTIL_Query()
                .withFrom(AsyncApexJob.SObjectType)
                .withSelectFields(fields)
                .withWhere('Id = :jobId')
                .build();

            List<SObject> records = Database.query(soql);
            return records == null  || records.isEmpty() ? null : (AsyncApexJob) records[0];
        }
    }
}