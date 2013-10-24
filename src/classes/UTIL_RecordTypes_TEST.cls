/**
* @author Evan Callahan
* @date 2010 
* @description tests for recordtype wrapper for easy access in other codeblocks 
*/

@isTest
private class UTIL_RecordTypes_TEST {

    // TEST
    static testmethod void testRecTypes() {
        // try bogus values
        Id reallyBogus = UTIL_RecordTypes.GetRecordTypeId('Bogus', 'Bogus');
        Id bogus = UTIL_RecordTypes.GetRecordTypeId('Opportunity', 'Bogus');
        bogus = UTIL_RecordTypes.GetRecordTypeId('Contact', 'Bogus');
        bogus = UTIL_RecordTypes.GetRecordTypeId('Campaign', 'Bogus');
        
        // try all the functions
        set<Id> oppRtSet = UTIL_RecordTypes.GetRecordTypeIdSet('Opportunity', (new set<string>{'Bogus', 'Master', 'Grant'}));
        Map<String, Id> oppTypeMap = UTIL_RecordTypes.GetRecordTypeIdMap('Opportunity');
        List<SelectOption> rtOptions = UTIL_RecordTypes.getRecordTypesForSelectList('Opportunity');
        system.assertEquals('TestName',UTIL_RecordTypes.GetOppNamingSuffix('TestName'));
        
        // check against queried rectypes
        list<recordtype> ort = [select id, name from recordtype where isactive=true and sobjecttype='Opportunity' limit 1];
        if (!ort.isEmpty()) {
            Id rtId = UTIL_RecordTypes.GetRecordTypeId('Opportunity', ort[0].name);
            system.assertEquals(ort[0].id, rtId); 
            String rtName = UTIL_RecordTypes.GetRecordTypeName('Opportunity', ort[0].id);
            system.assertEquals(ort[0].name, rtName); 

            // the sets above should contain something too
            system.assert(oppRtSet.size() > 0);
            system.assert(oppTypeMap.size() > 0);
            system.assert(rtOptions.size() > 0);            
        }       
    }
    
    static testMethod void TestRecordTypes() {

        ID idGift = UTIL_RecordTypes.GetRecordTypeId('Opportunity', UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        
        Set<String> setStr = new Set<String>{UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity')};
        Set<Id> setId = UTIL_RecordTypes.GetRecordTypeIdSet('Opportunity', setStr);
        if(idGift!=null){
            system.Assert(setId.contains(idGift));
        
            Map<String, Id> mapRCId = UTIL_RecordTypes.GetRecordTypeIdMap('Opportunity');
        
            system.AssertEquals(idGift, mapRCId.get(UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity')));       
            
            system.AssertEquals(UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'), UTIL_RecordTypes.GetRecordTypeName('Opportunity', idGift));        
            
            system.AssertEquals(UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'), UTIL_RecordTypes.GetOppNamingSuffix(UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity')));        
    
            List<SelectOption> listSO = UTIL_RecordTypes.getRecordTypesForSelectList('Opportunity');
            system.Assert(listSO.IsEmpty() == false);       
        }
    }       

}