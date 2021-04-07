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
* @description Address Service class in NPSP.
*/
public inherited sharing class AddressService {

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

    /*******************************************************************************************************
    * @description Utility to copy Address fields between Contacts and Accounts (or vice-versa).
    * Handles instances where State and Country picklists are enabled, and multiline street addresses.
    * @param sobjSrc the source Contact or Account
    * @param strFieldPrefixSrc the address fields to copy from, ie., Mailing, Other, Shipping, Billing
    * @param sobjDst the destination Contact or Account
    * @param strFieldPrefixDst the address fields to copy to, ie., Mailing, Other, Shipping, Billing
    */
    public void copyAddressStdSObj(SObject sobjSrc, String strFieldPrefixSrc, SObject sobjDst, String strFieldPrefixDst) {
        sobjDst.put(strFieldPrefixDst + 'Street', sobjSrc.get(strFieldPrefixSrc + 'Street'));
        sobjDst.put(strFieldPrefixDst + 'City', sobjSrc.get(strFieldPrefixSrc + 'City'));
        sobjDst.put(strFieldPrefixDst + 'PostalCode', sobjSrc.get(strFieldPrefixSrc + 'PostalCode'));
        sobjDst.put(strFieldPrefixDst + 'State', sobjSrc.get(strFieldPrefixSrc + 'State'));
        sobjDst.put(strFieldPrefixDst + 'Country', sobjSrc.get(strFieldPrefixSrc + 'Country'));
        sobjDst.put(strFieldPrefixDst + 'Latitude', sobjSrc.get(strFieldPrefixSrc + 'Latitude'));
        sobjDst.put(strFieldPrefixDst + 'Longitude', sobjSrc.get(strFieldPrefixSrc + 'Longitude'));

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            sobjDst.put(strFieldPrefixDst + 'StateCode', sobjSrc.get(strFieldPrefixSrc + 'StateCode'));
            sobjDst.put(strFieldPrefixDst + 'CountryCode', sobjSrc.get(strFieldPrefixSrc + 'CountryCode'));
        }
    }

    /*******************************************************************************************************
    * @description utility to compare a Contact or Account address to the Address record
    * @param sObj Account or Contact
    * @param addr Address
    * @return boolean. true if any of the Address fields on the Contact are different from this Address record
    */
    public Boolean isSObjectAddressDifferent(SObject sObj, Address__c addr) {
        if (sObj == null || addr == null) {
            return false;
        }
        Boolean isContact = (sObj.getSObjectType() == Contact.SObjectType);
        String prefix = (isContact ? 'Mailing' : 'Billing');

        Boolean isDifferent = (
                !equalsCaseSensitive((String) sObj.get(prefix + 'Street'), getMultilineStreet(addr)) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'City'), addr.MailingCity__c) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'State'), addr.MailingState__c) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'PostalCode'), addr.MailingPostalCode__c) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'Country'), addr.MailingCountry__c) ||
                        (Decimal) sObj.get(prefix + 'Latitude') != addr.Geolocation__Latitude__s ||
                        (Decimal) sObj.get(prefix + 'Longitude') != addr.Geolocation__Longitude__s ||
                        (isContact &&
                                (!equalsCaseSensitive((String) sObj.get('npe01__Primary_Address_Type__c'), addr.Address_Type__c) ||
                                        !equalsCaseSensitive((String) sObj.get('Current_Address__c'), addr.Id))
                        )
        );
        return isDifferent;
    }

    /*******************************************************************************************************
    * @description Returns whether two strings are equal, using a case sensitve comparison
    * @param str1 The first string
    * @param str2 The second string
    * @return boolean
    ********************************************************************************************************/
    public Boolean equalsCaseSensitive(String str1, String str2) {
        if (str1 == null) {
            return str2 == null;
        }
        if (str2 == null) {
            return false;
        }
        return str1.equals(str2);
    }

    /*******************************************************************************************************
    * @description utility to combine mailing street fields into a single string with embedded CR LF
    * @param addr the Address to look at
    * @return boolean
    */
    public String getMultilineStreet(Address__c addr) {
        Boolean isOneLineStreetAddress = String.isBlank(addr.MailingStreet2__c);
        if (isOneLineStreetAddress) {
            return addr.MailingStreet__c;
        }
        return addr.MailingStreet__c + '\r\n' + addr.MailingStreet2__c;
    }

}