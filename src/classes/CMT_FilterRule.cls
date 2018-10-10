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
* @description Instance class for a single Filter Rule. Handles actions for that specific Filter Rule, such as
* evaluating the rule against a specified SObject record.
*/
public class CMT_FilterRule {

    /**
     * @description Enum of valid filter operations. Matches Filter_Rule__mdt.Operation__c
     */
    public Enum FilterOperation {
        Equals,
        Not_Equals,
        Greater,
        Less,
        Greater_or_Equal,
        Less_or_Equal,
        Starts_With,
        Contains,
        Does_Not_Contain,
        In_List,
        Not_In_List,
        Is_Included,
        Is_Not_Included
    }

    public Enum DateFilterConstant {
        TODAY, YESTERDAY,
        THIS_YEAR, LAST_YEAR, TWO_YEARS_AGO,
        THIS_FISCAL_YEAR, LAST_FISCAL_YEAR, TWO_FISCAL_YEARS_AGO,
        THIS_MONTH, LAST_MONTH, TWO_MONTHS_AGO,
        THIS_WEEK, LAST_WEEK, TWO_WEEKS_AGO
    }

    /**
     * @description 3 character prefix for Record Type Id's. Used to determine the comparison type for record types.
     */
    private static final String recordTypeIdPrefix = SObjectType.RecordType.getKeyPrefix();

    /**
     * @description Date type filter rules supports a defined set of specific constants that roughly mimic
     * what Salesforce native supports
     */
    public static Set<String> validDateConstants {
        get {
            if (validDateConstants == null) {
                validDateConstants = new Set<String>();
                for (DateFilterConstant f : DateFilterConstant.values()) {
                    validDateConstants.add(f.name());
                }
            }
            return validDateConstants;
        } private set;
    }

    /**
     * @description Convert each SoapType (for a field) into the appropriate custom Comparison class
     */
    private static final Map<SoapType, Type> converters = new Map<SoapType, Type>{
            SoapType.BOOLEAN    => CompareBooleans.class,
            SoapType.DOUBLE     => CompareDoubles.class,
            SoapType.INTEGER    => CompareDoubles.class,
            SoapType.DATE       => CompareDates.class,
            SoapType.DATETIME   => CompareDateTimes.class,
            SoapType.ID         => CompareIds.class,
            SoapType.STRING     => CompareStrings.class
            /*SoapType.TIME       => CompareTimes.class -- Time is not a field type we can support yet */
    };

    /**
     * @description Class properties
     */
    protected Schema.SObjectType objectType;
    protected Schema.SObjectField field;
    protected FilterOperation operation;
    protected String constant;
    public String objectName;
    public Id ruleId;

    /**
     * @description Constructor - Instantiate the the appropriate comparison interface class based on the Field SoapType
     * @param filterRule
     */
    public CMT_FilterRule(Filter_Rule__mdt filterRule) {

        this.ruleId = filterRule.Id;
        this.objectName = filterRule.Object__r.QualifiedApiName;
        this.objectType = UTIL_Describe.getObjectDescribe(filterRule.Object__r.QualifiedApiName).getSObjectType();
        this.field = UTIL_Describe.getFieldDescribe(filterRule.Object__r.QualifiedApiName, filterRule.Field__r.QualifiedApiName).getSObjectField();
        this.constant = filterRule.Constant__c;
        this.operation = CMT_FilterRuleUI_SVC.getFilterOperationFromString(filterRule.Operator__c);

        if (field.getDescribe().getSOAPType() == SoapType.DATETIME && constant != null &&
                constant.length() == 10 && !CMT_FilterRule.validDateConstants.contains(constant)) {
            // If the field is a datetime type, and the constant is a date format (YYYY-DD-MM) then use
            // DATE comparison class rather than the date time comparison class

            this.compare = (ICompare) converters.get(SoapType.DATE).newInstance();

        } else if (filterRule.Field__r.QualifiedApiName == 'RecordTypeId' && !filterRule.Constant__c.contains(recordTypeIdPrefix)) {
            // If the field is the RecordTypeId AND the value is not an Id, then treat it as Text
            // using RecordType.DeveloperName values
            this.compare = (ICompare) converters.get(SoapType.STRING).newInstance();

        } else {
            this.compare = (ICompare) converters.get(field.getDescribe().getSOAPType()).newInstance();
        }
    }

    /**
     * @description Returns the SObjectType referenced by the current FilterRule instanace
     */
    public SObjectType getObjectType() {
        return this.objectType;
    }

