public with sharing class PermissionsChecker {
    private IDefinePermissions definedPermissions;

    private List<FieldAccessDefinition> readFields;
    private List<FieldAccessDefinition> editFields;
    private List<ObjectAccessDefinition> readObjects;
    private List<ObjectAccessDefinition> editObjects;
    private List<ObjectAccessDefinition> deleteObjects;
    private List<ObjectAccessDefinition> createObjects;

    @TestVisible
    private UTIL_Permissions utilPermissions {
        get {
            if (utilPermissions == null) {
                utilPermissions = new UTIL_Permissions();
            }
            return utilPermissions;
        }
        set;
    }

    public PermissionsChecker(IDefinePermissions definedPermissions) {
        this.definedPermissions = definedPermissions;
        this.initializeAccessDefinitionsByLevel();
        this.populateAccessDefinitionsByLevel();
    }

    public void initializeAccessDefinitionsByLevel() {
        this.readFields = new List<FieldAccessDefinition>();
        this.editFields = new List<FieldAccessDefinition>();
        this.readObjects = new List<ObjectAccessDefinition>();
        this.editObjects = new List<ObjectAccessDefinition>();
        this.deleteObjects = new List<ObjectAccessDefinition>();
        this.createObjects = new List<ObjectAccessDefinition>();
    }

    public void populateAccessDefinitionsByLevel() {
        for (FieldAccessDefinition fieldAccessDef : definedPermissions.getFieldAccessDefinitions()) {
            if (fieldAccessDef.level == DataAccessLevel.READ) {
                this.readFields.add(fieldAccessDef);
            } else if (fieldAccessDef.level == DataAccessLevel.MODIFY) {
                this.editFields.add(fieldAccessDef);
            }
        }

        for (ObjectAccessDefinition objectAccessDef : definedPermissions.getObjectAccessDefinitions()) {
            if (objectAccessDef.level == DataAccessLevel.READ) {
                this.readObjects.add(objectAccessDef);
            }

            if (objectAccessDef.level == DataAccessLevel.CREATE) {
                this.createObjects.add(objectAccessDef);
            }

            if (objectAccessDef.level == DataAccessLevel.MODIFY) {
                this.editObjects.add(objectAccessDef);
            }

            if (objectAccessDef.level == DataAccessLevel.DEL) {
                this.deleteObjects.add(objectAccessDef);
            }
        }
    }

    public Boolean hasFieldPermissions() {
        return true;
    }

    public Boolean hasObjectPermissions() {
        for (ObjectAccessDefinition objectAccessDef : definedPermissions.getObjectAccessDefinitions()) {

        }

        return false;
    }
    
    public Boolean hasFieldPermissionsStripInaccessible(List<SObject> sObjectsToCheck) {
        Boolean hasNecessaryEditAccess = this.hasEditPermissionsStripInaccessible(sObjectsToCheck);
        Boolean hasNecessaryReadAccess = this.hasReadPermissionsStripInaccessible(sObjectsToCheck);
        SObjectAccessDecision editDecision = Security.stripInaccessible(AccessType.UPDATABLE, sObjectsToCheck);

        return false;
    }

    private Boolean hasReadPermissionsStripInaccessible(List<SObject> sObjects) {
        SObjectAccessDecision readDecision = Security.stripInaccessible(AccessType.READABLE, sObjects);
        Map<String, Set<String>> removedFields = readDecision.getRemovedFields();
        for (FieldAccessDefinition fieldAccessDef : this.readFields) {

        }
    }

    private Boolean hasEditPermissionsStripInaccessible(List<SObject> sObjects) {
        return true;
    }

    public Boolean hasObjectPermissionsStripInaccessible(List<SObject> sObjectsToCheck) {
        return false;
    }


    private List<FieldAccessDefinition> fieldsWithoutReadAccess(List<FieldAccessDefinition> fieldAccessDefinitions) {
        return new List<FieldAccessDefinition>();
    }
}