@isTest
private class SoftCreditsView_TEST {
    @isTest
    static void shouldReturn2OpportunityContactRolesFromAdditionalObjectJSON() {
        String additionalObjectStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        SoftCredits softCredits =
            new AdditionalObjectJSON(additionalObjectStringWithSoftCredits)
            .asSoftCredits();
        SoftCreditsDTO softCreditsDTO = new SoftCreditsDTO(softCredits);
        SoftCreditsView softCreditsView = new SoftCreditsView(softCreditsDTO);

        System.assertEquals(2, softCreditsView.all.size());
    }

    @isTest
    static void shouldReturn0OpportunityContactRoles() {
        String additionalObjectStringWithGeneralAccountUnits =
            new UTIL_AdditionalObjectData_TEST()
            .withGeneralAccountingUnits(3)
            .build();

        SoftCredits softCredits =
            new AdditionalObjectJSON(additionalObjectStringWithGeneralAccountUnits)
            .asSoftCredits();
        SoftCreditsDTO softCreditsDTO = new SoftCreditsDTO(softCredits);
        SoftCreditsView softCreditsView = new SoftCreditsView(softCreditsDTO);

        System.assertEquals(0, softCreditsView.all.size());
    }
}

