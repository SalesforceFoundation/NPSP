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
* @description Wrapper class of properties to be tracked for each rollup across all of the Detail records.
* This class is used to hold all rollup data across a rollup operation; including operations that are stateful
* in a batch process.
*
*/
public class CRLP_Rollup {

    private static CRLP_FiscalYears fiscalYrs;

    public List<Rollupmdt> rollupsMdt;
    public String resultFieldName;
    public SoapType resultFieldType;
    public DisplayType resultFieldDisplaytype;
    public Boolean useFiscalYear;
    public String filterGroup;
    public String summaryObject;
    public String detailObject;
    public String amountObject;
    public String amountFieldName;
    public String dateObject;
    public String dateFieldName;
    public SoapType dateFieldType;
    public String currCode;     // The currency code of the target (summary) object
    public String timeBoundOperation;
    public Integer daysBack;
    public Integer yearsAgo;
    public Boolean isYearsAgoSingleResult;

    // Basic counter vars
    public Integer theCount;        // count, average
    public Decimal theSum;          // sum, average
    public Decimal maxValue;        // smallest/largest
    public Decimal minValue;        // smallest/largest
    public Date maxDate;            // first/last
    public Date minDate;            // first/last
    public DateTime maxDateTime;    // first/last
    public DateTime minDateTime;    // first/last

    // Vars to handle using a different field for the summary. For example, might have Largest as the Operation
    // against the Opportunity.Amount, but the ResultField might pull in Opportunity.Id or any field from the
    // Opportunity object.
    // Using Four-dimensional array to store first/last/largest/smallest values for all the various data types.
    // For example, might have a rollup of "Id of the first donation", "Amount of the last donation",
    // or "{some text field} from first donation"
    public String[] textValue;
    public Decimal[] numValue;
    public Id[] idValue;
    public Date[] dateValue;
    public DateTime[] dateTimeValue;

    // Maps of rolled up stats by year; where the map key is the year (fiscal or calendar) from the specified date field
    public Map<String, Decimal> sumByYear;
    public Map<String, Decimal> minByYear;
    public Map<String, Decimal> maxByYear;
    public Map<String, Integer> countByYear;

    /** @description Constructor */
    public CRLP_Rollup(Rollup__mdt rlp) {
        if (this.rollupsMdt == null) {
            this.rollupsMdt = new List<Rollupmdt>();

            // Field and Object details
            this.summaryObject = rlp.Summary_Object__r.QualifiedApiName;
            this.amountObject = rlp.Amount_Object__r.QualifiedApiName;
            this.dateObject = rlp.Date_Object__r.QualifiedApiName;
            this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
            this.filterGroup = rlp.Filter_Group__c;

            // Year and Date/Day related details
            this.useFiscalYear = rlp.Use_Fiscal_Year__c;
            this.timeBoundOperation = rlp.Time_Bound_Operation_Type__c;
            if (this.timeBoundOperation == CRLP_Operation.TimeBoundOperationType.DAYS_BACK.name()) {
                this.daysBack = Integer.valueOf(rlp.Integer__c);
            }

            this.isYearsAgoSingleResult = false;
            if (this.timeBoundOperation == CRLP_Operation.TimeBoundOperationType.YEARS_AGO.name()) {
                this.yearsAgo = Integer.valueOf(rlp.Integer__c);
                if (rlp.Operation__c == CRLP_Operation.RollupType.Largest.name()
                        || rlp.Operation__c == CRLP_Operation.RollupType.Smallest.name()
                        || rlp.Operation__c == CRLP_Operation.RollupType.First.name()
                        || rlp.Operation__c == CRLP_Operation.RollupType.Last.name()) {
                    this.isYearsAgoSingleResult = true;
                }
            }

            // Clear all the counter values
            resetValues();
        }
        addNewMDTRecord(rlp);
    }

