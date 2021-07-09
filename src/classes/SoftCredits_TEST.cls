@isTest
private class SoftCredits_TEST {

    @isTest
    static void shouldHave2OpportunityContactRolesFromAdditionalObjectJSON() {
        SoftCredits softCredits =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS)
            .asSoftCredits();

        System.assertEquals(2, softCredits.size());
        System.assertEquals(2, softCredits.unprocessed().size());
    }

    @isTest
    static void shouldHave0OpportunityContactRoles() {
        SoftCredits softCredits =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS)
            .asSoftCredits();

        System.assertEquals(0, softCredits.size());
        System.assertEquals(0, softCredits.unprocessed().size());
    }

    @isTest
    static void shouldBeAbleToAddMoreOpportunityContactRoles() {
        SoftCredits softCredits =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS)
            .asSoftCredits();

        System.assertEquals(0, softCredits.size());
        System.assertEquals(0, softCredits.unprocessed().size());

        OpportunityContactRole dummyOpportunityContactRole = new OpportunityContactRole();
        softCredits.add(dummyOpportunityContactRole);

        System.assertEquals(1, softCredits.size());

        List<OpportunityContactRole> dummyOpportunityContactRoles = new List<OpportunityContactRole> {
            new OpportunityContactRole(),
            new OpportunityContactRole(),
            new OpportunityContactRole()
        };
        softCredits.addAll(dummyOpportunityContactRoles);

        System.assertEquals(4, softCredits.size());
    }
}
