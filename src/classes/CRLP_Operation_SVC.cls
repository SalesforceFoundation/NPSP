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
* @description Rollup Operation Services:
* Called by the RollupHandler service class instance for each Source record and each active rollup that
* passes the filter. For example, there may be 10 instances of the CRLP_Rollup class created for 10 rollups
* from Opportunity to Account. Each instances doOperation() method will get called once to do the rollup from
* the Detail/Attribution records to the Source record - though the values are actually stored in the CRLP_Rollup
* instance until ready to be written to the Sobject.
*
*/
public class CRLP_Operation_SVC {

    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    private static final String oppObjectName = UTIL_Describe.getObjectDescribe('Opportunity').getName();

    /* @description Is the Org enabled for Multi-Currency */
    private static final Boolean isMultiCurrencyOrg = UTIL_Currency.getInstance().isMultiCurrencyOrganization();

    /**
     * @description Perform the rollup operation based on the details in the CRLP_Rollup_SVC.Rollup instance
     * against the passed  SObjects
     * @param rollup Instance of CRLP_Rollup_SVC.Rollup with the Rollup Definition details and counter/sum vars.
     * This var is passed by reference and modified directly. There is no method return.
     * @param opp Opportunity SObject. All Roll-ups operate against Opportunity even if the Detail object is
     * Payment, Allocation, OCR or PSC.
     * @param detailSObject Secondary detail Sobject (Payment, Allocation, etc.); or Opportunity if the detail
     * object is Opportunity.
     */
    public static void doRollupOperation(CRLP_Rollup rollup, Opportunity oppSObject, SObject detailSObject) {

        // these values should be the same for every rollup definition in the CRLP_Rollup instance

        List<Object> dateValues = getDateValue(rollup, oppSObject, detailSObject);
        Date dateValue = (dateValues[0] != null ? (Date) dateValues[0] : null);
        Datetime dateTimeValue = (dateValues[1] != null ? (Datetime) dateValues[1] : null);
        String theYear;
        Integer yearNum;

        CRLP_FiscalYears fiscalYrs = new CRLP_FiscalYears(rollup.useFiscalYear);

        if (dateValue != null) {
            yearNum = fiscalYrs.getYear(dateValue);
            theYear = fiscalYrs.getYearFormattedString(dateValue);

        } else if (dateTimeValue != null) {
            yearNum = fiscalYrs.getYear(dateTimeValue.date());
            theYear = fiscalYrs.getYearFormattedString(dateTimeValue.date());
        }

        // For Timebound Operations ... When working with DAYS_AGO, all of the Sum/Largest/Smallest
        // operations have to be limited to the specified date range based on the value in daysAgo
        // Due to the large variation of possible combinations, Rollups for DAYS_AGO TimeBoundOperation
        // types cannot be combined with other rollups of different types/days.
        if (rollup.isDaysAgoOperation) {
            if (dateValue == null || dateValue.daysBetween(Date.today()) > rollup.daysBack) {
                return;
            }
        }

        // In the case of a years-ago-single-result group, only proceed if the detail
        // record is in the right year
        if (rollup.isYearsAgoSingleResult) {
            Integer thisYear = (rollup.useFiscalYear ? fiscalYrs.getYear(Date.today()) : Date.today().year()) - rollup.yearsAgo;
            if (yearNum != thisYear) {
                return;
            }
        }

        // Get the Amount value from the appropriate object
        Decimal amountValue = getAmountValue(rollup, oppSObject, detailSObject, dateValue);

        // Increment the overall count of Opportunities (all time)
        rollup.theCount++;

        // If there is a Detail field retrieve its value and convert as required
        // There is only one Rollup__mdt record when a Detail Object/Field is involved.
        // Single Results of this nature are limited to an Operation type of First, Last, Largest or Smallest only
        if (rollup.hasSingleResultOperations) {
            processSingleResultRollups(rollup, oppSObject, detailSObject, amountValue, dateValue, dateTimeValue);
        }

        handleRollupAggregation(rollup, amountValue, dateValue, dateTimeValue, theYear);
    }

    /**
     * @description Retrieve the Date and Datetime values from the detail record
     * @param rollup
     * @param oppSObject
     * @param detailSObject
     * @return List<Object>{ Date, Datetime }
     */
    private static List<Object> getDateValue(CRLP_Rollup rollup, Opportunity oppSObject, SObject detailSObject) {
        Date dateValue = null;
        Datetime dateTimeValue = null;
        String dateField = rollup.dateFieldName;

        // Get the Date value from the appropriate object. There should always be a date!
        // It's a LOT faster the use the actual field name to retrieve the date than to use .get(fieldName).
        // Since the Date is almost always the CloseDate field, hardcoding this performance tweak.
        if (rollup.dateObject == oppObjectName && dateField == 'CloseDate') {
            dateValue = oppSObject.CloseDate;
        }

        SObject dateSObject = rollup.dateObject == 'Opportunity' ? oppSObject : detailSObject;
        if (dateValue == null && dateField != null && dateSObject.get(dateField) != null) {

            if (rollup.dateFieldType == SoapType.DATE) {
                dateValue = (Date) dateSObject.get(dateField);

            } else if (rollup.dateFieldType == SoapType.DATETIME) {
                dateTimeValue = (DateTime) dateSObject.get(dateField);
                dateValue = dateTimeValue.date();
            }
        }

        return new List<Object>{ dateValue, dateTimeValue };
    }

