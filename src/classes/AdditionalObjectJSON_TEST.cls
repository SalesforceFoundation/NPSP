@isTest
private class AdditionalObjectJSON_TEST {
    @isTest
    static void shouldHaveSoftCreditsWithSize2() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(additionalObjectString);
        SoftCredits softCredits = additionalObjectJSON.asSoftCredits();

        System.assertEquals(2, softCredits.size());
    }

    @isTest
    static void shouldHaveSoftCreditsWithSize0() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(0)
            .build();

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(additionalObjectString);
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
