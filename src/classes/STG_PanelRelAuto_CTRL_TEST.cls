@IsTest
private class STG_PanelRelAuto_CTRL_TEST {

    @IsTest
    static void userHasAccess() {
       User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert('System Administrator');

        System.runAs(adminUser) {
            STG_PanelRelAuto_CTRL controller = new STG_PanelRelAuto_CTRL();
            Boolean hasAccess = controller.getHasAccess();

            System.assertEquals(true, hasAccess, 'The access check should return true if the user has ' +
                    'access to the Relationship_Auto_Create__c custom setting object');
        }
    }

    @IsTest
    static void userHasNoAccess() {
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert('Standard User');

        System.runAs(standardUser) {
            STG_PanelRelAuto_CTRL controller = new STG_PanelRelAuto_CTRL();
            Boolean hasAccess = controller.getHasAccess();

            System.assertEquals(false, hasAccess, 'The access check should return false if the user does NOT have ' +
                    'access to the Relationship_Auto_Create__c custom setting object');
        }
    }
}