/*
    Copyright (c) 2021 Salesforce.org
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
/**
* @author Salesforce.org
* @date 2021
* @description SoftCredits tests.
*/
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
        System.assertEquals(2, softCredits.all().size());
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
            new OpportunityContactRole(Role='Influencer'),
            new OpportunityContactRole(Role='Honoree'),
            new OpportunityContactRole(Role='Household Member')
        };
        softCredits.addAll(dummyOpportunityContactRoles);

        System.assertEquals(4, softCredits.size());
        System.assertEquals(4, softCredits.all().size());
    }

    @isTest
    static void shouldNotAddDuplicateOpportunityContactRoles() {
        Id dummyContactId0 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id dummyContactId1 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id dummyContactId2 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id dummyContactId3 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);

        List<OpportunityContactRole> dummyOpportunityContactRoles =
            new List<OpportunityContactRole> {
                new OpportunityContactRole(Role='Soft Credit', ContactId=dummyContactId0),
                new OpportunityContactRole(Role='Household Member', ContactId=dummyContactId0),
                new OpportunityContactRole(Role='Influencer', ContactId=dummyContactId1),
                new OpportunityContactRole(Role='Soft Credit', ContactId=dummyContactId2)
            };

        SoftCredits softCredits = new SoftCredits(dummyOpportunityContactRoles);
        softCredits.addAll(dummyOpportunityContactRoles);
        softCredits.addAll(dummyOpportunityContactRoles);
        softCredits.addAll(dummyOpportunityContactRoles);
        softCredits.addAll(dummyOpportunityContactRoles);
        softCredits.addAll(dummyOpportunityContactRoles);

        System.assertNotEquals(24, softCredits.size());
        System.assertEquals(4, softCredits.size());
    }

    @isTest
    static void shouldKeepExistingOpportunityContactRoleWhenNetNewAreDuplicates() {
        SoftCredits softCredits = new SoftCredits(new List<OpportunityContactRole>());

        Id ocrId0 = UTIL_UnitTestData_TEST.mockId(OpportunityContactRole.SObjectType);
        Id dummyContactId0 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        softCredits.add(new OpportunityContactRole(Id=ocrId0, Role='Influencer', ContactId=dummyContactId0));
        softCredits.add(new OpportunityContactRole(Role='Influencer', ContactId=dummyContactId0));
        softCredits.add(new OpportunityContactRole(Role='Influencer', ContactId=dummyContactId0));
        softCredits.add(new OpportunityContactRole(Role='Influencer', ContactId=dummyContactId0));
        softCredits.add(new OpportunityContactRole(Role='Influencer', ContactId=dummyContactId0));

        System.assertEquals(1, softCredits.size());
        System.assertEquals(ocrId0, softCredits.all()[0].Id);
    }
}
