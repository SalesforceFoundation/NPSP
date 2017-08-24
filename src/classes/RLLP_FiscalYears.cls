//TODO get tests for these methods from RLLP_OppRollup_TEST
public with sharing class RLLP_FiscalYears {
    /*********************************************************************************************************
    * @description Queries for the Organization's fiscal year information.
    */
    private static Organization fiscalYearInfo {
        get {
            if (fiscalYearInfo == null) {
                fiscalYearInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName FROM Organization 
                                  WHERE Id = :UserInfo.getOrganizationId()];
            }
            return fiscalYearInfo;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description Returns the current year, fiscal or calendar depending on the rollup custom setting.
    * @param targetDate The date for which to look up the year.
    * @return Integer The calendar or fiscal year for the given Date.
    */
    public static Integer getYear(Date targetDate){
        if (UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Use_Fiscal_Year_for_Rollups__c) {
            return getFiscalYear(targetDate);
        } else {
            return targetDate.year();
        }
    }

    /*********************************************************************************************************
    * @description Determines the fiscal year for the given date based on Organization fiscal year settings.
    * Only supports standard fiscal years.
    * @param targetDate The date for which to look up the fiscal year.
    * @return Integer The Fiscal Year for the given Date.
    */
    public static Integer getFiscalYear(Date targetDate) {
        Date fiscalYearStartDate = Date.newInstance(
            targetDate.year(),
            fiscalYearInfo.fiscalYearStartMonth,
            1
        );

        Date fiscalYearEndDate = fiscalYearStartDate.addYears(1).addDays(-1);

        if (targetDate < fiscalYearStartDate) {
            fiscalYearStartDate = fiscalYearStartDate.addYears(-1);
            fiscalYearEndDate = fiscalYearEndDate.addYears(-1);
        }

        if (fiscalYearInfo.usesStartDateAsFiscalYearName) {
            return fiscalYearStartDate.year();
        } else {
            return fiscalYearEndDate.year();
        }
    }
}