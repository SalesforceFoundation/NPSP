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
* @description Controller for the Schedule Visualization Component
*
*/
public with sharing class RD2_VisualizeScheduleController {

    @TestVisible
    private static RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        } set;
    }

    /***
    * @description Recurring Donation custom settings
    */
    private static Date startDate {
        get {
            if (startDate == null) {
                Integer matchDays = new RD2_Settings().nextDonationDateMatchDays;
                startDate = RD2_ScheduleService.currentDate.addDays(-matchDays);
            }
            return startDate;
        }
        set;
    }

    /**
     * @description Builds future installments for the Recurring Donation
     * @param recordId Record Id
     * @param displayNum Number of installments to display
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getInstallments(Id recordId, Integer displayNum) {
        validate(recordId);

        npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);
        DataTable dataTable = buildInstallmentDataTable(rd);

        if (dataTable.getColumns().isEmpty()) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerFLSInstallment);
        }

        getInstallmentRecords(rd, displayNum, dataTable);

        if (dataTable.getRecords().isEmpty()) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerMessageNoSchedule);
        }

        return new Map<String, Object>{ 'dataTable' => dataTable };
    }

    /**
     * @description Constructs the data table columns for the projected installments on the Recurring Donation
     * @param rd Recurring Donation
     * @return DataTable
     */
    private static DataTable buildInstallmentDataTable(npe03__Recurring_Donation__c rd) {
        return new DataTable()
            .addColumn(new DataTableColumn()
                .withFieldName('donationDate')
                .withLabel(System.Label.RD2_ScheduleVisualizerColumnDate)
                .withIsAccessible(Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_Of_Month__c)
                .withType(Schema.DisplayType.DATE)
                .withTypeAttributes(new Map<String, Object>{
                    'month' => '2-digit',
                    'day' => '2-digit'
                })
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Amount__c)
                .withFieldName('amount')
                .withTypeAttributes(new Map<String, Object>{
                    'currencyCode' => getCurrencyCode(rd)
                })
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.PaymentMethod__c)
                .withFieldName('paymentMethod')
            );
    }

    /**
     * @description Retrieves installments for the Recurring Donation
     * and adds them into the data table
     * @param rd Recurring Donation
     * @param displayNum Maximum number of installments to return
     * @param dataTable Data table containing installment columns and records
     * @return void
     */
    private static void getInstallmentRecords(npe03__Recurring_Donation__c rd, Integer displayNum, DataTable dataTable) {
        if (rd.Status__c == RD2_Constants.STATUS_CLOSED) {
            return;
        }

        Integer counter = 1;
        scheduleService.evaluateScheduleEndDateForFixedLength(rd, rd.RecurringDonationSchedules__r);

        for (RD2_ScheduleService.Installment installment : scheduleService.getVisualizedInstallments(
            RD2_ScheduleService.currentDate, displayNum, rd.RecurringDonationSchedules__r
        )) {
            dataTable.addRecord(new Installment(counter++, installment));
        }
    }

    /**
     * @description Retrieves active schedules for the Recurring Donation
     * @param recordId Record Id
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getSchedules(Id recordId) {
        validate(recordId);

        npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);
        DataTable dataTable = buildScheduleDataTable(rd);

        if (dataTable.getColumns().size() <= 1) {//is current field is always part of the data table fields
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerFLSSchedule);
        }

        Integer counter = 1;
        if (rd.Status__c != RD2_Constants.STATUS_CLOSED) {
            for (RD2_ScheduleService.ActiveSchedule schedule : scheduleService.getVisualizedSchedules(rd)) {
                dataTable.addRecord(new Schedule(counter++, schedule));
            }
        }

        if (dataTable.getRecords().isEmpty()) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerMessageNoActiveSchedule);
        }

        return new Map<String, Object>{ 'dataTable' => dataTable };
    }

    /**
     * @description Constructs the data table columns for schedules on the Recurring Donation
     * @param rd Recurring Donation
     * @return DataTable
     */
    private static DataTable buildScheduleDataTable(npe03__Recurring_Donation__c rd) {
        return new DataTable()
            .addColumn(new DataTableColumn()
                .withFieldName('isCurrent')
                .withType(Schema.DisplayType.BOOLEAN)
                .withIsAccessible(true)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Amount__c)
                .withFieldName('amount')
                .withTypeAttributes(new Map<String, Object>{
                    'currencyCode' => getCurrencyCode(rd)
                })
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.PaymentMethod__c)
                .withFieldName('paymentMethod')
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Recurring_Donation_Campaign__c)
                .withFieldName('campaign')
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.StartDate__c)
                .withFieldName('startDate')
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.StartDate__c)
                .withFieldName('endDate')
                .withLabel(System.Label.RD2_ScheduleLWCEndDate)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Installment_Period__c)
                .withFieldName('period')
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.InstallmentFrequency__c)
                .withFieldName('frequency')
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_of_Month__c)
                .withFieldName('dayOfMonth')
            );
    }

    /**
     * @description Retrieve the full Recurring Donation record
     * @param recordId Recurring Donations Id
     * @return npe03__Recurring_Donation__c
     */
    private static npe03__Recurring_Donation__c cachedRd;
    private static npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        if (cachedRd == null) {
            Set<String> queryFields = new Set<String>{
                'Id',
                'StartDate__c',
                'InstallmentFrequency__c',
                'npe03__Installment_Period__c',
                'npe03__Amount__c',
                'PaymentMethod__c',
                'npe03__Recurring_Donation_Campaign__r.Name',
                'Day_of_Month__c',
                'Status__c',
                'RecurringType__c',
                'npe03__Installments__c',
                'npe03__Total_Paid_Installments__c'
            };
            if (UserInfo.isMultiCurrencyOrganization()) {
                queryFields.add('CurrencyIsoCode');
            }

            RD2_OpportunityEvaluationService oppEvalService = new RD2_OpportunityEvaluationService();
            queryFields.add(oppEvalService.getScheduleSubQuery());
            queryFields.add(oppEvalService.getOpportunitySubQuery());

            String soql = new UTIL_Query()
                .withFrom(npe03__Recurring_Donation__c.SObjectType)
                .withSelectFields(queryFields)
                .withWhere('Id = :recordId')
                .build();

            cachedRd = Database.query(soql);
        }

        return cachedRd;
    }

    /**
     * @description Validates if enhanced Recurring Donation format is enabled
     * and if component is being used for the Recurring Donation page.
     * @param recordId Record Id
     * @return void
     */
    private static void validate(Id recordId) {
        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorInvalidUsage);
        }

        if (recordId == null || recordId.getSObjectType() != npe03__Recurring_Donation__c.SObjectType) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot);
        }
    }

    /**
     * @description Retrieves the currency code to use for the display
     * @param sobj Record
     * @return CurrencyIsoCode
     */
    public static String getCurrencyCode(SObject sobj) {
        if (UserInfo.isMultiCurrencyOrganization()) {
            return (String)sobj.get('CurrencyIsoCode');
        } else {
            return UserInfo.getDefaultCurrency();
        }
    }

    /**
     * @description Recurring Donation future installment Opportunity
     */
    public class Installment {
        @AuraEnabled public Integer installmentNumber;
        @AuraEnabled public Date donationDate;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String paymentMethod;

        public Installment(Integer num, RD2_ScheduleService.Installment installment) {
            this.installmentNumber = num;
            this.paymentMethod = installment.paymentMethod;
            this.donationDate = installment.nextDonationDate;
            this.amount = installment.installmentAmount;
        }
    }

    /**
     * @description Recurring Donation Schedule wrapper
     */
    public class Schedule {
        @AuraEnabled public Integer scheduleNumber;
        @AuraEnabled public Boolean isCurrent;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public String campaign;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String period;
        @AuraEnabled public Integer frequency;
        @AuraEnabled public String dayOfMonth;

        public Schedule(Integer num, RD2_ScheduleService.ActiveSchedule schedule) {
            this.scheduleNumber = num;
            this.isCurrent = schedule.isCurrent;
            this.amount = schedule.installmentAmount;
            this.paymentMethod = schedule.paymentMethod;
            this.campaign = schedule.campaignName;
            this.startDate = schedule.startDate;
            this.endDate = schedule.endDate;
            this.period = schedule.installmentPeriod;
            this.frequency = schedule.installmentFrequency;
            this.dayOfMonth = schedule.dayOfMonth;
        }
    }


    public with sharing class DataTable {
        @TestVisible
        private List<DataTableColumn> columns = new List<DataTableColumn>();

        @TestVisible
        private List<Object> records = new List<Object>();

        public DataTable addColumn(DataTableColumn column) {
            if (column.isAccessible) {
                columns.add(column);
            }

            return this;
        }

        @AuraEnabled
        public List<DataTableColumn> getColumns() {
            return columns;
        }

        public void addRecord(Object record) {
            records.add(record);
        }

        public void setRecords(List<Object> records) {
            this.records = records;
        }

        @AuraEnabled
        public List<Object> getRecords() {
            return this.records == null ? new List<Object>() : this.records;
        }
    }


    public with sharing class DataTableColumn {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean sortable = false;
        @AuraEnabled public Map<String, Object> typeAttributes = new Map<String, Object>();
        @AuraEnabled public Boolean isAccessible = false;

        /**
         * @description Constructor
         */
        public DataTableColumn() {}

        /**
         * @description Constructor
         */
        public DataTableColumn(Schema.DescribeFieldResult field) {
            this.fieldName = field.getName();
            this.label = field.getLabel();
            this.type = getType(field.getType());
            this.typeAttributes = getTypeAttributes(field.getType());
            this.sortable = field.isSortable();
            this.isAccessible = field.isAccessible();
        }

        public DataTableColumn withLabel(String label) {
            this.label = label;
            return this;
        }

        public DataTableColumn withFieldName(String fieldName) {
            this.fieldName = fieldName;
            return this;
        }

        public DataTableColumn withIsAccessible(Schema.DescribeFieldResult field) {
            this.isAccessible = field.isAccessible();
            return this;
        }

        public DataTableColumn withIsAccessible(Boolean isAccessible) {
            this.isAccessible = isAccessible;
            return this;
        }

        public DataTableColumn withType(Schema.DisplayType displayType) {
            this.type = getType(displayType);
            this.typeAttributes = getTypeAttributes(displayType);
            return this;
        }

        public String getType(Schema.DisplayType displayType) {
            return UTIL_LightningComponentSupport.getColumnType(displayType);
        }

        public DataTableColumn withTypeAttributes(Map<String, Object> typeAttributes) {
            this.typeAttributes = typeAttributes;
            return this;
        }

        public Map<String, Object> getTypeAttributes(final Schema.DisplayType displayType) {
            return UTIL_LightningComponentSupport.getColumnTypeAttributes(displayType);
        }
    }
}