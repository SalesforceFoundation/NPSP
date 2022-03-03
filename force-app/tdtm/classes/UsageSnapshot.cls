public without sharing virtual class UsageSnapshot {

    protected Datetime timeStamp;
    protected UsageIncrement increment;

    protected UsageSnapshot() {
    }

    public UsageSnapshot(Datetime timeStamp, UsageIncrement usageIncrement) {
        this.increment = usageIncrement;
        this.timeStamp = timeStamp;
    }

    public UsageIncrement usageIncrement() {
        return increment;
    }

     public Datetime timeStamp() {
        return timeStamp;
    }
}