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
* @description Mapper used to convert legacy Recurring Donations to enhanced Recurring Donations.
*
*/
public class RD2_DataMigrationMapper {

    /**
    * @description Defines mock "Day of Month" last day value for dry run data migration
    */
    private static final String DRY_RUN_DAY_OF_MONTH_LAST_DAY = '30';

    /**
    * @description Recurring Donation to convert to enhanced format
    */
    private npe03__Recurring_Donation__c rd;

    /**
    * @description Indicates data migration mode
    */
    private Boolean isDryRunMode = false;

    /**
    * @description All Opportunities related to the Recurring Donation
    */
    private List<Opportunity> allRelatedOpps;

    /**
    * @description Related Open Opportunities to void
    */
    public List<Opportunity> openOppsToVoid {
        get {
            if (openOppsToVoid == null) {
                openOppsToVoid = getOpenOpportunitiesToVoid();
            }
            return openOppsToVoid;
        }
        private set;
    }

    /**
     * @description Constructor
     */
    public RD2_DataMigrationMapper(npe03__Recurring_Donation__c rd, Boolean isDryRunMode) {
        this.rd = rd;
        this.isDryRunMode = isDryRunMode;
    }

    /**
     * @description Constructor, used in test for the data migration mapping tests
     */
    @TestVisible
    private RD2_DataMigrationMapper(npe03__Recurring_Donation__c rd) {
        this(rd, false);
    }

    /**
     * @description Adds related Opportunities to the mapper
     * @param opps Recurring Donation related Opportunities
     */
    public RD2_DataMigrationMapper withRelatedOpportunities(List<Opportunity> allRelatedOpps) {
        this.allRelatedOpps = allRelatedOpps;
        return this;
    }

    /**
     * @description Converts the RD record to enhanced Recurring Donation format
     * by updating the new and existing fields on the record as required.
     * @return npe03__Recurring_Donation__c Recurring Donation in enhanced format
     */
    public npe03__Recurring_Donation__c convertToEnhancedRD() {
        if (isConverted()) {
            return rd;
        }

        setInstallmentFields(rd);
        setStartDate(rd);
        setDayOfMonth(rd);
        setStatus(rd);
        setOtherFields(rd);

        if (isDryRunMode) {
            setFixedToOpenDuringDryRun(rd);
        }

        return rd;
    }

    /**
     * @description Returns true if the RD record is already in enhanced Recurring Donation format
     */
    public Boolean isConverted() {
        return String.isNotBlank(rd.Status__c) && rd.InstallmentFrequency__c != null;
    }

    /**
     * @description Sets Installment Frequency and Installment Period fields where applicable
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void setInstallmentFields(npe03__Recurring_Donation__c rd) {

        Set<String> frequencyOneInstallmentPeriods = new Set<String>{
            RD_Constants.INSTALLMENT_PERIOD_YEARLY,
            RD_Constants.INSTALLMENT_PERIOD_MONTHLY,
            RD_Constants.INSTALLMENT_PERIOD_WEEKLY,
            RD_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH
        };

        if (rd.npe03__Installment_Period__c == RD_Constants.INSTALLMENT_PERIOD_QUARTERLY) {
            rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY;
            rd.InstallmentFrequency__c = 3;

        } else if (frequencyOneInstallmentPeriods.contains(rd.npe03__Installment_Period__c)) {
            if (rd.InstallmentFrequency__c == null) {
                rd.InstallmentFrequency__c = 1;
            }

        } else {
            handleCustomInstallmentPeriod(rd);
        }

        validateAmountCanBeCalculated(rd);

        if ((rd.npe03__Schedule_Type__c == RD_Constants.SCHEDULE_TYPE_DIVIDE_BY || rd.npe03__Schedule_Type__c == null)
            && rd.npe03__Installment_Amount__c != null
            && rd.npe03__Installment_Amount__c != 0
        ) {
            rd.npe03__Amount__c = rd.npe03__Installment_Amount__c;
        }
    }

    /**
     * @description Determines whether Amount can be calculated.  Throws an exception if not.
     * @param rd Recurring Donation
     */
    private void validateAmountCanBeCalculated(npe03__Recurring_Donation__c rd) {

        if (rd.npe03__Open_Ended_Status__c == RD_Constants.OPEN_ENDED_STATUS_CLOSED
            && String.isBlank(rd.npe03__Schedule_Type__c)
            && rd.npe03__Installments__c != null
            && Math.abs(rd.npe03__Installments__c) > 1)
        {
            throw new MigrationException(System.Label.RD2_DataMigrationInvalidPlannedInstallments);
        }
    }

