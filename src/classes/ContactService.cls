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
* @description Contact Service class in NPSP.
*/
public with sharing class ContactService {

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    @TestVisible
    private AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    /*******************************************************************************************************
    * @description compares two contacts' addresses
    * @param con1 a Contact
    * @param con2 a Contact
    * @return boolean. true if the Mailing Address fields have changed
    ********************************************************************************************************/
    public Boolean isContactAddressChanged(Contact con1, Contact con2) {
        // if both null, no change
        if (con1 == null && con2 == null) {
            return false;
        }

        // if one null, make sure other has at least one address field set
        if (con1 == null || con2 == null) {
            if (con1 == null) {
                con1 = con2;
            }
            return (!isContactAddressEmpty(con1) ||
                    con1.npe01__Primary_Address_Type__c != null);
        }

        // both provided, so look for at least one change between address fields
        Boolean isChanged =
                !addressService.equalsCaseSensitive(con1.MailingStreet, con2.MailingStreet) ||
                        !addressService.equalsCaseSensitive(con1.MailingCity, con2
                                .MailingCity) ||
                        !addressService.equalsCaseSensitive(con1.MailingState, con2
                                .MailingState) ||
                        !addressService.equalsCaseSensitive(con1.MailingPostalCode, con2
                                .MailingPostalCode) ||
                        !addressService.equalsCaseSensitive(con1.MailingCountry, con2
                                .MailingCountry) ||
                        !addressService.equalsCaseSensitive(con1
                                .npe01__Primary_Address_Type__c,
                                con2
                                .npe01__Primary_Address_Type__c);

        if (!isChanged && orgConfig.isStateCountryPicklistsEnabled()) {
            isChanged =
                    !addressService.equalsCaseSensitive(String.valueOf(con1.get
                            ('MailingStateCode')),
                            String.valueOf(con2.get('MailingStateCode'))) ||
                            !addressService.equalsCaseSensitive(String.valueOf(con1.get
                                    ('MailingCountryCode')), String.valueOf(con2.get('MailingCountryCode')));
        }
        return isChanged;
    }

    /*******************************************************************************************************
    * @description returns whether the contact's mailing address is empty
    * @param con1 a Contact
    * @return boolean. true if the Mailing Address fields are all empty
    ********************************************************************************************************/
    public Boolean isContactAddressEmpty(Contact con1) {
        Boolean isEmpty =
                con1.MailingStreet == null &&
                        con1.MailingCity == null &&
                        con1.MailingState == null &&
                        con1.MailingPostalCode == null &&
                        // note that we decided to ignore country so that a default value won't create unnecessary address objects
                        (con1.MailingCountry == null || orgConfig.isStateCountryPicklistsEnabled()) &&
                        // only test StateCode if picklists enabled.
                        (!orgConfig.isStateCountryPicklistsEnabled() || con1.get('MailingStateCode') == null);
        return isEmpty;

    }

}