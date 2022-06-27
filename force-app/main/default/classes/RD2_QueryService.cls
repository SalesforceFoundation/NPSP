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
/**
* @author Salesforce.org
* @date 2021
* @group Recurring Donations
* @description Recurring Donation query helper service
*
*/
public inherited sharing class RD2_QueryService {
    /***
     * @description CurrencyIsoCode field name
     */
    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;

    /***
    * @description Determines if multi-currency is enabled for the org
    */
    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    @TestVisible
    private static RD2_StatusMapper statusMapper {
        get {
            if (statusMapper == null) {
                statusMapper = new RD2_StatusMapper();
            }
            return statusMapper;
        }
        set;
    }

    /***
    * @description Contains the current custom field mappings used to copy specified fields
    * on Recurring Donation to mapped fields onto the Opportunity record
    */
    private RD2_CustomFieldMapper customFieldMapper {
        get {
            if (customFieldMapper == null) {
                customFieldMapper = new RD2_CustomFieldMapper();
            }
            return customFieldMapper;
        }
        set;
    }

    private RD2_Settings settings {
        get {
            if (settings == null) {
                settings = new RD2_Settings();
            }
            return settings;
        }
        set;
    }

    /**
    * @description Contains all mandatory Recurring Donation fields required for the Opportunity Evaluation Service
    */
    private Set<String> rdFields = new Set<String> {
        'CreatedDate',
        'CreatedById',
        'Id',
        'LastModifiedDate',
        'LastModifiedById',
        'Name',
        'OwnerId',
        'npe03__Organization__c',
        'npe03__Amount__c',
        'npe03__Contact__c',
        'npe03__Contact__r.AccountId',
        'npe03__Date_Established__c',
        'npe03__Donor_Name__c',
        'npe03__Installments__c',
        'npe03__Installment_Period__c',
        'npe03__Last_Payment_Date__c',
        'npe03__Next_Payment_Date__c',
        'npe03__Paid_Amount__c',
        'npe03__Recurring_Donation_Campaign__c',
        'npe03__Total_Paid_Installments__c',
        String.valueOf(npe03__Recurring_Donation__c.ChangeType__c),
        String.valueOf(npe03__Recurring_Donation__c.ClosedReason__c),
        String.valueOf(npe03__Recurring_Donation__c.CommitmentId__c),
        String.valueOf(npe03__Recurring_Donation__c.CurrentYearValue__c),
        String.valueOf(npe03__Recurring_Donation__c.Day_of_Month__c),
        String.valueOf(npe03__Recurring_Donation__c.DisableFirstInstallment__c),
        String.valueOf(npe03__Recurring_Donation__c.EndDate__c),
        String.valueOf(npe03__Recurring_Donation__c.InstallmentFrequency__c),
        String.valueOf(npe03__Recurring_Donation__c.NextYearValue__c),
        String.valueOf(npe03__Recurring_Donation__c.PaymentMethod__c),
        String.valueOf(npe03__Recurring_Donation__c.RecurringType__c),
        String.valueOf(npe03__Recurring_Donation__c.StartDate__c),
        String.valueOf(npe03__Recurring_Donation__c.Status__c)
    };

    /**
     * @description Populate the collection of Recurring Donation records, querying ALL fields,
     * with the related Installment Opportunities and Active Schedule Records. Due to a core KI (W-2503825)
     * this query needs to exclude CLOB fields. Since there is no pure definition of that for a Describe, the
     * query excludes Large Text Area fields larger than 4KB. These would only be custom fields.
     * @param rdIds Recurring Donation Ids
     * @param startDate offset by the Next Donation Date match days before the year start date
     *      so past Opportunities matching future projected installments are returned.
     *      See getOpportunitySubQuery() for usage.
     * @return List<RecurringDonation> Recurring Donations with related installment Opportunities and active Schedules
     */
    public List<npe03__Recurring_Donation__c> getRecurringDonationsWithRelatedRecords(Set<Id> rdIds, Date startDate) {
        Set<String> queryFields = new Set<String>();

        queryFields.addAll(rdFields);
        queryFields.addAll(customFieldMapper.getRdFieldNames());
        queryFields.addAll((new RD2_NamingService()).nameFormatter.fields);
        queryFields.add(getOpportunitySubQuery());
        queryFields.add(getScheduleSubQuery());

        if (UserInfo.isMultiCurrencyOrganization()) {
            queryFields.add('CurrencyIsoCode');
        }

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN :rdIds')
            .build();

        return Database.query(soql);
    }

    /**
     * @description Retrieve a recurring donation with fields needed for UI applications
     * @param recurringDonationId Recurring Donation Id
     * @return npe03__Recurring_Donation__c The Recurring Donation
     */
    public npe03__Recurring_Donation__c getRecurringDonationForUI(Id recurringDonationId) {
        Set<String> queryFields = new Set<String>();

        queryFields.addAll(rdFields);
        queryFields.addAll(new Set<String>{
                'npe03__Organization__r.RecordTypeId',
                'npe03__Contact__r.Account.RecordTypeId',
                String.valueOf(npe03__Recurring_Donation__c.ACH_Last_4__c),
                String.valueOf(npe03__Recurring_Donation__c.CardLast4__c),
                String.valueOf(npe03__Recurring_Donation__c.CardExpirationMonth__c),
                String.valueOf(npe03__Recurring_Donation__c.CardExpirationYear__c)
        });

        queryFields.addAll(getCustomFieldNames());

        if (UserInfo.isMultiCurrencyOrganization()) {
            queryFields.add(CURRENCY_ISO_CODE_FIELD);
        }

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id = :recurringDonationId')
            .withLimit(1)
            .build();

        List<npe03__Recurring_Donation__c> results = Database.query(soql);
        return results[0];
    }



    /**
     * @description Returns query on Recurring Donation Schedule
     * Return all schedules for the RD Schedule visualization.
     * The Schedule Service will filter them out if not applicable within the time period.
     * @return String RD Schedule subquery used in the Recurring Donation SOQL
     */
    public String getScheduleSubQuery() {
        Set<String> fields = new RD2_ScheduleService.ScheduleQueryHandler().getFields();

        return '(SELECT ' + String.join(new List<String>(fields), ', ') + ' FROM RecurringDonationSchedules__r)';
    }

    /**
     * @description Returns query on Opportunity required to verify, create or update the Opportunity record
     * @return String Opportunity subquery used in the Recurring Donation SOQL
     */
    public String getOpportunitySubQuery() {
        //Return Recurring Donations'
        //open Opps regardless of the Close Date
        //and Opps with Close Date >= current date regardless if closed or open
        //and all Opps with Close Date in this current year
        Set<String> oppSubqueryFields = new Set<String>{
            'Id', 'Name', 'AccountId', 'Primary_Contact__c',
            'npe03__Recurring_Donation__c',
            'Amount', 'CloseDate',
            'StageName', 'IsClosed', 'IsWon',
            'CampaignId', 'Recurring_Donation_Installment_Number__c'
        };

        if (isMultiCurrencyEnabled) {
            oppSubqueryFields.add(CURRENCY_ISO_CODE_FIELD);
        }

        oppSubqueryFields.addAll(customFieldMapper.getOpportunityFieldNames());

        String oppSubquery = new UTIL_Query()
            .withSelectFields(oppSubqueryFields)
            .withFrom('npe03__Donations__r')
            .withWhere(
                'IsClosed = false ' +
                    'OR CloseDate >= :startDate '
            )
            .withOrderBy('npe03__Recurring_Donation__c, CloseDate ASC')
            .build();

        return '(' + oppSubquery + ')';
    }

    private List<String> getCustomFieldNames() {
        List<String> fieldNames = new List<String>();
        for(FieldSetMember field : settings.getCustomFieldSetMembers()) {
            fieldNames.add(field.fieldPath);
        }
        return fieldNames;
    }

    public List<SObject> getSObjectWithActiveRecurringDonations(String sObjectType, Set<Id> recordIds) {
        Set<String> statusValues = statusMapper.getActiveStatusValues();
        String queryString = getSObjectWithRecurringDonationsQuery(sObjectType);

        return Database.query(queryString);
    }

    public List<SObject> getSObjectWithLapsedRecurringDonations(String sObjectType, Set<Id> recordIds) {
        Set<String> statusValues = statusMapper.getLapsedStatusValues();
        String queryString = getSObjectWithRecurringDonationsQuery(sObjectType);

        return Database.query(queryString);
    }

    public List<SObject> getSObjectWithClosedRecurringDonations(String sObjectType, Set<Id> recordIds) {
        Set<String> statusValues = statusMapper.getClosedStatusValues();
        String queryString = getSObjectWithRecurringDonationsQuery(sObjectType);

        return Database.query(queryString);
    }

    private String getSObjectWithRecurringDonationsQuery(String sObjectType) {
        Set<String> selectedField = new Set<String>{
            UTIL_Namespace.StrTokenNSPrefix('Sustainer__c'),
            getRecurringDonationSubQuery(sObjectType)
        };

        return new UTIL_Query()
            .withSelectFields(selectedField)
            .withFrom(sObjectType)
            .withWhere(
                'Id IN: recordIds')
            .build();
    }

    private String getRecurringDonationSubQuery(String sObjectType) {
        String lookupReference = sObjectType == 'Account'
            ? 'npe03__RecurringDonations__r'
            : 'npe03__R00N80000002bOmREAU__r';

        return '(SELECT Id FROM ' + lookupReference +' WHERE Status__c IN: statusValues LIMIT 1)';
    }
}