    /**
     * @description Sets Installment Frequency and Installment Period for custom Installment Period
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void handleCustomInstallmentPeriod(npe03__Recurring_Donation__c rd) {
        npe03__Custom_Installment_Settings__c settings = UTIL_ListCustomSettingsFacade.getMapCustomInstallmentSettings()
            .get(rd.npe03__Installment_Period__c);

        if (settings == null) {
            throwInvalidInstallmentPeriodException(rd.npe03__Installment_Period__c);
        }

        String settingsIncrement = settings.npe03__Increment__c;
        switch on settingsIncrement {
            when 'Days' {
                rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_DAILY;
            }
            when 'Weeks' {
                rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_WEEKLY;
            }
            when 'Months' {
                rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY;
            }
            when 'Years' {
                rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_YEARLY;
            }
            when else {
                throwInvalidInstallmentPeriodException(rd.npe03__Installment_Period__c);
            }
        }

        rd.InstallmentFrequency__c = Integer.valueOf(settings.npe03__Value__c);
    }

    /**
     * @description Throws invalid installment period exception
     * @param installmentPeriod Recurring Donation installment period
     * @return void
     */
    private void throwInvalidInstallmentPeriodException(String installmentPeriod) {
        throw new MigrationException(
            String.format(
                System.Label.RD2_DataMigrationInvalidInstallmentPeriod,
                new String[]{ installmentPeriod }
            )
        );
    }

    /**
     * @description Sets Recurring Donation Start Date field as Date Established.
     * If Date Established is null, earliest related Opportunity Close Date is used.
     * If both of those options result in null Start Date, Created Date is used.
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void setStartDate(npe03__Recurring_Donation__c rd) {

        if (rd.npe03__Date_Established__c != null) {
            rd.StartDate__c = rd.npe03__Date_Established__c;
            return;
        }

        if (allRelatedOpps != null && !allRelatedOpps.isEmpty()) {
            Date startDate;
            for (Opportunity opp : allRelatedOpps) {
                if (startDate == null || startDate > opp.CloseDate) {
                    startDate = opp.CloseDate;
                }
            }
            rd.StartDate__c = startDate;
        }

        if (rd.StartDate__c == null) {
            rd.StartDate__c = rd.CreatedDate.dateGmt();
        }
    }

    /**
     * @description Sets Day of Month field
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void setDayOfMonth(npe03__Recurring_Donation__c rd) {
        final String lastDayOfMonth = '31';

        if (rd.Always_Use_Last_Day_Of_Month__c == false
            && String.isEmpty(rd.Day_of_Month__c)
        ) {
            rd.Day_of_Month__c = calculateDayOfMonth(rd);
        }

        if (rd.Always_Use_Last_Day_Of_Month__c == true
            || rd.Day_of_Month__c == lastDayOfMonth
        ) {
            rd.Day_of_Month__c = isDryRunMode
                ? DRY_RUN_DAY_OF_MONTH_LAST_DAY
                : RD2_Constants.DAY_OF_MONTH_LAST_DAY;
        }
    }

    /**
    * @description If the Day_Of_Month__c field is blank on the Recurring Donation record, use the
    * NextPaymentDate (if there is one) or the DateEstablished to determine the DayOfMonth to
    * start the logic with.
    * @param rd RecurringDonation
    * @return String representation of the DayOfMonth (1-31)
    */
    private String calculateDayOfMonth(npe03__Recurring_Donation__c rd) {

        Date installmentDate;
        if (rd.npe03__Next_Payment_Date__c != null) {
            installmentDate = rd.npe03__Next_Payment_Date__c;
        } else if (rd.npe03__Date_Established__c != null) {
            installmentDate = rd.npe03__Date_Established__c;
        }

        return installmentDate == null ? null : installmentDate.day().format();
    }