    /**
     * @description Add a Rollup__mdt metadata type record to the collection of rollupmetadata type instances updating
     * instance vars as needed to ensure proper grouping.
     * @param rlp Rollup__mdt record
     */
    public void addNewMDTRecord(Rollup__mdt rlp) {
        // If the first MDT added to this instance had a null DetailField, but a later one had a defined DetailField
        // use that info to allow grouping of similar rollup types. A null value means it's ignored anyway.
        if (this.resultFieldName == null && rlp.Detail_Field__c != null) {
            this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
            DescribeFieldResult resultField = CRLP_Rollup_SVC.getSObjectFieldDescribe(this.detailObject, rlp.Detail_Field__r.QualifiedApiName);
            this.resultFieldType = resultField.getSoapType();
            this.resultFieldDisplaytype = resultField.getType();
            this.resultFieldName = rlp.Detail_Field__r.QualifiedApiName;
        }
        if (this.dateFieldType == null && rlp.Date_Field__c != null) {
            DescribeFieldResult dateField = CRLP_Rollup_SVC.getSObjectFieldDescribe(dateObject, rlp.Date_Field__r.QualifiedApiName);
            this.dateFieldType = dateField.getSoapType();
            this.dateFieldName = rlp.Date_Field__r.QualifiedApiName;
        }
        // Don't get the amount field if the operation is a Count
        if (this.amountFieldName == null && rlp.Amount_Field__c != null && rlp.Operation__c != CRLP_Operation.RollupType.COUNT.name()) {
            this.amountFieldName = rlp.Amount_Field__r.QualifiedApiName;
        }
        this.rollupsMdt.add(new Rollupmdt(rlp));
    }

    /** @description Reset all counter vars to 0/null */
    public void resetValues() {
        this.theCount = 0;
        this.theSum = this.minValue = this.maxValue = 0;
        this.minDate = this.maxDate = null;
        this.minDateTime = this.maxDateTime = null;

        this.minByYear = new Map<String, Decimal>();
        this.maxByYear = new Map<String, Decimal>();
        this.sumByYear = new Map<String, Decimal>();
        this.countByYear = new Map<String, Integer>();

        this.textValue = new List<String>{ null, null, null, null };
        this.numValue = new List<Decimal>{ 0, 0, 0, 0 };
        this.idValue = new List<Id>{ null, null, null, null };
        this.dateValue = new List<Date>{ null, null, null, null };
        this.dateTimeValue = new List<DateTime>{ null, null, null, null };
    }

    /**
     * @description Set the currency code of the target (Summary) record. This will be used for converting the
     * detail record amount values to the currency of the target record.
     * @param currencyIsoCode
     */
    public void setCurrencyCode(String currCode) {
        this.currCode = currCode;
    }

