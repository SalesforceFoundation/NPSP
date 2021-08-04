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
* @description AdditionalObjectJSON tests.
*/
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

    @isTest
    static void shouldAddSoftCreditsToDynamicSourceGroup() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withGeneralAccountingUnits(3)
            .build();

        AdditionalObjectJSON additionalObjectJSON = new AdditionalObjectJSON(additionalObjectString);

        String dummyContactId0 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        String dummyContactId1 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        String dummyContactId2 = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        List<OpportunityContactRole> dummyOCRs = new List<OpportunityContactRole> {
            new OpportunityContactRole(Role = 'Influencer', ContactId = dummyContactId0),
            new OpportunityContactRole(Role = 'Soft Credit', ContactId = dummyContactId1)
        };

        SoftCredits dummySoftCredits = new SoftCredits(dummyOCRs);

        BDI_DynamicSourceGroup dynamicSourceGroup = additionalObjectJSON.dynamicSourceGroup;
        System.assertEquals(dynamicSourceGroup.dynamicSourceByObjMappingDevName.values().size(), 3);

        additionalObjectJSON.add(dummySoftCredits);

        System.assertEquals(dynamicSourceGroup.dynamicSourceByObjMappingDevName.values().size(), 5);

        String backToJSON = additionalObjectJSON.asJSON();
        System.assert(backToJSON.contains(dummyContactId0));
        System.assert(backToJSON.contains(dummyContactId1));
        System.assert(!backToJSON.contains(dummyContactId2));
    }
}
