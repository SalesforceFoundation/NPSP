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
* @group CMT Filter Rules
* @description Service class to handle evaluating CMT Filter Rules (i.e., all Rules within a specified Filter Group)
*/
public class CMT_FilterRuleEvaluation_SVC {

    /**
     * @description Create an instance of the FiscalYear service class with UseFiscalYear set to true
     * to use when handling Fiscal_Year constant operations
     */
    private static CRLP_FiscalYears fiscalYear = new CRLP_FiscalYears(true);

    /**
     * @description Static map of instantiated Filter_Rule__mdt by FilterGroupId
     */
    private static Map<Id, List<CMT_FilterRule>> mapOfFilterRulesByGroupId = new Map<Id, List<CMT_FilterRule>>();

    /**
     * @description Static cache of filter group eval results by a concatenation of detail row Ids
     */
    @TestVisible
    private static Map<String, Boolean> cachedFilterEvalResults = new Map<String, Boolean>();

    /* @description When working with the filterRule Cache, if the recordId is null make up a value to use to make each record unique */
    private static Integer nullIdRowCounter = 1;

    /**
     * @description Allow the cache of filter group eval results to be cleared externally, such as when the
     * detail record changes.
     */
    public static void clearEvaluationCache() {
        cachedFilterEvalResults.clear();
    }

    /**
     * @description For a given SObject detail record and possibly a related related record, evaluate the
     * record(s) against the FilterRules in the specified FilterGroupId.
     * @param detailRows A collection of SObject records to be processed.
     * @param filterGroupId The Id of specific FilterGroup to retrieve the Filter_Rules for to evaluate against
     * @return True if the record passed the rule or False if it failed the rule.
     */
    public static Boolean evaluateFilterGroup(List<SObject> detailRows, Id filterGroupId) {

        // If there is no filter group to evaluate against, return true to support an 'all rows' type scenario
        if (filterGroupId == null) {
            return true;
        }

        // Build a unique key of a concatenation of the Id's of all the detail rows.
        String cacheKey = filterGroupId + '.';
        for (SObject record : detailRows) {
            String recordId = (record.Id == null ? (nullIdRowCounter++).format() : record.Id);
            cacheKey += recordId;
        }
        // If this set of detail rows has already been evaluated for this filter group, return the cached result
        if (cachedFilterEvalResults.containsKey(cacheKey)) {
            return cachedFilterEvalResults.get(cacheKey);
        }

        // If the Rules within the Filter Group have not already been instantiated, retrieve them
        // and save the list of instantiated rules into the static map
        if (!mapOfFilterRulesByGroupId.containsKey(filterGroupId)) {
            List<CMT_FilterRule> rules = new List<CMT_FilterRule>();
            for (Filter_Rule__mdt rule : CMT_FilterRule_SEL.getFilterRulesByGroup().get(filterGroupId)) {
                rules.add(new CMT_FilterRule(rule));
            }
            mapOfFilterRulesByGroupId.put(filterGroupId, rules);
        }

        List<CMT_FilterRule> rulesToEvaluate = mapOfFilterRulesByGroupId.get(filterGroupId);

        for (SObject record : detailRows) {
            String recordId = (record.Id == null ? (nullIdRowCounter++).format() : record.Id);
            SObjectType objType = record.getSObjectType();
            for (CMT_FilterRule rule : rulesToEvaluate) {
                if (objType == rule.getObjectType()) {
                    // Not only caching the entire FilterGroup result, we're also caching the
                    // individual filter rule result to help with performance.
                    String ruleCacheKey = recordId + '.' + rule.getCacheKeyPrefix();
                    Boolean isIncluded;
                    if (cachedFilterEvalResults.containsKey(ruleCacheKey)) {
                        isIncluded = cachedFilterEvalResults.get(ruleCacheKey);
                    } else {
                        isIncluded = rule.isIncluded(record);
                        cachedFilterEvalResults.put(ruleCacheKey, isIncluded);
                    }
                    if (!isIncluded) {
                        // No reason to continue if any one rule for any one record fails the evaluation
                        cachedFilterEvalResults.put(cacheKey, false);
                        return false;
                    }
                }
            }
        }

        // if make it all the way through the rules for all records without any exclusions, then it passes
        cachedFilterEvalResults.put(cacheKey, true);
        return true;
    }

