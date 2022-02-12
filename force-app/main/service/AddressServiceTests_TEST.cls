@IsTest
private class AddressServiceTests_TEST {

    /**
     * @description in order to be effective this test must be run in an Org that has State
     * & Country picklists enabled.
     * NPSP's in-memory map, validStatesByLabel(), has no way of knowing which State is
     * applicable for which Country. The platform does and will automatically populate the
     * state code depending on the value in the Country (or CountryCode) value.
     */
    @IsTest
    static void shouldNotDirectlySetStateCodeValue() {
        if (!stateAndCountryPicklistsEnabled()) {
            return;
        }

        // Arrange
        Contact aContact = new Contact();
        IAddress anAddress = new NPSP_Address(
                new Address__c(
                        MailingState__c = 'Montana',
                        MailingCountry__c = 'United States'
                )
        );
        AddressService addressService = new AddressService();

        // Act
        addressService.copyOntoSObject(
                anAddress,
                aContact,
                'Mailing',
                null
        );

        // Assert
        System.assertEquals(null, aContact.get('MailingStateCode'),
                'The copyOntoSObject method should not be setting State Code values.');
    }

    private static Boolean stateAndCountryPicklistsEnabled() {
        fflib_SObjectDescribe accountDescribe =
                fflib_SObjectDescribe.getDescribe(Account.SObjectType);
        SObjectField sObjectField = accountDescribe.getField('BillingStateCode');
        return sObjectField != null;
    }
}