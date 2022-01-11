public without sharing class UsageSnapshotFake extends UsageSnapshot {

    private Integer val;

    public UsageSnapshotFake(Integer val){
       this.val = val;
    }

    public override Integer dmlRows() {
        return val;
    }

    public override Integer cpuTime() {
        return val;
    }

    public override Integer queries() {
        return val;
    }

    public override Long timeMillis() {
        return val;
    }

}