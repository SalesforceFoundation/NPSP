public with sharing class FieldAccessDefinition {
    public Schema.SObjectField field;
    public DataAccessLevel level;
    public Boolean isOptional;

    public FieldAccessDefinition(SObjectField field, DataAccessLevel level, Boolean isOptional) {
        this.isOptional = isOptional;
        this.field = field;
        if (level == DataAccessLevel.DEL || level == DataAccessLevel.CREATE) {
            throw new FieldAccessDefinitionException('Cannot define FieldAccessDefinition with access level: ' + this.level.name());
        }
        this.level = level;
    }

    public FieldAccessDefinition(SObjectField field, DataAccessLevel level) {
        this(field, level, false);
    }

    public class FieldAccessDefinitionException extends Exception {}
}