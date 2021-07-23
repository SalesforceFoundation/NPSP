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

    public Boolean hasSingleResultOperations = false;
    public Boolean isDaysAgoOperation = false;
    public Boolean isYearsAgoSingleResult = false;

    // The following properties have to be the same for all Rollup Definitions in this group
    public Boolean useFiscalYear;
    public String filterGroup;
    public String summaryObject;
    public String detailObject;
    public String amountObject;
    public String amountFieldName;
    public Schema.DisplayType amountFieldType;
    public String dateObject;
    public String dateFieldName;
    public SoapType dateFieldType;
    public String currCode;     // The currency code of the target (summary) object
    public Integer daysBack;
    public Integer yearsAgo;

    // Basic counter vars
    public Integer theCount;        // count, average
    public Decimal theSum;          // sum, average
    public Decimal maxValue;        // smallest/largest
    public Decimal minValue;        // smallest/largest
    public Date maxDate;            // first/last
    public Date minDate;            // first/last
    public Datetime maxDateTime;    // first/last
    public Datetime minDateTime;    // first/last

    // Maps of rolled up stats by year; where the map key is the year
    // (fiscal or calendar) from the specified date field
    public Map<String, Decimal> sumByYear;
    public Map<String, Decimal> minByYear;
    public Map<String, Decimal> maxByYear;
    public Map<String, Integer> countByYear;

    /** @description Constructor */
    public CRLP_Rollup(Rollup__mdt rlp) {

        if (this.rollupsMdt == null) {
            setDefaultsFromFirstMdt(rlp);
        }
        addNewMDTRecord(rlp);
    }

    /**
     * @description Set the default CRLP_Rollup properties from the first Rollup__mdt record added to the group
     * @param rlp Rollup__mdt record
     */
    private void setDefaultsFromFirstMdt(Rollup__mdt rlp) {
        this.rollupsMdt = new List<Rollupmdt>();

        // Field and Object details
        this.summaryObject = rlp.Summary_Object__r.QualifiedApiName;
        this.amountObject = rlp.Amount_Object__r.QualifiedApiName;
        this.dateObject = rlp.Date_Object__r.QualifiedApiName;
        this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
        this.filterGroup = rlp.Filter_Group__c;

        // Year and Date/Day related details
        this.useFiscalYear = rlp.Use_Fiscal_Year__c;
        if (rlp.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Days_Back.name()) {
            this.daysBack = Integer.valueOf(rlp.Integer__c);
        }
        if (rlp.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Years_Ago.name()) {
            this.yearsAgo = Integer.valueOf(rlp.Integer__c);
        }

        // Clear all the counter values
        resetValues();
    }

    /**
     * @description Add a Rollup__mdt metadata type record to the collection of rollupmetadata type instances updating
     * instance vars as needed to ensure proper grouping.
     * @param rlp Rollup__mdt record
     */
    public void addNewMDTRecord(Rollup__mdt rlp) {

        // If the first MDT added to this instance had a null DetailField, but a later one had a defined DetailField
        // use that info to allow grouping of similar rollup types. A null value means it's ignored anyway.
        if (this.detailObject == null && rlp.Detail_Field__c != null) {
            this.detailObject = rlp.Detail_Object__r.QualifiedApiName;
        }

        if (this.dateFieldType == null && rlp.Date_Field__c != null) {
            DescribeFieldResult dateField = CRLP_Rollup_SVC.getSObjectFieldDescribe(dateObject, rlp.Date_Field__r.QualifiedApiName);
            this.dateFieldType = dateField.getSoapType();
            this.dateFieldName = rlp.Date_Field__r.QualifiedApiName;
        }

        // Don't get the amount field if the operation is a Count
        if (this.amountFieldName == null && rlp.Amount_Field__c != null && rlp.Operation__c != CRLP_Operation.RollupType.Count.name()) {
            DescribeFieldResult amountField = CRLP_Rollup_SVC.getSObjectFieldDescribe(amountObject, rlp.Amount_Field__r.QualifiedApiName);
            this.amountFieldType = amountField.getType();
            this.amountFieldName = rlp.Amount_Field__r.QualifiedApiName;
        }

        Rollupmdt mdt = new Rollupmdt(rlp);
        this.rollupsMdt.add(mdt);
        if (mdt.singleResultRollupType == true) {
            this.hasSingleResultOperations = true;
        }
        if (mdt.isYearsAgoSingleResult == true) {
            this.isYearsAgoSingleResult = true;
            this.yearsAgo = mdt.yearsAgo;
        }
        if (rlp.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Days_Back.name()) {
            this.isDaysAgoOperation = true;
        }
    }

    public void resetValues() {
        this.theCount = 0;
        this.theSum = this.minValue = this.maxValue = 0;
        this.minDate = this.maxDate = null;
        this.minDateTime = this.maxDateTime = null;

        this.minByYear = new Map<String, Decimal>();
        this.maxByYear = new Map<String, Decimal>();
        this.sumByYear = new Map<String, Decimal>();
        this.countByYear = new Map<String, Integer>();

        for (Rollupmdt r : rollupsMdt) {
            r.resultValue = null;
            r.resultDate = null;
            r.resultDatetime = null;
            r.resultString = null;
        }
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
     * @description Determine if the passed Rollup__mdt record can be included in this instance of CRLP_Rollup.
     * Grouping of Rollup__mdt records in instances of CRLP_Rollup improves the overall rollup performance
     * because it reduced the number of for-loop iterations for each detail record being rolled up.
     * Special Grouping Rules:
     * - All DaysAgo operations are grouped together with the same DaysAgo value
     * - All YearsAgo operations for a SingleResultType (Smallest/Largest/First/Last) are
     *    grouped with others with the same YearsAgo value
     * @param Rollup__mdt
     * @return True (group the Mdt record into this CRLP_Rollup instance) or False (create a new CRLP_Rollup instance for this record)
     */
    public Boolean isRollupInSameGroup(Rollup__mdt otherMdtRollup) {
        if (this.rollupsMdt == null) {
            return true;
        }

        if (!isMatchForRequiredAttributes(otherMdtRollup)) {
            return false;
        }

        // If DaysBack operation, is the Integer value different?
        Boolean isThisDaysBack = (otherMdtRollup.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Days_Back.name());
        if (this.isDaysAgoOperation != isThisDaysBack) {
            return false;
        } else if (this.isDaysAgoOperation && otherMdtRollup.Integer__c != this.daysBack) {
            return false;
        }

        // Have to group single result operations using YearsAgo together because
        // things like First/Last/Largest/Smallest are unique to that timeframe
        // Will also need to update the Operations service to exit out before the
        // full aggregation when there is a YearsAgoSingleResult operation
        Boolean isThisYearsAgo = CRLP_Rollup_SVC.isSingleResultRollup(otherMdtRollup)
            && otherMdtRollup.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Years_Ago.name();
        if (this.isYearsAgoSingleResult != isThisYearsAgo) {
            return false;
        } else if (this.isYearsAgoSingleResult && otherMdtRollup.Integer__c != this.yearsAgo) {
            return false;
        }

        return true;
    }

    /**
     * @description First Level Grouping Match:
     * - Fiscal Year, Filter Group, Detail Object
     * - Amount Object/Field (only if not a Count Rollup)
     * - Date Object/Field (only if not a Count Rollup that uses DaysBack or YearsAgo)
     * @param otherMdtRollup
     * @return True if in the same group, False if not.
     */
    private Boolean isMatchForRequiredAttributes(Rollup__mdt otherMdtRollup) {

        // Is the Fiscal Year, Detail Object or Filter Group different?
        if (this.useFiscalYear != otherMdtRollup.Use_Fiscal_Year__c) {
            return false;
        }
        if (this.filterGroup != otherMdtRollup.Filter_Group__c) {
            return false;
        }
        if (this.detailObject != otherMdtRollup.Detail_Object__r.QualifiedApiName) {
            return false;
        }

        // If NOT a count operation, are the Amount Objects/Fields different?
        String countOperation = CRLP_Operation.RollupType.Count.name();
        if (otherMdtRollup.Operation__c != countOperation) {
            if (this.amountObject != otherMdtRollup.Amount_Object__r.QualifiedApiName) {
                return false;
            }
            if (this.amountFieldName != otherMdtRollup.Amount_Field__r.QualifiedApiName) {
                return false;
            }
        }

        // Count Rollups that are not using a TimeBoundOperation type can ignore the Date field
        if (otherMdtRollup.Operation__c != countOperation
                || otherMdtRollup.Time_Bound_Operation_Type__c != CRLP_Operation.TimeBoundOperationType.All_Time.name()
        ) {
            if (this.dateObject != otherMdtRollup.Date_Object__r.QualifiedApiName) {
                return false;
            }
            if (this.dateFieldName != otherMdtRollup.Date_Field__r.QualifiedApiName) {
                return false;
            }
        }

        // Everything matches, so return true
        return true;
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
        Decimal sumForSpecifiedYear = 0;
        Decimal maxForSpecifiedYear = 0;
        Decimal minForSpecifiedYear = 0;
        Decimal countForSpecifiedYear = 0;
        Boolean useYearsAgoValue = (r.timeBoundOperationType == CRLP_Operation.TimeBoundOperationType.Years_Ago.name());

        if (useYearsAgoValue == true) {

            // Find the data for the specified number of years back.
            Integer getThisYear = (this.useFiscalYear ? fiscalYrs.getYear(Date.today()) : Date.today().year()) - r.yearsAgo;
            String yrString = UTIL_String.removeNonNumericCharacters(getThisYear.format());

            // If the map of sums by year include the specified year, then get the Sum/Min/Max
            if (sumByYear.containsKey(yrString)) {
                sumForSpecifiedYear += sumByYear.get(yrString);
                minForSpecifiedYear += maxByYear.get(yrString);
                maxForSpecifiedYear += minByYear.get(yrString);
            }
            if (countByYear.containsKey(yrString)) {
                countForSpecifiedYear += countByYear.get(yrString);
            }
//            CRLP_Debug_UTIL.amendLastCurrentRollupState('Yr=' + yrString + ' / Sum=' + sumForSpecifiedYear);
        }

        // ================================================================
        // First/Last ,such as "Last Gift Amount"
        // This could be an Id or pretty much any other field that can be stored as 'text'
        // ================================================================
        if (operation == CRLP_Operation.RollupType.First || operation == CRLP_Operation.RollupType.Last) {
            resultValue = r.getResultValue();
        }

        // ================================================================
        // Sum, Average, Largest, Smallest, Count
        // ================================================================
        else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.Sum) {
            if (useYearsAgoValue == false) {
                resultValue = theSum;
            } else {
                resultValue = sumForSpecifiedYear;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.Average) {
            if (useYearsAgoValue == false && theCount != 0) {
                resultValue = theSum.divide(theCount, 2, RoundingMode.HALF_UP);
            } else if (countForSpecifiedYear != 0) {
                resultValue = sumForSpecifiedYear.divide(countForSpecifiedYear, 2, RoundingMode.HALF_UP);
            } else {
                resultValue = 0;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.Smallest) {
            if (useYearsAgoValue == false) {
                resultValue = minValue;
            } else {
                resultValue = minForSpecifiedYear;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.Largest) {
            if (useYearsAgoValue == false) {
                resultValue = maxValue;
            } else {
                resultValue = maxForSpecifiedYear;
            }
        } else if (fldType == SoapType.DOUBLE && operation == CRLP_Operation.RollupType.Count) {
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
        if (operation == CRLP_Operation.RollupType.Largest || operation == CRLP_Operation.RollupType.Smallest) {
            resultValue = r.getResultValue();
        }

        // abbreviate strings that are too long for the target field
        if (resultValue instanceof String) {
            String stringValue = (String) resultValue;
            Integer maxFieldLength = targetField.getLength();
            if (stringValue.length() > maxFieldLength && maxFieldLength >= 4) {
                resultValue = stringValue.abbreviate(maxFieldLength);
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
        public DisplayType summaryFieldDisplayType;
        public Integer yearsAgo;

        public Boolean isYearsAgoSingleResult = false;
        public Boolean singleResultRollupType = false;

        public String detailObject;
        public String detailField;
        public DisplayType resultFieldDisplayType;

        private String resultString;
        private Date resultDate;
        private Datetime resultDatetime;
        private Decimal resultValue;

        public Rollupmdt(Rollup__mdt rlp) {
            operation = rlp.Operation__c;
            timeBoundOperationType = (rlp.Time_Bound_Operation_Type__c != null ? rlp.Time_Bound_Operation_Type__c :
                    CRLP_Operation.TimeBoundOperationType.All_Time.name());
            summaryObject = rlp.Summary_Object__r.QualifiedApiName;
            summaryField = rlp.Summary_Field__r.QualifiedApiName;
            detailObject = rlp.Detail_Object__r.QualifiedApiName;
            detailField = rlp.Detail_Field__r.QualifiedApiName;

            DescribeFieldResult summaryFieldDescribe = CRLP_Rollup_SVC.getSObjectFieldDescribe(summaryObject, summaryField);
            if (summaryFieldDescribe != null) {
                summaryFieldDisplayType = summaryFieldDescribe.getType();
            }

            DescribeFieldResult resultFieldDescribe;
            if (detailField != null) {
                resultFieldDescribe = CRLP_Rollup_SVC.getSObjectFieldDescribe(detailObject, detailField);
            } else {
                resultFieldDescribe = CRLP_Rollup_SVC.getSObjectFieldDescribe(summaryObject, summaryField);
            }
            if (resultFieldDescribe != null) {
                resultFieldDisplayType = resultFieldDescribe.getType();
            }

            singleResultRollupType = CRLP_Rollup_SVC.isSingleResultRollup(rlp);

            // Special logic for YearsAgo rollup types
            if (rlp.Time_Bound_Operation_Type__c == CRLP_Operation.TimeBoundOperationType.Years_Ago.name()) {
                yearsAgo = Integer.valueOf(rlp.Integer__c);
                isYearsAgoSingleResult = singleResultRollupType;
            }
        }

        /**
         * @description Because it's not possible to use an 'Object' type var in this class (because Objects
         * cannot be serialized into json), the individual target data types have to independent vars.
         * This method retrieves the appropriate value based on the type of the target (summary) field.
         * @return object
         */
        public Object getResultValue() {
            switch on (summaryFieldDisplayType) {
                when DOUBLE, INTEGER, CURRENCY, LONG {
                    return resultValue;
                }
                when DATE {
                    return resultDate;
                }
                when DATETIME {
                    return resultDatetime;
                }
                when else {
                    return resultString;
                }
            }
        }

        /**
         * @description Because it's not possible to use an 'Object' type var in this class (because Objects
         * cannot be serialized into json), the individual target data types have to independent vars.
         * This method retrieves the appropriate value based on the type of the target (summary) field.
         * @param val The value to be saved into one of the four concrete-type specific fields
         */
        public void setResultValue(Object val) {
            if (val == null) {
                return;
            }
            switch on (summaryFieldDisplayType) {
                when DOUBLE, INTEGER, CURRENCY, LONG {
                    resultValue = Double.valueOf(val);
                }
                when DATE {
                    resultDate = Date.valueOf(val);
                }
                when DATETIME {
                    resultDatetime = Datetime.valueOf(val);
                }
                when else {
                    resultString = String.valueOf(val);
                }
            }

        }
    }
}