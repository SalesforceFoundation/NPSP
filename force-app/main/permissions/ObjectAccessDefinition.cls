public with sharing class ObjectAccessDefinition {
    public DataAccessLevel level; // level is also used for field access
    public Schema.SObjectType sObjectType;
    public Boolean isOptional; // rename to isRequired
    private Map<String, FieldAccessDefinition> fieldAccessDefinitionsByName;

    public ObjectAccessDefinition(Schema.SObjectType sObjectType, DataAccessLevel level, Boolean isOptional) {
        this.fieldAccessDefinitionsByName = new Map<String, FieldAccessDefinition>();
        this.sObjectType = sObjectType;
        this.isOptional = isOptional;
        this.level = level;
    }

    public ObjectAccessDefinition(Schema.SObjectType sObjectType, DataAccessLevel level) {
        this(sObjectType, level, false);
    }

    public Set<Schema.SObjectField> getRequiredAccessFields() {
        return getRequiredFields(fieldAccessDefinitionsByName.values());
    }

    private Set<Schema.SObjectField> getRequiredFields(List<FieldAccessDefinition> fieldAccessDefinitions) {
        Set<Schema.SObjectField> fieldNames = new Set<Schema.SObjectField>();
        for (FieldAccessDefinition fieldAccessDefinition : fieldAccessDefinitions) {
            if (fieldAccessDefinition.isRequired()) {
                fieldNames.add(fieldAccessDefinition.field);
            }
        }
        return fieldNames;
    }

    public ObjectAccessDefinition addField(FieldAccessDefinition fieldAccessDefinition) {
        this.fieldAccessDefinitionsByName.put(fieldAccessDefinition.getFieldName(), fieldAccessDefinition);
        return this;
    }

    public ObjectAccessDefinition addFields(List<FieldAccessDefinition> fieldAccessDefinitions) {
        for (FieldAccessDefinition fieldAccessDefinition : fieldAccessDefinitions) {
            this.addField(fieldAccessDefinition);
        }
        return this;
    }

}