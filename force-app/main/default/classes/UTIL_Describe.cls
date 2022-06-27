/*
    Copyright (c) 2014 Salesforce.org
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
/**
* @author Salesforce.org
* @date 2014
* @group Utilities
* @description This class allows easy access to object and field description information from within other classes.
*
* It is called statically, and therefore will supply the same information to all calls made from
* within one transaction, or set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient.
*/

public class UTIL_Describe {

    // throw custom exceptions when a bogus object or field is provided.
    public class SchemaDescribeException extends Exception {}

    // maps to hold the describe info
    private static Map<String, Schema.SObjectType> gd;
    private static Map<String, Schema.DescribeSObjectResult> objectDescribes = new Map<String, Schema.DescribeSObjectResult>();
    private static Map<Schema.SObjectType, Schema.DescribeSObjectResult> objectDescribesByType = new Map<Schema.SObjectType, Schema.DescribeSObjectResult>();
    private static Map<String, Map<String, Schema.SObjectField>> fieldTokens = new Map<String,Map<String, Schema.SObjectField>>();
    private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldDescribes = new Map<String,Map<String, Schema.DescribeFieldResult>>();
    private static UTIL_Describe utilDescribeInstance;
    private static Map<Schema.SObjectField, Map<String, String>> picklistTranslations = new Map<Schema.SObjectField, Map<String, String>>();

    /**
    * @description Returns static instance of this class.  Primarily used to facilitate
    * dependency injection in tests.
    * @return Instance of UTIL_Describe class.
    */
    public static UTIL_Describe getInstance(){
        if (utilDescribeInstance == null) {
            utilDescribeInstance = new UTIL_Describe();
        }
        return utilDescribeInstance;
    }

    /**
    * @description Sets instance member variable holding instance of this class.  Primarily
    * used to facilitate dependency injection in tests.
    * @param utilDescribe An instance of the UTIL_Describe
    * class.
    */
    @TestVisible
    private static void setInstance(UTIL_Describe utilDescribe){
        utilDescribeInstance = utilDescribe;
    }

    /*******************************************************************************************************
    * @description Map display types to a friendly user-readable label.
    */
    private static final Map<String, String> LABELS_BY_DISPLAY_TYPE = new Map<String, String> {
        'ADDRESS' => 'Address',
        'BASE64' => 'Base64',
        'BOOLEAN' => 'Checkbox',
        'COMBOBOX' => 'Picklist',
        'CURRENCY' => 'Currency',
        'DATACATEGORYGROUPREFERENCE' => 'DataCategoryGroupReference',
        'DATE' => 'Date',
        'DATETIME' => 'Date/Time',
        'DOUBLE' => 'Number',
        'EMAIL' => 'Email',
        'ENCRYPTEDSTRING' => 'Text (Encrypted)',
        'ID' => 'Id',
        'INTEGER' => 'Number',
        'LONG' => 'Text Area (Long)',
        'MULTIPICKLIST' => 'Picklist (Multi-Select)',
        'PERCENT' => 'Percent',
        'PHONE' => 'Phone',
        'PICKLIST' => 'Picklist',
        'REFERENCE' => 'Lookup Relationship',
        'STRING' => 'Text',
        'TEXTAREA' => 'Text Area',
        'TIME' => 'Time',
        'URL' => 'URL'
    };

    /*******************************************
    * Gets describe maps for a new object
    ********************************************/
    static void fillMapsForObject(String objectName) {
        objectName = objectName.toLowerCase();

        // get the object map the first time
        if (gd == null) {
            gd = Schema.getGlobalDescribe();
        }

        // get the object description
        if (gd.containsKey(objectName)) {
            if (!objectDescribes.containsKey(objectName)) {
                Schema.DescribeSObjectResult objDescribe = gd.get(objectName).getDescribe();
                objectDescribes.put(objectName, objDescribe);
                objectDescribesByType.put(objDescribe.getSObjectType(), objDescribe);
            }
        } else {
            throw new SchemaDescribeException('Invalid object name \'' + objectName + '\'');
        }
    }