    /**
     * @description Retrieve the Amount value in the appropriate currency
     * @param rollup
     * @param oppSObject
     * @param amtSObject
     * @param dateValue
     * @return Amount (converted to the currency of the summary record)
     */
    private static Decimal getAmountValue(CRLP_Rollup rollup, Opportunity oppSObject, SObject amtSObject, Date dateValue) {
        Decimal amount = null;
        String amtField = rollup.amountFieldName;

        // Hardcoding this performance tweak similar to the Opportunity.CloseDate field above
        if (rollup.AmountObject == oppObjectName && amtField == 'Amount') {
            amount = oppSObject.Amount;
        }

        if (amount == null && amtField != null) {
            try {
                amount = (Decimal) amtSObject.get(amtField);
            } catch (Exception e) {
                amount = null;
            }
        }

        return convertAmountToCurrency(amount, rollup, amtSObject, dateValue);
    }

    /**
     * @description Convert amount to correct currency if the org is MultiCurrencyOrganization
     * @param amount
     * @param rollup
     * @param amtSObject
     * @param dateValue
     */
    private static Decimal convertAmountToCurrency(Decimal amount, CRLP_Rollup rollup, SObject amtSObject, Date dateValue) {

        // If the amount is not null or zero, then convert to the Account currency as required
        if (amount == null || amount == 0
            || !isMultiCurrencyOrg
            || rollup.amountFieldType != Schema.DisplayType.Currency
        ) {
            return amount;
        }

        // If multi currency is enabled in the organization, get the "From" CurrencyCode to use for conversion
        // default just in case there's an issue getting the detail record currency
        String fromCurrency = UserInfo.getDefaultCurrency();

        try {
            Object currencyIsoCode = amtSObject.get('CurrencyIsoCode');
            if (currencyIsoCode != null) {
                fromCurrency = (String) currencyIsoCode;
            }
        } catch (Exception ex) { }

        // Convert the Amount value to the summary objects currency.
        return UTIL_CurrencyConversion.convertAmount(amount, dateValue, fromCurrency, rollup.currCode);
    }

    /**
     * @description Loop through the Rollupmdt instances within the CRLP_Rollup instance to process
     * any single result operation rollups (First/Last/Largest/Smallest). The result of these is stored
     * within a Map<String,Object> on the CRLP_Rollup instance
     * @param rollup
     * @param oppSObject
     * @param detailSObject
     * @param amountValue
     * @param dateValue
     * @param dateTimeValue
     */
    private static void processSingleResultRollups(CRLP_Rollup rollup, SObject oppSObject, SObject detailSObject,
            Decimal amountValue, Date dateValue, Datetime dateTimeValue) {

        String amtField = rollup.amountFieldName; // firstRollup.amountField;
        String objName = UTIL_Describe.getObjectDescribe(detailSObject.getSObjectType()).getName();

        if (rollup.detailObject != objName && rollup.detailObject != oppObjectName) {
            return;
        }

        // For each RollupDefinition within this group where the Rollup is a SingleResultType
        // (First, Last, Largest, Smallest)
        for (Integer ns = 0, listSize = rollup.rollupsMdt.size(); ns < listSize; ns++) {
            CRLP_Rollup.Rollupmdt r = rollup.rollupsMdt[ns];

            // if this isn't a single result operation rollup, just skip the rollup
            if (!r.singleResultRollupType || r.resultFieldDisplayType == null) {
                continue;
            }

            Object resultVal;
            CRLP_Operation.RollupType operation = CRLP_Operation.getRollupTypeFromString(r.operation);

            // If the ResultField (DetailField) is the same as the Amount Field, then just get the value that
            // was retrieved/converted in the code block above. Otherwise retrieve and convert.
            if (r.detailField == amtField && r.detailObject == oppObjectName) {
                resultVal = amountValue;
            } else {
                // This retrieves the DetailField, which could be nearly any field type (String, Id, Date, etc.)
                resultVal = (r.detailObject == oppObjectName ?
                    oppSObject.get(r.detailField) : detailSObject.get(r.detailField));

                // If the result field is a currency type field and multi-currency is enabled in the org
                // then convert it to the target currency
                if (resultVal != null && r.resultFieldDisplayType == DisplayType.CURRENCY && isMultiCurrencyOrg) {
                    String fromCurrency = UserInfo.getDefaultCurrency(); // default just in case there's an issue getting the detail record currency
                    try {
                        Object currencyIsoCode = (r.detailObject == oppObjectName ?
                            oppSObject.get('CurrencyIsoCode') : detailSObject.get('CurrencyIsoCode'));
                        if (currencyIsoCode != null) {
                            fromCurrency = (String) currencyIsoCode;
                        }
                    } catch (Exception ex) { }
                    resultVal = UTIL_CurrencyConversion.convertAmount((Decimal) resultVal, dateValue, fromCurrency, rollup.currCode);
                }
            }

            if (dateTimeValue != null && operation == CRLP_Operation.RollupType.First
                && (dateTimeValue < rollup.minDateTime || rollup.minDateTime == null)
            ) {
                // Operation = FIRST (always based on a date)
                // Only want to use < as the operator for the date comparison so it only retrieves the first
                // record that meets the minimum date.
                r.setResultValue(resultVal);

            } else if (dateTimeValue != null && operation == CRLP_Operation.RollupType.Last
                    && (dateTimeValue >= rollup.maxDateTime || rollup.maxDateTime == null)
            ) {
                // Operation = LAST (always based on a date)
                // Use >= because Opps are sorted by CreatedDate ASC, meaning that we want to keep getting the
                // result value from whatever record makes up the 'last' record' by date
                r.setResultValue(resultVal);

            }

            // only allow datevalue to drive first and last values if datetimevalue wasn't already used
            else if (dateTimeValue == null && dateValue != null && operation == CRLP_Operation.RollupType.First
                && (dateValue < rollup.minDate || rollup.minDate == null)
            ) {
                // Operation = FIRST (always based on a date)
                // Only want to use < as the operator for the date comparison so it only retrieves the first
                // record that meets the minimum date.
                r.setResultValue(resultVal);

            } else if (dateTimeValue == null && dateValue != null && operation == CRLP_Operation.RollupType.Last
                && (dateValue >= rollup.maxDate || rollup.maxDate == null)
            ) {
                // Operation = LAST (always based on a date)
                // Use >= because Opps are sorted by CreatedDate ASC, meaning that we want to keep getting the
                // result value from whatever record makes up the 'last' record' by date
                r.setResultValue(resultVal);

            } else if (amountValue != null && operation == CRLP_Operation.RollupType.Smallest
                && (amountValue < rollup.minValue || rollup.minValue == 0)
            ) {
                // Operation = SMALLEST (always based on an amount, but the result field might actually be a date)
                // This should get the first Opp with the smallest amount (in case there is more than one with the same amount)
                r.setResultValue(resultVal);

            } else if (amountValue != null && operation == CRLP_Operation.RollupType.Largest
                && (amountValue >= rollup.maxValue || rollup.maxValue == 0)
            ) {
                // Operation = LARGEST (always based on an amount, but the result field might actually be a date)
                // This should get the last Opp with the largest amount (in case there is more than one with the same amount)
                r.setResultValue(resultVal);

            }
        }
    }

