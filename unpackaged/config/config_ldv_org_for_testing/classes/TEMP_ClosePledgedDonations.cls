public class TEMP_ClosePledgedDonations implements Database.Batchable<sObject> {

    private Integer filterByYear = 2020;
    private Integer filterMonth = 12;

    public TEMP_ClosePledgedDonations(Integer filterYear, Integer filterMonth) {
        this.filterByYear = filterYear;
        this.filterMonth = filterMonth;
    }

    public database.Querylocator start(Database.BatchableContext bc) {
        Integer filterYear = this.filterByYear;
        Integer startMonth = (this.filterMonth == 6 ? 1 : 7);
        Integer endMonth = (this.filterMonth == 6 ? 6 : 12);
        return Database.getQueryLocator([
            SELECT Id FROM npe03__Recurring_Donation__c
                WHERE CALENDAR_YEAR(npe03__Date_Established__c) = :filterYear
                AND CALENDAR_MONTH(npe03__Date_Established__c) >= :startMonth
                AND CALENDAR_MONTH(npe03__Date_Established__c) <= :endMonth
        ]);
    }

    public void execute(Database.BatchableContext bc, List<npe03__Recurring_Donation__c> rds) {
        List<Opportunity> updatedOpps = new List<Opportunity>();
        for (Opportunity opp : [SELECT Id, IsClosed, StageName, CloseDate
                                    FROM Opportunity
                                    WHERE npe03__Recurring_Donation__c IN :rds
                                    AND IsClosed = FALSE
                                    AND CloseDate < 2020-08-01
                                    ORDER BY AccountId
        ]) {
            opp.StageName = 'Closed Won';
            updatedOpps.add(opp);
        }
        update updatedOpps;
    }

    public void finish(Database.BatchableContext bc) { }
}