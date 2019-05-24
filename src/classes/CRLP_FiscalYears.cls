/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Methods needed to handle Fiscal or Calendar Year operations
*
*/
public class CRLP_FiscalYears {

    /*********************************************************************************************************
     * @description Should getYear() use the defined Fiscal Year or the Calendar Year
     */
    private final Boolean useFiscalYear;

    /*********************************************************************************************************
     * @description Constructor. The value for this is passed based on either Rollup__mdt.Use_Fiscal_Year__c or
     * AllocationSettings.Use_Fiscal_Year_for_Rollups__c
     */
    public CRLP_FiscalYears(Boolean useFiscalYear) {
        this.useFiscalYear = useFiscalYear;
    }

    /*********************************************************************************************************
    * @description Returns the current year, fiscal or calendar depending on the rollup setting.
    * @param targetDate The date for which to look up the year.
    * @return Integer The calendar or fiscal year for the given Date.
    */
    public Integer getYear(Date targetDate) {
        if (this.useFiscalYear) {
            return getFiscalYear(targetDate);
        } else {
            return targetDate.year();
        }
    }

    /*********************************************************************************************************
    * @description Returns the current year, fiscal or calendar depending on the rollup setting as a formatted string.
    All punctuation will have been removed
    * @param targetDate The date for which to look up the year.
    * @return String The calendar or fiscal year for the given Date as a string.
    */
    public String getYearFormattedString(Date targetDate) {
        return UTIL_String.removeNonNumericCharacters(getYear(targetDate).format());
    }

    /*********************************************************************************************************
     * @description Wrapper class for the Organization Fiscal year information. This allows the values
     * to be overrriden by unit tests
     */
    public class OrgFiscalYearInfo {
        public Integer fiscalYearStartMonth { get; set; }
        public Boolean usesStartDateAsFiscalYearName { get; set; }

        public OrgFiscalYearInfo(Organization org) {
            this.fiscalYearStartMonth = org.FiscalYearStartMonth;
            this.usesStartDateAsFiscalYearName = org.UsesStartDateAsFiscalYearName;
        }
    }

    /*********************************************************************************************************
    * @description Queries for the Organization's fiscal year information.
    */
    @testVisible
    private static OrgFiscalYearInfo fiscalYearInfo {
        get {
            if (fiscalYearInfo == null) {
                fiscalYearInfo = new OrgFiscalYearInfo(
                    [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                        FROM Organization
                        WHERE Id = :UserInfo.getOrganizationId()]
                );
            }
            return fiscalYearInfo;
        }
        set;
    }

    /*********************************************************************************************************
    * @description Determines the fiscal year for the given date based on Organization fiscal year settings.
    * Only supports standard fiscal years.
    * @param targetDate The date for which to look up the fiscal year.
    * @return Integer The Fiscal Year for the given Date.
    */
    private static Integer getFiscalYear(Date targetDate) {
        Date fiscalYearStartDate = Date.newInstance(
            targetDate.year(), CRLP_FiscalYears.fiscalYearInfo.FiscalYearStartMonth, 1
        );

        Date fiscalYearEndDate = fiscalYearStartDate.addYears(1).addDays(-1);

        if (targetDate < fiscalYearStartDate) {
            fiscalYearStartDate = fiscalYearStartDate.addYears(-1);
            fiscalYearEndDate = fiscalYearEndDate.addYears(-1);
        }

        if (CRLP_FiscalYears.fiscalYearInfo.UsesStartDateAsFiscalYearName) {
            return fiscalYearStartDate.year();
        } else {
            return fiscalYearEndDate.year();
        }
    }
}