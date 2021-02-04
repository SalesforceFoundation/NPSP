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
* @group Utilities
* @description Utility for the *standard* fiscal year processing and determination
*
*/
public with sharing class UTIL_FiscalYearInfo {
    /** @description Fiscal year start or ending month (see below) */
    public Integer startMonth { get; set; }

    /** @description Defines the fiscal year value.
     * If true, then the fiscal year starts on the start month that same year.
     * If false, then fiscal year ends on the start month that year and the next one begins.
     */
    public Boolean isStartDateYearFiscalYear { get; set; }

    /** @description Defines if the Use Fiscal Year is set for a specific Custom Settings configuration */
    public Boolean useFiscalYear { get; private set; }

    /** @description Determines if the custom fiscal year is enabled for the org */
    @TestVisible
    public Boolean isCustomFiscalYearEnabled { 
        get {
            if (isCustomFiscalYearEnabled == null) {
                List<SObject> customFiscalYearSettings = Database.query(
                    'SELECT Id FROM FiscalYearSettings WHERE IsStandardYear = false'
                );

                isCustomFiscalYearEnabled = !customFiscalYearSettings.isEmpty();
            }
            return isCustomFiscalYearEnabled;
        } 
        private set; 
    }

    /** @description static instance of the current class. It is used as the instance in a Singleton context */
    @TestVisible
    private static UTIL_FiscalYearInfo fiscalYearInfo;


    /***
    * @description Get the instance of the current class
    * @return UTIL_FiscalYearInfo The instance of the current class.
    */
    public static UTIL_FiscalYearInfo getInstance() {
        if (fiscalYearInfo == null) {
            fiscalYearInfo = new UTIL_FiscalYearInfo([
                SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                FROM Organization
                WHERE Id = :UserInfo.getOrganizationId()
            ]);
        }
        return fiscalYearInfo;
    }

    /***
    * @description Constructor
    * @param org Organization details containing the fiscal year settings
    */
    public UTIL_FiscalYearInfo(Organization org) {
        this(org.FiscalYearStartMonth, org.UsesStartDateAsFiscalYearName);
    }

    /***
    * @description Constructor
    * @param startMonth Fiscal year start month
    * @param isStartDateYearFiscalYear Indicates if the fiscal year value is the same as the start date *year*.
    */
    @TestVisible
    private UTIL_FiscalYearInfo(Integer startMonth, Boolean isStartDateYearFiscalYear) {
        this.startMonth = startMonth;
        this.isStartDateYearFiscalYear = isStartDateYearFiscalYear;
        this.useFiscalYear = false;
    }

    /***
    * @description Passes in the configuration for the fiscal year usage
    * @param useFiscalYear Configured Use Fiscal Year value in a custom settings
    * The usage is supported for standard fiscal year only, ie the custom fiscal year is not supported
    * @return UTIL_FiscalYearInfo This class instance
    */
    public UTIL_FiscalYearInfo withUseFiscalYear(Boolean useFiscalYear) {
        this.useFiscalYear = useFiscalYear == true;

        //Do not use fiscal year when custom fiscal year is enabled.
        //Standard fiscal year is supported only
        if (this.useFiscalYear) {
            this.useFiscalYear = !isCustomFiscalYearEnabled;
        }
        return this;
    }

    /***
    * @description Determines the fiscal or calendar year start and end dates in the reference to the given date
    * @param targetDate The date for which to look up the year details.
    * @return YearInfo
    */
    public YearInfo getYearInfo(Date targetDate) {   
        Date startDate = getStartDate(targetDate);
        Date endDate = startDate.addYears(1).addDays(-1);

        return new YearInfo(startDate, endDate);
    }

    /***
    * @description Determines the fiscal or calendar year for the given date
    * @param targetDate The date for which to look up the year details.
    * @return Integer The fiscal or calendar year the target date belongs
    */
    public Integer getFiscalYear(Date targetDate) {   
        if (!useFiscalYear) {
            return targetDate.year();  
        }

        YearInfo yearInfo = getYearInfo(targetDate);

        if (targetDate < yearInfo.startDate && isStartDateYearFiscalYear) {
            return yearInfo.startDate.year() - 1;

        } else if (targetDate >= yearInfo.startDate && !isStartDateYearFiscalYear) {//the next fiscal year has been started
            return yearInfo.startDate.year() + 1;
        }

        return yearInfo.startDate.year();
    }

    /***
    * @description Determines the fiscal or calendar start date in the reference to the given date
    * @param targetDate The date for which to look up the year details.
    * @return Date The fiscal or calendar year start date
    */
    private Date getStartDate(Date targetDate) { 
        if (!useFiscalYear) {
            return Date.newInstance(targetDate.year(), 1, 1);
        }  
          
        Date startDate = Date.newInstance(targetDate.year(), startMonth, 1);

        if (targetDate < startDate) {
            startDate = startDate.addYears(-1);
        }

        return startDate;
    }

    /***
    * @description Contains fiscal/calendar year start and end dates
    */
    public class YearInfo {
        public Date startDate { get; private set; }
        public Date endDate { get; private set; }

        /***
        * @description Constructor for the fiscal/calendar year details
        * @param startDate The year start date
        * @param endDate The year end date
        */
        public YearInfo(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}
