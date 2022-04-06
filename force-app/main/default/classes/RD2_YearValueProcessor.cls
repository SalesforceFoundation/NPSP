/*
    Copyright (c) 2020 Salesforce.org
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
* @group Recurring Donations
* @description Recurring Donation Current and Next Year Value processor
*
*/
public inherited sharing class RD2_YearValueProcessor {

    /**
    * @description Recurring Donation Schedule Service
    */
    private RD2_ScheduleService scheduleService;

    /**
    * @description Date representing current date.
    * It can be back-dated or future-dated during testing, but it defaults to today
    * in the batch scheduler or if not provided in testing.
    * Date is populated from the Opp eval service.
    */
    private Date currentDate;

    /**
    * @description Contains year info and configuration.
    * Fiscal year will be used if the configuration indicates it should be used.
    */
    @TestVisible
    private UTIL_FiscalYearInfo fiscalYearInfo {
        get {
            if (fiscalYearInfo == null) {
                fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
                    .withUseFiscalYear(RD2_Settings.getInstance().useFiscalYear);
            }
            return fiscalYearInfo;
        }
        set;
    }

    /**
    * @description Contains the current fiscal/calendar year start and end dates
    */
    private UTIL_FiscalYearInfo.YearInfo currentYearInfo {
        get {
            if (currentYearInfo == null) {
                currentYearInfo = fiscalYearInfo.getYearInfo(currentDate);
            }
            return currentYearInfo;
        }
        set;
    }
    /**
    * @description Contains the next fiscal/calendar year start and end dates
    */
    private UTIL_FiscalYearInfo.YearInfo nextYearInfo {
        get {
            if (nextYearInfo == null) {
                nextYearInfo = fiscalYearInfo.getYearInfo(currentDate.addYears(1));
            }
            return nextYearInfo;
        }
        set;
    }

    /**
    * @description Constructor
    * @param currentDate Current Date
    * @param scheduleService RD Schedule Service
    */
    public RD2_YearValueProcessor(Date currentDate, RD2_ScheduleService scheduleService) {
        this.currentDate = currentDate;
        this.scheduleService = scheduleService;
    }

    /**
    * @description Returns the earliest date to filter open/closed Opportunities based on their Close Date.
    * If the current year is a calendar year, the current year start date is earlier than the current date.
    * If the current year is a fiscal year, the current year start date is also earlier than the current date.
    * So regardless if we calculate calendar or fiscal year values, we can use the current year start date
    * as the cut off date to get existing Opportunities in the Opp eval service.
    */
    public Date getStartDate() {
        return currentYearInfo.startDate;
    }

    /**
    * @description Calculates the Current Year Value
    * NOTE: the value is calculated based on the calendar year currently.
    *
    * @param opps Opportunities on a Recurring Donation
    * @param schedules Schedules on a Recurring Donation
    * @return Decimal
    */
    public Decimal calcCurrentYearValue(List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {
        return calcYearValue(opps, schedules, currentDate, currentYearInfo);
    }

    /**
    * @description Calculates the Next Year Value
    * NOTE: the value is calculated based on the calendar year currently.
    *
    * @param opps Opportunities on a Recurring Donation
    * @param schedules Schedules on a Recurring Donation
    * @return Decimal
    */
    public Decimal calcNextYearValue(List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {
        return calcYearValue(opps, schedules, nextYearInfo.startDate, nextYearInfo);
    }

    /**
    * @description Calculates calendar/fiscal Current or Next Year Value.
    * @param opps Opportunities on a Recurring Donation
    * @param schedules Schedules on a Recurring Donation
    * @param asOfCurrentDate This is the current date for the current year calculations
    * or the next year start date for the next year value calculations.
    * It is used as a start cutoff date for existing Opps in order to 
    * determine their matching projected installments.
    * Installments are built for the current/future donation dates.
    * @param yearInfo The current or next year info object containing the year start and end dates
    * @return Decimal
    */
    public Decimal calcYearValue(
        List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules, 
        Date asOfCurrentDate, UTIL_FiscalYearInfo.YearInfo yearInfo
    ) {
        RD2_OpportunityMatcher matcher = new RD2_OpportunityMatcher(asOfCurrentDate)
            .includeByYear(
                opps, yearInfo.startDate, yearInfo.endDate
            )
            .match(scheduleService.getVisualizedInstallments(
                asOfCurrentDate, yearInfo.endDate, schedules
            ));

        Decimal value = 0;
        for (RD2_OpportunityMatcher.Record record : matcher.getRecords()) {
            Date closeDate = record.getCloseDate();

            //There is additional filtering required since the matcher might return
            //a past Opp in the last year matching with a future installment in this year.
            //In such case, the Opp should be excluded from the next year calculations
            //since it is already included in the current year value.
            //Include open/closed won/projected matched records within the exact start/end dates.
            if (!record.isClosedLost()
                && closeDate >= yearInfo.startDate 
                && closeDate <= yearInfo.endDate
            ) {
                value += record.getAmount();
            }
        }

        return value;
    }
}
