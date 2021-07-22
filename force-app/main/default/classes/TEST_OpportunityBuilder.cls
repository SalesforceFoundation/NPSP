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
* @group Opportunity
* @description Opportunity Builder for unit tests
*
*/
@isTest
public without sharing class TEST_OpportunityBuilder {
    private Map<String, Object> valuesByFieldName;

    /***
    * @description Constructor
    */
    public TEST_OpportunityBuilder() {
        valuesByFieldName = new Map<String, Object>();

        this.withName();
    }

    /***
    * @description Sets Opportunity Id
    * @param oppId Opportunity or mock Id
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withId(Id oppId) {
        valuesByFieldName.put('Id', oppId);
        return this;
    }

    /***
    * @description Sets the mock Id
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withMockId() {
        valuesByFieldName.put('Id', UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType));
        return this;
    }

    /***
    * @description Sets Name
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withName() {
        return withName('Opp' + UTIL_UnitTestData_TEST.getUniqueString());
    }

    /***
    * @description Sets Name
    * @param name Opportunity name
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withName(String name) {
        valuesByFieldName.put('Name', name);
        return this;
    }

    /***
    * @description Sets Account
    * @param name Mock Account name
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withAccount(String name) {
        return withAccount(new Account(Name = name));
    }

    /***
    * @description Sets Account
    * @param acc Existing or mock Account record
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withAccount(Account acc) {
        valuesByFieldName.put(String.valueOf(Account.SObjectType), acc);
        return withAccount(acc.Id);
    }

    /***
    * @description Sets Account
    * @param accId Existing or mock Account Id
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withAccount(Id accId) {
        valuesByFieldName.put('AccountId', accId);
        return this;
    }

    /***
    * @description Sets PrimaryContact
    * @param con Existing or mock Contact record
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withContact(Contact con) {
        valuesByFieldName.put('Primary_Contact__c', con.Id);
        return withContact(con.Id);
    }

    /***
    * @description Sets PrimaryCotact
    * @param contactId Existing or mock Contact Id
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withContact(Id contactId) {
        valuesByFieldName.put('Primary_Contact__c', contactId);
        return this;
    }

    /***
    * @description Sets Campaign
    * @param campaignId Existing or mock Campaign Id
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withCampaign(Id campaignId) {
        valuesByFieldName.put('CampaignId', campaignId);
        return this;
    }

    /***
    * @description Sets Close Data
    * @param dt Date
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withCloseDate(Date dt) {
        valuesByFieldName.put('CloseDate', dt);
        return this;
    }

    /***
    * @description Sets Amount
    * @param amount Amount
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withAmount(Decimal amount) {
        valuesByFieldName.put('Amount', amount);
        return this;
    }

    /***
    * @description Sets CurrencyIsoCode
    * @param ccyIsoCode CurrencyIsoCode value
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withCurrencyIsoCode(String ccyIsoCode) {
        if (UserInfo.isMultiCurrencyOrganization()) {
            valuesByFieldName.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, ccyIsoCode);
        }

        return this;
    }

    /***
    * @description Determines the Closed Won stage value and sets StageName to it
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withClosedWonStage() {
        valuesByFieldName.put('StageName', UTIL_UnitTestData_TEST.getClosedWonStage());
        return this;
    }

    /***
    * @description Determines the Closed Lost stage value and sets StageName to it
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withClosedLostStage() {
        valuesByFieldName.put('StageName', UTIL_UnitTestData_TEST.getClosedLostStage());
        return this;
    }

    /***
    * @description Determines the open stage value and sets StageName to it
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withOpenStage() {
        valuesByFieldName.put('StageName', UTIL_UnitTestData_TEST.getOpenStage());
        return this;
    }

    /***
    * @description Sets Recurring Donation Id on the Opportunity
    * @param rdId Recurring Donation Id
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withRecurringDonation(Id rdId) {
        valuesByFieldName.put('npe03__Recurring_Donation__c', rdId);
        return this;
    }

    /***
    * @description Sets Recurring Donation Installment Number
    * @param installmentNumber Recurring Donation Installment Number
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withInstallmentNumber(Integer installmentNumber) {
        valuesByFieldName.put('Recurring_Donation_Installment_Number__c', installmentNumber);
        return this;
    }

    /***
    * @description Sets Recurring Donation Installment Number to the value set in data migration
    * @param installmentNumber Recurring Donation Installment Number
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withInstallmentNumberMigrationFlag() {
        return withInstallmentNumber(RD2_DataMigrationBase_BATCH.MIGRATION_INSTALLMENT_NUMBER_FLAG);
    }

    /***
    * @description Sets CommitmentId field
    * @param commitmentId  value
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withCommitmentId(String commitmentId) {
        valuesByFieldName.put('CommitmentId__c', commitmentId);
        return this;
    }

    /***
    * @description Sets the specified custom or standard field to the specified value
    * @param fieldName Any field name on the Opportunity
    * @param value The field value
    * @return TEST_OpportunityBuilder Builder instance
    */
    public TEST_OpportunityBuilder withField(String fieldName, Object value) {
        valuesByFieldName.put(fieldName, value);
        return this;
    }

    /***
    * @description Attaches child records to the Opportunity
    * @param childRecords Child record on the Opportunity
    * @return Map<String, Object> Related list map values
    */
    private Map<String, Object> makeArray(List<SObject> childRecords) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('records', childRecords);
        result.put('totalSize', childRecords.size());
        result.put('done', true);

        return result;
    }

    /***
    * @description Builds Opportunity sObject based on the provided values
    * @return Opportunity
    */
    public Opportunity build() {
        Opportunity opp = new Opportunity();

        for (String fieldName : valuesByFieldName.keySet()) {
            opp.put(fieldName, valuesByFieldName.get(fieldName));
        }

        return opp;
    }

    /***
    * @description Builds "size" number of Opportunity records based on already provided values
    * @param size Number of Opportunity records
    * @return List<Opportunity> Opportunity records
    */
    public List<Opportunity> build(Integer size) {
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < size; i++) {
            opps.add(this
                .withName(UTIL_UnitTestData_TEST.getUniqueString())
                .build()
            );
        }

        return opps;
    }

    /**
     * @description Instantiate an Opportunity builder for the specified Recurring Donation
     * @param rd Recurring Donation
     * @return TEST_OpportunityBuilder New Opportunity builder
     */
    public static TEST_OpportunityBuilder getOpportunityBuilder(npe03__Recurring_Donation__c rd) {
        return new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAccount(rd.npe03__Organization__c)
            .withAmount(rd.npe03__Amount__c)
            .withInstallmentNumber(1);
    }

    /**
     * @description Sets IsClosed and IsWon fields where applicable for specified Opportunities
     * @param opps Opportunities
     * @return void
     */
    public static void setUneditableFields(List<Opportunity> opps) {
        Set<String> closedStageNames = new Set<String>{
            UTIL_UnitTestData_TEST.getClosedWonStage(),
            UTIL_UnitTestData_TEST.getClosedLostStage()
        };

        for (Integer i = 0, size = opps.size(); i < size; i++) {
            if (!closedStageNames.contains(opps[i].StageName)) {
                continue;
            }

            String objJson = JSON.serialize(opps[i]);
            objJson = objJson.left(objJson.length() - 1);
            objJson += ',"IsClosed":true,"IsWon":' + (opps[i].StageName ==  UTIL_UnitTestData_TEST.getClosedWonStage()) + '}';
            opps[i] = (Opportunity)JSON.deserialize(objJson, Opportunity.class);
        }
    }

}