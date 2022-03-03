public without sharing class TriggerHandlerRunResultFake extends TriggerHandlerRunResult {

    @TestVisible
    private TriggerHandlerRunResultFake(
            String serviceName,
            String action,
            SObjectType sObjType
    ) {
        this.service = serviceName;
        this.action = action;
        this.sObjType = sObjType;
        this.start = new UsageSnapshotFake(1);
        this.stop = new UsageSnapshotFake(2);
    }
}