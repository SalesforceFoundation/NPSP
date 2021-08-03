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
@isTest
private class GiftDTO_TEST {

    @isTest
    static void shouldReturnGift() {
        GiftDTO dummyGiftDTO = new GiftDTO();
        dummyGiftDTO.fields = new Map<String, Object>();
        dummyGiftDTO.fields.put('Id', DUMMY_DATA_IMPORT_ID);
        dummyGiftDTO.fields.put(ACCOUNT1_IMPORTED_FIELD, DUMMY_ACCOUNT_ID);
        dummyGiftDTO.fields.put(DONATION_AMOUNT_FIELD, 55.55);
        Gift dummyGift = dummyGiftDTO.asGift();

        System.assertEquals(DUMMY_DATA_IMPORT_ID, dummyGift.fields().get('Id'));
        System.assertEquals(DUMMY_ACCOUNT_ID, dummyGift.fields().get(ACCOUNT1_IMPORTED_FIELD));
        System.assertEquals(55.55, dummyGift.fields().get(DONATION_AMOUNT_FIELD));
    }

    @isTest
    static void shouldReturnGiftWithSoftCredits() {
        List<OpportunityContactRole> dummyOpportunityContactRoles = buildDummyOCRs(5);
        SoftCredits dummySoftCredits = new SoftCredits(dummyOpportunityContactRoles);
        SoftCreditsDTO softCreditsDTO = new SoftCreditsDTO(dummySoftCredits);

        String additionalObjectJSONStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
                .withOpportunityContactRoles(3)
                .build();
        GiftDTO dummyGiftDTO = new GiftDTO();
        dummyGiftDTO.fields = new Map<String, Object>();
        dummyGiftDTO.fields.put(ADDITIONAL_OBJECT_JSON_FIELD, additionalObjectJSONStringWithSoftCredits);
        dummyGiftDTO.softCreditsDTO = softCreditsDTO;

        Gift dummyGift = dummyGiftDTO.asGift();

        System.assertEquals(8, dummyGift.softCredits().size());
        System.assertEquals(3, dummyGift.softCredits().unprocessed().size());
    }

    @isTest
    static void shouldHaveExpectedPropertiesWhenConstructedWithAGenericMap() {
        List<OpportunityContactRole> dummyOpportunityContactRoles = buildDummyOCRs(5);
        SoftCredits dummySoftCredits = new SoftCredits(dummyOpportunityContactRoles);
        SoftCreditsDTO dummySoftCreditsDTO = new SoftCreditsDTO(dummySoftCredits);

        Map<String, Object> giftDTOAsGenericMap = new Map<String, Object>();
        giftDTOAsGenericMap.put('fields', new Map<String, Object> {
            'Id' => DUMMY_DATA_IMPORT_ID,
            ACCOUNT1_IMPORTED_FIELD => DUMMY_ACCOUNT_ID
        });
        giftDTOAsGenericMap.put('softCreditsDTO', dummySoftCreditsDTO);

        GiftDTO dummyGiftDTO = new GiftDTO(giftDTOAsGenericMap);

        System.assertEquals(DUMMY_DATA_IMPORT_ID, dummyGiftDTO.fields.get('Id'));
        System.assertEquals(dummySoftCreditsDTO, dummyGiftDTO.softCreditsDTO);
    }

    @isTest
    static void shouldHaveExpectedPropertiesWhenConstructedWithAGift() {
        String additionalObjectStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        DataImport__c dummyDataImport = new DataImport__c(
            Id = DUMMY_DATA_IMPORT_ID,
            Account1Imported__c = DUMMY_ACCOUNT_ID,
            Donation_Amount__c = 33.33,
            Additional_Object_JSON__c = additionalObjectStringWithSoftCredits
        );
        Gift dummyGift = new Gift(dummyDataImport);

        GiftDTO dummyGiftDTO = new GiftDTO(dummyGift);

        System.assertEquals(33.33, dummyGiftDTO.fields.get(DONATION_AMOUNT_FIELD));
        System.assertEquals(DUMMY_ACCOUNT_ID, dummyGiftDTO.fields.get(ACCOUNT1_IMPORTED_FIELD));
        System.assertEquals(DUMMY_DATA_IMPORT_ID, dummyGiftDTO.fields.get('Id'));
        System.assertEquals(2, dummyGiftDTO.softCreditsDTO.softCredits.size());
    }

    private static List<OpportunityContactRole> buildDummyOCRs(Integer count) {
        List<OpportunityContactRole> dummyOpportunityContactRoles = new List<OpportunityContactRole>();
        for (Integer i = 0; i < count; i++) {
            OpportunityContactRole dummyOCR = new OpportunityContactRole(
                Id = UTIL_UnitTestData_TEST.mockId(OpportunityContactRole.sObjectType),
                Role = 'DUMMY ROLE ' + i,
                ContactId = UTIL_UnitTestData_TEST.mockId(Contact.sObjectType)
            );

            dummyOpportunityContactRoles.add(dummyOCR);
        }
        return dummyOpportunityContactRoles;
    }

    private static final String DONATION_AMOUNT_FIELD = String.valueOf(DataImport__c.Donation_Amount__c);
    private static final String ACCOUNT1_IMPORTED_FIELD = String.valueOf(DataImport__c.Account1Imported__c);
    private static final String ADDITIONAL_OBJECT_JSON_FIELD = String.valueOf(DataImport__c.Additional_Object_JSON__c);
    private static final String DUMMY_DATA_IMPORT_ID = UTIL_UnitTestData_TEST.mockId(DataImport__c.sObjectType);
    private static final String DUMMY_ACCOUNT_ID = UTIL_UnitTestData_TEST.mockId(Account.sObjectType);
}
