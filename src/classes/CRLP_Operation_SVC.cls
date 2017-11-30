/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Rollup Operation Services
*/
public class CRLP_Operation_SVC {

/*
Called by the RollupHandler service class instance for each Source record and each active rollup that
passes the filter. For example, there may be 10 instances of the CRLP_Rollup class created for 10 rollups
from Opportunity to Account. Each instances doOperation() method will get called once to do the rollup from
the Detail/Attribution records to the Source record - though the values are actually stored in the CRLP_Rollup
instance until ready to be written to the Sobject.
 */

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

        CRLP_FiscalYears fiscalYrs = new CRLP_FiscalYears(rollup.useFiscalYear);
        Rollup__mdt firstRollup = rollup.rollupsMdt[0];
        String dateField = firstRollup.Date_Field__r.QualifiedApiName;
        String amtField = firstRollup.Amount_Field__r.QualifiedApiName;

        Date dateValue, resultFieldDate;
        Datetime resultFieldDateTime;
        Double amountValue = 0, resultFieldAmount = 0;
        String resultFieldText;

        String objName = detailSObject.getSObjectType().getDescribe().getName();

        // Get the Date value from the appropriate object. There should always be a date!
        SObject dateSObject = detailSObject;
        if (rollup.dateObject != objName && UTIL_Describe.getSObjectType(rollup.dateObject) == Opportunity.SObjectType) {
            dateSObject = oppSObject;
        }
        if (dateSObject.get(dateField) != null) {
            dateValue = (Date) dateSObject.get(dateField);
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
        if (rollup.AmountObject != objName && UTIL_Describe.getSObjectType(rollup.dateObject) == Opportunity.SObjectType) {
            amtSObject = oppSObject;
        }
        if (amtSObject.get(amtField) != null) {
            amountValue = (Double) amtSObject.get(amtField);
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
                } catch (Exception ex) {
                }
                amountValue = UTIL_CurrencyConversion.convertAmount(amountValue, dateValue, fromCurr, rollup.currCode);
            }
        }

        // Increment the overall counter
        rollup.theCount++;

        // If there is a result field retrieve it's value and convert as required
        // There is only one Rollup__mdt record when a Result Object/Field is involved.
        // Single Results of this nature are limited to an Operation type of First, Last, Largest or Smallest only
        if (rollup.resultFieldType != null && rollup.detailObject == objName) {

            Object resultVal = detailSObject.get(rollup.resultFieldName);
            CRLP_Operation.RollupType operation = CRLP_Operation.getRollupTypeFromString(firstRollup.Operation__c.replaceAll(' ', '_'));

            /*System.debug(LoggingLevel.ERROR, '>> ResultField Operation: ' + rollup.resultFieldName + ' ' + operation +
                ' for ' + resultVal + ' // maxDate=' + rollup.maxDate + ', dateValue=' + dateValue);*/

            if (operation == CRLP_Operation.RollupType.FIRST && dateValue < rollup.minDate) {
                // Operation = FIRST (always based on a date)
                setResultFieldValue(rollup.resultFieldType, resultVal, rollup);

            } else if (operation == CRLP_Operation.RollupType.LAST && dateValue > rollup.maxDate) {
                // Operation = LAST (always based on a date)
                setResultFieldValue(rollup.resultFieldType, resultVal, rollup);

            } else if (operation == CRLP_Operation.RollupType.SMALLEST && amountValue < rollup.minValue) {
                // Operation = LARGEST (always based on an amount)
                setResultFieldValue(rollup.resultFieldType, resultVal, rollup);

            } else if (operation == CRLP_Operation.RollupType.LARGEST && amountValue > rollup.maxValue) {
                // Operation = SMALLEST (always based on an amount)
                setResultFieldValue(rollup.resultFieldType, resultVal, rollup);

            } else if ((operation == CRLP_Operation.RollupType.LAST || operation == CRLP_Operation.RollupType.FIRST)
                    && (rollup.minDate == null || rollup.maxDate == null)) {
                // If the Min/Max fields are null, then the value is alway both the First and Last date.
                setResultFieldValue(rollup.resultFieldType, resultVal, rollup);
            }
        }

        // Set the Largest/Smallest Amount values
        if (amountValue != null) {
            rollup.theSum += amountValue;
            if (rollup.minValue > amountValue) {
                rollup.minValue = amountValue;
            }
            if (rollup.maxValue < amountValue) {
                rollup.maxValue = amountValue;
            }
        }

        String theYear;

        // Set the First/Last Date values
        if (dateValue != null) {
            theYear = fiscalYrs.getYear(dateValue).format().replace(',','');
            if (rollup.minDate == null || rollup.minDate > dateValue) {
                rollup.minDate = dateValue;
            }
            if (rollup.maxDate == null || rollup.maxDate < dateValue) {
                rollup.maxDate = dateValue;
            }

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
    private static void setResultFieldValue(SoapType resultFieldType, Object resultVal, CRLP_Rollup rollup) {
        if (resultVal == null) {
            // do nothing
        } else if (resultFieldType == SoapType.DATE) {
            rollup.dateValue = (Date) resultVal;
        } else if (resultFieldType == SoapType.DATETIME) {
            rollup.dateTimeValue = (DateTime) resultVal;
        } else if (resultFieldType == SoapType.ID) {
            rollup.idValue = (Id) resultVal;
        } else {
            rollup.textValue = String.valueOf(resultVal);
        }
    }
}