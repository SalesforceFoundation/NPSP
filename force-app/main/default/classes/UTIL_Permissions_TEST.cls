/*
    Copyright (c) 2018 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
@isTest
public with sharing class UTIL_Permissions_TEST {

    // Read Only users don't have access to custom objects or fields
    private static User getReadOnlyUser() {
        return UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);
    }

    // System Administrators have read/write access to custom and standard fields
    private static User getSysAdmin() {
        return UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);
    }

    private static SObjectType customSObjType = Address__c.SObjectType;
    private static SObjectField customSObjField = Address__c.Address_Type__c;
    private static String customObjectName = UTIL_Namespace.StrAllNSPrefix(String.valueOf(customSObjType));
    private static String customFieldName = UTIL_Namespace.StrAllNSPrefix(String.valueOf(customSObjField));
    private static String standardObjectName = 'Contact';
    private static String standardFieldName = 'FirstName';


    @isTest
    static void shouldReturnTrueForUserWithCreateAccessToObjectByString() {
        System.runAs(getSysAdmin()) {
            System.assert(UTIL_Permissions.canCreate(standardObjectName),
                'Privileged user should have create access to standard object.');
        }
    }

    @isTest
    static void shouldThrowExceptionForUserWithoutCreateAccessToObjectByString() {
        System.runAs(getReadOnlyUser()) {
            try {
                UTIL_Permissions.canCreate(standardObjectName);
            } catch (Exception ex) {
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException,
                    'Minimum access user should not have create access to standard object.');
            }
        }
    }

    @isTest
    static void shouldReturnTrueForUserWithReadAccessToObjectByString() {
        System.runAs(getSysAdmin()) {
            System.assert(UTIL_Permissions.canRead(standardObjectName),
                'Privileged user should have read access to standard object.');
        }
    }

    @isTest
    static void shouldThrowExceptionForUserWithoutReadAccessToObjectByString() {
        System.runAs(getReadOnlyUser()) {
            try {
                UTIL_Permissions.canRead(standardObjectName);
            } catch (Exception ex) {
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException,
                    'Minimum access user should not have read access to standard.');
            }
        }
    }

    @isTest
    static void shouldReturnTrueForUserWithEditAccessToObjectByString() {
        System.runAs(getSysAdmin()) {
            System.assert(UTIL_Permissions.canUpdate(standardObjectName),
                'Privileged user should have update access to standard object.');
        }
    }

    @isTest
    static void shouldThrowExceptionForUserWithoutEditAccessToObjectByString() {
        System.runAs(getReadOnlyUser()) {
            try {
                UTIL_Permissions.canUpdate(standardObjectName);
            } catch (Exception ex) {
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException,
                    'Minimum access user should not have edit access to standard.');
            }
        }
    }

    @isTest
    static void shouldReturnTrueForUserWithDeleteAccessToObjectByString() {
        System.runAs(getSysAdmin()) {
            System.assert(UTIL_Permissions.canDelete(standardObjectName),
                'Privileged user should have delete access to standard object.');
        }
    }

    @isTest
    static void shouldThrowExceptionForUserWithoutDeleteAccessToObjectByString() {
        System.runAs(getReadOnlyUser()) {
            try {
                UTIL_Permissions.canDelete(standardObjectName);
            } catch (Exception ex) {
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException,
                    'Minimum access user should not have delete access to standard.');
            }
        }
    }

    @isTest
    static void shouldReturnTrueForUserWithDeleteAccessToSObjectType() {
        System.runAs(getSysAdmin()) {
            UTIL_Permissions utilPermissions = UTIL_Permissions.getInstance();
            System.assert(utilPermissions.canDelete(Contact.SObjectType),
                'Privileged user should have delete access to standard object.');
        }
    }

    @isTest
    static void shouldReturnTrueForUserWithCreateAccessToFieldByDescribeFieldResult() {
        System.runAs(getSysAdmin()) {
            System.assert(UTIL_Permissions.canCreate(Contact.LastName.getDescribe()),
                'Privileged user should have create access to standard field.');
        }
    }

    @isTest
    static void shouldThrowExceptionForUserWithoutCreateAccessToFieldByDescribeFieldResult() {
        System.runAs(getReadOnlyUser()) {
            try {
                UTIL_Permissions.canCreate(Contact.LastName.getDescribe());
            } catch (Exception ex) {
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException,
                    'Minimum access user should not have create access to standard field.');
            }
        }
    }

    @isTest
    static void shouldReturnFalseForUserWithoutCreateAccessToFieldByString() {
        System.runAs(getReadOnlyUser()) {
            System.assert(!UTIL_Permissions.canCreate(standardObjectName, standardFieldName, false),
                'Minimum access user should not have create access to standard field.');
        }
    }

    @isTest
    static void shouldReturnFalseForUserWithoutReadAccessToCustomFieldByString() {
        System.runAs(getReadOnlyUser()) {
            System.assert(!UTIL_Permissions.canRead(customObjectName, customFieldName, false),
                'Minimum access user should not have read access to custom field.');
        }
    }

    @isTest
    static void shouldReturnFalseForUserWithoutUpdateAccessToFieldByString() {
        System.runAs(getReadOnlyUser()) {
            System.assert(!UTIL_Permissions.canUpdate(standardObjectName, standardFieldName, false),
                'Minimum access user should not have update access to standard field.');
        }
    }

    @isTest
    static void shouldReturnFalseForUserWithoutDeleteAccessToCustomFieldByString() {
        System.runAs(getReadOnlyUser()) {
            System.assert(!UTIL_Permissions.canUpdate(customObjectName, customFieldName, false),
                'Minimum access user should not have delete access to custom field.');
        }
    }

    @isTest
    static void readOnlyUserCannotReadCustomObjectException() {
        Boolean exceptionCaught = false;

        System.runAs(getReadOnlyUser()) {
            try {
                System.assert(!UTIL_Permissions.canRead(customObjectName));
            } catch (Exception ex) {
                exceptionCaught = true;
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException);
            }
        }

        System.assert(exceptionCaught);
    }

    @isTest
    static void readOnlyUserCannotUpdateStandardObjectException() {
        Boolean exceptionCaught = false;

        System.runAs(getReadOnlyUser()) {
            try {
                System.assert(!UTIL_Permissions.canUpdate(customObjectName));
            } catch (Exception ex) {
                exceptionCaught = true;
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException);
            }
        }

        System.assert(exceptionCaught);
    }

    @isTest
    static void sysAdminCanDeleteCustomObjectException() {
        Boolean exceptionCaught = false;

        System.runAs(getSysAdmin()) {
            try {
                System.assert(UTIL_Permissions.canDelete(customObjectName));
            } catch (Exception ex) {
                exceptionCaught = true;
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException);
            }
        }

        System.assert(!exceptionCaught);
    }

    @isTest
    static void sysAdminObjectCheckNoException() {
        System.runAs(getSysAdmin()) {
            System.assert(UTIL_Permissions.canRead(customObjectName, false));
            System.assert(UTIL_Permissions.canCreate(customObjectName, false));
            System.assert(UTIL_Permissions.canUpdate(customObjectName, false));
            System.assert(UTIL_Permissions.canDelete(customObjectName, false));
            System.assert(UTIL_Permissions.canRead(standardObjectName, false));
            System.assert(UTIL_Permissions.canCreate(standardObjectName, false));
            System.assert(UTIL_Permissions.canUpdate(standardObjectName, false));
            System.assert(UTIL_Permissions.canDelete(standardObjectName, false));
        }
    }

    @isTest
    static void readOnlyUserCannotReadCustomFieldException() {
        Boolean exceptionCaught = false;

        System.runAs(getReadOnlyUser()) {
            try {
                System.assert(!UTIL_Permissions.canRead(customObjectName, customFieldName));
            } catch (Exception ex) {
                exceptionCaught = true;
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException);
            }
        }

        System.assert(exceptionCaught);
    }

    @isTest
    static void readOnlyUserCannotUpdateStandardFieldException() {
        Boolean exceptionCaught = false;

        System.runAs(getReadOnlyUser()) {
            try {
                System.assert(!UTIL_Permissions.canUpdate(customObjectName, customFieldName));
            } catch (Exception ex) {
                exceptionCaught = true;
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException);
            }
        }

        System.assert(exceptionCaught);
    }

    @isTest
    static void sysAdminCanUpdateCustomFieldException() {
        Boolean exceptionCaught = false;

        System.runAs(getSysAdmin()) {
            try {
                System.assert(UTIL_Permissions.canUpdate(customObjectName, customFieldName));
            } catch (Exception ex) {
                exceptionCaught = true;
                System.assert(ex instanceof UTIL_Permissions.InsufficientPermissionException);
            }
        }

        System.assert(!exceptionCaught);
    }

    @isTest
    static void sysAdminFieldCheckNoException() {
        System.runAs(getSysAdmin()) {
            DescribeFieldResult customFieldResult =
                UTIL_Describe.getFieldDescribe(customObjectName, customFieldName);
            DescribeFieldResult standardFieldResult =
                UTIL_Describe.getFieldDescribe(standardObjectName, standardFieldName);

            System.assert(UTIL_Permissions.canRead(customObjectName, customFieldName, false));
            System.assert(UTIL_Permissions.canCreate(customObjectName, customFieldName, false));
            System.assert(UTIL_Permissions.canUpdate(customObjectName, customFieldName, false));
            System.assert(UTIL_Permissions.canRead(standardObjectName, standardFieldName, false));
            System.assert(UTIL_Permissions.canCreate(standardObjectName, standardFieldName, false));
            System.assert(UTIL_Permissions.canUpdate(standardObjectName, standardFieldName, false));
            System.assert(UTIL_Permissions.canRead(customFieldResult, false));
            System.assert(UTIL_Permissions.canCreate(customFieldResult, false));
            System.assert(UTIL_Permissions.canUpdate(customFieldResult, false));
            System.assert(UTIL_Permissions.canRead(standardFieldResult, false));
            System.assert(UTIL_Permissions.canCreate(standardFieldResult, false));
            System.assert(UTIL_Permissions.canUpdate(standardFieldResult, false));
        }
    }

    @isTest
    private static void shouldReturnFalseForReadOnlyUserOnCustomObjectAndFields() {
        UTIL_Permissions perms = new UTIL_Permissions();

        System.runAs(getReadOnlyUser()) {
            System.assert(!perms.canRead(customSObjType, new Set<SObjectField>{ customSObjField }), 'Read user should not have read access to the custom object/field.');
            System.assert(!perms.canUpdate(customSObjType, new Set<SObjectField>{ customSObjField }), 'Read user should not have update access to the custom object/field.');
        }
    }

    @isTest
    private static void shouldReturnTrueForAdminUserOnCustomObjectAndFields() {
        UTIL_Permissions perms = new UTIL_Permissions();

        System.runAs(getSysAdmin()) {
            System.assert(perms.canRead(customSObjType, new Set<SObjectField>{ customSObjField }), 'Admin user should have read access to the custom object/field.');
            System.assert(perms.canUpdate(customSObjType, new Set<SObjectField>{ customSObjField }), 'Admin user should have read access to the custom object/field.');
        }
    }

    /***
    * @description Stub for UTIL_Permissions instance
    */
    public class Stub implements System.StubProvider {
        public Boolean hasRead = true;
        public Boolean hasUpdate = true;
        public Boolean hasCreate = true;
        public Boolean hasDelete = true;
        public SObjectType readSObjType;
        public SObjectType updateSObjType;
        public SObjectType createSObjType;
        public SObjectType deleteSObjType;
        public Set<SObjectField> readSObjFields = new Set<SObjectField>();
        public Set<SObjectField> updateSObjFields = new Set<SObjectField>();
        public Set<SObjectField> createSObjFields = new Set<SObjectField>();

        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'canRead' {
                    readSObjType = (SObjectType) args[0];
                    readSObjFields = getArgumentFields(args);

                    return hasRead;

                } when 'canUpdate' {
                    updateSObjType = (SObjectType) args[0];
                    updateSObjFields = getArgumentFields(args);

                    return hasUpdate;

                } when 'canCreate' {
                    createSObjType = (SObjectType) args[0];
                    createSObjFields = getArgumentFields(args);

                    return hasCreate;

                } when 'canDelete' {
                    deleteSObjType = (SObjectType) args[0];

                    return hasDelete;

                } when else {
                    return null;
                }
            }
        }

        /***
        * @description Extracts SObject fields from the second argument if specified
        * @param args Method arguments
        * @return Set<SObjectField> Fields specified in the second argument of the stubbed method
        */
        private Set<SObjectField> getArgumentFields(List<Object> args) {
            return args.size() > 1 ? (Set<SObjectField>) args[1] : new Set<SObjectField>();
        }
    }


}