    /**
     * @description Handle date and datetime comparisons when the comparison value is one of the defined constants
     * @param fieldType The SoapType of the field to compare against
     * @param fieldValue The value of the field to be compared
     * @param compareValue The constant string to use for the comparison
     * @return True if the comparison is successful
     */
    public static Boolean compareDateTypeWithConstant(SoapType fieldType, Object fieldValue, String compareValue,
            CMT_FilterRule.FilterOperation operation) {

        Date today = System.Today();
        Boolean dateValueMatches = false;

        // Simple comparison for a null field and/or a null comparison value
        if (fieldValue == null) {
            // If the field is null and we're comparing to any of the constant values (THIS_YEAR, etc.)
            // then the result will always be false
            return false;
        }

        // Create comparison date and/or year values based on the current date and the date constant
        Integer compareYearValue;
        Date compareStartDate, compareEndDate;

        if (compareValue == CMT_FilterRule.DateFilterConstant.THIS_YEAR.name()) {
            compareYearValue = today.year();
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.LAST_YEAR.name()) {
            compareYearValue =  today.year() - 1;
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.TWO_YEARS_AGO.name()) {
            compareYearValue = today.year() - 2;

        } else if (compareValue == CMT_FilterRule.DateFilterConstant.THIS_FISCAL_YEAR.name()) {
            compareYearValue = fiscalYear.getYear(today);
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.LAST_FISCAL_YEAR.name()) {
            compareYearValue = fiscalYear.getYear(today) - 1;
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.TWO_FISCAL_YEARS_AGO.name()) {
            compareYearValue = fiscalYear.getYear(today) - 2;

        } else if (compareValue == CMT_FilterRule.DateFilterConstant.TODAY.name()) {
            compareStartDate = today;
            compareEndDate = today;
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.YESTERDAY.name()) {
            compareStartDate = today.addDays(-1);
            compareEndDate = today.addDays(-1);

        } else if (compareValue == CMT_FilterRule.DateFilterConstant.THIS_MONTH.name()) {
            compareStartDate = today.toStartOfMonth();
            compareEndDate = compareStartDate.addMonths(1).addDays(-1);
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.LAST_MONTH.name()) {
            compareStartDate = today.toStartOfMonth().addMonths(-1);
            compareEndDate = compareStartDate.addMonths(1).addDays(-1);
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.TWO_MONTHS_AGO.name()) {
            compareStartDate = today.toStartOfMonth().addMonths(-2);
            compareEndDate = compareStartDate.addMonths(1).addDays(-1);

        } else if (compareValue == CMT_FilterRule.DateFilterConstant.THIS_WEEK.name()) {
            compareStartDate = today.toStartOfWeek();
            compareEndDate = compareStartDate.addDays(7);
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.LAST_WEEK.name()) {
            compareStartDate = today.toStartOfWeek().addDays(-7);
            compareEndDate = compareStartDate.addDays(7);
        } else if (compareValue == CMT_FilterRule.DateFilterConstant.TWO_WEEKS_AGO.name()) {
            compareStartDate = today.toStartOfWeek().addDays(-14);
            compareEndDate = compareStartDate.addDays(7);

        }

        // Get the appropriate date or year (integer) values from the field value based on the data type
        Date fieldDateValue;
        Integer fieldYearValue;

        if (fieldType == SoapType.DATETIME) {
            fieldDateValue = DateTime.valueOf(fieldValue).date();

        } else if (fieldType == SoapType.DATE) {
            fieldDateValue = Date.valueOf(fieldValue);
        }
        fieldYearValue = fieldDateValue.year();

        // Compare the field to the year or start/end dates as appropriate
        if (compareValue.contains('YEAR')) {
            if (operation == CMT_FilterRule.FilterOperation.EQUALS) {
                return fieldYearValue == compareYearValue;
            } else if (operation == CMT_FilterRule.FilterOperation.NOT_EQUALS) {
                return fieldYearValue != compareYearValue;
            } else if (operation == CMT_FilterRule.FilterOperation.GREATER) {
                return fieldYearValue > compareYearValue;
            } else if (operation == CMT_FilterRule.FilterOperation.LESS) {
                return fieldYearValue < compareYearValue;
            } else if (operation == CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL) {
                return fieldYearValue >= compareYearValue;
            } else if (operation == CMT_FilterRule.FilterOperation.LESS_OR_EQUAL) {
                return fieldYearValue <= compareYearValue;
            }
        } else {
            if (operation == CMT_FilterRule.FilterOperation.EQUALS) {
                return (fieldDateValue >= compareStartDate && fieldDateValue <= compareEndDate);
            } else if (operation == CMT_FilterRule.FilterOperation.NOT_EQUALS) {
                return !(fieldDateValue >= compareStartDate && fieldDateValue <= compareEndDate);
            } else if (operation == CMT_FilterRule.FilterOperation.GREATER) {
                return fieldDateValue > compareEndDate;
            } else if (operation == CMT_FilterRule.FilterOperation.LESS) {
                return fieldDateValue < compareStartDate;
            } else if (operation == CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL) {
                return fieldDateValue >= compareEndDate;
            } else if (operation == CMT_FilterRule.FilterOperation.LESS_OR_EQUAL) {
                return fieldDateValue <= compareStartDate;
            }
        }
        return false;
    }
}