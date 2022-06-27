/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @description Tests for the Address Service class in NPSP.
*/
@IsTest
private class AddressServiceTests_TEST {

    private static OrgConfig orgConfig = new OrgConfig();

    /**
     * @description in order to be effective this test must be run in an Org that has State
     * & Country picklists enabled.
     * NPSP's in-memory map, validStatesByLabel(), has no way of knowing which State is
     * applicable for which Country. The platform does and will automatically populate the
     * state code depending on the value in the Country (or CountryCode) value.
     */
    @IsTest
    static void shouldDirectlySetStateCodeValue() {
        if (!orgConfig.isStateCountryPicklistsEnabled()) {
            return;
        }

        // Arrange
        String stateName = 'Minnesota';
        String stateCode = 'MN';
        Contact aContact = new Contact();
        IAddress anAddress = new NPSP_Address(
                new Address__c(
                        MailingState__c = stateName,
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
        System.assertEquals(stateCode, aContact.get('MailingStateCode'),
                'The copyOntoSObject method should be setting State Code values.');
    }

    @IsTest
    static void shouldCopyUndeliverableStatus(){
        // Arrange
        Contact aContact = new Contact();
        IAddress anUndeliverableAddress = new NPSP_Address(
                new Address__c(
                        Undeliverable__c = true
                )
        );
        AddressService addressService = new AddressService();

        // Act
        addressService.copyOntoSObject(
                anUndeliverableAddress,
                aContact,
                'Mailing',
                null
        );

        // Assert
        System.assertEquals(true, aContact.Undeliverable_Address__c,
                'The copyOntoSObject method should map the Addresses undeliverable status.');
    }
}