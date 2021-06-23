/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Utilities
* @description Simple Field Mapper for identifying identically named,
*              compatible Fields.  Identifies overlapping fields
*              between two SObjects types for the purpose of
*              copying between them
*
*/
public with sharing class UTIL_SimpleFieldMapper {

    /** @description Exception Class for problems that occur during runtime use */
    public class SimpleFieldMapperException extends Exception {}

    /** @description SObjectType for the Source Object to determine overlapping fields from */
    @testVisible private Schema.SObjectType sourceSObjectType;

    /** @description Source fields map for the Source Object */
    @testVisible private Map<String, Schema.SObjectField> sourceFields;

    /** @description SObjectType for the Target Object to determine overlapping fields from */
    @testVisible private Schema.SObjectType targetSObjectType;

    /** @description Target fields map for the Target Object */
    @testVisible private Map<String, Schema.SObjectField> targetFields;

    /** @description Set of API FieldNames to exclude from the resulting Set of overlapping fields.
                     By default, this includes any standard fields that should not be mapped
                     by this process */
    @testVisible private Set<String> fieldsToExclude = new Set<String> {
        'Id',
        'Name',
        'RecordType',
        'CreatedById',
        'CreatedDate',
        'IsDeleted',
        'LastModifiedById',
        'LastModifiedDate'
    };
    // TODO: Confirm list of default fieldsToExclude values is sufficient

    /** @description Boolean indicating whether or not to include standard fields.  The default is false. */
    private Boolean includeStandardFields = false;
    // TODO: Expose this setting for update.  Requires more testing, etc.  For now, leaving false so only
    //       Custom fields can be mapped.

    /** @description Boolean indicates whether or not it will return fields of the same name if the target
                     type is String, and the source type is something else.  This requires additional
                     handling, and is not enabled by default. */
    @testVisible private Boolean includeAnySoapTypeToString = false;

    /*********************************************************************************************************
    * @description The constructor
    * @param sourceSObjectType The Source Mapping Object's SObjectType
    * @aram targetSObjectType The Target Mapping Object's SObjectType
    */
    @testVisible private UTIL_SimpleFieldMapper(SObjectType sourceSObjectType, SObjectType targetSObjectType) {
        this.sourceSObjectType = sourceSObjectType;
        this.targetSObjectType = targetSObjectType;
    }

    /*********************************************************************************************************
    * @description Factory method responsible for creating new UTIL_SimpleFieldMapper classes.
    * @param sourceSObjectType The Source Mapping Object's SObjectType
    * @aram targetSObjectType The Target Mapping Object's SObjectType
    */
    public static UTIL_SimpleFieldMapper getInstanceOf(SObjectType sourceSObjectType, SObjectType targetSObjectType) {
        return new UTIL_SimpleFieldMapper(sourceSObjectType, targetSObjectType);
    }

    /*********************************************************************************************************
    * @description Indicates whether the mapper should include any field type to String mappings, or to be
    *              more restrictive in this mapping.  Note:  Additional conversion handling is required if
    *              set to true.  The default is false
    * @param includeAnySoapTypeToString If true, will include all matched mappings to text fields
    * @return UTIL_SimpleFieldMapper Current instance of the Simple Field Mapper
    */
    public UTIL_SimpleFieldMapper withIncludeAnySoapTypeToString(Boolean includeAnySoapTypeToString) {
        this.includeAnySoapTypeToString = includeAnySoapTypeToString;

        return this;
    }

    /*********************************************************************************************************
    * @description The set of field API Names to exclude from mapping even if they overlap both objects.
    *              Note: Fields values to exlude are ignored if they are not present in either the Source
    *              or Target Object
    * @param additionalFieldsToExclude The additional fields to exclude from the process
    * @return UTIL_SimpleFieldMapper Current instance of the Simple Field Mapper
    */
    public UTIL_SimpleFieldMapper withAdditionalFieldsToExclude(Set<String> additionalFieldsToExclude) {

        for (String fieldToExclude : additionalFieldsToExclude) {
            if (getSourceFields().containsKey(fieldToExclude) || getTargetFields().containsKey(fieldToExclude)) { // Must be present in either Source or Target to be added to fieldsToExclude Set
                this.fieldsToExclude.add(fieldToExclude.toLowerCase());
            }
        }
        return this;
    }

    /*********************************************************************************************************
    * @description Returns a populated map of Source fields for the Source Mapping Object.
    *              Note: Lazy, onetime initialization is used
    * @return Populated fields Map for Source Mapping Object
    */
    @testVisible private Map<String, Schema.SObjectField> getSourceFields() {
        if (this.sourceFields == null) {
            this.sourceFields = sourceSObjectType.getDescribe().fields.getMap();
        }
        return this.sourceFields;
    }

    /*********************************************************************************************************
    * @description Returns a populated map of Target fields for the Target Mapping Object.
    *              Note: Lazy, onetime initialization is used
    * @return Populated fields Map for Target Mapping Object
    */
    @testVisible private Map<String, Schema.SObjectField> getTargetFields() {
        if (this.targetFields == null) {
            this.targetFields = targetSObjectType.getDescribe().fields.getMap();
        }
        return this.targetFields;
    }

    /*********************************************************************************************************
    * @description Determines the Set of Mappable Fields for the two objects, filtering out
    *              any that are incompatible, as well as ignoring ones that are present in the
    *              fieldsToExclude set.  Note: Fields must be present with identical API names to
    *              match, including the namespace prefix.
    * @return Populated Set of Mappable fields for the Source and Target Object Types
    */
    public Set<String> determineMappableFields() {
        Set<String> mappableFields = new Set<String>();
        Set<String> candidateFields = new Set<String>();

        // Will use whichever SObjectType has less fields to iterate over
        Map<String, Schema.SObjectField> fieldsForReview = (getSourceFields().size() > getTargetFields().size()) ? getSourceFields() : getTargetFields();

        for (String fieldForReview :fieldsForReview.keySet()) {
            String candidateField = fieldForReview.toLowerCase();

            if (this.fieldsToExclude.contains(candidateField)) { // Skip this field
                continue;
            }

            Schema.SObjectField targetField = getTargetFields().get(candidateField);
            Schema.SObjectField sourceField = getSourceFields().get(candidateField);

            if (sourceField == null || targetField == null) { // Not a potential match
                continue;
            }

            if (isFieldCandidateForMapping(candidateField, targetField, false)) {
                candidateFields.add(candidateField);
            }
        }

        // Check if candidate fields are compatible and then add to mappableFields Set
        for (String candidateField : candidateFields) {
            Schema.SObjectField sourceField = sourceFields.get(candidateField);
            Schema.SObjectField targetField = targetFields.get(candidateField);

            if (isCompatibleFieldMapping(sourceField, targetField)) {
                mappableFields.add(candidateField);
            }
        }

        return mappableFields;
    }

    /*********************************************************************************************************
    * @description Checks to see if the field is a type that is allowed to be mapped.
    * @return Boolean true, if it can potentially be mapped.
    */
    @testVisible private Boolean isFieldCandidateForMapping(String fieldName, Schema.SObjectField soField, Boolean includeFormulaFields) {
            String fieldNameVal = fieldName.toLowerCase();

            Schema.DescribeFieldResult fieldDescribe = soField.getDescribe();

            if (!this.includeStandardFields && !fieldDescribe.isCustom()) { // Only Custom Fields
                return false;
            }

            if (fieldDescribe.isCalculated() && !includeFormulaFields) { // Not Mapping formula fields
                return false;
            }

            return true;
    }

    /*********************************************************************************************************
    * @description Checks to see if the source and target fields are compatible
    * @param sourceField Field from Source Object
    * @param targetField Field from Target Object
    * @return Boolean true, if the fields can be mapped.
    */
    @testVisible private Boolean isCompatibleFieldMapping(Schema.SObjectField sourceField, Schema.SObjectField targetField) {

        Map<Schema.DisplayType, Set<Schema.DisplayType>> validFieldMappingCombinations = new Map<Schema.DisplayType, Set<Schema.DisplayType>> {
            Schema.DisplayType.STRING => new Set<Schema.DisplayType> {Schema.DisplayType.PICKLIST, Schema.DisplayType.MULTIPICKLIST, Schema.Displaytype.URL},
            // TODO: Add additional checks for additional compatible types TBD
            Schema.DisplayType.Picklist => new Set<Schema.DisplayType> {Schema.DisplayType.STRING},
            Schema.DisplayType.MultiPicklist => new Set<Schema.DisplayType> {Schema.DisplayType.STRING},
            Schema.DisplayType.Phone => new Set<Schema.DisplayType> {Schema.DisplayType.STRING},
            Schema.DisplayType.Email => new Set<Schema.DisplayType> {Schema.DisplayType.STRING}
        };

        Schema.DescribeFieldResult  targetFieldDescribe = targetField.getDescribe();
        Schema.DescribeFieldResult sourceFieldDescribe = sourceField.getDescribe();

        if (sourceFieldDescribe.getType() == Schema.DisplayType.EncryptedString) { // Not allowing mapping of Encrypted fields
            return false;
        }

        // Check that Source Field not larger than 255 characters
        if (sourceFieldDescribe.getLength() > 255) { // Not Mapping larger fields
            return false;
        }

        // Lookup fields require additional checks (to make sure the source and destination refer to the same object(s))
        if (sourceFieldDescribe.getType() == Schema.DisplayType.REFERENCE && targetFieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
            Set<Schema.SObjectType> srcReferences = new Set<Schema.SObjectType>(sourceFieldDescribe.getReferenceTo());
            Set<Schema.SObjectType> targetReferences = new Set<Schema.SObjectType>(targetFieldDescribe.getReferenceTo());

            // Probably could have done a single value compare of element 0, but this handles the exception case when the Reference field is overloaded for multiple objects.
            // To be compatible src and target have all the same object references.  If they are not, it will not automap this field
            return (srcReferences.containsAll(targetReferences) && targetReferences.containsAll(srcReferences));

        }

        // Check if the source and target are compatible types
        if (targetFieldDescribe.getSoapType() == sourceFieldDescribe.getSoapType()) { // If target type is same as source type, can map
            return true;
        }

        // Check to see if it is a type we can allow even if types do not precisely match.
        if (validFieldMappingCombinations.containsKey(sourceFieldDescribe.getType())) {
            Set<Schema.DisplayType> validDestinationFieldTypes = validFieldMappingCombinations.get(sourceFieldDescribe.getType());
            if (validDestinationFieldTypes.contains(targetFieldDescribe.getType())) {
                return true;
            }
        }

        // Requires additional handling to convert value from its type to text so requires special enablement
        if (includeAnySoapTypeToString && targetFieldDescribe.getSoapType() == Schema.SoapType.STRING) { // If target type is String, can map
            return true;
        }

        return false;
    }

}