    /**
     * @description Update the aggregate fields on the CRLP_Rollup instance as needed
     * @param rollup
     * @param amountValue
     * @param dateValue
     * @param dateTimeValue
     * @param theYear
     */
    private static void  handleRollupAggregation(CRLP_Rollup rollup, Decimal amountValue,
            Date dateValue, Datetime dateTimeValue, String theYear
    ) {

            // Set the Largest/Smallest Amount values
        if (amountValue != null) {
            rollup.theSum += amountValue;
            if (rollup.minValue > amountValue || rollup.minValue == 0) {
                rollup.minValue = amountValue;
            }
            if (rollup.maxValue < amountValue) {
                rollup.maxValue = amountValue;
            }
        }

        // Set the First/Last Date values; excluding Opportunities with a null Date or a null Amount
        if (dateValue != null) {

            if (rollup.minDate == null || rollup.minDate > dateValue) {
                rollup.minDate = dateValue;
            }
            if (rollup.maxDate == null || rollup.maxDate < dateValue) {
                rollup.maxDate = dateValue;
            }
            if (dateTimeValue != null) {
                if (rollup.minDateTime == null || rollup.minDateTime > dateTimeValue) {
                    rollup.minDateTime = dateTimeValue;
                }
                if (rollup.maxDateTime == null || rollup.maxDateTime < dateTimeValue) {
                    rollup.maxDateTime = dateTimeValue;
                }
            }
            if (rollup.sumByYear.containsKey(theYear)) {
                rollup.countByYear.put(theYear, rollup.countByYear.get(theYear) + 1);
                if (amountValue != null) {
                    rollup.sumByYear.put(theYear, rollup.sumByYear.get(theYear) + amountValue);
                    if (rollup.minByYear.get(theYear) > amountValue) {
                        rollup.minByYear.put(theYear, amountValue);
                    }
                    if (rollup.maxByYear.get(theYear) < amountValue) {
                        rollup.maxByYear.put(theYear, amountValue);
                    }
                }
            } else {
                if (rollup.countByYear.containsKey(theYear)) {
                    rollup.countByYear.put(theYear, rollup.countByYear.get(theYear) + 1);
                } else {
                    rollup.countByYear.put(theYear, 1);
                }
                if (amountValue != null) {
                    rollup.sumByYear.put(theYear, amountValue);
                    rollup.minByYear.put(theYear, amountValue);
                    rollup.maxByYear.put(theYear, amountValue);
                }
            }
        }
    }
}