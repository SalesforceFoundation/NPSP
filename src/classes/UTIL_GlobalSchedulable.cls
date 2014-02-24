public with sharing class UTIL_GlobalSchedulable implements Schedulable {

    public Interface IScheduled {
        void execute(SchedulableContext context);
    }
    
    public void execute(SchedulableContext context) {
        UTIL_GlobalSchedulableHelper.runJobs(context);
    }
}