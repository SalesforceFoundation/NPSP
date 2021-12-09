/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @description Provides functionality related to custom AutoNumbers for an SObject.
* Custom AutoNumbers provide the ability to have an "auto number" field that can
* switch between Display Formats.  Standard Auto Number fields allow changing of the
* Display Format but the number increments regardless of the format.  Custom AutoNumbers
* use the active AutoNumber__c record when determining which Display Format to use, and
* each Display Format keeps track of its Max Last Used number.  This allows it to
* increment based on the last used number for the active Display Format, rather than
* using a global number sequence for all new records for the object.
*/
public class AN_AutoNumberService {
    SObjectType sObjType;
    List<SObject> recordsToBeAutoNumbered;
    public class AutoNumberException extends Exception {}

    /**
     * @description This constructor is currently used by the settings UI
     * to create and activate/deactivate Auto Numbers for the passed in
     * SObjectType.
     */
    public AN_AutoNumberService(SObjectType sObjType) {
        this.sObjType = sObjType;
    }

    /**
     * @description This constructor is currently used by the Trigger Handler
     * framework when applying Auto Numbers to new records.
     * @param records Inserted records that need AutoNumbers applied. Currently,
     * this will be newList passed in in AfterInsert context by TDTM.
     */
    public AN_AutoNumberService(List<SObject> records) {
        this.recordsToBeAutoNumbered = records;
        this.sObjType = records.isEmpty() ? null : records[0].getSObjectType();
    }

    /**
     * @description Activates the AutoNumber record associated with the passed in
     * Id and inserts the AutoNumber Trigger Handler for the SObject if it does
     * not already exist.
     */
    public void activate(String autoNumberId) {
        List<AutoNumber__c> autoNumbersToUpdate = new List<AutoNumber__c>();
        for (AutoNumber__c autoNumber : activeAutoNumbers) {
            autoNumber.IsActive__c = false;
            autoNumbersToUpdate.add(autoNumber);
        }

        autoNumbersToUpdate.add(new AutoNumber__c(Id = autoNumberId, IsActive__c = true));
        update autoNumbersToUpdate;

        if (!isTriggerHandlerEnabled) {
            insert triggerHandler;
        }
    }

    /**
     * @description Deactivates the AutoNumber record associated with the passed in Id.
     */
    public void deactivate(String autoNumberId) {
        update new AutoNumber__c(Id = autoNumberId, IsActive__c = false);
    }

    /**
     * @description Attempts to convert the passed in JSON String to an AutoNumber record.
     * The JSON object should have a property named "fields" that is an object with key
     * value pairs of fieldApiName to fieldValue for fields on the AutoNumber__c object.
     */
    public AutoNumber__c save(String autoNumberJSON) {
        return new AutoNumber(autoNumberJSON, this).save();
    }

    /**
     * @description Primary method used by callers to apply Auto Numbers to the
     * records in the trigger context that have active Auto Numbers.
     */
    public void apply() {
        AutoNumber an = getAutoNumber();
        if (an == null) {
            return;
        }

        List<SObject> sObjectsToUpdate = new List<SObject>();
        Integer nextAutoNumberInSequence = an.nextAutoNumber;
        for (SObject record : recordsToBeAutoNumbered) {
            SObject clone = record.clone(true);
            clone.put(an.sObjField, an.getFormattedNumber(nextAutoNumberInSequence));
            sObjectsToUpdate.add(clone);
            nextAutoNumberInSequence++;
        }

        update sObjectsToUpdate;

        // Update the AutoNumber record AFTER Successful Save
        an.setMaxUsedNumber(nextAutoNumberInSequence - 1);
    }

    private List<AutoNumber__c> activeAutoNumbers {
        get {
            return [
                    SELECT IsActive__c
                    FROM AutoNumber__c
                    WHERE Object_API_Name__c = :String.valueOf(sObjType)
                    AND IsActive__c = true
            ];
        }
    }

    // TDTM expects local names without namespaces for Class and Object
    private final String TRIGGER_HANDLER_CLASS_NAME = 'AN_AutoNumber_TDTM';
    @TestVisible
    Boolean isTriggerHandlerEnabled {
        get {
            return ![
                    SELECT Id
                    FROM Trigger_Handler__c
                    WHERE Object__c = :sObjType.getDescribe().getLocalName()
                    AND Class__c = :TRIGGER_HANDLER_CLASS_NAME
                    AND Active__c = true
            ].isEmpty();
        }
    }

