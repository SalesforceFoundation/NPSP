@isTest
private class RLLP_OppAccount_TEST {

    public static final String accountLimit = '1';
/*
    @isTest(SeeAllData=true)
    static void PerformanceNEW() {
        TDTM_TriggerHandler.disableTDTM = true;
        Long startTime = System.currentTimeMillis();

        RLLP_OppAccount rollup = new RLLP_OppAccount();
        String detailQuery = rollup.getDetailQuery();
        String summaryQuery = rollup.getSummaryQuery();
        //System.debug('njjc detail query: ' + detailQuery);
        //System.debug('njjc summary query: ' + summaryQuery);
        List<Account> accounts = Database.query(summaryQuery + ' ORDER BY npo02__Best_Gift_Year_Total__c DESC NULLS LAST LIMIT ' + accountLimit);
        List<Opportunity> opps = Database.query(detailQuery + ' WHERE AccountId IN :accounts');
        rollup.processDetails(opps);
        List<Account> results = rollup.getResults();
        update results;

        Long executionTime = System.currentTimeMillis() - startTime;
        System.debug('Execution time new: ' + executionTime);
    }

    @istest(SeeAllData=true)
    static void PerformanceOLD() {
        TDTM_TriggerHandler.disableTDTM = true;
        Long startTime = System.currentTimeMillis();
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        Map<Id, Account> accs = new Map<Id, Account>((List<Account>)Database.query(oppRollupUtil.buildAccountQuery() + ' ORDER BY npo02__Best_Gift_Year_Total__c DESC NULLS LAST LIMIT ' + accountLimit));
        RLLP_OppRollup oppRoller = new RLLP_OppRollup();
        oppRoller.RollupAccounts(accs);
        Long executionTime = System.currentTimeMillis() - startTime;
        System.debug('Execution time old: ' + executionTime);
    }
*/

    static testMethod void test_method_one() {
        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'foo',
            AccountId = acc.Id,
            Amount = 8,
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = System.today(),
            RecordTypeId = UTIL_RecordTypes.getRecordTypeIdForGiftsTests(Opportunity.SOBjectType),
            npe01__Member_Level__c = 'foo',
            npe01__Membership_Origin__c = 'bar'
        );
        insert opp;

        RLLP_OppAccount rollup = new RLLP_OppAccount();
        String query = rollup.getDetailQuery();
        Opportunity queryOpp = Database.query(query);
        System.debug('njjc query ' + query);

        try {
            rollup.processDetails(new List<SObject>{queryOpp});
        } catch (Exception ex) {
            System.assert(false, ex + ' stack: ' + ex.getStackTraceString());
        }
        system.debug('njjc heap' + Limits.getHeapSize());
        //System.assert(false, 'njjc results :' + rollup.getResults());

    }
}