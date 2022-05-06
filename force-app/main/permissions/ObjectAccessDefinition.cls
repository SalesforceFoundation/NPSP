public with sharing class ObjectAccessDefinition {
    public DataAccessLevel level;
    public Schema.SObjectType sObjectType;
    public Boolean isOptional;

    public ObjectAccessDefinition(Schema.SObjectType sObjectType, DataAccessLevel level, Boolean isOptional) {
        this.sObjectType = sObjectType;
        this.isOptional = isOptional;
        this.level = level;
    }

    public ObjectAccessDefinition(Schema.SObjectType sObjectType, DataAccessLevel level) {
        this(sObjectType, level, false);
    }

}