    /**
     * @description Determine if the passed Rollup__mdt record has the identical key properties to this
     * Rollup instance: FilterGroup, Summary Object, Detail Field, Amount Field, Date Field, and UseFiscalYear.
     * Grouping of Rollup__mdt records in instances of CRLP_Rollup significantly improves the overall rollup performance
     * because it reduced the number of for-loop iterations for each detail record being rolled up.
     * @param Rollup__mdt
     * @return True (group the Mdt record into this CRLP_Rollup instance) or False (create a new CRLP_Rollup instance for this record)
     */
    public Boolean isRollupInSameGroup(Rollup__mdt otherMdtRollup) {
        Set<String> matchingFields = new Set<String>{
                'Filter_Group__c','Summary_Object__c','Detail_Field__c', 'Detail_Object__c',
                'Date_Field__c', 'Amount_Field__c', 'Use_Fiscal_Year__c'
        };
        if (this.rollupsMdt == null) {
            return true;
        }

        // Due to the large variation of possible combinations, Rollups for DAYS_BACK TimeBoundOperation
        // types cannot be combined with other rollups of different types/days. Group these together
        // where the NumberOfDays is the same.

        Boolean isSameRollupGroup = true;

        // Convert a null TimeBoundOperationType to AllTime to ease comparisons
        String otherMdtTimeBoundOperationType = (otherMdtRollup.Time_Bound_Operation_Type__c != null ?
                otherMdtRollup.Time_Bound_Operation_Type__c : CRLP_Operation.TimeBoundOperationType.All_Time.name());

        // DaysBack operations have to be grouped together, so if the value doesn't match exactly don't
        // consider them in the same group
        String daysBackOperation = CRLP_Operation.TimeBoundOperationType.DAYS_BACK.name();
        if ((this.timeBoundOperation == daysBackOperation && (otherMdtTimeBoundOperationType != daysBackOperation ||
                this.daysBack != otherMdtRollup.Integer__c)) ||
                (otherMdtTimeBoundOperationType == daysBackOperation && this.timeBoundOperation != daysBackOperation)
                ) {
            isSameRollupGroup = false;
        }

        // YearsAgo operations have to be grouped together by year for Single Result Operations,
        // so if the op group + value don't match exactly don't consider them in the same group
        String yearsAgoOperation = CRLP_Operation.TimeBoundOperationType.YEARS_AGO.name();
        Boolean isSingleResult = otherMdtRollup.Operation__c == CRLP_Operation.RollupType.Largest.name() || otherMdtRollup.Operation__c == CRLP_Operation.RollupType.Smallest.name()
                ||   otherMdtRollup.Operation__c == CRLP_Operation.RollupType.First.name() || otherMdtRollup.Operation__c == CRLP_Operation.RollupType.Last.name();
        if ((this.isYearsAgoSingleResult == true
                && (otherMdtTimeBoundOperationType != yearsAgoOperation
                || otherMdtRollup.Integer__c != this.yearsAgo
                || !isSingleResult))
                ||
                (this.isYearsAgoSingleResult != true
                && otherMdtTimeBoundOperationType == yearsAgoOperation
                && isSingleResult)) {
            isSameRollupGroup = false;
        }

        // The Amount and Detail fields do not matter for Count operations, so remove them from the
        // grouping matching logic if this Rollup is a Count OR there is only one MDT record in the
        // instance and that one is a Count.
        if (otherMdtRollup.Operation__c == CRLP_Operation.RollupType.COUNT.name()
                || (this.rollupsMdt.size() == 1 && this.rollupsMdt[0].operation == CRLP_Operation.RollupType.COUNT.name())) {
            matchingFields.remove('Amount_Field__c');
            matchingFields.remove('Detail_Field__c');
        }

        for (String fld : matchingFields) {
            Object val;
            Object otherVal = otherMdtRollup.get(fld);
            if (fld == 'Filter_Group__c') {
                val = this.filterGroup;
            } else if (fld == 'Use_Fiscal_Year__c') {
                val = this.useFiscalYear;
            } else {
                if (fld == 'Summary_Object__c') {
                    val = this.summaryObject;
                    otherVal = otherMdtRollup.Summary_Object__r.QualifiedApiName;
                } else if (fld == 'Detail_Object__c') {
                    val = this.detailObject;
                    otherVal = otherMdtRollup.Detail_Object__r.QualifiedApiName;
                } else if (fld == 'Detail_Field__c') {
                    val = this.resultFieldName;
                    otherVal = otherMdtRollup.Detail_Field__r.QualifiedApiName;
                } else if (fld == 'Date_Field__c') {
                    val = this.dateFieldName;
                    otherVal = otherMdtRollup.Date_Field__r.QualifiedApiName;
                } else if (fld == 'Amount_Field__c') {
                    val = this.amountFieldName;
                    otherVal = otherMdtRollup.Amount_Field__r.QualifiedApiName;
                }
            }
            if (val != otherVal && otherVal != null && val != null) {
                isSameRollupGroup = false;
                break;
            }
        }

        return isSameRollupGroup;
    }

    /**
     * @description Returns the appropriate return for this rollup based on the rollup operation type
     * and the target field data type
     */
    public Map<String, Object> getFinalValues() {
        Map<String, Object> rtnValues = new Map<String, Object>();

        // Instantiate this with the first Rollup__mdt record. All records have the same
        // value in the Use_Fiscal_Year__c field.
        fiscalYrs = new CRLP_FiscalYears(this.useFiscalYear);

        // Get the rolled up value for each Rollup__mdt record
        for (Integer ns=0, listSize=rollupsMdt.size(); ns<listSize; ns++) {
            Rollupmdt r = this.rollupsMdt[ns];
            Schema.DescribeFieldResult targetField = CRLP_Rollup_SVC.getSObjectFieldDescribe(this.summaryObject, r.summaryField);
            Object val = determineRollupValue(r, targetField);
            if (val != null) {
                rtnValues.put(r.summaryField, val);
            }
        }

        return rtnValues;
    }

