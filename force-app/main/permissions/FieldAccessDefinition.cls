public with sharing class FieldAccessDefinition {
    public Schema.SObjectField field;
    private Boolean isOptional;

    public FieldAccessDefinition(Schema.SObjectField field, Boolean isOptional) {
        this.isOptional = isOptional;
        this.field = field;
    }

    public Boolean isRequiredAccess() {
        return !this.isOptional;
    }

    public String getFieldName() {
        return String.valueOf(this.field);
    }

    public FieldAccessDefinition(SObjectField field) {
        this(field, false);
    }

    public class FieldAccessDefinitionException extends Exception {}
}