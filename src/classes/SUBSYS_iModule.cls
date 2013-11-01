public interface SUBSYS_iModule {

    void runFuture(Set<Id> newList, Set<Id> oldList, String ta, String obj);
    void run(List<Sobject> newlist, List<Sobject> oldlist, SUBSYS_triggerAction ta, 
            Schema.Describesobjectresult obj);
}