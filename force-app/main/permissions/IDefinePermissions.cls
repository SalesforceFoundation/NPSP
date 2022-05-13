public interface IDefinePermissions {
    List<ObjectAccessDefinition> getAccessDefinitions();
    ObjectAccessDefinition getAccessDefinitionsByObjectName(String objectName); // for StripInaccessible comparisons
    // List<CustomMetadataAccessDefinition> getCMTAccessDefinitions();
    // does user need a custom permission
    // does user need access to a CMT Record
}