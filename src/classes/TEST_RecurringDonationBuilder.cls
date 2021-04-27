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
* @description Recurring Donations Builder
*
*/
@isTest
public without sharing class TEST_RecurringDonationBuilder {

    private class BuilderException extends Exception {}

    public static final Date DEFAULT_ESTABLISHED_DATE = Date.newInstance(1970,6,12);

    /***
    * @description Indicates Recurring Donation mode
    */
    public Enum Mode {
        Legacy,
        Enhanced
    }

    /***
    * @description Contains record field values
    */
    private Map<String, Object> valuesByFieldName = new Map<String, Object>();

    /***
    * @description String representation of CreatedDate
    */
    private String createdDateValue;

    /***
    * @description Recurring Donation builder mode
    */
    private Mode recordMode;

    /***
    * @description Set to true to automatically calculate the NextPaymentDate field value when building the RD
    * For enhanced mode only
    */
    private Boolean calculateNextDonationDate = false;

    /***
    * @description Constructor
    */
    public TEST_RecurringDonationBuilder() {
        this.recordMode = RD2_EnablementService.isRecurringDonations2Enabled
            ? Mode.Enhanced
            : Mode.Legacy;

        this.withName();
    }

    /***
    * @description Constructor
    */
    private TEST_RecurringDonationBuilder(Mode recordMode) {
        this.recordMode = recordMode;

        this.withName();
    }

    /***
    * @description Returns legacy Recurring Donation builder
    */
    public static TEST_RecurringDonationBuilder constructLegacyBuilder() {
        return new TEST_RecurringDonationBuilder(Mode.Legacy);
    }

    /***
    * @description Returns enhanced Recurring Donation builder
    */
    public static TEST_RecurringDonationBuilder constructEnhancedBuilder() {
        return new TEST_RecurringDonationBuilder(Mode.Enhanced);
    }

    /***
    * @description Validates field is set on the correct Recurring Donation type that depends on the Mode
    */
    private void validateMode(Mode validMode) {
        if (recordMode != validMode) {
            throw new BuilderException('This settings is not applicable to ' + validMode.name() + ' Recurring Donations');
        }
    }

    /***
    * @description Sets the Id
    * @param rdId Recurring Donation Id
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withId(Id rdId) {
        valuesByFieldName.put('Id', rdId);
        return this;
    }

    /***
    * @description Sets the mock Id
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withMockId() {
        valuesByFieldName.put('Id', UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType));
        return this;
    }

    /***
    * @description Sets the Owner to the current user Id
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withOwnerId() {
        valuesByFieldName.put('OwnerId', System.UserInfo.getUserId());
        return this;
    }

    /***
    * @description Sets Name
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withName() {
        return withName('RD' + UTIL_UnitTestData_TEST.getUniqueString());
    }

    /***
    * @description Sets Name
    * @param name Recurring Donation Name
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withName(String name) {
        valuesByFieldName.put('Name', name);
        return this;
    }

    /***
    * @description Sets Account
    * @param accountId Account Id
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withAccount(Id accountId) {
        valuesByFieldName.put('npe03__Organization__c', accountId);
        return this;
    }

    /***
    * @description Sets Contact
    * @param contactId Contact Id
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withContact(Id contactId) {
        valuesByFieldName.put('npe03__Contact__c', contactId);
        return this;
    }

    /***
    * @description Sets Recurring Donation Campaign
    * @param campaignId Campaign Id
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withCampaign(Id campaignId) {
        valuesByFieldName.put('npe03__Recurring_Donation_Campaign__c', campaignId);
        return this;
    }

    /***
    * @description Sets Amount
    * @param amount Amount
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withAmount(Decimal amount) {
        valuesByFieldName.put('npe03__Amount__c', amount);
        return this;
    }

    /***
    * @description Sets Amount
    * @param amount Amount
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withPaymentMethod(String payMethod) {
        validateMode(Mode.Enhanced);

        valuesByFieldName.put('PaymentMethod__c', payMethod);
        return this;
    }

    /***
    * @description Sets CurrencyIsoCode
    * @param ccyIsoCode CurrencyIsoCode value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withCurrencyIsoCode(String ccyIsoCode) {
        if (UserInfo.isMultiCurrencyOrganization()) {
            valuesByFieldName.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, ccyIsoCode);
        }

        return this;
    }

    /***
    * @description Sets Date Established to default value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withDateEstablished() {
        return withDateEstablished(DEFAULT_ESTABLISHED_DATE);
    }

    /***
    * @description Sets Date Established
    * @param dt Date
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withDateEstablished(Date dt) {
        valuesByFieldName.put('npe03__Date_Established__c', dt);
        return this;
    }

    /***
    * @description Sets CreatedDate to default value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withCreatedDate() {
        return withCreatedDate(DEFAULT_ESTABLISHED_DATE);
    }

    /***
    * @description Sets Created Date value
    * @param dt Date
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withCreatedDate(Date dt) {
        createdDateValue = (Datetime.newInstance(dt.year(), dt.month(), dt.day())).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        return this;
    }

    /***
    * @description Sets End Date
    * @param dt Date
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withEndDate(Date dt) {
        valuesByFieldName.put('EndDate__c', dt);
        return this;
    }

    /***
    * @description Sets Next Payment Date
    * @param dt Date
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withNextPaymentDate(Date dt) {
        validateMode(Mode.Legacy);

        valuesByFieldName.put('npe03__Next_Payment_Date__c', dt);
        return this;
    }

    /***
    * @description Sets if the last day of month should be used
    * @param shouldUse Indicates if the field should be set to true or false
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withAlwaysUseLastDayOfMonth(Boolean shouldUse) {
        validateMode(Mode.Legacy);

        valuesByFieldName.put('Always_Use_Last_Day_Of_Month__c', shouldUse);
        return this;
    }

    /***
    * @description Sets Day of Month
    * @param dayOfMonth Day of Month value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withDayOfMonth(String dayOfMonth) {
        valuesByFieldName.put('Day_Of_Month__c', dayOfMonth);
        return this;
    }

    /***
    * @description Sets Start Date
    * @param startDate Start Date
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withStartDate(Date startDate) {
        validateMode(Mode.Enhanced);

        valuesByFieldName.put('StartDate__c', startDate);
        return this;
    }

    /***
    * @description Sets Number of Planned Installments for a Fixed Length RD
    * @param numberOfInstallments Number of Planned Installments
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withPlannedInstallments(Integer numberOfInstallments) {
        valuesByFieldName.put('npe03__Installments__c', numberOfInstallments);
        return this;
    }

    /***
    * @description Sets Installment Frequency
    * @param frequency Installment Frequency
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withInstallmentFrequency(Integer frequency) {
        validateMode(Mode.Enhanced);

        valuesByFieldName.put('InstallmentFrequency__c', frequency);
        return this;
    }

    /***
    * @description Sets Number of Paid Installments (a Rollup Field used by both Legacy and Enhanced)
    * @param Total Number of Paid installments
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withPaidInstallments(Integer installment) {
        valuesByFieldName.put('npe03__Total_Paid_Installments__c', installment);
        return this;
    }

    /***
    * @description Sets Installment Period to Yearly
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodYearly() {
        return withInstallmentPeriod(RD_Constants.INSTALLMENT_PERIOD_YEARLY);
    }

    /***
    * @description Sets Installment Period to Quarterly
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodQuarterly() {
        validateMode(Mode.Legacy);

        return withInstallmentPeriod(RD_Constants.INSTALLMENT_PERIOD_QUARTERLY);
    }

    /***
    * @description Sets Installment Period to Monthly
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodMonthly() {
        return withInstallmentPeriod(RD_Constants.INSTALLMENT_PERIOD_MONTHLY);
    }

    /***
    * @description Sets Installment Period to Weekly
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodWeekly() {
        return withInstallmentPeriod(RD_Constants.INSTALLMENT_PERIOD_WEEKLY);
    }

    /***
    * @description Sets Installment Period
    * @param installmentPeriod Installment Period
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriod(String installmentPeriod) {
        valuesByFieldName.put('npe03__Installment_Period__c', installmentPeriod);
        return this;
    }

    /***
    * @description Sets Schedule Type
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withScheduleTypeMultiplyValue() {
        return withScheduleType(RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY);
    }

    /***
    * @description Sets Schedule Type
    * @param scheduleType Recurrig Donation schedule type
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withScheduleType(String scheduleType) {
        validateMode(Mode.Legacy);

        valuesByFieldName.put('npe03__Schedule_Type__c', scheduleType);
        return this;
    }

    /***
    * @description Sets Open Ended Status to Open Status
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatusOpen() {
        return withOpenEndedStatus(RD_Constants.OPEN_ENDED_STATUS_OPEN);
    }

    /***
    * @description Sets Open Ended Status to Closed Status
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatusClosed() {
        return withOpenEndedStatus(RD_Constants.OPEN_ENDED_STATUS_CLOSED);
    }

    /***
    * @description Sets Open Ended Status to None
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatusNone() {
        return withOpenEndedStatus('None');
    }

    /***
    * @description Sets Open Ended Status
    * @param status Status value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatus(String status) {
        validateMode(Mode.Legacy);

        valuesByFieldName.put('npe03__Open_Ended_Status__c', status);
        return this;
    }

    /***
    * @description Sets Recurring Donation Status to Active
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withStatusActive() {
        return withStatus(RD2_Constants.STATUS_ACTIVE);
    }

    /***
    * @description Sets Recurring Donation Status to Lapsed
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withStatusLapsed() {
        return withStatus(RD2_Constants.STATUS_LAPSED);
    }

    /***
    * @description Sets Recurring Donation Status to Closed
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withStatusClosed() {
        return withStatus(RD2_Constants.STATUS_CLOSED);
    }

    /***
    * @description Sets Recurring Donation Status to Paused
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withStatusPaused() {
        return withStatus(RD2_Constants.STATUS_PAUSED);
    }

    /***
    * @description Sets Status field
    * @param status Status value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withStatus(String status) {
        validateMode(Mode.Enhanced);

        valuesByFieldName.put('Status__c', status);
        return this;
    }

    /***
    * @description Sets Recurring Donation Closed Reason
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withClosedReason(String closedReason) {
        validateMode(Mode.Enhanced);

        valuesByFieldName.put('ClosedReason__c', closedReason);
        return this;
    }

    /***
    * @description Sets Recurring Type field
    * @param recurringType Recurring Type value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withRecurringTypeOpen() {
        return withRecurringType(RD2_Constants.RECURRING_TYPE_OPEN);
    }

    /***
    * @description Sets Recurring Type field
    * @param recurringType Recurring Type value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withRecurringTypeFixed() {
        return withRecurringType(RD2_Constants.RECURRING_TYPE_FIXED);
    }

    /***
    * @description Sets Recurring Type field
    * @param recurringType Recurring Type value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withRecurringType(String recurringType) {
        validateMode(Mode.Enhanced);

        valuesByFieldName.put('RecurringType__c', recurringType);
        return this;
    }

    /***
    * @description Sets Next Donation Date. It's the same field as NextPaymentDate, but in RD2 this field is generally
    * calculated automatically during insert.
    * @param dt Date
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withNextDonationDate(Date dt) {
        valuesByFieldName.put('npe03__Next_Payment_Date__c', dt);
        return this;
    }

    /***
    * @description Sets CommitmentId field
    * @param commitmentId  value
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withCommitmentId(String commitmentId) {
        valuesByFieldName.put('CommitmentId__c', commitmentId);
        return this;
    }

    /***
    * @description Tell the build process to call the ScheduleService method
    * to calculate the Next Donation Date on the Recurring Donation
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withCalculateNextDonationDate() {
        validateMode(Mode.Enhanced);
        this.calculateNextDonationDate = true;
        return this;
    }

    /***
    * @description Set DisableFirstInstallment field to true. This field is by default false.
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withFirstInstallmentDisabled() {
        validateMode(Mode.Enhanced);
        valuesByFieldName.put('DisableFirstInstallment__c', true);
        return this;
    }

    /***
    * @description Set LastElevateVersionPlayed
    * @param version Integer for the 'Last Elevate Version Played'
    * @return TEST_RecurringDonationBuilder Builder instance
    */
    public TEST_RecurringDonationBuilder withLastElevateVersionPlayed(Integer version) {
        valuesByFieldName.put('LastElevateVersionPlayed__c', version);
        return this;
    }

    /**
    * @description Configure the RD with the appropriate default values based on the mode
    */
    public TEST_RecurringDonationBuilder withDefaultValues() {

        if (recordMode == Mode.Enhanced) {
            this.withStatusActive()
                .withRecurringTypeOpen()
                .withInstallmentPeriodMonthly()
                .withInstallmentFrequency(1)
                .withDayOfMonth('15');
        }

        return this;
    }

    /***
    * @description Builds Recurring Donation sObject based on the provided values
    * @return npe03__Recurring_Donation__c Recurring Donation record
    */
    public npe03__Recurring_Donation__c build() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();

        for (String fieldName : valuesByFieldName.keySet()) {
            rd.put(fieldName, valuesByFieldName.get(fieldName));
        }

        rd = handleCreatedDate(rd);

        if (calculateNextDonationDate) {
            new RD2_RecurringDonation(rd)
                .reviseNextDonationDateBeforeInsert(new RD2_ScheduleService());
        }

        return rd;
    }

    /***
    * @description Inserts Created Date into Recurring Donation record
    * @param rd npe03__Recurring_Donation__c
    * @return npe03__Recurring_Donation__c
    */
    private npe03__Recurring_Donation__c handleCreatedDate(npe03__Recurring_Donation__c rd) {
        if (createdDateValue == null) {
            return rd;
        }

        String rdRecord = JSON.serialize(rd);
        rdRecord = rdRecord.left(rdRecord.length() - 1);
        rdRecord += ',"CreatedDate":"' + createdDateValue + '"}';

        return (npe03__Recurring_Donation__c) JSON.deserialize(rdRecord, npe03__Recurring_Donation__c.class);
    }

    /***
    * @description Builds "size" number of Recurring Donation records based on already provided values
    * @param size Number of Recurring Donation records
    * @return List<npe03__Recurring_Donation__c> Recurring Donation records
    */
    public List<npe03__Recurring_Donation__c> build(Integer size) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Integer i = 0; i < size; i++) {
            rds.add(this
                .withName()
                .build()
            );
        }

        return rds;
    }

    /***
    * @description Builds Recurring Donation records for each provided Contact
    * @param contacts Contact records to build Recurring Donation record for
    * @return List<npe03__Recurring_Donation__c> Recurring Donation records
    */
    public List<npe03__Recurring_Donation__c> build(List<Contact> contacts) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Contact c : contacts) {
            rds.add(this
                .withName()
                .withContact(c.Id)
                .build()
            );
        }

        return rds;
    }

    /***
    * @description Builds Recurring Donation records for each provided Account
    * @param accounts Account records to build Recurring Donation record for
    * @return List<npe03__Recurring_Donation__c> Recurring Donation records
    */
    public List<npe03__Recurring_Donation__c> build(List<Account> accounts) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Account acc : accounts) {
            rds.add(this
                .withName()
                .withAccount(acc.Id)
                .build()
            );
        }

        return rds;
    }

    /**
    * @description Adds a child relationship to the Recurring Donation instance
    * @param rd RecuringDonation instance
    * @param relationshipName Name of the relationship to add
    * @param records List of SObjects to include for the relationship
    * @return Updated npe03__Recurring_Donation__c record
    */
    public static npe03__Recurring_Donation__c addRelatedList(npe03__Recurring_Donation__c rd, String relationshipName, List<SObject> records) {
        String rdRecord = JSON.serialize(rd);
        rdRecord = rdRecord.left(rdRecord.length()-1);

        String objJson = JSON.serialize(records);
        rdRecord += ',"' + relationshipName + '":{"totalSize":' + records.size() + ',"done":true,"records":' + objJson + '}';

        rdRecord += '}';

        return (npe03__Recurring_Donation__c)JSON.deserialize(rdRecord, npe03__Recurring_Donation__c.class);
    }


    /**
    * @description Adds a foreign key relationship to the Recurring Donation instance, such as Contact__r.AccountId
    * @param rd RecuringDonation instance
    * @param relationshipName Name of the relationship to add
    * @param foreignObject The SObject for the relationship
    * @return Updated npe03__Recurring_Donation__c record
    */
    public static npe03__Recurring_Donation__c addForeignKey(npe03__Recurring_Donation__c rd, String relationshipName, SObject foreignObject) {
        String rdRecord = JSON.serialize(rd);
        rdRecord = rdRecord.left(rdRecord.length()-1);

        String objJson = JSON.serialize(foreignObject);
        rdRecord += ',"' + relationshipName + '":' + objJson + '';

        rdRecord += '}';

        return (npe03__Recurring_Donation__c)JSON.deserialize(rdRecord, npe03__Recurring_Donation__c.class);
    }

    /**
     * @description Builds a fully mocked RecurringDonation record with subqueries on Opportunities and Schedules. This is
     * used to support mocked tests against the RD2_OpportunityEvaluationService without having to insert any records.
     * @param rd Mocked Recurring Donation using TEST_RecurringDonationBuilder
     * @param opps Mocked Related Opportunties (or an empty collection)
     * @param schedules Mockked RecurringDonationSchedule records (can be built using the RD2_ScheduleService)
     * @return RecurringDonation with the Subqueries fully populated.
     */
    public static npe03__Recurring_Donation__c mockRecurringDonationFullQueryResult(npe03__Recurring_Donation__c rd,
            List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {

        if (opps == null) {
            opps = new List<Opportunity>();
        }

        if (schedules == null) {
            schedules = new List<RecurringDonationSchedule__c>();
        }

        Contact contact = new Contact(
            Id = rd.npe03__Contact__c,
            AccountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            LastName = UTIL_UnitTestData_TEST.getUniqueString()
        );

        rd = addForeignKey(rd, 'npe03__Contact__r', contact);
        rd = addRelatedList(rd, 'npe03__Donations__r', opps);
        rd = addRelatedList(rd, UTIL_Namespace.StrTokenNSPrefix('RecurringDonationSchedules__r'), schedules);

        return rd;
    }
}