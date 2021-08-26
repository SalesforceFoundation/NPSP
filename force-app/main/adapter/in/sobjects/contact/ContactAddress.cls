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
* @description Originally an inner class of CONV_Account_Conversion_BATCH, this class
* has been extracted for additional use as an adapter when Contacts and Addresses are
* inserted.
*/
public class ContactAddress {

    public ContactAddress(Contact c) {
        this.contact = c;
        this.ConId = c.Id;
        this.AccountId = c.AccountId;
        this.MailingStreet = c.MailingStreet;
        this.MailingCity = c.MailingCity;
        this.MailingState = c.MailingState;
        this.MailingZip = c.MailingPostalCode;
        this.MailingCountry = c.MailingCountry;
        this.AddressType = c.npe01__Primary_Address_Type__c;
        this.AddressBlob = Blob.valueOf(c.MailingStreet + c.MailingCity + c.MailingState + c.MailingPostalCode + c.MailingCountry);
    }

    public Contact contact;
    public Id ConId;
    public Id AccountId;
    public String MailingStreet;
    public String MailingCity;
    public String MailingState;
    public String MailingZip;
    public String MailingCountry;
    public String AddressType;
    private Blob AddressBlob;
    private String MD5;

    /*******************************************************************************************************
    * @description Compares a CONV_Account_Conversion_BATCH.ContactAddress object with the current object
    * @param ca A ContactAddress object
    * @return Boolean
    */
    public Boolean isSameAddress(ContactAddress ca) {
        if (this.MailingStreet == ca.MailingStreet &&
                this.MailingCity == ca.MailingCity &&
                this.MailingState == ca.MailingState &&
                this.MailingZip == ca.MailingZip &&
                this.MailingCountry == ca.MailingCountry) {
            return true;
        } else {
            return false;
        }
    }

    /*******************************************************************************************************
    * @description Compares an Address__c object with the current object
    * @param add An Address__c object
    * @return Boolean
    */
    public Boolean isSameAddress(Address__c add) {
        String strStreet = add.MailingStreet__c;
        if (add.MailingStreet2__c != null && add.MailingStreet2__c.length() > 0) {
            strStreet += '\n' + add.MailingStreet2__c;
        }

        if (this.MailingStreet == strStreet &&
                this.MailingCity == add.MailingCity__c &&
                this.MailingState == add.MailingState__c &&
                this.MailingZip == add.MailingPostalCode__c &&
                this.MailingCountry == add.MailingCountry__c) {
            return true;
        } else {
            return false;
        }
    }

    /*******************************************************************************************************
    * @description Gets the MD5 hash of this addresses information. Used for equality comparisons
    * @return String
    */
    public String getMD5() {
        if (MD5 != null) {
            return MD5;
        } else {
            Blob MD5Hash;
            MD5Hash = System.Crypto.generateDigest('MD5', AddressBlob);
            MD5 = EncodingUtil.base64Encode(MD5Hash);
            return MD5;
        }
    }

    /*******************************************************************************************************
    * @description Determines of there is an address value passed
    * @return Boolean
    */
    public Boolean hasAddress() {
        if (MailingStreet != null ||
                MailingCity != null ||
                MailingState != null ||
                MailingZip != null ||
                MailingCountry != null) {
            return true;
        } else {
            return false;
        }
    }
}