    /**
     * @description Returns a "unique" string that can be used to retrieve a cached version of this result
     * object+field+operation+constant
     */
    public String getCacheKeyPrefix() {
        return (this.objectName + '.' + this.field + '.' + this.operation.name() + '.' + this.constant).toLowerCase();
    }

    /**
     * @description Evaluate the passed SObject record against the current FilterRule instance
     * @param record to evaluate
     * @return True if the record matches and will be included in the roll-up, false otherwise
     */
    public Boolean isIncluded(SObject record) {
        Boolean included = compare.isIncluded(record, this);
        // TODO Remove the debug statements once all testing is finalized
        /*if (!included) {
            System.debug(LoggingLevel.Error, '>>> THIS FAILED  - ' + this.objectType.getDescribe().getName() + '.' +
                    this.field.getDescribe().getName() + ' ' + this.operation + ' ' + this.constant);
        } else {
            System.debug(LoggingLevel.Error, '>>> THIS PASSED - ' + this.objectType.getDescribe().getName() + '.' +
                    this.field.getDescribe().getName() + ' ' + this.operation + ' ' + this.constant);
        }*/
        return included;
    }

    /**
     * @description ICompare interface class used to implement a generic comparison inner class
     */
    private final ICompare compare;
    public interface ICompare {
        Boolean isIncluded(SObject record, CMT_FilterRule rule);
    }

    // ============================================================================================
    // COMPARISON IMPLEMENTATIONS BY SOAPTYPE
    // ============================================================================================

    /**
     * @description Compare implementation for a Boolean data type
     */
    public class CompareBooleans implements ICompare {
        public Boolean isIncluded(SObject record, CMT_FilterRule rule) {
            Boolean fieldValue = (record.get(rule.field) != null ? (Boolean)record.get(rule.field) : false);
            // Note: Boolean.valueOf() will convert anything into a false, even a string that is not true or false
            Boolean compareValue = (String.isNotEmpty(rule.constant) ? Boolean.valueOf(rule.constant) : null);

            if (rule.operation == FilterOperation.EQUALS) {
                return fieldValue == compareValue;
            } else if (rule.operation == FilterOperation.NOT_EQUALS) {
                return fieldValue != compareValue;
            }
            return false;
        }
    }

    /**
     * @description Compare implementation for a Double data type
     */
    public class CompareDoubles implements ICompare {
        public Boolean isIncluded(SObject record, CMT_FilterRule rule) {
            Double fieldValue = (record.get(rule.field) != null ? (Double)record.get(rule.field) : null);
            Double compareValue = (String.isNotEmpty(rule.constant) ? Double.valueOf(rule.constant) : null);

            if (fieldValue == null && compareValue == null) {
                // A null to null comparison is either Equals (true) or false for any other operation
                if (rule.operation == FilterOperation.EQUALS) {
                    return true;
                } else {
                    return false;
                }
            }

            // if the field is null and not comparing to null, then set the field value to zero
            // so the rest of the comparisons work properly
            if (fieldValue == null) {
                fieldValue = 0;
            }

            if (rule.operation == FilterOperation.EQUALS) {
                return fieldValue == compareValue;
            } else if (rule.operation == FilterOperation.NOT_EQUALS) {
                return fieldValue != compareValue;
            } else if (rule.operation == FilterOperation.GREATER) {
                return fieldValue > compareValue;
            } else if (rule.operation == FilterOperation.LESS) {
                return fieldValue < compareValue;
            } else if (rule.operation == FilterOperation.GREATER_OR_EQUAL) {
                return fieldValue >= compareValue;
            } else if (rule.operation == FilterOperation.LESS) {
                return fieldValue < compareValue;
            } else if (rule.operation == FilterOperation.LESS_OR_EQUAL) {
                return fieldValue <= compareValue;
            }
            return false;
        }
    }

