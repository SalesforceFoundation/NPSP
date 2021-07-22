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

    /**
     * @description Converts the enum strings into api name for picklist values. The Enum value
     * and the String label should exactly match the picklist values in the Filter_Rule__mdt.Operation__c field
     */
    public static Map<CMT_FilterRule.FilterOperation, String> getFilterOperations() {
        return new Map<CMT_FilterRule.FilterOperation, String>{
                CMT_FilterRule.FilterOperation.Equals => 'Equals',
                CMT_FilterRule.FilterOperation.Not_Equals => 'Not_Equals',
                CMT_FilterRule.FilterOperation.Greater => 'Greater Than',
                CMT_FilterRule.FilterOperation.Less => 'Less Than',
                CMT_FilterRule.FilterOperation.Greater_or_Equal => 'Greater_or_Equal',
                CMT_FilterRule.FilterOperation.Less_or_Equal => 'Less_or_Equal',
                CMT_FilterRule.FilterOperation.Starts_With => 'Starts_With',
                CMT_FilterRule.FilterOperation.Contains => 'Contains',
                CMT_FilterRule.FilterOperation.Does_Not_Contain => 'Does_Not_Contain',
                CMT_FilterRule.FilterOperation.In_List => 'In_List',
                CMT_FilterRule.FilterOperation.Not_In_List => 'Not_In_List',
                CMT_FilterRule.FilterOperation.Is_Included => 'Is_Included',
                CMT_FilterRule.FilterOperation.Is_Not_Included => 'Is_Not_Included'
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
}