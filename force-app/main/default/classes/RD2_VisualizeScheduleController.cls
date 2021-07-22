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

    private static final String INSTALLMENT_DONATION_DATE = 'donationDate';
    private static final String INSTALLMENT_AMOUNT = 'amount';
    private static final String INSTALLMENT_PAYMENT_METHOD = 'paymentMethod';
    private static final String INSTALLMENT_PAUSE_STATUS = 'pauseStatus';

    private static final String SCHEDULE_IS_CURRENT = 'isCurrent';
    private static final String SCHEDULE_AMOUNT = 'amount';
    private static final String SCHEDULE_PAYMENT_METHOD = 'paymentMethod';
    private static final String SCHEDULE_CAMPAIGN = 'campaign';
    private static final String SCHEDULE_START_DATE = 'startDate';
    private static final String SCHEDULE_END_DATE = 'endDate';
    private static final String SCHEDULE_PERIOD = 'period';
    private static final String SCHEDULE_FREQUENCY = 'frequency';
    private static final String SCHEDULE_DAY_OF_MONTH = 'dayOfMonth';

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
    * @description Specifies the earliest date when searching for Opportunities
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
     * @description Builds future projected installments for the Recurring Donation
     * @param recordId Record Id
     * @param displayNum Number of installments to display
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getInstallments(Id recordId, Integer displayNum) {
        validate(recordId);

        RD2_RecurringDonation rd = getRecurringDonation(recordId);
        DataTable dataTable = buildInstallmentDataTable(rd.getSObject());

        if (dataTable.getColumns().isEmpty()) {
            throwAuraHandledException(System.Label.RD2_ScheduleVisualizerFLSInstallment);
        }

        getInstallmentRecords(rd, displayNum, dataTable);

        if (dataTable.getRecords().isEmpty()) {
            throwAuraHandledException(System.Label.RD2_ScheduleVisualizerMessageNoSchedule);
        }

        sanitizeInstallments(dataTable);

        return new Map<String, Object>{ 'dataTable' => dataTable };
    }

    /**
     * @description Retrieves installments for the Recurring Donation
     * and adds them into the data table
     * @param rd Recurring Donation
     * @param displayNum Maximum number of installments to return
     * @param dataTable Data table to populate with projected installment records
     * @return void
     */
    private static void getInstallmentRecords(RD2_RecurringDonation rd, Integer displayNum, DataTable dataTable) {
        if (rd.isClosed()) {
            return;
        }

        Integer counter = 1;
        scheduleService.evaluateScheduleEndDate(rd, rd.getSobject().RecurringDonationSchedules__r);

        for (RD2_ScheduleService.Installment installment : scheduleService.getAllVisualizedInstallments(
            RD2_ScheduleService.currentDate, displayNum, rd.getSobject().RecurringDonationSchedules__r
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

        RD2_RecurringDonation rd = getRecurringDonation(recordId);
        DataTable dataTable = buildScheduleDataTable(rd.getSObject());

        if (dataTable.getColumns().size() <= 1) {//"isCurrent" field is always part of the data table fields
            throwAuraHandledException(System.Label.RD2_ScheduleVisualizerFLSSchedule);
        }

        Integer counter = 1;
        if (!rd.isClosed()) {
            for (RD2_ScheduleService.ActiveSchedule schedule : scheduleService.getVisualizedSchedules(rd.getSObject())) {
                dataTable.addRecord(new Schedule(counter++, schedule));
            }
        }

        if (dataTable.getRecords().isEmpty()) {
            throwAuraHandledException(System.Label.RD2_ScheduleVisualizerMessageNoActiveSchedule);
        }

        sanitizeSchedules(dataTable);

        return new Map<String, Object>{ 'dataTable' => dataTable };
    }

    /**
     * @description Constructs the data table columns for the projected installments display
     * @param rd Recurring Donation
     * @return DataTable
     */
    @TestVisible
    private static DataTable buildInstallmentDataTable(npe03__Recurring_Donation__c rd) {
        return new DataTable()
            .addColumn(new DataTableColumn()
                .withFieldName(INSTALLMENT_DONATION_DATE)
                .withLabel(System.Label.RD2_ScheduleVisualizerColumnDate)
                .withIsAccessible(Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_Of_Month__c)
                .withType(Schema.DisplayType.DATE)
                .withTypeAttributes(new Map<String, Object>{
                    'month' => '2-digit',
                    'day' => '2-digit'
                })
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Amount__c)
                .withFieldName(INSTALLMENT_AMOUNT)
                .withTypeAttributes(new Map<String, Object>{
                    'currencyCode' => getCurrencyCode(rd)
                })
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.PaymentMethod__c)
                .withFieldName(INSTALLMENT_PAYMENT_METHOD)
            );
    }

    /**
     * @description Constructs the data table RD schedule columns
     * @param rd Recurring Donation
     * @return DataTable
     */
    @TestVisible
    private static DataTable buildScheduleDataTable(npe03__Recurring_Donation__c rd) {
        return new DataTable()
            .addColumn(new DataTableColumn()
                .withFieldName(SCHEDULE_IS_CURRENT)
                .withType(Schema.DisplayType.BOOLEAN)
                .withIsAccessible(true)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Amount__c)
                .withFieldName(SCHEDULE_AMOUNT)
                .withTypeAttributes(new Map<String, Object>{
                    'currencyCode' => getCurrencyCode(rd)
                })
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.PaymentMethod__c)
                .withFieldName(SCHEDULE_PAYMENT_METHOD)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Recurring_Donation_Campaign__c)
                .withFieldName(SCHEDULE_CAMPAIGN)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.StartDate__c)
                .withFieldName(SCHEDULE_START_DATE)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.StartDate__c)
                .withFieldName(SCHEDULE_END_DATE)
                .withLabel(System.Label.RD2_ScheduleLWCEndDate)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.npe03__Installment_Period__c)
                .withFieldName(SCHEDULE_PERIOD)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.InstallmentFrequency__c)
                .withFieldName(SCHEDULE_FREQUENCY)
            )
            .addColumn(new DataTableColumn(Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_of_Month__c)
                .withFieldName(SCHEDULE_DAY_OF_MONTH)
            );
    }

    /**
     * @description Sets null on fields that are not accessible
     * @param dataTable Data table containing columns and installment records
     * @return void
     */
    @TestVisible
    private static void sanitizeInstallments(DataTable dataTable) {
        Boolean hasPauseStatus = false;
        for (Object obj : dataTable.getRecords()) {
            Installment record = (Installment) obj;
            Integer hiddenFieldCounter = 0;

            if (!dataTable.isAccessible(INSTALLMENT_DONATION_DATE)) {
                record.donationDate = null;
                hiddenFieldCounter++;
            }
            if (!dataTable.isAccessible(INSTALLMENT_AMOUNT)) {
                record.amount = null;
                hiddenFieldCounter++;
            }
            if (!dataTable.isAccessible(INSTALLMENT_PAYMENT_METHOD)) {
                record.paymentMethod = null;
                hiddenFieldCounter++;
            }
            if (hiddenFieldCounter == 3) {//all fields are hidden
                record.pauseStatus = null;
            }

            if (String.isNotBlank(record.pauseStatus)) {
                hasPauseStatus = true;
            }
        }

        if (hasPauseStatus) {
            dataTable.addColumn(new DataTableColumn()
                .withFieldName(INSTALLMENT_PAUSE_STATUS)
                .withLabel(null)
                .withIsAccessible(true)
                .withType(Schema.DisplayType.STRING)
            );
        }
    }

    /**
     * @description Sets null on fields that are not accessible
     * @param dataTable Data table containing columns and schedule records
     * @return void
     */
    @TestVisible
    private static void sanitizeSchedules(DataTable dataTable) {
        if (dataTable.getColumns().size() == 9) {
            return;//all columns are visible
        }

        for (Object obj : dataTable.getRecords()) {
            Schedule record = (Schedule) obj;
            if (!dataTable.isAccessible(SCHEDULE_AMOUNT)) {
                record.amount = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_PAYMENT_METHOD)) {
                record.paymentMethod = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_CAMPAIGN)) {
                record.campaign = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_START_DATE)) {
                record.startDate = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_END_DATE)) {
                record.endDate = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_PERIOD)) {
                record.period = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_FREQUENCY)) {
                record.frequency = null;
            }
            if (!dataTable.isAccessible(SCHEDULE_DAY_OF_MONTH)) {
                record.dayOfMonth = null;
            }
        }
    }

    /**
     * @description Retrieve the full Recurring Donation record
     * @param recordId Recurring Donations Id
     * @return npe03__Recurring_Donation__c
     */
    @TestVisible
    private static RD2_RecurringDonation cachedRd;
    private static RD2_RecurringDonation getRecurringDonation(Id recordId) {
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
                'npe03__Total_Paid_Installments__c',
                'EndDate__c'
            };
            if (UserInfo.isMultiCurrencyOrganization()) {
                queryFields.add('CurrencyIsoCode');
            }

            RD2_QueryService queryService = new RD2_QueryService();
            queryFields.add(queryService.getScheduleSubQuery());
            queryFields.add(queryService.getOpportunitySubQuery());

            String soql = new UTIL_Query()
                .withFrom(npe03__Recurring_Donation__c.SObjectType)
                .withSelectFields(queryFields)
                .withWhere('Id = :recordId')
                .build();

            cachedRd = new RD2_RecurringDonation(Database.query(soql));
        }

        return cachedRd;
    }

    /**
     * @description Validates if enhanced Recurring Donation format is enabled
     * and if component is being used for the Recurring Donation page.
     * Throws an exception if validation results in an alert.
     * @param recordId Record Id
     * @return void
     */
    private static void validate(Id recordId) {
        String alert = getValidationAlert(recordId);

        if (String.isNotBlank(alert)) {
            throwAuraHandledException(alert);
        }
    }

    /**
     * @description Validates if enhanced Recurring Donation format is enabled
     * and if component is being used for the Recurring Donation page.
     * @param recordId Record Id
     * @return String An alert message if validation failes, otherwise null.
     */
    public static String getValidationAlert(Id recordId) {
        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            // The label value: "You must enable Enhanced Recurring Donations to use this component."
            return System.Label.RD2_ScheduleVisualizerErrorInvalidUsage;
        }

        if (recordId == null || recordId.getSObjectType() != npe03__Recurring_Donation__c.SObjectType) {
            // The label value: "This component must be used on a Recurring Donations record page."
           return System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot;
        }

        return null;
    }
    

    /***
    * @description Throws AuraHandledException
    * The wrapping of the error message again is required
    * so the specific message is displayed instead of generic "Script thrown exception".
    * @param errMessage Exception message that needs to be set again
    * @return void
    */
    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
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
        @AuraEnabled public Boolean isSkipped;
        @AuraEnabled public String pauseStatus;

        public Installment(Integer num, RD2_ScheduleService.Installment installment) {
            this.installmentNumber = num;
            this.paymentMethod = UTIL_Describe.getTranslatedPicklistLabel(
                npe03__Recurring_Donation__c.SObjectType,
                npe03__Recurring_Donation__c.PaymentMethod__c,
                installment.paymentMethod
            );
            this.donationDate = installment.nextDonationDate;
            this.amount = installment.installmentAmount;
            this.isSkipped = installment.isSkipped;
            this.pauseStatus = installment.isSkipped ? System.Label.RD2_InstallmentStatusSkipped : '';
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
            this.paymentMethod = UTIL_Describe.getTranslatedPicklistLabel(
                npe03__Recurring_Donation__c.SObjectType,
                npe03__Recurring_Donation__c.PaymentMethod__c,
                schedule.paymentMethod);
            this.campaign = schedule.campaignName;
            this.startDate = schedule.startDate;
            this.endDate = schedule.endDate;
            this.period = UTIL_Describe.getTranslatedPicklistLabel(
                npe03__Recurring_Donation__c.SObjectType,
                npe03__Recurring_Donation__c.npe03__Installment_Period__c,
                schedule.installmentPeriod);
            this.frequency = schedule.installmentFrequency;
            this.dayOfMonth = UTIL_Describe.getTranslatedPicklistLabel(
                npe03__Recurring_Donation__c.SObjectType,
                npe03__Recurring_Donation__c.Day_of_Month__c,
                schedule.dayOfMonth);
        }
    }


    /**
     * @description Data table containing columns and records to display
     */
    public with sharing class DataTable {
        /**
         * @description Contains data table columns and their attributes
         */
        @TestVisible
        private Map<String, DataTableColumn> columnByFieldName = new Map<String, DataTableColumn>();

        /**
         * @description Contains data table records
         */
        @TestVisible
        private List<Object> records = new List<Object>();

        /**
         * @description Adds column to the data table only if the user has the field accessible permission
         * @param column Data table column
         * @return DataTable This data table instance
         */
        public DataTable addColumn(DataTableColumn column) {
            if (column.isAccessible) {
                columnByFieldName.put(column.fieldName, column);
            }

            return this;
        }

        /**
         * @description Returns data table columns (if any)
         * @return List<DataTableColumn>
         */
        @AuraEnabled
        public List<DataTableColumn> getColumns() {
            return columnByFieldName.values();
        }

        /**
         * @description Returns data table column if it is in the data table
         * @return DataTableColumn
         */
        public DataTableColumn getColumn(String fieldName) {
            return columnByFieldName.get(fieldName);
        }

        /**
         * @description Determines if the Object.fieldName is accessible
         * @return Boolean
         */
        public Boolean isAccessible(String fieldName) {
            return columnByFieldName.containsKey(fieldName);
        }

        /**
         * @description Adds record to the data table
         * @param Object Record
         * @return void
         */
        public void addRecord(Object record) {
            records.add(record);
        }

        /**
         * @description Sets all records in the data table
         * @return void
         */
        public void setRecords(List<Object> records) {
            this.records = records;
        }

        /**
         * @description Returns data table records (if any)
         * @return List<Object>
         */
        @AuraEnabled
        public List<Object> getRecords() {
            return this.records == null ? new List<Object>() : this.records;
        }
    }


    /**
     * @description Data column containing field attributes required to display it
     */
    public with sharing class DataTableColumn {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean sortable = false; // records are not sortable in the datatable
        @AuraEnabled public Map<String, Object> typeAttributes = new Map<String, Object>();
        @AuraEnabled public Boolean isAccessible = false;
        @AuraEnabled public Boolean hideDefaultActions = true;

        /**
         * @description Default constructor
         */
        public DataTableColumn() {}

        /**
         * @description Constructor setting field attributes
         * @param field SObject field
         */
        public DataTableColumn(Schema.DescribeFieldResult field) {
            this.fieldName = field.getName();
            this.label = field.getLabel();
            this.type = getType(field.getType());
            this.typeAttributes = getTypeAttributes(field.getType());
            this.isAccessible = field.isAccessible();
        }

        /**
         * @description Sets the column label
         * @param label Label to display to the user
         * @return DataTableColumn This column instance
         */
        public DataTableColumn withLabel(String label) {
            this.label = label;
            return this;
        }

        /**
         * @description Sets the field name used to connect the column
         * and the record field value. For example,
         * the Installment object has "donationDate" field that will be
         * mapped to the column with fieldName = donationDate in the LWC component.
         * @param fieldName Record field name so column and field value can be connected
         * @return DataTableColumn This column instance
         */
        public DataTableColumn withFieldName(String fieldName) {
            this.fieldName = fieldName;
            return this;
        }

        /**
         * @description Sets the accessible attribute on the column
         * @param field The column accessible attribute is determined by the field's isAccessible() value
         * @return DataTableColumn This column instance
         */
        public DataTableColumn withIsAccessible(Schema.DescribeFieldResult field) {
            this.isAccessible = field.isAccessible();
            return this;
        }

        /**
         * @description Sets the accessible attribute on the column
         * @param isAccessible Attribute value
         * @return DataTableColumn This column instance
         */
        public DataTableColumn withIsAccessible(Boolean isAccessible) {
            this.isAccessible = isAccessible;
            return this;
        }

        /**
         * @description Sets the column data type and type attributes
         * @param displayType Field display type
         * @return DataTableColumn This column instance
         */
        public DataTableColumn withType(Schema.DisplayType displayType) {
            this.type = getType(displayType);
            this.typeAttributes = getTypeAttributes(displayType);
            return this;
        }

        /**
         * @description Returns the column data type determined based on the field display type
         * @param displayType Field display type
         * @return String Data type used to format field in the LWC
         */
        public String getType(Schema.DisplayType displayType) {
            return UTIL_LightningComponentSupport.getColumnType(displayType);
        }

        /**
         * @description Sets the column data type attributes
         * @param typeAttributes Attribute value by the attribute name, ie "month" => "2-digit"
         * @return DataTableColumn This column instance
         */
        public DataTableColumn withTypeAttributes(Map<String, Object> typeAttributes) {
            this.typeAttributes = typeAttributes;
            return this;
        }

        /**
         * @description Returns the column data type attributes determined based on the field display type
         * @param displayType Field display type
         * @return Map<String, Object> Attribute value by the attribute name, ie "month" => "2-digit"
         */
        public Map<String, Object> getTypeAttributes(Schema.DisplayType displayType) {
            return UTIL_LightningComponentSupport.getColumnTypeAttributes(displayType);
        }
    }
}