@isTest
private class RLLP_OppContact_TEST {
    static testMethod void test_method_one() {
        Contact con = new Contact(LastName='foo');
        insert con;
        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.Id,
            Amount = 8,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = System.today(),
            RecordTypeId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SOBjectType),
            npe01__Member_Level__c = 'foo',
            npe01__Membership_Origin__c = 'bar'
        );
        insert opp;
        RLLP_OppContact rollup = new RLLP_OppContact();
        Opportunity queryopp = (Opportunity)Database.query(rollup.getDetailQuery() + ' WHERE Id = \'' + opp.id + '\'');
        try {
            rollup.processDetails(new List<SObject>{queryopp});
            System.debug('njjc ' + rollup);
        } catch (Exception ex) {
            System.assert(false, ex + ' stack: ' + ex.getStackTraceString());
        }
//        System.assert(false, 'njjc results :' + rollup.getResults());
    }
}