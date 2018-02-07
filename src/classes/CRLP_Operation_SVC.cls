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

    /**
     * @description Perform the rollup operation based on the details in the CRLP_Rollup_SVC.Rollup instance
     * against the passed  SObjects
     * @param rollup Instance of CRLP_Rollup_SVC.Rollup with the Rollup Definition details and counter/sum vars.
     * This var is passed by reference and modified directly. There is no method return.
     * @param opp Opportunity SObject. All Roll-ups operate against Opportunity even if the Detail object is
     * Payment, Allocation, OCR or PSC.
     * @param detailSObject Secondary detail Sobject (Payment, Allocation, etc.); or Opportunity if the detil
     * object is Opportunity.
     */
    public static void doRollupOperation(CRLP_Rollup rollup, Opportunity oppSObject, SObject detailSObject) {

        String objName = detailSObject.getSObjectType().getDescribe().getName();

        CRLP_Debug_UTIL.setCurrentRollupState('doRollupOperation() for ' + oppSObject.Id + ' ' + objName, rollup);

        CRLP_FiscalYears fiscalYrs = new CRLP_FiscalYears(rollup.useFiscalYear);

        // Get the the first rollup in the list.
        Rollup__mdt firstRollup = rollup.rollupsMdt[0];

        // these values should be the same for every rollup definition in the CRLP_Rollup instance
        String dateField = firstRollup.Date_Field__r.QualifiedApiName;
        String amtField = firstRollup.Amount_Field__r.QualifiedApiName;

//        System.debug('>>>> doRollupOperation() for ' + oppSObject.Primary_Contact__c + ' ' + objName + ' / ' + firstRollup.Summary_Field__r.QualifiedApiName);

        Date dateValue;
        DateTime dateTimeValue;
        Decimal amountValue = null;
        String resultFieldText;

        // Get the Date value from the appropriate object. There should always be a date!
        // It's a LOT faster the use the actual field name to retrieve the date than to use .get(fieldName).
        // Since the Date is almost always the CloseDate field, hardcoding this performance tweak.
        SObject dateSObject = detailSObject;
        if (rollup.dateObject == oppObjectName && dateField == 'CloseDate') {
            dateValue = oppSObject.CloseDate;
        }
        if (dateValue == null && dateField != null && dateSObject.get(dateField) != null) {
            if (rollup.dateFieldType == SoapType.DATE) {
                dateValue = (Date) dateSObject.get(dateField);
            } else if (rollup.dateFieldType == SoapType.DATETIME) {
                dateTimeValue = (DateTime) dateSObject.get(dateField);
                dateValue = dateTimeValue.date();
            }
        }

        // For Yearly Operations ... When working with DAYS_AGO, all of the Sum/Largest/Smallest
        // operations have to be limited to the specified date range based on the value in daysAgo
        // Due to the large variation of possible combinations, Rollups for DAYS_AGO YearlyOperation
        // types cannot be combined with other rollups of different types/days.
        if (rollup.yearlyOperation == CRLP_Operation.YearlyOperationType.DAYS_BACK.name()) {
            if (dateValue == null || dateValue.daysBetween(Date.Today()) > rollup.daysBack) {
                return;
            }
        }

        // Get the Amount value from the appropriate object
        SObject amtSObject = detailSObject;
        // Hardcoding this performance tweak similar to the Opportunity.CloseDate field above
        if (rollup.AmountObject == oppObjectName && amtField == 'Amount') {
            amountValue = oppSObject.Amount;
        }
        if (amountValue == null && amtField != null && amtSObject.get(amtField) != null) {
            amountValue = (Decimal) amtSObject.get(amtField);
        }

        // If the amount is not null or zero, then convert to the Account currency as required
        if (amountValue != null && amountValue != 0) {
            // If multi currency is enabled in the organization, convert the Amount value to the
            // summary objects currency.
            if (UTIL_Currency.getInstance().isMultiCurrencyOrganization()) {
                // Convert the Amount to the currency of the target record
                String fromCurr = rollup.currCode; // default just in case there's an issue getting the detail record currency
                try {
                    fromCurr = (String) detailSObject.get('CurrencyIsoCode');
                } catch (Exception ex) { }
                amountValue = UTIL_CurrencyConversion.convertAmount(amountValue, dateValue, fromCurr, rollup.currCode);
            }
        }

        // Increment the overall counter
        rollup.theCount++;

        // If there is a result field retrieve it's value and convert as required
        // There is only one Rollup__mdt record when a Result Object/Field is involved.
        // Single Results of this nature are limited to an Operation type of First, Last, Largest or Smallest only
        if (rollup.resultFieldType != null && (rollup.detailObject == objName || rollup.detailObject == oppObjectName)) {

            Object resultVal;
            // If the ResultField (DetailField) is the same as the Amount Field, then just get the value that
            // was retrieved/converted in the code block above. Otherwise retrieve and convert as required.
            if (rollup.resultFieldName == amtField && rollup.detailObject == oppObjectName) {
                resultVal = amountValue;
            } else {
                resultVal = (rollup.detailObject == oppObjectName ?
                        oppSObject.get(rollup.resultFieldName) : detailSObject.get(rollup.resultFieldName));

                // If the result field is a currency type field and multi-currency is enabled in the org
                // then convert it to the target currency
                if (resultVal != null && rollup.resultFieldDisplaytype == DisplayType.CURRENCY &&
                        UTIL_Currency.getInstance().isMultiCurrencyOrganization()) {
                    // Convert the Amount to the currency of the target record
                    String fromCurr = rollup.currCode; // default just in case there's an issue getting the detail record currency
                    try {
                        fromCurr = (String) detailSObject.get('CurrencyIsoCode');
                    } catch (Exception ex) {
                    }
                    resultVal = UTIL_CurrencyConversion.convertAmount((Decimal) resultVal, dateValue, fromCurr, rollup.currCode);
                }
            }

            for (Integer ns=0, listSize=rollup.rollupsMdt.size(); ns<listSize; ns++) {
                Rollup__mdt r = rollup.rollupsMdt[ns];
                CRLP_Operation.RollupType operation = CRLP_Operation.getRollupTypeFromString(r.Operation__c);

                if (dateTimeValue != null && operation == CRLP_Operation.RollupType.FIRST && (dateTimeValue < rollup.minDateTime || rollup.minDateTime == null)) {
                    // Operation = FIRST (always based on a date)
                    // Only want to use < as the operator for the date comparison so it only retrieves the first
                    // record that meets the minimum date.
                    setResultFieldValue(rollup.resultFieldType, resultVal, rollup, operation);

                } else if (dateTimeValue != null && operation == CRLP_Operation.RollupType.LAST && (dateTimeValue >= rollup.maxDateTime || rollup.maxDateTime == null)) {
                    // Operation = LAST (always based on a date)
                    // Use >= because Opps are sorted by CreatedDate ASC, meaning that we want to keep getting the
                    // result value from whatever record makes up the 'last' record' by date
                    setResultFieldValue(rollup.resultFieldType, resultVal, rollup, operation);

                } else if (dateValue != null && operation == CRLP_Operation.RollupType.FIRST && (dateValue < rollup.minDate || rollup.minDate == null)) {
                    // Operation = FIRST (always based on a date)
                    // Only want to use < as the operator for the date comparison so it only retrieves the first
                    // record that meets the minimum date.
                    setResultFieldValue(rollup.resultFieldType, resultVal, rollup, operation);

                } else if (dateValue != null && operation == CRLP_Operation.RollupType.LAST && (dateValue >= rollup.maxDate || rollup.maxDate == null)) {
                    // Operation = LAST (always based on a date)
                    // Use >= because Opps are sorted by CreatedDate ASC, meaning that we want to keep getting the
                    // result value from whatever record makes up the 'last' record' by date
                    setResultFieldValue(rollup.resultFieldType, resultVal, rollup, operation);

                } else if (amountValue != null && operation == CRLP_Operation.RollupType.SMALLEST && (amountValue < rollup.minValue || rollup.minValue == 0)) {
                    // Operation = SMALLEST (always based on an amount, but the result field might actually be a date)
                    // This should get the first Opp with the smallest amount (in case there is more than one with the same amount)
                    setResultFieldValue(rollup.resultFieldType, resultVal, rollup, operation);

                } else if (amountValue != null && operation == CRLP_Operation.RollupType.LARGEST && (amountValue >= rollup.maxValue || rollup.maxValue == 0)) {
                    // Operation = LARGEST (always based on an amount, but the result field might actually be a date)
                    // This should get the last Opp with the largest amount (in case there is more than one with the same amount)
                    setResultFieldValue(rollup.resultFieldType, resultVal, rollup, operation);

                }
            }
        }

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

        String theYear;

        // Set the First/Last Date values; excluding Opportunities with a null Date or a null Amount
        if (dateValue != null) {
            theYear = fiscalYrs.getYear(dateValue).format().replace(',', '');
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
        }
        if (dateValue != null && amountValue != null) {
            if (rollup.sumByYear.containsKey(theYear)) {
                rollup.sumByYear.put(theYear, rollup.sumByYear.get(theYear) + amountValue);
                rollup.countByYear.put(theYear, rollup.countByYear.get(theYear) + 1);

                if (rollup.minByYear.get(theYear) > amountValue) {
                    rollup.minByYear.put(theYear, amountValue);
                }
                if (rollup.maxByYear.get(theYear) < amountValue) {
                    rollup.maxByYear.put(theYear, amountValue);
                }
            } else {
                rollup.countByYear.put(theYear, 1);
                rollup.sumByYear.put(theYear, amountValue);
                rollup.minByYear.put(theYear, amountValue);
                rollup.maxByYear.put(theYear, amountValue);
            }
        }
    }

    /**
     * @description Update the Result field value in the Rollup object based on the type of data being passed
     * @param resultFieldType Field SoapType
     * @param resultVal Object (the data)
     * @param rollup CRLP_Rollup instance
     */
    private static void setResultFieldValue(SoapType resultFieldType, Object resultVal, CRLP_Rollup rollup, CRLP_Operation.RollupType operation) {
        Integer arrayPosition = CRLP_Operation.operationTypeToArrayPosition(operation);
        if (resultVal == null) {
            // do nothing
        } else if (resultFieldType == SoapType.DATE) {
            rollup.dateValue[arrayPosition] = (Date) resultVal;
        } else if (resultFieldType == SoapType.DATETIME) {
            rollup.dateTimeValue[arrayPosition] = (DateTime) resultVal;
        } else if (resultFieldType == SoapType.ID) {
            rollup.idValue[arrayPosition] = (Id) resultVal;
        } else if (resultFieldType == SoapType.DOUBLE) {
            rollup.numValue[arrayPosition] = (Decimal)resultVal;
        } else {
            rollup.textValue[arrayPosition] = String.valueOf(resultVal);
        }
    }
}