    /**
     * @description Compare implementation for a Date data type
     */
    public class CompareDates implements ICompare {
        public Boolean isIncluded(SObject record, CMT_FilterRule rule) {
            Date fieldValue = (record.get(rule.field) != null ? Date.valueOf(record.get(rule.field)) : null);
            String dateConstant = (rule.constant != null && CMT_FilterRule.validDateConstants.contains(rule.constant) ?
                    rule.constant : null);
            Date compareValue = (String.isNotEmpty(rule.constant) && dateConstant == null ? Date.valueOf(rule.constant) : null);

            // If the field is actually a DATETIME field, but it's being compared to a pure date, then
            // some extra processing is needed to convert the date string properly to avoid timezone issues
            try {
                String strField = String.valueOf(record.get(rule.field));
                DateTime dtm = DateTime.valueOfGmt(strField);
                fieldValue = Date.valueOf(dtm.format('YYYY-MM-dd'));
            } catch (Exception ex) {}

            if (fieldValue == null && compareValue == null) {
                // A null to null comparison is either Equals (true) or false for any other operation
                if (rule.operation == FilterOperation.EQUALS) {
                    return true;
                } else {
                    return false;
                }
            } else if (dateConstant != null) {
                return CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATE, fieldValue, dateConstant, rule.operation);
            } else if (rule.operation == FilterOperation.EQUALS) {
                return fieldValue.isSameDay(compareValue); // fieldValue == compareValue;
            } else if (rule.operation == FilterOperation.NOT_EQUALS) {
                return !fieldValue.isSameDay(compareValue);
            } else if (rule.operation == FilterOperation.GREATER) {
                return fieldValue > compareValue;
            } else if (rule.operation == FilterOperation.LESS) {
                return fieldValue < compareValue;
            } else if (rule.operation == FilterOperation.GREATER_OR_EQUAL) {
                return fieldValue >= compareValue;
            } else if (rule.operation == FilterOperation.LESS) {
                return fieldValue < compareValue;
            } else if (rule.operation == FilterOperation.LESS_OR_EQUAL) {
                return fieldValue <= compareValue;
            }
            return false;
        }
    }

    /**
     * @description Compare implementation for a DateTime data type
     */
    public class CompareDateTimes implements ICompare {
        public Boolean isIncluded(SObject record, CMT_FilterRule rule) {
            DateTime fieldValue = (record.get(rule.field) != null ? (DateTime)record.get(rule.field) : null);
            String dateConstant = (String.isNotEmpty(rule.constant) && CMT_FilterRule.validDateConstants.contains(rule.constant) ?
                    rule.constant : null);
            DateTime compareValue = (String.isNotEmpty(rule.constant) && dateConstant == null ? DateTime.valueOf(rule.constant) : null);

            if (fieldValue == null && compareValue == null) {
                // A null to null comparison is either Equals (true) or false for any other operation
                if (rule.operation == FilterOperation.EQUALS) {
                    return true;
                } else {
                    return false;
                }
            } else if (dateConstant != null) {
                return CMT_FilterRuleEvaluation_SVC.compareDateTypeWithConstant(SoapType.DATETIME, fieldValue, dateConstant, rule.operation);
            } else if (rule.operation == FilterOperation.EQUALS) {
                return fieldValue == compareValue;
            } else if (rule.operation == FilterOperation.NOT_EQUALS) {
                return fieldValue != compareValue;
            } else if (rule.operation == FilterOperation.GREATER) {
                return fieldValue > compareValue;
            } else if (rule.operation == FilterOperation.LESS) {
                return fieldValue < compareValue;
            } else if (rule.operation == FilterOperation.GREATER_OR_EQUAL) {
                return fieldValue >= compareValue;
            } else if (rule.operation == FilterOperation.LESS) {
                return fieldValue < compareValue;
            } else if (rule.operation == FilterOperation.LESS_OR_EQUAL) {
                return fieldValue <= compareValue;
            }
            return false;
        }
    }

    /**
     * @description Compare implementation for an Id data type
     */
    public class CompareIds implements ICompare {
        public Boolean isIncluded(SObject record, CMT_FilterRule rule) {
            Id fieldValue = (record.get(rule.field) != null ? (Id)record.get(rule.field) : null);

            if (rule.operation == FilterOperation.EQUALS) {
                Id compareValue = String.isBlank(rule.constant) ? null : Id.valueOf(rule.constant);
                return fieldValue == compareValue;

            } else if (rule.operation == FilterOperation.NOT_EQUALS) {
                Id compareValue = String.isBlank(rule.constant) ? null : Id.valueOf(rule.constant);
                return fieldValue != compareValue;

            } else if (rule.operation == FilterOperation.IN_LIST || rule.operation == FilterOperation.NOT_IN_LIST) {
                // IN and NOT-IN only works with standard text and simple picklist fields
                // It checks to see if the field value is in the liste of entered value(s)
                String compareValue = String.isBlank(rule.constant) ? '' : String.valueOf(rule.constant);

                List<String> selectedValues = compareValue.split(';');
                Boolean found = false;
                for (String compVal : selectedValues) {
                    if (fieldValue != null && fieldValue.equals(compVal.trim())) {
                        found = true;
                        break;
                    }
                }

                if (rule.operation == FilterOperation.IN_LIST) {
                    return found;
                } else {
                    return !found;
                }
            }

            return false;
        }
    }

    /**
     * @description Compare implementation for a String data type
     */
    public class CompareStrings implements ICompare {
        public Boolean isIncluded(SObject record, CMT_FilterRule rule) {
            String fieldValue = (record.get(rule.field) != null ? (String)record.get(rule.field) : null);
            String compareValue = (String.isNotEmpty(rule.constant) ? String.valueOf(rule.constant) : null);

            // If the field is the RecordTypeId AND the value is not an Id, then treat it as Text
            // using RecordType.DeveloperName values
            if (rule.field.getDescribe().getName() == 'RecordTypeId' && !compareValue.contains(recordTypeIdPrefix)) {
                if (record.getSObject('RecordType') != null) {
                    fieldValue = (String) record.getSObject('RecordType').get('DeveloperName');
                }
            }

            if (fieldValue == null && compareValue == null) {
                // A null to null comparison is true for Equals/StartsWith/Contains or false for any other operation
                if (rule.operation == FilterOperation.EQUALS || rule.operation == FilterOperation.STARTS_WITH || rule.operation == FilterOperation.CONTAINS) {
                    return true;
                } else {
                    return false;
                }

            } else if (fieldValue == null && (rule.operation == FilterOperation.DOES_NOT_CONTAIN
                    || rule.operation == FilterOperation.NOT_IN_LIST || rule.operation == FilterOperation.IS_NOT_INCLUDED)) {
                // If the field value is null value and the operation is one of these exclusionary types, then
                // always return true (i.e. passed)
                return true;

            } else if (fieldValue == null && (rule.operation == FilterOperation.CONTAINS
                    || rule.operation == FilterOperation.STARTS_WITH || rule.operation == FilterOperation.IS_INCLUDED)) {
                // If the field value is null value and the operation is one of these inclusion types, then
                // always return false (i.e. not-passed)
                return false;

            } else if (rule.operation == FilterOperation.EQUALS) {
                return fieldValue == compareValue;

            } else if (rule.operation == FilterOperation.NOT_EQUALS) {
                return fieldValue != compareValue;

            } else if (rule.operation == FilterOperation.STARTS_WITH) {
                compareValue = (compareValue == null ? '' : compareValue);
                return fieldValue.startsWithIgnoreCase(compareValue);

            } else if (rule.operation == FilterOperation.CONTAINS) {
                compareValue = (compareValue == null ? '' : compareValue);
                return fieldValue.containsIgnoreCase(compareValue);

            } else if (rule.operation == FilterOperation.DOES_NOT_CONTAIN) {
                compareValue = (compareValue == null ? '' : compareValue);
                return !fieldValue.containsIgnoreCase(compareValue);

            } else if (rule.operation == FilterOperation.IS_INCLUDED || rule.operation == FilterOperation.IS_NOT_INCLUDED) {
                // Included only works with Multi-Select picklist fields
                // It checks to see if the entered value(s) are in the list of picklist values in the field
                compareValue = (compareValue == null ? '' : compareValue);

                List<String> selectedValues = compareValue.split(';');
                List<String> fieldValues = fieldValue.split(';');
                Boolean isIncluded = false;
                for (String fldVal : fieldValues) {
                    for (String compVal : selectedValues) {
                        if (fldVal.equalsIgnoreCase(compVal.trim())) {
                            isIncluded = true;
                            break;
                        }
                    }
                }

                if (rule.operation == FilterOperation.IS_INCLUDED) {
                    return isIncluded;
                } else {
                    return !isIncluded;
                }

            } else if (rule.operation == FilterOperation.IN_LIST || rule.operation == FilterOperation.NOT_IN_LIST) {
                // IN and NOT-IN only works with standard text and simple picklist fields
                // It checks to see if the field value is in the liste of entered value(s)
                compareValue = (compareValue == null ? '' : compareValue);

                List<String> selectedValues = compareValue.split(';');
                Boolean found = false;
                for (String compVal : selectedValues) {
                    if (fieldValue != null && fieldValue.equalsIgnoreCase(compVal.trim())) {
                        found = true;
                        break;
                    }
                }

                if (rule.operation == FilterOperation.IN_LIST) {
                    return found;
                } else {
                    return !found;
                }
            }

            return false;
        }
    }

}