    /*******************************************
    * Gets a field map for a new object/field pair
    ********************************************/
    private static void fillFieldMapsForObject(String objectName, String fieldName) {
        // get the object map the first time
        fillMapsForObject(objectName);

        // get the field description
        if (!fieldTokens.containsKey(objectName)) {
            fieldTokens.put(objectName, objectDescribes.get(objectName).fields.getMap());
            fieldDescribes.put(objectName, new Map<String, Schema.DescribeFieldResult>());
        }
        if (!fieldDescribes.get(objectName).containsKey(fieldName)) {
            if (fieldTokens.get(objectName).containsKey(fieldName)) {
                Schema.DescribeFieldResult dfr = fieldTokens.get(objectName).get(fieldName).getDescribe();
                fieldDescribes.get(objectName).put(fieldName, dfr);
            } else {
                throw new SchemaDescribeException('Invalid field name \'' + fieldName + '\'');
            }
        }
    }

    /*******************************************
    * Gets all field maps for a new object
    ********************************************/
    static void fillFieldMapsForObject(String objectName) {
        objectName = objectName.toLowerCase();

        // get the object map the first time
        fillMapsForObject(objectName);

        // get the field description
        if (!fieldTokens.containsKey(objectName)) {
            fieldTokens.put(objectName, objectDescribes.get(objectName).fields.getMap());
            fieldDescribes.put(objectName, new Map<String, Schema.DescribeFieldResult>());
        }

        //Map<String, Schema.SObjectField> fieldsMap = objectDescribes.get(objectName).fields.getMap();
        if (fieldTokens.get(objectName).size() != fieldDescribes.get(objectName).size()) {
            for ( String fieldName : fieldTokens.get(objectName).keySet()) {
                if (!fieldDescribes.get(objectName).containsKey(fieldName)) {
                    Schema.DescribeFieldResult dfr = fieldTokens.get(objectName).get(fieldName).getDescribe();
                    fieldDescribes.get(objectName).put(fieldName, dfr);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Returns new object of given type.
    * @param objectName the name of the object to create
    * @return the new SObject
    */
    public static SObject getPrototypeObject(String objectName) {
        objectName = objectName.toLowerCase();
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) {
            fillMapsForObject(objectName);
        }

        return gd.get(objectName).newSObject();
    }

    /*******************************************************************************************************
    * @description Returns object friendly name.
    * @param objectName the name of the object to lookup
    * @return the Label of the object
    */
    public static String getObjectLabel(String objectName) {
        objectName = objectName.toLowerCase();
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) {
            fillMapsForObject(objectName);
        }

        return objectDescribes.get(objectName).getLabel();
    }

    public static String getObjectLabelPlural(String objectName) {
        objectName = objectName.toLowerCase();
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) {
            fillMapsForObject(objectName);
        }

        return objectDescribes.get(objectName).getLabelPlural();
    }

    /*******************************************************************************************************
    * @description Returns object describe data.
    * @param objectName the name of the object to lookup
    * @return Schema.DescribeSObjectResult of the object
    */
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        objectName = objectName.toLowerCase();
        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) {
            fillMapsForObject(objectName);
        }

