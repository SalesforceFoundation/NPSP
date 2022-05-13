public with sharing class BulkPermissionsService {
    private IDefinePermissions definedPermissions;

    private List<ObjectAccessDefinition> readAccessDefinitions;
    private List<ObjectAccessDefinition> editAccessDefinitions;
    private List<ObjectAccessDefinition> deleteAccessDefinitions;
    private List<ObjectAccessDefinition> createAccessDefinitions;

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

    public BulkPermissionsService(IDefinePermissions definedPermissions) {
        this.definedPermissions = definedPermissions;
        this.initializeAccessDefinitionsByLevel();
        this.populateAccessDefinitionsByLevel();
    }

    public void initializeAccessDefinitionsByLevel() {
        this.readAccessDefinitions = new List<ObjectAccessDefinition>();
        this.editAccessDefinitions = new List<ObjectAccessDefinition>();
        this.deleteAccessDefinitions = new List<ObjectAccessDefinition>();
        this.createAccessDefinitions = new List<ObjectAccessDefinition>();
    }

    public void populateAccessDefinitionsByLevel() {
        for (ObjectAccessDefinition objectAccessDef : definedPermissions.getAccessDefinitions()) {
            if (objectAccessDef.level == DataAccessLevel.READ) {
                this.readAccessDefinitions.add(objectAccessDef);
            } else if (objectAccessDef.level == DataAccessLevel.CREATE) {
                this.createAccessDefinitions.add(objectAccessDef);
            } else if (objectAccessDef.level == DataAccessLevel.MODIFY) {
                this.editAccessDefinitions.add(objectAccessDef);
            } else if (objectAccessDef.level == DataAccessLevel.DEL) {
                this.deleteAccessDefinitions.add(objectAccessDef);
            }
        }
    }

    public PermissionsInfo getRequiredPermissionsInfo() {
        PermissionsInfo permInfo = new PermissionsInfo();

        permInfo.hasRequiredRead = this.hasAllReadPermissions();
        permInfo.hasRequiredEdit = this.hasAllEditPermissions();
        permInfo.hasRequiredCreate = this.hasAllCreatePermissions();
        permInfo.hasRequiredDelete = this.hasAllDeletePermissions();

        return permInfo;
    }

    private Boolean hasAllDeletePermissions() {
        for (ObjectAccessDefinition deleteAccessDef : this.deleteAccessDefinitions) {
            if (!this.hasRequiredDeletePermissions(deleteAccessDef)) {
                return false;
            }
        }
        return true;
    }

    private Boolean hasAllReadPermissions() {
        for (ObjectAccessDefinition readAccessDef : this.readAccessDefinitions) {
            if (!this.hasRequiredReadPermissions(readAccessDef)) {
                return false;
            }
        }
        return true;
    }

    private Boolean hasAllEditPermissions() {
        for (ObjectAccessDefinition editAccessDef : this.editAccessDefinitions) {
            if (!this.hasRequiredEditPermissions(editAccessDef)) {
                return false;
            }
        }
        return true;
    }

    private Boolean hasAllCreatePermissions() {
        for (ObjectAccessDefinition createAccessDef : this.createAccessDefinitions) {
            if (!this.hasRequiredCreatePermissions(createAccessDef)) {
                return false;
            }
        }
        return true;
    }

    private Boolean hasRequiredCreatePermissions(ObjectAccessDefinition objectAccessDef) {
        Set<Schema.SObjectField> fieldRefs = objectAccessDef.getRequiredAccessFields();
        return utilPermissions.canCreate(objectAccessDef.sObjectType, fieldRefs);
    }

    private Boolean hasRequiredDeletePermissions(ObjectAccessDefinition objectAccessDef) {
        return utilPermissions.canDelete(objectAccessDef.sObjectType);
    }

    private Boolean hasRequiredEditPermissions(ObjectAccessDefinition objectAccessDef) {
        Set<Schema.SObjectField> fieldRefs = objectAccessDef.getRequiredAccessFields();
        return utilPermissions.canUpdate(objectAccessDef.sObjectType, fieldRefs);
    }

    private Boolean hasRequiredReadPermissions(ObjectAccessDefinition objectAccessDef) {
        Set<Schema.SObjectField> fieldRefs = objectAccessDef.getRequiredAccessFields();
        return utilPermissions.canRead(objectAccessDef.sObjectType, fieldRefs);
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
//        for (FieldAccessDefinition fieldAccessDef : this.readFields) {
//
//        }

        return false;
    }

    private Boolean hasEditPermissionsStripInaccessible(List<SObject> sObjects) {
        SObjectAccessDecision editDecision = Security.stripInaccessible(AccessType.UPDATABLE, sObjects);
        Map<String, Set<String>> removedFields = editDecision.getRemovedFields();
        Set<Schema.SObjectField> requiredFieldNames;
        for (String objectName : removedFields.keySet()) {
            Set<String> removedFieldNames = removedFields.get(objectName);
            if (removedFieldNames.size() == 0) {
                continue;
            }
            ObjectAccessDefinition objectAccess = definedPermissions.getAccessDefinitionsByObjectName(objectName);
            requiredFieldNames = objectAccess.getRequiredAccessFields(); // used to return Set<String>
        }
        // return requiredFieldNames.retainAll(removedFieldNames);
        return false;
    }

    public Boolean hasObjectPermissionsStripInaccessible(List<SObject> sObjectsToCheck) {
        return false;
    }


    private List<FieldAccessDefinition> fieldsWithoutReadAccess(List<FieldAccessDefinition> fieldAccessDefinitions) {
        return new List<FieldAccessDefinition>();
    }
}