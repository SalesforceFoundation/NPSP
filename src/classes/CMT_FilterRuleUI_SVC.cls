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
* @description Service Class for Filter Rules as it pertains the custom User Interface where Filter Rules are maintained
*/
public class CMT_FilterRuleUI_SVC {

    // ============================================================================================
    // STATIC METHODS FOR HANDLING UI INTERACTION AND OVERALL PROCESSING
    // ============================================================================================

    /**
     * @description Converts the enum strings into friendly strings for the pick-lists. The Enum value
     * and the String label should exactly match the picklist values in the Filter_Rule__mdt.Operation__c field
     */
    public static Map<CMT_FilterRule.FilterOperation, String> getFilterOperations() {
        return new Map<CMT_FilterRule.FilterOperation, String>{
                CMT_FilterRule.FilterOperation.EQUALS => 'Equals',
                CMT_FilterRule.FilterOperation.NOT_EQUALS => 'Not Equals',
                CMT_FilterRule.FilterOperation.GREATER => 'Greater',
                CMT_FilterRule.FilterOperation.LESS => 'Less',
                CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL => 'Greater or Equals',
                CMT_FilterRule.FilterOperation.LESS_OR_EQUAL => 'Less or Equals',
                CMT_FilterRule.FilterOperation.STARTS_WITH => 'Starts With',
                CMT_FilterRule.FilterOperation.CONTAINS => 'Contains',
                CMT_FilterRule.FilterOperation.DOES_NOT_CONTAIN => 'Does Not Contain',
                CMT_FilterRule.FilterOperation.IN_LIST => 'In',
                CMT_FilterRule.FilterOperation.NOT_IN_LIST => 'Not In',
                CMT_FilterRule.FilterOperation.IS_INCLUDED => 'Included',
                CMT_FilterRule.FilterOperation.IS_NOT_INCLUDED => 'Not Included'
        };
    }

    /**
     * @description Converts the picklist value for Operation into a CMT_FilterRule.FilterOperation enum
     * @param operation name (CMT_FilterRule.FilterOperation.name())
     * @return CMT_FilterRule.FilterOperation enum
     */
    public static CMT_FilterRule.FilterOperation getFilterOperationFromString(String operation) {
        for (CMT_FilterRule.FilterOperation fo : getFilterOperations().keySet()) {
            if (fo.name() == operation) {
                return fo;
            }
        }
        return null;
    }

    /**
     * @description Build a SelectOption list of all visible fields in the specified object.
     * @param objType Object Type
     * @return SelectOption list is grouped by Standard and then Custom fields, sorted alphabetically within each group
     */
    public static List<SelectOption> getAvailableFields(SObjectType objType) {
        Map<String, Schema.DescribeFieldResult> allFields = UTIL_Describe.getAllFieldsDescribe(objType.getDescribe().getName());
        Set<String> ignoreTheseFields = new Set<String>{'IsDeleted', 'SystemModstamp'};
        List<String> fieldsForSort = new List<String>(allFields.keySet());
        fieldsForSort.sort();

        List<SelectOption> options = new List<SelectOption>();
        for (String category : new List<String>{'Standard Fields', 'Custom Fields'}) {
            options.add(new SelectOption('', category, true));
            for (String fldName : fieldsForSort) {
                DescribeFieldResult fld = allFields.get(fldName);
                // Ignore fields that are not accessible, not an Id Lookup to another object,
                // not deprecated, and not of type TIME, BLOB, LOCATION or ADDRESS
                if (fld.isAccessible() && !fld.isIdLookup() && !fld.isDeprecatedAndHidden() &&
                        fld.getType() != DisplayType.TIME && fld.getType() != DisplayType.BASE64 &&
                        fld.getType() != DisplayType.LOCATION && fld.getType() != DisplayType.ADDRESS &&
                        !ignoreTheseFields.contains(fld.getName()) &&
                        (category == 'Standard Fields' && !fld.isCustom()) || category == 'Custom Fields' && fld.isCustom()) {
                    options.add(new SelectOption(fld.getName(), fld.getLabel()));
                }
            }
        }
        return options;
    }

