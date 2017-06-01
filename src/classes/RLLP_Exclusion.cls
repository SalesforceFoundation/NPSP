//how will this work for user defined exclusions?
public interface RLLP_Exclusion {

    Boolean isExcluded(SObject detail);

    /*public enum Comparison {EQUALS, NOT_EQUALS, GREATER, LESS, GREATER_OR_EQUAL, LESS_OR_EQUAL, STARTS_WITH, CONTAINS}
    
    public Schema.SObjectType objectType;
    public Schema.SObjectField field1;
    public Schema.SObjectField field2;
    public Comparison comparison;
    public String constant;

    public RLLP_Exclusion() {}

    public Boolean isExcluded(SObject detail) {
        //TODO: throw exceptoin if type of detail doesn't match exclusion type? or just assume and don't allow attribution object based exclusion? we need it for soft credits
        //TODO: verify type of fields is the same when allowing externally defined types
        for (Exclusion exclusion : exclusions) {
            Object value1 = detail.get(exclusion.field1);
            Object value2 = detail.get(exclusion.field2);
        }
        return false;
    }*/
}