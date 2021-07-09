@isTest
private class SoftCredits_TEST {

    @isTest
    static void shouldReturn2OpportunityContactRolesFromAdditionalObjectJSON() {
        SoftCredits softCredits =
            new SoftCredits(null, UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS);

        System.assertEquals(2, softCredits.all().size());
        System.assertEquals(2, softCredits.size());
    }

    @isTest
    static void shouldReturn0OpportunityContactRoles() {
        SoftCredits softCredits =
            new SoftCredits(null, UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS);

        System.assertEquals(0, softCredits.all().size());
        System.assertEquals(0, softCredits.size());
    }
}
