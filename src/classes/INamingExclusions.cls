public interface INamingExclusions {

    Boolean isExcludedFromName();
    Boolean isExcludedFromFormalGreeting();
    Boolean isExcludedFromInformalGreeting();
    Boolean equals(INamingExclusions other);
    void synchronizeFrom(INamingExclusions other);
    boolean hasNamingExclusions();
}