    /**
     * @description Build a SelectOption list of valid operations based on the field type.
     * @param objectName Object Name
     * @param fieldName Field Name`
     */
    public static List<SelectOption> getAvailableOperations(String objectName, String fieldName) {
        Map<CMT_FilterRule.FilterOperation, String> filterOps = getFilterOperations();
        Schema.DisplayType fldType = UTIL_Describe.getFieldDisplaytype(objectName, fieldName);

        List<SelectOption> options = new List<SelectOption>();
        if (fldType == Schema.DisplayType.BOOLEAN) {

            // Boolean fields only support Equals and Not Equals
            options.add(new SelectOption(CMT_FilterRule.FilterOperation.EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.EQUALS)));
            options.add(new SelectOption(CMT_FilterRule.FilterOperation.NOT_EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.NOT_EQUALS)));

        } else if (fldType == Schema.DisplayType.Reference) {

            // Id fields support Equals and Not Equals, IN and Not In
            options.add(new SelectOption(CMT_FilterRule.FilterOperation.EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.EQUALS) ));
            options.add(new SelectOption(CMT_FilterRule.FilterOperation.NOT_EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.NOT_EQUALS) ));
            options.add(new SelectOption(CMT_FilterRule.FilterOperation.IN_LIST.name(), filterOps.get(CMT_FilterRule.FilterOperation.IN_LIST)));
            options.add(new SelectOption(CMT_FilterRule.FilterOperation.NOT_IN_LIST.name(), filterOps.get(CMT_FilterRule.FilterOperation.NOT_IN_LIST)));

        } else if (fldType == Schema.DisplayType.DATE || fldType == Schema.DisplayType.DATETIME || fldType == Schema.DisplayType.TIME
            || fldType == Schema.DisplayType.DOUBLE || fldType == Schema.DisplayType.INTEGER || fldType == Schema.DisplayType.CURRENCY
            || fldType == Schema.DisplayType.PERCENT) {

            // Date, Time and Number fields support Equals, NotEquals, Greater, Less and variations of
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.EQUALS) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.NOT_EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.NOT_EQUALS) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.GREATER.name(), filterOps.get(CMT_FilterRule.FilterOperation.GREATER) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL.name(), filterOps.get(CMT_FilterRule.FilterOperation.GREATER_OR_EQUAL) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.LESS.name(), filterOps.get(CMT_FilterRule.FilterOperation.LESS) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.LESS_OR_EQUAL.name(), filterOps.get(CMT_FilterRule.FilterOperation.LESS_OR_EQUAL) ));

        } else {

            options.add( new SelectOption(CMT_FilterRule.FilterOperation.EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.EQUALS) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.NOT_EQUALS.name(), filterOps.get(CMT_FilterRule.FilterOperation.NOT_EQUALS) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.STARTS_WITH.name(), filterOps.get(CMT_FilterRule.FilterOperation.STARTS_WITH) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.CONTAINS.name(), filterOps.get(CMT_FilterRule.FilterOperation.CONTAINS) ));
            options.add( new SelectOption(CMT_FilterRule.FilterOperation.DOES_NOT_CONTAIN.name(), filterOps.get(CMT_FilterRule.FilterOperation.DOES_NOT_CONTAIN) ));

            // Multi-Select Pick-Lists use "Included" and "Not Included", while all other non-blob text fields
            // can use "In" and "Not In"
            if (fldType == Schema.DisplayType.MULTIPICKLIST) {
                options.add(new SelectOption(CMT_FilterRule.FilterOperation.IS_INCLUDED.name(), filterOps.get(CMT_FilterRule.FilterOperation.IS_INCLUDED)));
                options.add(new SelectOption(CMT_FilterRule.FilterOperation.IS_NOT_INCLUDED.name(), filterOps.get(CMT_FilterRule.FilterOperation.IS_NOT_INCLUDED)));
            } else if (fldType != Schema.DisplayType.TEXTAREA) {
                options.add(new SelectOption(CMT_FilterRule.FilterOperation.IN_LIST.name(), filterOps.get(CMT_FilterRule.FilterOperation.IN_LIST)));
                options.add(new SelectOption(CMT_FilterRule.FilterOperation.NOT_IN_LIST.name(), filterOps.get(CMT_FilterRule.FilterOperation.NOT_IN_LIST)));
            }
        }

        return options;
    }

    /**
     * @description Given a specific field and operation, validates that the comparison value string is valid.
     * For example, a valueString of “xyz” would not be a valid comparison for a Date field. This does not need
     * to validate the Operation for the SObjectField because the the UI should enforce only valid operation types
     * using the above getAvailableOperations() method.
     * @param fld SObjectField
     * @param operation FilterOperation
     * @param value entered value
     * @return True if the operation and value are valid for the given field
     */
    public static Boolean validateFilterValue(SObjectField fld, CMT_FilterRule.FilterOperation operation, String value) {

        // if the comparison value is 'null' then the only valid operations are Equals or Not Equals
        if (value == null) {
            if (operation != CMT_FilterRule.FilterOperation.EQUALS && operation != CMT_FilterRule.FilterOperation.NOT_EQUALS) {
                return false;
            } else {
                return true;
            }
        }

        Schema.SoapType fldType = fld.getDescribe().getSoapType();
        if (fldType == SoapType.DATETIME) {
            if (CMT_FilterRule.validDateConstants.contains(value)) {
                return true;
            } else if (value.length() == 10) {
                try {
                    Date dt = Date.valueOf(value);
                    return true;
                } catch (Exception ex) {
                    // The date format is not recognized
                }
            } else {
                try {
                    DateTime dt = DateTime.valueOf(value);
                    return true;
                } catch (Exception ex) {
                    // The datetime format is not recognized
                }
            }

        } else if (fldType == SoapType.DATE) {
            if (CMT_FilterRule.validDateConstants.contains(value)) {
                return true;
            } else {
                try {
                    Date dt = Date.valueOf(value);
                    return true;
                } catch (Exception ex) {
                    // The date format is not recognized
                }
            }

        } else if (fldType == SoapType.DOUBLE || fldType == SoapType.INTEGER) {
            try {
                Double dblValue = Double.valueOf(value);
                return true;
            } catch (Exception ex) {
                // The number format is not recognized
            }

        } else if (fldType == SoapType.BOOLEAN) {
            if (value == null || value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
                return true;
            }

        } else if (fldType == SoapType.ID) {
            try {
                // Id's can be a single value or a semi-colon separated list of Id's
                for (String v : value.split(';')) {
                    Id dblValue = Id.valueOf(v);
                }
                return true;
            } catch (Exception ex) {
                // The Id format is not recognized
            }
        }

        return false;
    }
}