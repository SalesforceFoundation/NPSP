public without sharing class UsageSnapshotFake extends UsageSnapshot {

    public UsageSnapshotFake(Integer val) {
        this.timeStamp = System.now();
        this.increment = new UsageIncrement(val, val, val, val);
    }
}