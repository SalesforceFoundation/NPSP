@isTest
private class SoftCreditsView_TEST {
    @isTest
    static void shouldReturn2OpportunityContactRolesFromAdditionalObjectJSON() {
        SoftCredits softCredits =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS)
            .asSoftCredits();
        SoftCreditsDTO softCreditsDTO = new SoftCreditsDTO(softCredits);
        SoftCreditsView softCreditsView = new SoftCreditsView(softCreditsDTO);

        System.assertEquals(2, softCreditsView.all.size());
    }

    @isTest
    static void shouldReturn0OpportunityContactRoles() {
        SoftCredits softCredits =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS)
            .asSoftCredits();
        SoftCreditsDTO softCreditsDTO = new SoftCreditsDTO(softCredits);
        SoftCreditsView softCreditsView = new SoftCreditsView(softCreditsDTO);

        System.assertEquals(0, softCreditsView.all.size());
    }
}

