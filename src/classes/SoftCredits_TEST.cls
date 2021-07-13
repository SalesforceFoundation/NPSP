@isTest
private class SoftCredits_TEST {

    @isTest
    static void shouldHave2OpportunityContactRolesFromAdditionalObjectJSON() {
        String additionalObjectStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        SoftCredits softCredits =
            new AdditionalObjectJSON(additionalObjectStringWithSoftCredits)
            .asSoftCredits();

        System.assertEquals(2, softCredits.size());
        System.assertEquals(2, softCredits.unprocessed().size());
    }

    @isTest
    static void shouldHave0OpportunityContactRoles() {
        String additionalObjectStringWithGeneralAccountUnits =
            new UTIL_AdditionalObjectData_TEST()
            .withGeneralAccountingUnits(3)
            .build();

        SoftCredits softCredits =
            new AdditionalObjectJSON(additionalObjectStringWithGeneralAccountUnits)
            .asSoftCredits();

        System.assertEquals(0, softCredits.size());
        System.assertEquals(0, softCredits.unprocessed().size());
    }

    @isTest
    static void shouldBeAbleToAddMoreOpportunityContactRoles() {
        String additionalObjectStringWithGeneralAccountUnits =
            new UTIL_AdditionalObjectData_TEST()
            .withGeneralAccountingUnits(3)
            .build();

        SoftCredits softCredits =
            new AdditionalObjectJSON(additionalObjectStringWithGeneralAccountUnits)
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