    /**
     * @description For a given Rollup__mdt, retrieve the correct rolled-up value using the class instance vars
     * @param Rollup__mdt
     * @param targetField DescribeFieldResult for the target (Summary) field
     * @return Object with the return value to be stored in the target field
     */
    private Object determineRollupValue(Rollupmdt r, DescribeFieldResult targetField) {
        SoapType fldType = targetField.getSoapType();
        Object resultValue;

        CRLP_Operation.RollupType operation = CRLP_Operation.getRollupTypeFromString(r.operation);

//        CRLP_Debug_UTIL.setCurrentRollupState(' - determineRollupValue: ' + targetField.getName() +
//                '/' + fldType + ' for ' + operation);

        // ================================================================
        // Yearly Operation Type - Get the Sum/Min/Max for the specified number of years back to use
        // in the later logic to determine the values to return for this rollup.
        // ================================================================
        Decimal sumForSpecifiedYear = 0, maxForSpecifiedYear = 0, minForSpecifiedYear = 0, countForSpecifiedYear = 0;
        Boolean useYearsAgoValue = ( r.timeBoundOperationType == CRLP_Operation.TimeBoundOperationType.YEARS_AGO.name());

        if (useYearsAgoValue == true) {
            
            // Find the data for the specified number of years back.
            Integer getThisYear = (this.useFiscalYear ? fiscalYrs.getYear(Date.today()) : Date.today().year()) - r.intValue;
            String yrString = UTIL_String.removeNonNumericCharacters(getThisYear.format());

            // If the map of sums by year include the specified year, then get the Sum/Min/Max
            if (sumByYear.containsKey(yrString)) {
                sumForSpecifiedYear += sumByYear.get(yrString);
                minForSpecifiedYear += maxByYear.get(yrString);
                maxForSpecifiedYear += minByYear.get(yrString);
                countForSpecifiedYear += countByYear.get(yrString);
            }
//            CRLP_Debug_UTIL.amendLastCurrentRollupState('Yr=' + yrString + ' / Sum=' + sumForSpecifiedYear);
        }

        // ================================================================
        // First/Last ,such as "Last Gift Amount"
        // This could be an Id or pretty much any other field that can be stored as 'text'
        // ================================================================
        if (operation == CRLP_Operation.RollupType.FIRST || operation == CRLP_Operation.RollupType.LAST) {
            Integer arrayPosition = CRLP_Operation.operationTypeToArrayPosition(operation);
            if (fldType == SoapType.DOUBLE) {
                resultValue = numValue[arrayPosition];
            } else if (fldType == SoapType.ID) {
                resultValue = idValue[arrayPosition];
            } else if (fldType == SoapType.DATE) {
                resultValue = dateValue[arrayPosition];
            } else if (fldType == SoapType.DATETIME) {
                resultValue = dateTimeValue[arrayPosition];
            } else {
                resultValue = textValue[arrayPosition];
            }
        }

        // ================================================================
        // Sum, Average, Largest, Smallest, Count
        // ================================================================
        else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.SUM) {
            if (useYearsAgoValue == false) {
                resultValue = theSum;
            } else {
                resultValue = sumForSpecifiedYear;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.AVERAGE) {
            if (useYearsAgoValue == false && theCount != 0) {
                resultValue = theSum.divide(theCount, 2, RoundingMode.HALF_UP);
            } else if (countForSpecifiedYear != 0) {
                resultValue = sumForSpecifiedYear.divide(countForSpecifiedYear, 2, RoundingMode.HALF_UP);
            } else {
                resultValue = 0;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.SMALLEST) {
            if (useYearsAgoValue == false) {
                resultValue = minValue;
            } else {
                resultValue = minForSpecifiedYear;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.LARGEST) {
            if (useYearsAgoValue == false) {
                resultValue = maxValue;
            } else {
                resultValue = maxForSpecifiedYear;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.COUNT) {
            if (useYearsAgoValue == false) {
                resultValue = theCount;
            } else {
                resultValue = countForSpecifiedYear;
            }
        }

        // ================================================================
        // Best Year or Best Year Total
        // ================================================================
        else if (operation == CRLP_Operation.RollupType.Best_Year || operation == CRLP_Operation.RollupType.Best_Year_Total) {
            Decimal maxVal = 0;
            String bestYr = null;
            List<String> years = new List<String>( this.sumByYear.keySet() );
            years.sort();
            for (String yr : years) {
                if (this.sumByYear.get(yr) > maxVal) {
                    bestYr = yr;
                    maxVal = this.sumByYear.get(yr);
                }
            }
            if (operation == CRLP_Operation.RollupType.Best_Year_Total) {
                resultValue = maxVal;
            } else {
                if (bestYr == null || fldType == SoapType.STRING) {
                    resultValue = bestYr;
                } else {
                    resultValue = Integer.valueOf(bestYr);
                }
            }
        }

        // ================================================================
        // Years Donated (semi-colon separated list)
        // ================================================================
        else if (operation == CRLP_Operation.RollupType.Years_Donated) {
            List<String> years = new List<String>( this.sumByYear.keySet() );
            years.sort();
            resultValue = (!years.isEmpty() ? String.join(years,';') : null);
        }

        // ================================================================
        // Current Streak (returns the number of years going back from this yer that a donation has been made)
        // ================================================================
        else if (operation == CRLP_Operation.RollupType.Donor_Streak) {
            List<String> yearlySorted = new List<String>(this.sumByYear.keySet());
            yearlySorted.sort();
            Integer streakLength = 0;

            Integer currentYear = fiscalYrs.getYear(System.today());
            if (yearlySorted.size() != 0 && currentYear != Integer.valueOf(yearlySorted[yearlySorted.size() - 1])) {
                // if they haven't donated this year, start counting last year
                currentYear--;
            }

            // Loop through all the years with donations in reverse to find the current streak
            for (Integer n = yearlySorted.size() - 1; n >= 0; n--) {
                if (Integer.valueOf(yearlySorted[n]) == currentYear) {
                    streakLength++;
                    currentYear--;
                } else {
                    break;
                }
            }
            resultValue = streakLength;
        }

        // ================================================================
        // Largest/Smallest for other types
        // ================================================================
        if (operation == CRLP_Operation.RollupType.LARGEST || operation == CRLP_Operation.RollupType.SMALLEST) {
            Integer arrayPosition = CRLP_Operation.operationTypeToArrayPosition(operation);
            if (fldType == SoapType.DOUBLE) {
                resultValue = numValue[arrayPosition];
            } else if (fldType == SoapType.ID) {
                resultValue = idValue[arrayPosition];
            } else if (fldType == SoapType.DATE) {
                resultValue = dateValue[arrayPosition];
            } else if (fldType == SoapType.DATETIME) {
                resultValue = dateTimeValue[arrayPosition];
            } else if (fldType == SoapType.STRING) {
                resultValue = textValue[arrayPosition];
            }
        }

//        CRLP_Debug_UTIL.amendLastCurrentRollupState('==> ' + resultValue);
        return resultValue;
    }

    /**
     * @description Wrapper class for the Rollup__mdt CMT records to use in the collection of MDT's within this
     * outer class and for stateful storage. Uses significantly less heap size than storing a list of Rollup__mdt records.
     */
    public class Rollupmdt {
        public String operation;
        public String timeBoundOperationType;
        public String summaryObject;
        public String summaryField;
        public String detailObject;
        public String detailField;
        public String amountObject;
        public String amountField;
        public String dateObject;
        public String dateField;
        public Integer intValue;

        public Rollupmdt(Rollup__mdt rlp) {
            this.operation = rlp.Operation__c;
            this.timeBoundOperationType = (rlp.Time_Bound_Operation_Type__c != null ? rlp.Time_Bound_Operation_Type__c :
                    CRLP_Operation.TimeBoundOperationType.All_Time.name());
            this.summaryObject = rlp.Summary_Object__r.QualifiedApiName;
            this.summaryField = rlp.Summary_Field__r.QualifiedApiName;
            this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
            this.detailField = rlp.Detail_Field__r.QualifiedApiName;
            this.amountObject = rlp.Amount_Object__r.QualifiedApiName;
            this.amountField = rlp.Amount_Field__r.QualifiedApiName;
            this.dateObject = rlp.Date_Object__r.QualifiedApiName;
            this.dateField = rlp.Date_Field__r.QualifiedApiName;
            this.intValue = (rlp.Integer__c != null ? rlp.Integer__c.intValue() : null);
        }
    }
}