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
        Id reallyBogus = GetRecordTypeId('Bogus', 'Bogus');
        Id bogus = GetRecordTypeId('Opportunity', 'Bogus');
        bogus = GetRecordTypeId('Contact', 'Bogus');
        bogus = GetRecordTypeId('Campaign', 'Bogus');
        
        // try all the functions
        set<Id> oppRtSet = GetRecordTypeIdSet('Opportunity', (new set<string>{'Bogus', 'Master', 'Grant'}));
        Map<String, Id> oppTypeMap = GetRecordTypeIdMap('Opportunity');
        List<SelectOption> rtOptions = getRecordTypesForSelectList('Opportunity');
        system.assertEquals('TestName',GetOppNamingSuffix('TestName'));
        
        // check against queried rectypes
        list<recordtype> ort = [select id, name from recordtype where isactive=true and sobjecttype='Opportunity' limit 1];
        if (!ort.isEmpty()) {
            Id rtId = GetRecordTypeId('Opportunity', ort[0].name);
            system.assertEquals(ort[0].id, rtId); 
            String rtName = GetRecordTypeName('Opportunity', ort[0].id);
            system.assertEquals(ort[0].name, rtName); 

            // the sets above should contain something too
            system.assert(oppRtSet.size() > 0);
            system.assert(oppTypeMap.size() > 0);
            system.assert(rtOptions.size() > 0);            
        }       
    }
    
    static testMethod void TestRecordTypes() {

        ID idGift = RecordTypes.GetRecordTypeId('Opportunity', getRecordTypeNameForGiftsTests('Opportunity'));
        
        Set<String> setStr = new Set<String>{getRecordTypeNameForGiftsTests('Opportunity')};
        Set<Id> setId = RecordTypes.GetRecordTypeIdSet('Opportunity', setStr);
        if(idGift!=null){
            system.Assert(setId.contains(idGift));
        
            Map<String, Id> mapRCId = RecordTypes.GetRecordTypeIdMap('Opportunity');
        
            system.AssertEquals(idGift, mapRCId.get(getRecordTypeNameForGiftsTests('Opportunity')));       
            
            system.AssertEquals(getRecordTypeNameForGiftsTests('Opportunity'), RecordTypes.GetRecordTypeName('Opportunity', idGift));        
            
            system.AssertEquals(getRecordTypeNameForGiftsTests('Opportunity'), RecordTypes.GetOppNamingSuffix(getRecordTypeNameForGiftsTests('Opportunity')));        
    
            List<SelectOption> listSO = RecordTypes.getRecordTypesForSelectList('Opportunity');
            system.Assert(listSO.IsEmpty() == false);       
        }
    }       

}