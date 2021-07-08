@isTest
private class GiftView_TEST {

    @isTest
    static void shouldReturnGiftViewWithDataImport() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);
        GiftDTO giftDTO = new GiftDTO(gift);
        GiftView giftView = new GiftView(giftDTO);

        System.assertEquals(dataImport, giftView.dataImport);
    }

    @isTest
    static void shouldReturnGiftViewWith2SoftCredits() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS
        );
        Gift gift = new Gift(dataImport);
        GiftDTO giftDTO = new GiftDTO(gift);
        GiftView giftView = new GiftView(giftDTO);

        System.assertEquals(2, giftView.softCredits.size());
    }

    static final String DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS = '{"name":"Additional_Object_JSON__c","dynamicSourceByObjMappingDevName":{"Opportunity_Contact_Role_1temp2":{"sourceObj":{"attributes":{"type":"DataImport__c"},"Opportunity_Contact_Role_1_Role__c":"Household Member","Contact1Imported__c":"0035600000VNllNAAT"},"objectMappingTemplateDevName":"Opportunity_Contact_Role_1","objectMappingDevName":"Opportunity_Contact_Role_1temp2","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"},"Opportunity_Contact_Role_1temp1":{"sourceObj":{"attributes":{"type":"DataImport__c"},"Opportunity_Contact_Role_1_Role__c":"Matched Donor","Contact1Imported__c":"0035600000VNllSAAT"},"objectMappingTemplateDevName":"Opportunity_Contact_Role_1","objectMappingDevName":"Opportunity_Contact_Role_1temp1","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"}}}';
}
