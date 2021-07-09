@isTest
private class AdditionalObjectJSON_TEST {
    @isTest
    static void shouldHaveSoftCreditsWithSize2() {
        AdditionalObjectJSON additionalObjectJSON =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(2, softCredits.size());
    }

    @isTest
    static void shouldHaveSoftCreditsWithSize0() {
        AdditionalObjectJSON additionalObjectJSON =
            new AdditionalObjectJSON(UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(0, softCredits.size());
    }

    @isTest
    static void shouldHaveSoftCreditsWithSize0ForNullAdditionalObjectJSONField() {
        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(null);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(0, softCredits.size());
    }
}
