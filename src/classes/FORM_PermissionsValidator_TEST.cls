@isTest
private with sharing class FORM_PermissionsValidator_TEST {

    @isTest
    static void shouldRetrieveTemplateWithPermissionCRUD() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(true,
            FORM_PermissionValidator.OBJECT_CRUD_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(UTIL_Permissions.class,
            utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock); 
        
        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        FORM_PermissionValidator validator = new FORM_PermissionValidator(template,
            new Set<FORM_PermissionValidator.AccessLevel>
                {FORM_PermissionValidator.AccessLevel.VALIDATE_READ,
                FORM_PermissionValidator.AccessLevel.VALIDATE_CREATE,
                FORM_PermissionValidator.AccessLevel.VALIDATE_UPDATE});
        
        FORM_Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isBlank(updatedTemplate.permissionErrors), 'There should be '
            + 'no permission errors when the user has all required CRUD and FLS permissions.');
        
        System.assertEquals(updatedTemplate.permissionErrorType, null, 'The template '
            + 'should not have a permission error type if the user has all required CRUD '
            + 'and FLS permissions.');
    }

    @isTest
    static void shouldRetrieveTemplateWithPermissionFLS() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(true,
            FORM_PermissionValidator.FLS_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
            UTIL_Permissions.class, utilPermissionsMockInstance);

        UTIL_Permissions.setInstance(utilPermissionsMock);
        
        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        FORM_PermissionValidator validator = new FORM_PermissionValidator(template,
            new Set<FORM_PermissionValidator.AccessLevel> {
                FORM_PermissionValidator.AccessLevel.VALIDATE_READ,
                FORM_PermissionValidator.AccessLevel.VALIDATE_CREATE,
                FORM_PermissionValidator.AccessLevel.VALIDATE_UPDATE});
        
        FORM_Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isBlank(updatedTemplate.permissionErrors), 'There should be '
            + 'no permission errors when the user has all required CRUD and FLS permissions.');
        
        System.assertEquals(updatedTemplate.permissionErrorType, null, 'The template '
            + 'should not have a permission error type if the user has all required CRUD '
            + 'and FLS permissions.');
    }
    
    @isTest
    static void shouldRetrieveTemplateWithCRUDErrors() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(false,
            FORM_PermissionValidator.OBJECT_CRUD_ERROR);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
            UTIL_Permissions.class, utilPermissionsMockInstance);

        UTIL_Permissions.setInstance(utilPermissionsMock);
        
        UTIL_UnitTestData_TEST.createSampleFieldMappings();
        
        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        
        FORM_PermissionValidator validator = new FORM_PermissionValidator(template,
            new Set<FORM_PermissionValidator.AccessLevel> {
                FORM_PermissionValidator.AccessLevel.VALIDATE_READ,
                FORM_PermissionValidator.AccessLevel.VALIDATE_CREATE,
                FORM_PermissionValidator.AccessLevel.VALIDATE_UPDATE});
        
        FORM_Template updatedTemplate = validator.validateTemplate();

        System.assert(String.isNotBlank(updatedTemplate.permissionErrors), 'There should '
            + 'be permission errors when the user has no CRUD access to an object.'); 

        System.assertEquals(updatedTemplate.permissionErrorType, 'CRUD', 'The '
            + 'permission error type should be \'CRUD\' when the user does not '
            + 'have CRUD permissions.'); 

        System.assert(updatedTemplate.permissionErrors.contains(Account.SObjectType.getDescribe().getName()), 'The '
            + 'permissions error should contain the Account object, which the user does not '
            + 'have access to.'); 
/*      // Should we be checking the widget permissions right now??
        System.assert(updatedTemplate.permissionErrors.contains('Contact'), 'The '
            + 'permissions error should contain the Contact object, which the user does not have '
            + 'access to.');
*/
    }

    @isTest
    static void shouldRetrieveTemplateWithFLSErrors() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(false,
            FORM_PermissionValidator.FLS_ERROR); 
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
            UTIL_Permissions.class, utilPermissionsMockInstance);

        UTIL_Permissions.setInstance(utilPermissionsMock);
        
        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        UTIL_UnitTestData_TEST.createSampleFieldMappings();
        
        FORM_PermissionValidator validator = new FORM_PermissionValidator(template,
            new Set<FORM_PermissionValidator.AccessLevel> {
                FORM_PermissionValidator.AccessLevel.VALIDATE_READ,
                FORM_PermissionValidator.AccessLevel.VALIDATE_CREATE,
                FORM_PermissionValidator.AccessLevel.VALIDATE_UPDATE});
        
        FORM_Template updatedTemplate = validator.validateTemplate(); 

        System.assert(String.isNotBlank(updatedTemplate.permissionErrors), 'There should '
            + 'be permission errors when the user has no FLS access to an object.');
        System.assertEquals(updatedTemplate.permissionErrorType, 'FLS', 'The '
            + 'permission error type should be \'FLS\' when the user does not have FLS '
            + 'permissions.'); 
        System.assert(updatedTemplate.permissionErrors.contains(Account.BillingCountry.getDescribe().getName()),
            'The permissions error should contain any field the user does not have access '
            + 'to.');
        System.assert(updatedTemplate.permissionErrors.contains(Account.Name.getDescribe().getName()), 'The '
            + 'permissions error should contain any field the user does not have access '
            + 'to.'); 

        /* Should we be testing widget permissions right now??
        System.assert(updatedTemplate.permissionErrors.contains('FirstName'), 'The '
            + 'permissions error should contain any field the user does not have access '
            + 'to.'); 
        System.assert(updatedTemplate.permissionErrors.contains('LastName'), 'The '
            + 'permissions error should contain any field the user does not have access '
            + 'to.');

        */
    }

    private class UTIL_PermissionsMock implements StubProvider {

        Boolean hasPermission;
        Boolean hasCRUDPermission;
        String permissionType;
        Boolean isFLS;

        public UTIL_PermissionsMock(Boolean hasPermission,  String permissionType) {
            this.hasPermission = hasPermission;
            this.permissionType = permissionType;
            this.isFLS = isFLS;
        }

        public Boolean getPermissions(List<Type> listOfParamTypes) {
            Set<Type> paramTypes = new Set<Type>(listOfParamTypes);

            Type objectFields = Type.forName('Set<SObjectField>');

            if(permissionType == FORM_PermissionValidator.FLS_ERROR &&
                !paramTypes.contains(objectFields)) { 
                return true;
            } else {
                return hasPermission;
            }
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
            Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on stubbedMethodName {
                when 'canRead' {
                    return getPermissions(listOfParamTypes);
                }
                when 'canCreate' {
                    return getPermissions(listOfParamTypes);
                }
                when 'canUpdate' {
                    return getPermissions(listOfParamTypes);
                }
            }
            return null;
        }
    }
}
