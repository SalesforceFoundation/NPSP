/*
    Copyright (c) 2011, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this List of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this List of conditions and the following disclaimer in the
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
* @group Utilities
* @description Tests for recordtype wrapper for easy access to record type information.
*/

@isTest
public class UTIL_RecordTypes_TEST {
    public static final Id MOCK_ID = '0120x00000QF099999';

    @isTest
    static void testRecTypes() {
        // try bogus values
        Id bogus = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, 'Bogus');
        bogus = UTIL_RecordTypes.getRecordTypeId(Contact.SObjectType, 'Bogus');
        bogus = UTIL_RecordTypes_API.GetRecordTypeId('Campaign', 'Bogus');

        // check against queried rectypes
        List<RecordType> oppRTs = [
            SELECT Id, toLabel(Recordtype.Name), DeveloperName FROM RecordType
            WHERE IsActive = True
            AND SobjectType = 'Opportunity'
            ORDER BY DeveloperName ASC
            LIMIT 1
        ];
        if (!oppRTs.isEmpty()) {
            Id rtId = UTIL_RecordTypes.getRecordTypeId(Opportunity.SObjectType, oppRTs[0].Name);
            System.assertEquals(oppRTs[0].Id, rtId, oppRTs[0].Name);
            String rtName = UTIL_RecordTypes_API.GetRecordTypeName('Opportunity', oppRTs[0].Id);
            System.assertEquals(oppRTs[0].Name, rtName);

            // try all the functions
            Set<Id> oppRtSet = UTIL_RecordTypes_API.GetRecordTypeIdSet('Opportunity',
                new Set<String>{'Bogus', 'Master', 'Grant', oppRTs[0].Name});
            System.assert(oppRtSet.size() > 0);

            List<SelectOption> rtOptions = UTIL_RecordTypes.getRecordTypesForSelectList(Opportunity.SObjectType);
            System.assert(rtOptions.size() > 0);
        }
    }

    @isTest
    static void testVFRecordTypes() {

        ID idGift = UTIL_RecordTypes.GetRecordTypeId(Opportunity.SObjectType,
            UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType));

        Set<String> setStr = new Set<String>{UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType)};
        Set<Id> setId = UTIL_RecordTypes.GetRecordTypeIdSet(Opportunity.SObjectType, setStr);

        if (idGift!=null) {
            System.assert(setId.contains(idGift));

            System.assertEquals(UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.SObjectType),
                UTIL_RecordTypes.GetRecordTypeName(Opportunity.SObjectType, idGift));

            List<SelectOption> listSO = UTIL_RecordTypes.getRecordTypesForSelectList(Opportunity.SObjectType);
            System.assert(listSO.IsEmpty() == false);
        }
    }

    @isTest
    static void testLightningRecordTypes() {

        User sysAdmin = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);
        System.runAs(sysAdmin) {
            List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE IsActive=true AND SObjectType='Opportunity'];

            List<Map<String, String>> recordTypeIdAndName = UTIL_RecordTypes.getRecordTypeDevNamesForLightningSelectList(Opportunity.SObjectType);
            List<Map<String, String>> recordTypeDevNameAndName = UTIL_RecordTypes.getRecordTypesForLightningSelect(Opportunity.SObjectType);
            List<Map<String, String>> recordTypeNameAndName = UTIL_RecordTypes.getStringRecordTypesForLightningSelect(Opportunity.SObjectType);

            if (recordTypes.size() > 0) {
                System.assert(recordTypeIdAndName.size() > 0, 'No record types are assigned.');
                System.assert(recordTypeDevNameAndName.size() > 0, 'No record types are assigned.');
                System.assert(recordTypeNameAndName.size() > 0, 'No record types are assigned.');
            }
        }
    }

    //Helper Methods

    /**
    * @description Return a random valid record type for the sObject
    * @param objectType The sObject type of the record type
    * @return Id
    */
    public static Id getRandomRecordTypeId(SObjectType objectType) {
        List<Schema.RecordTypeInfo> recordTypeInfos = objectType.getDescribe().getRecordTypeInfos();
        for (Schema.RecordTypeInfo rti : recordTypeInfos) {
            if (rti.isAvailable()) {
                return rti.getRecordTypeId();
            }
        }
        return null;
    }

    /**
    * @description Return the id of the active non-default record type of the sObject for the current user
    * @param objectType The sObject type of the record type
    * @return Id
    */
    public static Id getNonDefaultRecordTypeId(SObjectType objectType) {
        return getRecordType(objectType, false);
    }

    /**
    * @description Return the id of the active default record type of the sObject for the current user
    * @param objectType The sObject type of the record type
    * @return Id
    */
    public static Id getDefaultRecordTypeId(SObjectType objectType) {
        return getRecordType(objectType, true);
    }

    /**
    * @description Return the id of an active default/non default record type of the sObject for the current user
    * @param objectType The sObject type of the record type
    * @param isDefault Boolean to determine if the default record type is return or not
    * @return Id
    */
    private static Id getRecordType(SObjectType objectType, Boolean isDefault) {
        List<Schema.RecordTypeInfo> recordTypeInfos = objectType.getDescribe().getRecordTypeInfos();

        for (Schema.RecordTypeInfo rti : recordTypeInfos) {
            if (!rti.isMaster() && rti.isAvailable()) {
                if (isDefault && rti.isDefaultRecordTypeMapping()) {
                    return rti.getRecordTypeId();
                } else if (!isDefault && !rti.isDefaultRecordTypeMapping()) {
                    return rti.getRecordTypeId();
                }
            }
        }
        return null;
    }
}