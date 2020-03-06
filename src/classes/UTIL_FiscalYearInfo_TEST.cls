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
* @description Unit tests for the fiscal year info determination
*
*/
@IsTest(IsParallel=true)
private with sharing class UTIL_FiscalYearInfo_TEST {

    /**
     * @description Verifies calendar year is returned when the fiscal year should not be used
     */
    @IsTest
    private static void shouldReturnCalendarYearWhenFiscalYearIsNotConfigured() {
        UTIL_FiscalYearInfo fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(false);

        System.assertEquals(2014, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 3, 1)));
        System.assertEquals(2014, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 4, 1)));
        System.assertEquals(2015, fiscalYearInfo.getFiscalYear(Date.newInstance(2015, 3, 1)));
    }

    /**
     * @description Verifies fiscal year is returned when it should be used
     * and the fiscal year starts in the start month of the current calendar year
     */
    @IsTest
    private static void shouldReturnFiscalYearWhenConfiguredAndYearStartsInThisCalendarYear() {
        UTIL_FiscalYearInfo fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(true);

        //override the organization fiscal year settings for testing purposes
        fiscalYearInfo.startMonth = 4; 
        fiscalYearInfo.isStartDateYearFiscalYear = true; 
        
        //A fiscal year is April through March.
        //The fiscal year and the current calendar year align beginning the start month, ie
        //the fiscal year starts in the start month.
        System.assertEquals(2013, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 3, 31)));
        System.assertEquals(2014, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 4, 1)));
        System.assertEquals(2014, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 5, 1)));

        System.assertEquals(2014, fiscalYearInfo.getFiscalYear(Date.newInstance(2015, 3, 1)));
        System.assertEquals(2015, fiscalYearInfo.getFiscalYear(Date.newInstance(2015, 4, 1)));
    }

    /**
     * @description Verifies fiscal year is returned when it should be used
     * and the fiscal year ends before the start month of the current calendar year
     */
    @IsTest
    private static void shouldReturnFiscalYearWhenConfiguredAndYearEndsInThisCalendarYear() {
        UTIL_FiscalYearInfo fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(true);

        //override the organization fiscal year settings for testing purposes
        fiscalYearInfo.startMonth = 4; 
        fiscalYearInfo.isStartDateYearFiscalYear = false; 
        
        //A fiscal year is April through March.
        //The fiscal year and the current calendar year align before the start month, ie
        //the fiscal year ends before the start month and the next fiscal year starts in the start month.
        System.assertEquals(2014, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 3, 31)));
        System.assertEquals(2015, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 4, 1)));
        System.assertEquals(2015, fiscalYearInfo.getFiscalYear(Date.newInstance(2014, 5, 1)));

        System.assertEquals(2015, fiscalYearInfo.getFiscalYear(Date.newInstance(2015, 3, 1)));
        System.assertEquals(2016, fiscalYearInfo.getFiscalYear(Date.newInstance(2015, 4, 1)));
    }

    /**
     * @description Verifies calendar year start and end dates are returned when the fiscal year should not be used
     */
    @IsTest
    private static void shouldReturnCalendarYearInfoWhenFiscalYearIsNotConfigured() {
        UTIL_FiscalYearInfo.YearInfo yearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(false)
            .getYearInfo(Date.newInstance(2014, 3, 31));

        System.assertEquals(Date.newInstance(2014, 1, 1), yearInfo.startDate, 'Start Date should be the calendar year start');
        System.assertEquals(Date.newInstance(2014, 12, 31), yearInfo.endDate, 'End Date should be the calendar year end');
    }

    /**
     * @description Verifies calendar year start and end dates are returned when the fiscal year should not be used
     */
    @IsTest
    private static void shouldReturnCalendarYearInfoWhenFiscalYearIsConfiguredButNotSetForTheOrg() {
        UTIL_FiscalYearInfo fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(true);//A custom settings has Use Fiscal Year as checked

        //when the standard fiscal year is not configured for the Organization, 
        //these settings are applied in the Organization SObject
        fiscalYearInfo.startMonth = 1; 
        fiscalYearInfo.isStartDateYearFiscalYear = false; 

        UTIL_FiscalYearInfo.YearInfo yearInfo = fiscalYearInfo.getYearInfo(Date.newInstance(2014, 3, 31));
            
        System.assertEquals(Date.newInstance(2014, 1, 1), yearInfo.startDate, 'Start Date should be the calendar year start');
        System.assertEquals(Date.newInstance(2014, 12, 31), yearInfo.endDate, 'End Date should be the calendar year end');
    }

    /**
     * @description Verifies fiscal year start and end dates are returned when it should be used
     * and the fiscal year starts in the start month of the current calendar year
     */
    @IsTest
    private static void shouldReturnFiscalYearInfoWhenConfiguredAndYearStartsInThisCalendarYear() {
        UTIL_FiscalYearInfo fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(true);

        //override the organization fiscal year settings for testing purposes
        fiscalYearInfo.startMonth = 4; 
        fiscalYearInfo.isStartDateYearFiscalYear = true; 

        Date today = Date.newInstance(2014, 3, 31);
        Date yearStartDate = Date.newInstance(2013, 4, 1);
        Date yearEndDate = Date.newInstance(2014, 3, 31);
        Integer fiscalYear = 2013;
        UTIL_FiscalYearInfo.YearInfo yearInfo = fiscalYearInfo.getYearInfo(today);

        System.assertEquals(yearStartDate, yearInfo.startDate, 'The fiscal year started last calendar year');
        System.assertEquals(yearEndDate, yearInfo.endDate, 'The current fiscal year ends today');
        System.assertEquals(fiscalYear, fiscalYearInfo.getFiscalYear(today), 'The fiscal year is the last calendar year');

        today = Date.newInstance(2014, 4, 1);
        yearStartDate = Date.newInstance(2014, 4, 1);
        yearEndDate = Date.newInstance(2015, 3, 31);
        fiscalYear = 2014;
        yearInfo = fiscalYearInfo.getYearInfo(today);

        System.assertEquals(yearStartDate, yearInfo.startDate, 'The next fiscal year starts today');
        System.assertEquals(yearEndDate, yearInfo.endDate, 'The next fiscal year ends in the next calendar year');
        System.assertEquals(fiscalYear, fiscalYearInfo.getFiscalYear(today), 'The fiscal year is the current calendar year');

        today = Date.newInstance(2015, 3, 1);
        yearInfo = fiscalYearInfo.getYearInfo(today);

        System.assertEquals(yearStartDate, yearInfo.startDate, 'The fiscal year start date should match');
        System.assertEquals(yearEndDate, yearInfo.endDate, 'The fiscal year end date should match');
        System.assertEquals(fiscalYear, fiscalYearInfo.getFiscalYear(today), 'The fiscal year should match');
    }

    /**
     * @description Verifies fiscal year start and end dates are returned when it should be used
     * and the fiscal year ends before the start month of the current calendar year
     */
    @IsTest
    private static void shouldReturnFiscalYearInfoWhenConfiguredAndYearEndsInThisCalendarYear() {
        UTIL_FiscalYearInfo fiscalYearInfo = UTIL_FiscalYearInfo.getInstance()
            .withUseFiscalYear(true);

        //override the organization fiscal year settings for testing purposes
        fiscalYearInfo.startMonth = 4; 
        fiscalYearInfo.isStartDateYearFiscalYear = false; 

        Date today = Date.newInstance(2014, 3, 31);
        Date yearStartDate = Date.newInstance(2013, 4, 1);
        Date yearEndDate = Date.newInstance(2014, 3, 31);
        Integer fiscalYear = 2014;
        UTIL_FiscalYearInfo.YearInfo yearInfo = fiscalYearInfo.getYearInfo(today);

        System.assertEquals(yearStartDate, yearInfo.startDate, 'The fiscal year started last calendar year');
        System.assertEquals(yearEndDate, yearInfo.endDate, 'The current fiscal year ends today');
        System.assertEquals(fiscalYear, fiscalYearInfo.getFiscalYear(today), 'The fiscal year is the current calendar year');

        today = Date.newInstance(2014, 4, 1);
        yearStartDate = Date.newInstance(2014, 4, 1);
        yearEndDate = Date.newInstance(2015, 3, 31);
        fiscalYear = 2015;
        yearInfo = fiscalYearInfo.getYearInfo(today);

        System.assertEquals(yearStartDate, yearInfo.startDate, 'The next fiscal year starts today');
        System.assertEquals(yearEndDate, yearInfo.endDate, 'The next fiscal year ends in the next calendar year');
        System.assertEquals(fiscalYear, fiscalYearInfo.getFiscalYear(today), 'The fiscal year is the next calendar year');

        today = Date.newInstance(2015, 3, 1);
        yearInfo = fiscalYearInfo.getYearInfo(today);

        System.assertEquals(yearStartDate, yearInfo.startDate, 'The fiscal year start date should match');
        System.assertEquals(yearEndDate, yearInfo.endDate, 'The fiscal year end date should match');
        System.assertEquals(fiscalYear, fiscalYearInfo.getFiscalYear(today), 'The fiscal year should match');
    }

}