        return objectDescribes.get(objectName);
    }

    /*******************************************************************************************************
    * @description Returns object describe data.
    * @param objType the SObjectType of the object to lookup
    * @return Schema.DescribeSObjectResult of the object
    */
    public static Schema.DescribeSObjectResult getObjectDescribe(SObjectType objType) {
        // make sure we have this object's schema mapped
        if (objectDescribesByType == null || !objectDescribesByType.containsKey(objType)) {
            fillMapsForObject(objType.getDescribe().getName());
        }

        return objectDescribesByType.get(objType);
    }

    /*******************************************************************************************************
    * @description Returns object describe data.
    * @param objType the SObjectType of the object to lookup
    * @return Schema.DescribeSObjectResult of the object
    */
    public Schema.DescribeSObjectResult getObjectDescribeInstance(SObjectType objType) {
        return getObjectDescribe(objType);
    }

    /*******************************************************************************************************
    * @description Compares Id to verify object type
    * @param salesforceId of the object
    * @param objectName name of the sobject to compare with
    * @return true if the Id is for the given object type, false otherwise.
    */
    public static Boolean isObjectIdThisType(Id salesforceId, String objectName) {
        objectName = objectName.toLowerCase();

        // make sure we have this object's schema mapped
        if (!objectDescribes.containsKey(objectName)) {
            fillMapsForObject(objectName);
        }

        // now grab the requested id prefix
        Boolean ret = false;
        if (salesforceId != null) {
            String prefix = objectDescribes.get(objectName).getKeyPrefix();
            if (prefix != null) {
                ret = ((String) (salesforceId)).startsWith(prefix);
            }
        }
        return ret;
    }

    public static String objectNameFromId(Id objectId) {
        return objectId.getSobjectType().getDescribe().getName();
    }

    /*******************************************************************************************************
    * @description Returns all field describe data
    * @param objectName the name of the object to look up
    * @return Map<String, Schema.DescribeFieldResult> a map of field api names to describe file results.
    */
    public static Map<String, Schema.DescribeFieldResult> getAllFieldsDescribe(String objectName) {
        objectName = objectName.toLowerCase();

        // make sure we have this object's schema mapped
        fillFieldMapsForObject(objectName);

        Map<String, Schema.DescribeFieldResult> fieldMap = fieldDescribes.get(objectName);
        return fieldMap;
    }

    /*******************************************************************************************************
    * @description Returns the Name field of any given object.
    * @param objectName the name of the object to look up
    * @return String the API name of the Name field
    */
    public static String getNameField(String objectName) {
        String nameField = 'Name';
        objectName = objectName.toLowerCase();

        Map<String, Schema.DescribeFieldResult> mapObjectFields = getAllFieldsDescribe(objectName);

        if (!mapObjectFields.containsKey(nameField)) {
            nameField = null;
            for (String relatedFieldName : mapObjectFields.keySet()) {
                if (mapObjectFields.get(relatedFieldName).isNameField()) {
                    return relatedFieldName;
                }
            }
        }

        return nameField;
    }

    /*******************************************************************************************************
     * @description Provides the field used to retrieve the name of the related record for
     *              a lookup when querying the child record.
     * @return The dot-notation field name to use in SOQL queries for the field
     *          represented by the arguments. Ex: Account.Name, Case.CaseNumber,
     *          CustomObject__r.Name.
     *
     */
    public static String getReferenceObjectNameField(SObjectField field) {
        List<SObjectType> relatedObjects = field.getDescribe().getReferenceTo();
        if (relatedObjects.isEmpty()) {
            return null;
        }

        String childFieldName = String.valueOf(field);
        if (childFieldName.endsWithIgnoreCase('__c')) {
            childFieldName = childFieldName.removeEndIgnoreCase('c') + 'r';
        } else if (childFieldName.endsWithIgnoreCase('Id')) {
            childFieldName = childFieldName.removeEndIgnoreCase('Id');
        }

        return String.join(new List<String>{
                childFieldName,
                UTIL_Describe.getNameField(
                        String.valueOf(relatedObjects[0]))
        }, '.');
    }

    /*******************************************************************************************************
    * @description Gives field type name - ID, STRING, TEXTAREA, DATE, DATETIME, BOOLEAN, REFERENCE,
    * PICKLIST, MULTIPICKLIST, CURRENCY, DOUBLE, INTEGER, PERCENT, PHONE, EMAIL
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return string the name of the of the field's type
    */
    public static String getFieldType(String objectName, String fieldName) {
        objectName = objectName.toLowerCase();
        fieldName = fieldName.toLowerCase();

        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) {
            fillFieldMapsForObject(objectName, fieldName);
        }

        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getType().name();
    }

    public String getFieldTypeInstance(String objectName, String fieldName) {
        return getFieldType(objectName, fieldName);
    }

    /*******************************************************************************************************
    * @description Gives field type name - ID, STRING, TEXTAREA, DATE, DATETIME, BOOLEAN, REFERENCE,
    * PICKLIST, MULTIPICKLIST, CURRENCY, DOUBLE, INTEGER, PERCENT, PHONE, EMAIL
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return DisplayType the DisplayType of the field
    */
    public static Schema.DisplayType getFieldDisplayType(String objectName, String fieldName) {
        objectName = objectName.toLowerCase();
        fieldName = fieldName.toLowerCase();

        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) {
            fillFieldMapsForObject(objectName, fieldName);
        }

        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getType();
    }

    /*******************************************************************************************************
    * @description Gets a SObjectType token given the API name of that SObject.
    * @param qualifiedAPIName The API name of an SObject.
    * @return Schema.SObjectType The token for the object.
    */
    public static Schema.SObjectType getSObjectType(String qualifiedAPIName) {
        if (gd==null) gd = Schema.getGlobalDescribe();
        return gd.get(qualifiedAPIName);
    }

    /*******************************************************************************************************
    * @description Returns field describe data
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return Schema.DescribeFieldResult the describe field result for the given field
    */
    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        objectName = objectName.toLowerCase();
        fieldName = fieldName.toLowerCase();

        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) {
            fillFieldMapsForObject(objectName, fieldName);
        }

        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr;
    }

    /*******************************************************************************************************
    * @description Returns object describe data.
    * @param objType the SObjectType of the object to lookup
    * @return Schema.DescribeSObjectResult of the object
    */
    public Schema.DescribeFieldResult getFieldDescribeInstance(String objectName, String fieldName) {
        return getFieldDescribe(objectName, fieldName);
    }

    /*******************************************************************************************************
    * @description Gives field friendly name
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return string the label of the field
    */
    public static String getFieldLabel(String objectName, String fieldName) {
        objectName = objectName.toLowerCase();
        fieldName = fieldName.toLowerCase();

        // make sure we have this field's schema mapped
        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) {
            fillFieldMapsForObject(objectName, fieldName);
        }

        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
        return dfr.getLabel();
    }

    /*******************************************************************************************************
    * @description Gives field friendly name without throwing exception if not valid.
    * @param strObj the name of the object to look up
    * @param strField the name of the field to look up -- LOWERCASE
    * @return string the label of the field
    */
    public static String getFieldLabelSafe(String strObj, String strField) {
        try {
            return getFieldLabel(strObj, strField);
        } catch (Exception e) {
            return strField;
        }
    }

    /*******************************************************************************************************
    * @description Instance method that returns the inline help text for a field.
    * @param field SObjectField token of the field to analyze.
    * @return Help text configured within the fields metadata.
    */
    public String getHelpText(SObjectField field) {
        return field.getDescribe().getInlineHelpText();
    }

    /*******************************************************************************************************
    * @description returns friendly label for standard User lookups when we need to display them in custom UI.
    * This is necessary because these labels do not exist in any schema describe available.
    * @return string, translatable & friendly label without 'Id'
    */
    public static String getUserReferenceFieldLabel(DescribeFieldResult dfr) {
        if (dfr.name == 'CreatedById') {
            return Label.stgCreatedBy;
        } else if (dfr.name == 'OwnerId') {
            return Label.leadConvertOwner;
        } else if (dfr.name == 'LastModifiedById') {
            return Label.stgLastModifiedBy;
        } else {
            return dfr.label;
        }
    }

    /*******************************************************************************************************
    * @description checks whether the field exists
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return Boolean whether the field exists
    */
    public static Boolean isValidField(String objectName, String fieldName) {
        // make sure we have this field's schema mapped
        try {
            objectName = objectName.toLowerCase();
            fieldName = fieldName.toLowerCase();

            if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) {
                fillFieldMapsForObject(objectName, fieldName);
            }

            Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
            return dfr != null;
        } catch (Exception ex) {
            return false;
        }
    }

    /*******************************************************************************************************
    * @description checks whether the field is unique
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return Boolean whether the field is unique
    */
    public static Boolean isFieldUnique(String objectName, String fieldName) {
        objectName = objectName.toLowerCase();
        fieldName = fieldName.toLowerCase();

        if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) {
            fillFieldMapsForObject(objectName, fieldName);
        }

        Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);

        return dfr.isUnique() || dfr.isExternalId();
    }

    /*******************************************************************************************************
    * @description Determines whether a field is a Master-Detail field.
    * @param field The field to analyze.
    * @return True if the field is a Master-Detail field, otherwise false.
    */
    public Boolean isMasterDetailField(SObjectField field) {
        if (field.getDescribe().getRelationshipOrder() != null) {
            return true;
        } else {
            return false;
        }
    }

    /*******************************************************************************************************
    * @description utility to check for compatible datatypes for data copying
    * @param dtSrc the DisplayType of the source object
    * @param dtTgt the DisplayType of the target object
    * @return true if the types can be copied between
    */
    public static Boolean canDisplayTypesCopy(Schema.DisplayType dtSrc, Schema.DisplayType dtTgt) {

        if (dtSrc == dtTgt) {
            return true;
        }

        // date can go to datetime
        if (dtSrc == Schema.DisplayType.DATE && dtTgt == Schema.DisplayType.DATETIME) {
            return true;
        }

        // numbers can implicitly cast to other numbers
        if ((dtSrc == Schema.DisplayType.CURRENCY ||
            dtSrc == Schema.DisplayType.DOUBLE ||
            dtSrc == Schema.DisplayType.INTEGER ||
            dtSrc == Schema.DisplayType.PERCENT) &&
           (dtTgt == Schema.DisplayType.CURRENCY ||
            dtTgt == Schema.DisplayType.DOUBLE ||
            dtTgt == Schema.DisplayType.INTEGER ||
            dtTgt == Schema.DisplayType.PERCENT)) {
            return true;
        }

        // text can go to longer text
        if (dtSrc == Schema.DisplayType.STRING && dtTgt == Schema.DisplayType.TEXTAREA) {
            return true;
        }

        return false;
    }

    /*******************************************************************************************************
    * @description utility to return a list of field names from a field set.
    * @param obj the namespaced name of the object
    * @param fieldSetName the namespaced name of the object's field set
    * @return a list of strings of field names in the field set
    */
    public static List<String> listStrFromFieldSet(String obj, String fieldSetName) {
        return listStrFromFieldSet(obj, fieldSetName, false);
    }

    /*******************************************************************************************************
    * @description utility to return a list of field names from a field set.
    * @param obj the namespaced name of the object
    * @param fieldSetName the namespaced name of the object's field set
    * @param onlyRequired if true, only return required fields
    * @return a list of strings of field names in the field set
    */
    public static List<String> listStrFromFieldSet(String obj, String fieldSetName, Boolean onlyRequired) {
        List<String> fieldNames = new List<String>();
        if (gd==null) gd = Schema.getGlobalDescribe();
        Schema.SObjectType targetType = gd.get(obj);
        Schema.DescribeSObjectResult objectDescribe = targetType.getDescribe();
        Schema.FieldSet fieldSetDescribe = objectDescribe.fieldSets.getMap().get(fieldSetName);
        if (fieldSetDescribe == null) {
            return null;
        } else {
            for(Schema.FieldSetMember fieldSetMember : fieldSetDescribe.getFields()) {
                if (fieldSetMember.getFieldPath().contains('.')) {
                    String errorMessage = String.format(Label.FieldSetRelatedFieldError, 
                        new List<String>{'\''+fieldSetMember.getFieldPath()+'\'', '\''+fieldSetName+'\'', '\''+obj+'\''});
                    throw (new SchemaDescribeException(errorMessage));
                }
                if(!onlyRequired || fieldSetMember.getDbRequired() || fieldSetMember.getRequired()){
                    fieldNames.add(fieldSetMember.getFieldPath());
                }
            }
            return fieldNames;
        }
    }

    /*******************************************************************************************************
    * @description copies the specified fields, make sure the user has apppropriate permissions
    * @param strObject the name of the object
    * @param src the Source object
    * @param dst the Destination object
    * @param listStrF the list of field names to check FLS and copy data from
    */
    public static void copyObjectFLS(String strObject, SObject src, SObject dst, List<String> listStrF) {
        for (String strF : listStrF) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(strObject, strF);
            if (dfr == null || !dfr.isCreateable() || !dfr.isUpdateable()) {
                throw (new PermsException(String.format(Label.flsError, new String[]{
                        strObject + '.' + strF
                })));
            }

            // don't copy null for checkbox fields, or they will give an error on update
            if (dfr.isNillable() || src.get(strF)!= null) {
                dst.put(strF, src.get(strF));
            }
        }
    }

    /** @description Returns a list of SelectOptions for a given object and picklist field name.
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @return List<SelectOption> The select options for this picklist field.
    */

    public static List<SelectOption> getSelectOptions(String objectName, String fieldName) {
        Schema.DescribeFieldResult describeField = UTIL_Describe.getFieldDescribe(objectName, fieldName);

        List<SelectOption> result = new List<SelectOption>();
        if (describeField.getType() == Schema.DisplayType.PICKLIST) {
            for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
                if (entry.isActive()) {
                    result.add(new SelectOption(entry.getValue(), entry.getLabel()));
                }
            }
        }
        return result;
    }

    /** @description Returns the default SelectOption for a given object and picklist field name.
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @return String The default select option for this picklist field.
    */
    public static String getDefaultSelectOption(String objectName, String fieldName) {
        Schema.DescribeFieldResult describeField = getFieldDescribe(objectName, fieldName);

        if (describeField.getType() == Schema.DisplayType.PICKLIST) {
            for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
                if (entry.isDefaultValue()) {
                    return entry.getValue();
                }
            }
        }
        return null;
    }

    /** @description Returns a list of options formatted for Lightning Component use in lightning:select tags
    * for a given object and picklist field name.
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @return List<Map<String, String>> The options for this picklist field formatted for use in Lightning Components
    */
    public static List<Map<String, String>> getLightningSelectOptions(String objectName, String fieldName) {
        List<SelectOption> picklistOptions = UTIL_Describe.getSelectOptions(objectName,fieldName);

        List<Map<String, String>> options = new List<Map<String, String>>();
        for (SelectOption opt : picklistOptions) {
            if (opt.getDisabled() == false) {
                Map<String, String> labeledOption = new Map<String, String>();
                labeledOption.put('value', opt.getValue());
                labeledOption.put('label', opt.getLabel());
                options.add(labeledOption);
            }
        }
        return options;
    }

    /**
    * @description Returns Boolean to indicate whether select option api name valid for object/field.
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @param optionApiName The API name of the select option.
    * @return Boolean true if select option available, otherwise False.
    */
    public static Boolean isValidPicklistOption(String objectName, String fieldName, String optionApiName) {
        Schema.DescribeFieldResult describeField = UTIL_Describe.getFieldDescribe(objectName, fieldName);

        if (describeField.getType() == Schema.DisplayType.PICKLIST) {
            for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
                if (entry.isActive()
                    && entry.getValue() == optionApiName
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
    * @description Retrieve the localized picklist labels for any given picklist api name. This returns
    * the translation for all picklist values, not just the active ones.
    * @param objectType SObjectType
    * @param fieldType SObjectField
    * @param apiName picklist api name
    * @return Translated picklist label (could be English if the language is English)
    */
    public static String getTranslatedPicklistLabel(SObjectType objectType, SObjectField fieldType, String apiName) {
        if (!picklistTranslations.containsKey(fieldType)) {
            picklistTranslations.put(fieldType, new Map<String, String>());
            String fieldName = String.valueOf(fieldType);
            String objectName = String.valueOf(objectType);

            Schema.DescribeFieldResult describeField = UTIL_Describe.getFieldDescribe(objectName, fieldName);
            for (Schema.PicklistEntry entry : describeField.getPicklistValues()) {
                picklistTranslations.get(fieldType).put(entry.getValue(), entry.getLabel());
            }
        }
        return picklistTranslations.get(fieldType).get(apiName);
    }


    /** @description For a given object and field, verifies that the field is accessible and updateable
     * throwing an exception if it isn't.*/
    public static void checkFieldFLS(String objectName, String fieldName) {

        DescribeFieldResult dfr = getFieldDescribe(
            UTIL_Namespace.StrTokenNSPrefix(objectName),
            fieldName.endsWith('__c')?UTIL_Namespace.StrTokenNSPrefix(fieldName):fieldName
        );
        if (dfr == null || !dfr.isAccessible() || !dfr.isUpdateable()) {
            throw (new PermsException(
                    String.format(
                            Label.flsError,
                            new String[]{
                                    UTIL_Namespace.StrTokenNSPrefix(objectName) + '.' +
                                            UTIL_Namespace.StrTokenNSPrefix(fieldName)
                            }
                    )
            ));
        }
    }

    private static Boolean isMiddleNameEnabled { get; set; }

    /** @description returns true if the MiddleName field is enabled in this org */
    public static Boolean isMiddleNameEnabled() {
        if (isMiddleNameEnabled == null) {
            if (!fieldTokens.containsKey('Contact')) {
                fieldTokens.put('Contact', Contact.SObjectType.getDescribe().fields.getMap());
                fieldDescribes.put('Contact', new Map<String, Schema.DescribeFieldResult>());
            }
            isMiddleNameEnabled = fieldTokens.get('Contact').containsKey('middlename');
        }
        return isMiddleNameEnabled;
    }

    private static Boolean isNameSuffixEnabled { get; set; }

    /** @description returns true if the Suffix field is enabled in this org */
    public static Boolean isNameSuffixEnabled() {
        if (isNameSuffixEnabled == null) {
            if (!fieldTokens.containsKey('Contact')) {
                fieldTokens.put('Contact', Contact.SObjectType.getDescribe().fields.getMap());
                fieldDescribes.put('Contact', new Map<String, Schema.DescribeFieldResult>());
            }
            isNameSuffixEnabled = fieldTokens.get('Contact').containsKey('suffix');
        }
        return isNameSuffixEnabled;
    }

    /** @description Returns the correctly cased version of the field API Name for situations where it
    * is required (ex some LWC functions).
    * @param objectName The name of the object.
    * @param fieldName The name of the field.
    * @return String the canonical field name
    */
    public static String getFieldName(String objectName, String fieldName) {
        if (fieldName != null && objectName != null) {
            Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
            fieldName = fieldDescribe.getName();
        }

        return fieldName;
    }

    /** @description Returns the correctly cased version of the object API Name for situations where it
    * is required (ex some LWC functions).
    * @param objectName The name of the object.
    * @return String the canonical object name
    */
    public static String getObjectName(String objectName) {
        if (objectName != null) {
            Schema.DescribeSObjectResult objectDescribe = getObjectDescribe(objectName);
            objectName = objectDescribe.getName();
        }

        return objectName;
    }

    public Boolean isFieldSortable(Schema.SObjectField field) {
        return field.getDescribe().isSortable();
    }

    /** @description our exception object for Field Level & Object Security errors. */
    private class PermsException extends Exception {}

    /** @description Returns a friendlier label name for a given display type
    * @param displayType The all caps version of the display type provided from a field describe
    * @return String the friendly label name for the display type
    */
    public static String getLabelForDisplayType(String displayType) {
        return LABELS_BY_DISPLAY_TYPE.get(displayType);
    }
}