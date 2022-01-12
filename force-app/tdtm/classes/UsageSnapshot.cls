public without sharing virtual class UsageSnapshot {

    private LimitsMonitor limitsMonitor {
        get {
            if (limitsMonitor == null) {
                limitsMonitor = new LimitsMonitor();
            } return limitsMonitor;
        }
        set;
    }

    private Clock clock {
        get {
            if (clock == null) {
                clock = new Clock();
            }
            return clock;
        }
        set;
    }

    protected Long timeUsedMillis;
    protected Integer queriesUsed;
    protected Integer cpuUsed;
    protected Integer dmlRows;
    protected Datetime timeStamp;

    public UsageSnapshot() {
        this.timeUsedMillis = clock.getCurrentTimeMillis();
        this.queriesUsed = limitsMonitor.queries();
        this.cpuUsed = limitsMonitor.cpuTime();
        this.dmlRows = limitsMonitor.dmlRows();
        this.timeStamp = clock.timeStamp();
    }

    public UsageIncrement getIncrementFrom(UsageSnapshot offsetUsage) {
        return new UsageIncrement(
            timeMillis() - offsetUsage.timeUsedMillis,
                queries() - offsetUsage.queriesUsed,
                cpuTime() - offsetUsage.cpuUsed,
                dmlRows() - offsetUsage.dmlRows
        );
    }

    public virtual Integer dmlRows() {
        return dmlRows;
    }

    public virtual Integer cpuTime() {
        return cpuUsed;
    }

    public virtual Integer queries() {
        return queriesUsed;
    }

    public virtual Long timeMillis() {
        return timeUsedMillis;
    }

    public virtual Datetime timeStamp() {
        return timeStamp;
    }

    public Boolean isEqualTo(UsageSnapshot usageSnapshot) {
        return dmlRows() == usageSnapshot.dmlRows();
    }

}