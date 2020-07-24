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
public class AutoNumberService {
    SObjectType sObjType;
    List<SObject> records;
    public class AutoNumberException extends Exception {}

    /**
     * @description This constructor is currently used by the settings UI
     * to create and activate/deactivate Auto Numbers for the passed in
     * SObjectType.
     */
    public AutoNumberService(SObjectType sObjType) {
        this.sObjType = sObjType;
    }

    /**
     * @description This constructor is currently used by the Trigger Handler
     * framework when applying Auto Numbers to new records.
     */
    public AutoNumberService(List<SObject> records) {
        this.records = records;
        this.sObjType = records.isEmpty() ? null : records[0].getSObjectType();
    }

    public void activate(String autoNumberId) {
        List<AutoNumber__c> autoNumbersToUpdate = new List<AutoNumber__c>();
        for (AutoNumber__c autoNumber : activeAutoNumbers) {
            autoNumber.IsActive__c = false;
            autoNumbersToUpdate.add(autoNumber);
        }

        autoNumbersToUpdate.add(new AutoNumber__c(Id = autoNumberId, IsActive__c = true));
        update autoNumbersToUpdate;

        if (!hasTriggerHandlerEntry) {
            insert triggerHandler;
        }
    }

    public void deactivate(String autoNumberId) {
        AutoNumber__c a = new AutoNumber__c(
                Id = autoNumberId,
                IsActive__c = false
        );
        update a;
    }

    public AutoNumber__c save(String autoNumber) {
        AutoNumber__c an = convertJSONToAutoNumber(autoNumber);
        if (!isValid(an)) {
            throw new AutoNumberException('This Display Format is already in use.');
        }
        insert an;
        return an;
    }

    private Boolean isValid(AutoNumber__c an) {
        return (isValidPattern(an) && !isDuplicate(an));

    }

    private Boolean isValidPattern(AutoNumber__c an) {
        if (Pattern.matches('.*\\{.*?\\}', an.Display_Format__c)) {
            return true;
        } else {
            throw new AutoNumberException('Invalid Display Format: ' + an.Display_Format__c);
        }
    }

    private Boolean isDuplicate(AutoNumber__c an) {
        for (AutoNumber__c autoNumber : getAutoNumbers()) {
            if (autoNumber.Display_Format__c.substringBefore('{') ==
                    an.Display_Format__c.substringBefore('{')) {
                throw new AutoNumberException('Duplicate Display Format: ' +
                        an.Display_Format__c + ' for Object: ' + an.Object_API_Name__c);
            }
        }
        return false;
    }

    private AutoNumber__c convertJSONToAutoNumber(String autoNumber) {
        Map<String, Object> anMap =
                (Map<String, Object>) JSON.deserializeUntyped(autoNumber);

        AutoNumber__c an = new AutoNumber__c();
        Map<String, Object> fields = (Map<String, Object>) anMap.get('fields');
        an.Display_Format__c =
                (String) fields.get(String.valueOf(
                        AutoNumber__c.Display_Format__c));
        an.Field_API_Name__c =
                (String) fields.get(String.valueOf(
                        AutoNumber__c.Field_API_Name__c));
        an.Object_API_Name__c =
                (String) fields.get(String.valueOf(
                        AutoNumber__c.Object_API_Name__c));
        an.Starting_Number__c =
                Integer.valueOf(fields.get(String.valueOf(
                        AutoNumber__c.Starting_Number__c)));
        return an;
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
        for (SObject record : records) {
            SObject clone = record.clone(true);
            clone.put(an.fieldApiName, an.getFormattedNumber(nextAutoNumberInSequence));
            sObjectsToUpdate.add(clone);
            nextAutoNumberInSequence++;
        }

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        dmlWrapper.objectsToUpdate.addAll(sObjectsToUpdate);
        // Throws DmlException STRING TOO LONG if format+number is longer than target field
        TDTM_TriggerHandler.processDml(dmlWrapper);

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

    @TestVisible
    Boolean hasTriggerHandlerEntry {
        get {
            return ![
                    SELECT Id
                    FROM Trigger_Handler__c
                    WHERE Object__c = :String.valueOf(sObjType)
                    AND Class__c = :AutoNumber_TDTM.class.getName()
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
                    Class__c = AutoNumber_TDTM.class.getName(),
                    Load_Order__c = 0,
                    Object__c = String.valueOf(sObjType),
                    Trigger_Action__c = 'AfterInsert;');
        }
    }

    /**
     * @description Wrapper class used to provide easier access to calculated
     * properties for AutoNumber__c records.
     */
    private class AutoNumber {
        AutoNumber__c record;
        String fieldApiName;
        Integer nextAutoNumber;

        public AutoNumber(AutoNumber__c record) {
            this.record = record;
            fieldApiName = getFieldApiName();
            nextAutoNumber = getNextAutoNumber();
        }

        private String getFieldApiName() {
            // Throws "Invalid field name" error if the field name is not found in
            // the NPSP cached collection of describes...
            SObjectField token = UTIL_Describe.getFieldDescribe(
                    record.Object_API_Name__c,
                    record.Field_API_Name__c).getSobjectField();
            return String.valueOf(token);
        }

        private Integer getNextAutoNumber() {
            Integer maxUsedNumber = record.Max_Used_Number__c != null ?
                    Integer.valueOf(record.Max_Used_Number__c) : 0;
            Integer startingNumber = record.Starting_Number__c != null ?
                    Integer.valueOf(record.Starting_Number__c) : null;
            Integer nextNumber = maxUsedNumber + 1;
            if (startingNumber != null) {
                return maxUsedNumber < startingNumber ?
                        startingNumber :
                        nextNumber;
            } else {
                return nextNumber;
            }
        }

        private Integer getNumberLength() {
            String oB = '{';
            String cB = '}';
            Integer a = record.Display_Format__c.indexOf(oB);
            Integer b = record.Display_Format__c.indexOf(cB);
            Integer numLen = b - a - 1;
            return numLen < 0 ? 0 : numLen;
        }

        public String getFormattedNumber(Integer num) {
            return String.format(record.Display_Format__c,
                    new List<Object>{
                            String.valueOf(num).leftPad(getNumberLength(), '0')
                    }
            );
        }

        public void setMaxUsedNumber(Integer num) {
            record.Max_Used_Number__c = num;
            TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
            dmlWrapper.objectsToUpdate.add(record);
            TDTM_TriggerHandler.processDML(dmlWrapper);
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

    public List<AutoNumber__c> getAutoNumbers() {
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

}