    @TestVisible
    Trigger_Handler__c triggerHandler {
        get {
            return new Trigger_Handler__c(
                    Active__c = true,
                    Asynchronous__c = false,
                    Class__c = TRIGGER_HANDLER_CLASS_NAME,
                    Load_Order__c = 0,
                    Object__c = sObjType.getDescribe().getLocalName(),
                    Trigger_Action__c = 'AfterInsert;');
        }
    }

    /**
     * @description Wrapper class used to provide easier access to calculated
     * properties for AutoNumber__c records.
     */
    @TestVisible
    private class AutoNumber {
        AutoNumber__c record;
        Integer nextAutoNumber;
        AN_AutoNumberService autoNumberService;
        private SObjectType sObjType {
            get {
                return UTIL_Describe.getSObjectType(record.Object_API_Name__c);
            }
        }
        private SObjectField sObjField {
            get {
                return UTIL_Describe.getFieldDescribe(String.valueOf(sObjType),
                        record.Field_API_Name__c).getSobjectField();
            }
        }
        private String displayFormat {
            get {
                return record.Display_Format__c;
            }
        }

        public AutoNumber(String autoNumberJSON, AN_AutoNumberService ans) {
            this.record = convertJSONToAutoNumber(autoNumberJSON);
            this.autoNumberService = ans;
            this.validate();
        }

        public AutoNumber(AutoNumber__c record) {
            this.record = record;
            this.nextAutoNumber = getNextAutoNumber(this.record);
        }

        public String getFormattedNumber(Integer num) {
            Integer numberLength = getNumberLength();
            String singleDigit = '0';
            String currentDigitFormat = '{'  + singleDigit.repeat(numberLength) + '}';
            String singleDigitDisplayFormat = displayFormat.replace(currentDigitFormat, '{0}');
            return String.format(singleDigitDisplayFormat,
                    new List<Object>{
                            String.valueOf(num).leftPad(numberLength, '0')
                    }
            );
        }

        public AutoNumber__c save() {
            insert record;
            return record;
        }

        public void setMaxUsedNumber(Integer num) {
            record.Max_Used_Number__c = num;
            update record;
        }

        private AutoNumber__c convertJSONToAutoNumber(String autoNumber) {
            Map<String, Object> anMap =
                    (Map<String, Object>) JSON.deserializeUntyped(autoNumber);
            Map<String, Object> fields = (Map<String, Object>) anMap.get('fields');

            AutoNumber__c an = new AutoNumber__c();
            an.Display_Format__c =
                    (String) fields.get(String.valueOf(
                            AutoNumber__c.Display_Format__c));
            try {
                Integer startingNumber = Integer.valueOf(
                        fields.get(String.valueOf(
                                AutoNumber__c.Starting_Number__c)));
                an.Starting_Number__c = startingNumber;
            } catch (Exception e) {
                // Continue without assigning a value to Starting Number
                // if the value cannot be converted to an Integer.
            }
            an.Description__c =
                    (String) fields.get(String.valueOf(
                            AutoNumber__c.Description__c));
            an.Object_API_Name__c =
                    (String) fields.get(String.valueOf(
                            AutoNumber__c.Object_API_Name__c));
            an.Field_API_Name__c =
                    (String) fields.get(String.valueOf(
                            AutoNumber__c.Field_API_Name__c));
            return an;
        }

        private void validate() {
            if (!isValidPattern(displayFormat)) {
                throw new AutoNumberException(Label.autoNumberErrorInvalidDisplayFormat);
            }
            if (isDuplicate(displayFormat, autoNumberService.getAutoNumbers(sObjType))) {
                throw new AutoNumberException(Label.autoNumberErrorDuplicate);
            }
        }

        private Boolean isValidPattern(String displayFormat) {
            return String.isNotBlank(displayFormat) &&
                    Pattern.matches('.*\\{0+\\}', displayFormat) &&
                    displayFormat.countMatches('{') == 1 &&
                    displayFormat.countMatches('}') == 1;
        }

        private Boolean isDuplicate(String displayFormat, List<AutoNumber__c> autoNumbers) {
            for (AutoNumber__c autoNumber : autoNumbers) {
                if (autoNumber.Display_Format__c.substringBefore('{') ==
                        displayFormat.substringBefore('{')) {
                    return true;
                }
            }
            return false;
        }

        private Integer getNextAutoNumber(AutoNumber__c autoNumber) {
            Integer defaultFirstNumber = 1;
            if (autoNumber.Starting_Number__c != null &&
                    (autoNumber.Max_Used_Number__c == null ||
                            autoNumber.Max_Used_Number__c < autoNumber.Starting_Number__c)) {
                return (Integer) autoNumber.Starting_Number__c;
            } else if (autoNumber.Max_Used_Number__c != null) {
                Integer maxUsedNumber = (Integer) autoNumber.Max_Used_Number__c;
                return maxUsedNumber + 1;
            } else {
                return defaultFirstNumber;
            }
        }

