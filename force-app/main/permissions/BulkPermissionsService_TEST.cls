@IsTest
private class BulkPermissionsService_TEST {
    private class TestPermissions implements IDefinePermissions {
        public List<ObjectAccessDefinition> definitions = new List<ObjectAccessDefinition>();
        public List<ObjectAccessDefinition> getAccessDefinitions() {
            return definitions;
        }

        public ObjectAccessDefinition getAccessDefinitionsByObjectName(String objectName) {
            return null;
        }
    }

    @IsTest
    static void noReadAccess() {
        TestPermissions perms = new TestPermissions();
        ObjectAccessDefinition accountAccess = new ObjectAccessDefinition(Account.SObjectType, DataAccessLevel.READ);
        accountAccess.addFields(new List<FieldAccessDefinition>{
                new FieldAccessDefinition(Account.Name),
                new FieldAccessDefinition(Account.npo02__Formal_Greeting__c)
        });
        perms.definitions.add(accountAccess);
        UTIL_PermissionsMock mockPerms = new UTIL_PermissionsMock()
                .setNoFieldAccess(Account.Name)
                .setNoFieldAccess(Account.npo02__Formal_Greeting__c);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class,
                mockPerms);
        BulkPermissionsService checker = new BulkPermissionsService(perms);
        checker.utilPermissions = utilPermissionsMock;
        PermissionsInfo info = checker.getRequiredPermissionsInfo();
        System.debug(JSON.serializePretty(info));
        System.assertEquals(false, info.hasRequiredRead, 'Expected to not have read access.');
    }

    @IsTest
    static void noEditAccess() {

    }

    @IsTest
    static void noCreateAccess() {

    }

    @IsTest
    static void noDeleteAccess() {

    }

    @IsTest
    static void partialReadAccess() {

    }

    @IsTest
    static void partialEditAccess() {

    }

    @IsTest
    static void partialCreateAccess() {

    }

    @IsTest
    static void partialDeleteAccess() {

    }

    public class UTIL_PermissionsMock implements System.StubProvider {

        final String READ_ACCESS = 'READ';
        final String EDIT_ACCESS = 'EDIT';
        final String DEL_ACCESS = 'DELETE';
        final String CREATE_ACCESS = 'CREATE';
        final String NO_ACCESS = 'NONE';

        public Boolean defaultResult = true;
        private Map<Schema.SObjectField, String> fieldToAccessLevelMap;
        private Map<Schema.SObjectType, String> sObjectTypeToAccessLevel;

        public UTIL_PermissionsMock() {
            this.fieldToAccessLevelMap = new Map<Schema.SObjectField, String>();
        }

        public UTIL_PermissionsMock setCanRead(Schema.SObjectField field) {
            return this.setFieldAccessLevel(field, READ_ACCESS);
        }

        public UTIL_PermissionsMock setCanEdit(Schema.SObjectField field) {
            return this.setFieldAccessLevel(field, EDIT_ACCESS);
        }

        public UTIL_PermissionsMock setCanCreate(Schema.SObjectType sObjectType) {
            return this.setObjectAccessLevel(sObjectType, CREATE_ACCESS);
        }

        public UTIL_PermissionsMock setCanDelete(Schema.SObjectType sObjectType) {
            return this.setObjectAccessLevel(sObjectType, DEL_ACCESS);
        }

        public UTIL_PermissionsMock setNoObjectAccess(Schema.SObjectType sObjectType) {
            return this.setObjectAccessLevel(sObjectType, NO_ACCESS);
        }
        public UTIL_PermissionsMock setNoFieldAccess(Schema.SObjectField field) {
            return this.setFieldAccessLevel(field, NO_ACCESS);
        }

        private UTIL_PermissionsMock setObjectAccessLevel(Schema.SObjectType sObjectType, String accessLevel) {
            sObjectTypeToAccessLevel.put(sObjectType, accessLevel);
            return this;
        }

        private UTIL_PermissionsMock setFieldAccessLevel(Schema.SObjectField field, String accessLevel) {
            fieldToAccessLevelMap.put(field, accessLevel);
            return this;
        }

        private Boolean canRead(Schema.SObjectField field) {
            String accessLevel = fieldToAccessLevelMap.get(field);
            if (accessLevel == READ_ACCESS || accessLevel == EDIT_ACCESS) {
                return true;
            } else if (accessLevel == NO_ACCESS) {
                return false;
            }
            return defaultResult;
        }

        private Boolean canRead(Set<Schema.SObjectField> fields) {
            for (Schema.SObjectField field : fields) {
                if (!this.canRead(field)) {
                    return false;
                }
            }
            return true;
        }

        private Boolean canUpdate(Set<Schema.SObjectField> fields) {
            for (Schema.SObjectField field : fields) {
                if (!this.canUpdate(field)) {
                    return false;
                }
            }
            return true;
        }

        private Boolean canUpdate(Schema.SObjectField field) {
            String accessLevel = fieldToAccessLevelMap.get(field);
            if (accessLevel == EDIT_ACCESS) {
                return true;
            } else if (accessLevel == NO_ACCESS || accessLevel == READ_ACCESS) {
                return false;
            }
            return defaultResult;
        }

        public Object handleMethodCall(
                Object stubbedObject,
                String stubbedMethodName,
                System.Type returnType,
                List<System.Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            if (stubbedMethodName == 'canRead') {
                Set<Schema.SObjectField> fields = (Set<Schema.SObjectField>)listOfArgs[1];
                return this.canRead(fields);
            } else if (stubbedMethodName == 'canUpdate') {
                Set<Schema.SObjectField> fields = (Set<Schema.SObjectField>)listOfArgs[1];
                return this.canUpdate(fields);
            } else if (stubbedMethodName == 'canDelete') {

            } else if (stubbedMethodName == 'canCreate') {

            }

            return defaultResult;
        }
    }
}