    /**
     * @description Sets Status field
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void setStatus(npe03__Recurring_Donation__c rd) {
        String openEndedStatus = rd.npe03__Open_Ended_Status__c;

        if (String.isNotBlank(openEndedStatus)
            && openEndedStatus != RD_Constants.OPEN_ENDED_STATUS_OPEN
            && openEndedStatus != RD_Constants.OPEN_ENDED_STATUS_CLOSED
            && openEndedStatus != RD_Constants.OPEN_ENDED_STATUS_NONE
        ) {
            throw new MigrationException(
                String.format(
                    System.Label.RD2_DataMigrationInvalidOpenEndedStatus,
                    new String[]{ openEndedStatus }
                )
            );
        }

        if (openEndedStatus == RD_Constants.OPEN_ENDED_STATUS_CLOSED) {
            rd.Status__c = RD2_Constants.STATUS_CLOSED;

        } else {
            rd.Status__c = RD2_Constants.STATUS_ACTIVE;
        }
    }

    /**
     * @description Sets other fields on the legacy Recurring Donation to complete conversion to the enhanced format
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void setOtherFields(npe03__Recurring_Donation__c rd) {
        if (rd.npe03__Open_Ended_Status__c == RD_Constants.OPEN_ENDED_STATUS_NONE
                || rd.npe03__Open_Ended_Status__c == null) {
            rd.RecurringType__c = RD2_Constants.RECURRING_TYPE_FIXED;
        } else {
            rd.RecurringType__c = RD2_Constants.RECURRING_TYPE_OPEN;
        }

        if (rd.RecurringType__c == RD2_Constants.RECURRING_TYPE_OPEN) {
            rd.npe03__Installments__c = null;
        }
    }

    /**
     * @description Sets RecurringType__c to 'Open' if 'Fixed' picklist option not available during dry run.
     * @param rd Recurring Donation in the legacy format
     * @return void
     */
    private void setFixedToOpenDuringDryRun(npe03__Recurring_Donation__c rd) {
        if (!new RD2_RecurringDonation(rd).isFixedLength()) {
            return;
        }

        if (!RD2_EnablementService.fixedOptionAvailable) {
            rd.RecurringType__c = RD2_Constants.RECURRING_TYPE_OPEN;
        }
    }

    /**
     * @description Extracts open installment Opportunities with Close Date >= today and
     * return all but the Opportunity with the earliest Close Date.
     * These Opportunities will become void (either closed lost or deleted).
     * @return List<Opportunity> Open Opportunities
     */
    private List<Opportunity> getOpenOpportunitiesToVoid() {
        List<Opportunity> opps = new List<Opportunity>();

        if (allRelatedOpps == null || allRelatedOpps.isEmpty()
            || rd.npe03__Open_Ended_Status__c != RD_Constants.OPEN_ENDED_STATUS_OPEN
        ) {
            return opps;
        }

        final Date today = System.today();
        for (Opportunity opp : allRelatedOpps) {
            if (opp.IsClosed == false && opp.CloseDate >= today) {
                opps.add(opp);
            }
        }

        if (!opps.isEmpty()) {
            // Exclude the earliest Close Date Open Opp.
            // Opps are ordered by the Close Date.
            opps.remove(0);
        }

        return opps;
    }

    /**
     * @description Exception thrown when Recurring Donation cannot be converted to the enhanced format
     */
    public class MigrationException extends Exception { }
}