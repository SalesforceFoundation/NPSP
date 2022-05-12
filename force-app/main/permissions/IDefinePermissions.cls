public interface IDefinePermissions {
    List<ObjectAccessDefinition> getAccessDefinitions();
    // does user need a custom permission
    // does user need access to a CMT Record
}