        private Integer getNumberLength() {
            String oB = '{';
            String cB = '}';
            Integer a = displayFormat.indexOf(oB);
            Integer b = displayFormat.indexOf(cB);
            Integer numLen = b - a - 1;
            return numLen < 0 ? 0 : numLen;
        }
    }

    private AutoNumber getAutoNumber() {
        List<AutoNumber__c> autoNumbers = [
                SELECT
                        Display_Format__c,
                        Field_API_Name__c,
                        Object_API_Name__c,
                        Max_Used_Number__c,
                        Starting_Number__c
                FROM AutoNumber__c
                WHERE Object_API_Name__c = :String.valueOf(sObjType)
                AND IsActive__c = true
                LIMIT 1
                FOR UPDATE
        ];
        return autoNumbers.isEmpty() ? null : new AutoNumber(autoNumbers[0]);
    }

    public List<AutoNumber__c> getAutoNumbers(SObjectType sObjType) {
        return [
                SELECT Name,
                        Object_API_Name__c,
                        Field_API_Name__c,
                        Display_Format__c,
                        Starting_Number__c,
                        Max_Used_Number__c,
                        IsActive__c,
                        Description__c
                FROM AutoNumber__c
                WHERE Object_API_Name__c = :String.valueOf(sObjType)
                ORDER BY CreatedDate DESC, IsActive__c DESC
        ];
    }

    /**
    * @description Utility class that can be used when testing methods in this class.
    */
    @TestVisible
    private class TestUtility {

        SObjectType sObjType;
        String sObjTypeName {
            get {
                return String.valueOf(sObjType);
            }
        }
        SObjectField sObjField;
        String sObjFieldName {
            get {
                return String.valueOf(sObjField);
            }
        }

        public TestUtility(SObjectType sObjType, SObjectField sObjField) {
            this.sObjType = sObjType;
            this.sObjField = sObjField;
        }

        public String autoNumberJSON {
            get {
                return getAutoNumberJSON(sObjTypeName, sObjFieldName);
            }
        }

        /**
         * @description Valid JSON representation of an AutoNumber record that
         * uses the passed in sObjectName and fieldName as the Object and Field
         * API Name values.  Used for setting up AutoNumberService tests.
         */
        private String getAutoNumberJSON(String sObjectName, String fieldName) {
            String displayFormat = 'abc-{000}';
            Integer startingNumber = 100;

            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeStartObject();
            gen.writeFieldName('fields');
            gen.writeStartObject();
            gen.writeStringField(
                    String.valueOf(AutoNumber__c.Object_API_Name__c),
                    sObjectName);
            gen.writeStringField(
                    String.valueOf(AutoNumber__c.Field_API_Name__c),
                    fieldName);
            gen.writeStringField(
                    String.valueOf(AutoNumber__c.Display_Format__c),
                    displayFormat);
            gen.writeStringField(
                    String.valueOf(AutoNumber__c.Starting_Number__c),
                    String.valueOf(startingNumber));
            gen.writeEndObject();
            gen.writeEndObject();

            return gen.getAsString();
        }

        /**
         * @description Utility method used to insert an AutoNumber record for tests
         * and optionally insert a Trigger Handler entry.
         */
        public Id setupAutoNumber(Boolean isActive, String displayFormat,
                Integer startingNumber, Boolean insertTriggerHandler) {
            AutoNumber__c a = new AutoNumber__c(
                    Object_API_Name__c = sObjTypeName,
                    Field_API_Name__c = sObjFieldName,
                    Display_Format__c = displayFormat,
                    Starting_Number__c = startingNumber,
                    IsActive__c = isActive,
                    Description__c = 'test description'
            );
            insert a;

            if (insertTriggerHandler) {
                insert new AN_AutoNumberService(sObjType).triggerHandler;
            }

            return a.Id;
        }

        public AutoNumber__c getAutoNumberById(Id id) {
            return [
                    SELECT IsActive__c, Max_Used_Number__c
                    FROM AutoNumber__c
                    WHERE Id = :id
            ];
        }

        public List<SObject> getSObjectsById(List<Id> ids) {
            String queryString = new UTIL_Query()
                    .withSelectFields(new List<String>{
                            sObjFieldName
                    })
                    .withFrom(sObjTypeName)
                    .withWhere('Id IN :ids')
                    .build();
            return Database.query(queryString);
        }
    }

}
