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
private class UTIL_RecordTypes_TEST {

    @isTest
    static void testRecTypes() {
        // try bogus values
        Id bogus = UTIL_RecordTypes.GetRecordTypeId(Opportunity.sObjectType, 'Bogus');
        bogus = UTIL_RecordTypes.GetRecordTypeId(Contact.sObjectType, 'Bogus');
        bogus = UTIL_RecordTypes_API.GetRecordTypeId('Campaign', 'Bogus');
        
        // try all the functions
        Set<Id> oppRtSet = UTIL_RecordTypes_API.GetRecordTypeIdSet('Opportunity', (new Set<String>{'Bogus', 'Master', 'Grant'}));
        List<SelectOption> rtOptions = UTIL_RecordTypes.getRecordTypesForSelectList(Opportunity.sObjectType);
        
        // check against queried rectypes
        List<RecordType> ort = [SELECT Id, Name
                                FROM RecordType
                                WHERE IsActive=true
                                AND sObjectType='Opportunity'
                                LIMIT 1];
        if (!ort.isEmpty()) {
            Id rtId = UTIL_RecordTypes.GetRecordTypeId(Opportunity.sObjectType, ort[0].name);
            System.assertEquals(ort[0].id, rtId);
            String rtName = UTIL_RecordTypes_API.GetRecordTypeName('Opportunity', ort[0].id);
            System.assertEquals(ort[0].name, rtName);

            // the sets above should contain something too
            System.assert(oppRtSet.size() > 0);
            System.assert(rtOptions.size() > 0);
        }       
    }

    @isTest
    static void testVFRecordTypes() {

        ID idGift = UTIL_RecordTypes.GetRecordTypeId(Opportunity.sObjectType, UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.sObjectType));
        
        Set<String> setStr = new Set<String>{UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.sObjectType)};
        Set<Id> setId = UTIL_RecordTypes.GetRecordTypeIdSet(Opportunity.sObjectType, setStr);

        if (idGift!=null) {
            System.assert(setId.contains(idGift));
        
            System.assertEquals(UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.sObjectType), UTIL_RecordTypes.GetRecordTypeName(Opportunity.sObjectType, idGift));
                
            List<SelectOption> listSO = UTIL_RecordTypes.getRecordTypesForSelectList(Opportunity.sObjectType);
            System.assert(listSO.IsEmpty() == false);
        }
    }

    @isTest
    static void testLightningRecordTypes() {

        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE IsActive=true AND sObjectType='Opportunity' LIMIT 1];

        List<Map<String, String>> recordTypeIdAndName = UTIL_RecordTypes.getRecordTypeDevNamesForLightningSelectList(Opportunity.sObjectType);
        List<Map<String, String>> recordTypeDevNameAndName = UTIL_RecordTypes.getRecordTypesForLightningSelect(Opportunity.sObjectType);
        List<Map<String, String>> recordTypeNameAndName = UTIL_RecordTypes.getStringRecordTypesForLightningSelect(Opportunity.sObjectType);

        if (recordTypes.size() != null) {
            System.assert(recordTypeIdAndName.size() != 0, 'No record types are assigned.');
            System.assert(recordTypeDevNameAndName.size() != 0, 'No record types are assigned.');
            System.assert(recordTypeNameAndName.size() != 0, 'No record types are assigned.');
        }
    }

}