/*******************************************************************************************************
* @description Holds information about addresses.  Used for determining primacy of Contact addresses and deduplication
*/
public class ContactAddress{

    public ContactAddress(Contact c){
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
    * @param ca An Address__c object
    * @return Boolean
    */
    public Boolean isSameAddress(Address__c add) {
        string strStreet = add.MailingStreet__c;
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

