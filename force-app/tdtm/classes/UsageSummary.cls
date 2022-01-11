public without sharing class UsageSummary {

    private List<UsageSnapshot> snapshots;

    public UsageSummary(List<UsageSnapshot> usageSnapshots){
        this.snapshots = usageSnapshots;
    }

    public Integer totalQueries(){
        Integer total = 0;
        for (UsageSnapshot usageSnapshot : snapshots) {
            total += usageSnapshot.queries();
        }
        return total;
    }

    public Integer totalCpu(){
        Integer total = 0;
        for (UsageSnapshot usageSnapshot : snapshots) {
            total += usageSnapshot.cpuTime();
        }
        return total;
    }

    public Integer totalDmlRows(){
        Integer total = 0;
        for (UsageSnapshot usageSnapshot : snapshots) {
            total += usageSnapshot.dmlRows();
        }
        return total;
    }

    public Long totalTimeMillis(){
        Long total = 0;
        for (UsageSnapshot usageSnapshot : snapshots) {
            total += usageSnapshot.timeMillis();
        }
        return total;
    }

}