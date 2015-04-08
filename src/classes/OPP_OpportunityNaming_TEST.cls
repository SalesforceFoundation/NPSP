@isTest
private class OPP_OpportunityNaming_TEST
{
    @isTest
    static void itShould()
    {
        Opportunity_Naming_Settings__c ons = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Record_Types__c = UTIL_RecordTypes.GetRecordTypeId('Opportunity', UTIL_RecordTypes.getrecordTypeNameForGiftsTests('Opportunity')),
            Opportunity_Name_Format__c = '{!Account.Name} {!CloseDate} Donation'
        );
        insert ons;

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(
            AccountId = acc.id,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            RecordTypeId = UTIL_RecordTypes.GetRecordTypeId('Opportunity', UTIL_RecordTypes.getrecordTypeNameForGiftsTests('Opportunity')),
            Name='temp',
            Amount=8,
            CloseDate = system.today()
        );
        insert opp;

        list<Opportunity> queryOpp = [SELECT Name FROM Opportunity WHERE Id = :opp.id];
        system.assert(queryOpp[0].Name.contains('foo'), 'The name should be calculated based on the setting.');

    }
}