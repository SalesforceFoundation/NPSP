@isTest
private class RLLP_OppContact_TEST {
    static testMethod void test_method_one() {
        Contact con = new Contact(LastName='foo');
        insert con;
        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = con.Id,
            Amount = 8,
            StageName = 'Closed Won',
            CloseDate = System.today(),
            npe01__Member_Level__c = 'foo',
            npe01__Membership_Origin__c = 'bar'
        );
        insert opp;
        RLLP_OppContact rollup = new RLLP_OppContact();
        Opportunity queryopp = (Opportunity)Database.query(rollup.getDetailQuery() + ' WHERE Id = \'' + opp.id + '\'');
        try {
            rollup.processDetails(new List<SObject>{queryopp});
            System.debug('njjc ' + rollup);
            system.debug('njjc ' + rollup.getResults());
        } catch (Exception ex) {
            System.assert(false, ex + ' stack: ' + ex.getStackTraceString());
        }
    }
}