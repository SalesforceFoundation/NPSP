public interface IDefinePermissions {
    List<FieldAccessDefinition> getFieldAccessDefinitions();
    List<ObjectAccessDefinition> getObjectAccessDefinitions();
    // does user need a custom permission
    // does user need access to a CMT Record

}