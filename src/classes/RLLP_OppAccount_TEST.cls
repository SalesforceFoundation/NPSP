@isTest
private class RLLP_OppAccount_TEST {
    
    static testMethod void test_method_one() {
        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'foo',
            AccountId = acc.Id,
            Amount = 8,
            StageName = 'Posted',
            CloseDate = System.today(),
            npe01__Member_Level__c = 'foo',
            npe01__Membership_Origin__c = 'bar'
        );
        insert opp;
        RLLP_OppAccount rollup = new RLLP_OppAccount();
        try {
            rollup.processDetails(new List<SObject>{opp});
            System.debug('njjc ' + rollup);
            system.debug('njjc ' + rollup.getResults());
        } catch (Exception ex) {
            System.assert(false, ex + ' stack: ' + ex.getStackTraceString());
        }
    }
}