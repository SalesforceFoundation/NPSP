public interface INamingExclusions {

    Boolean isExcludedFromName(SObject sobj);
    Boolean isExcludedFromFormalGreeting(SObject sobj);
    Boolean isExcludedFromInformalGreeting(SObject sobj);

}