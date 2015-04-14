@isTest
private class OPP_OpportunityNaming_TEST
{
    @isTest
    static void itShould()
    {
        Opportunity_Naming_Settings__c ons = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Record_Types__c = UTIL_RecordTypes.GetRecordTypeId('Opportunity', UTIL_RecordTypes.getrecordTypeNameForGiftsTests('Opportunity')),
            Opportunity_Name_Format__c = '{!Account.Name} {!Contact.Name} {!CloseDate} {!RecordType.Name}'
        );
        insert ons;

        Account acc = new Account(Name='accname');
        insert acc;

        Contact con = new Contact(LastName='conname');
        insert con;

        Opportunity opp = new Opportunity(
            AccountId = acc.id,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            RecordTypeId = UTIL_RecordTypes.GetRecordTypeId('Opportunity', UTIL_RecordTypes.getrecordTypeNameForGiftsTests('Opportunity')),
            Name='temp',
            Amount=8,
            CloseDate = Date.newInstance(2000, 1, 1),
            npe01__Contact_Id_for_Role__c = con.id
        );
        insert opp;

        list<Opportunity> queryOpp = [SELECT Name FROM Opportunity WHERE Id = :opp.id];
        system.assertEquals('accname conname 2000.01.01 Donation', queryOpp[0].Name, 'The name should be calculated based on the setting.');

    }
}