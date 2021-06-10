/*******************************************************************************************************
* @description a class to retrieve DataImport__c records with derived donor information.
*/
public class GiftUIModel {
    @AuraEnabled public String donorName;
    @AuraEnabled public String donorLink;
    @AuraEnabled public String matchedRecordUrl;
    @AuraEnabled public String matchedRecordLabel;
    @AuraEnabled public DataImport__c record;
    @AuraEnabled public List<String> errors;

    public GiftUIModel(DataImport__c record) {
        getDonorInfo(record);
        setDryRunRecordInfo(record);
        this.record = record;
    }

    private void getDonorInfo(DataImport__c record) {
        String donorName = '';
        if (record.Donation_Donor__c == 'Account1' && record.Account1Imported__c != null) {
            this.donorName = record.Account1Imported__r.Name;
            this.donorLink = '/'+record.Account1Imported__c;
        }
        if (record.Donation_Donor__c == 'Contact1' && record.Contact1Imported__c != null) {
            this.donorName = record.Contact1Imported__r.Name;
            this.donorLink = '/'+record.Contact1Imported__c;
        }
    }

    /***************************************************************************************************
    * @description sets DataImport__c record with matching url or failure information matching based on
    * the BDI_Donations setDryRunDonationStatuses
    * @param record: the DataImport__c record to check for matches
    */
    private void setDryRunRecordInfo(DataImport__c record) {
        try {
            String matchedUrl = '';
            String matchedUrlLabel = '';
            List<String> errors = new List<String>();

            Boolean donationMatched = (record.DonationImported__c != null);
            Boolean paymentMatched = (record.PaymentImported__c != null);
            Boolean importFailure = (record.FailureInformation__c != null);

            if (paymentMatched) {
                //if there is a match, set url, preferably for the payment
                String importedId = record.PaymentImported__c;
                matchedUrlLabel = record.PaymentImported__r.Name;
                matchedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + importedId;
            } else if (donationMatched) {
                String importedId = record.DonationImported__c;
                matchedUrlLabel = record.DonationImported__r.Name;
                matchedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + importedId;
            }

            if (importFailure) {

                //if Donation and Payment didn't have matched or matched none status, then an error was set
                if (record.DonationImportStatus__c != null
                        && !donationMatched) {
                    errors.add(record.DonationImportStatus__c);
                }
                if (record.PaymentImportStatus__c != null
                        && !paymentMatched
                        && record.PaymentImportStatus__c != record.DonationImportStatus__c) {
                    errors.add(record.PaymentImportStatus__c);
                }

                //get any additional errors
                if (record.FailureInformation__c != record.PaymentImportStatus__c
                        && record.FailureInformation__c != record.DonationImportStatus__c) {
                    errors.add(record.FailureInformation__c);
                }
            }

            this.matchedRecordUrl = matchedUrl;
            this.matchedRecordLabel = matchedUrlLabel;
            this.errors = errors;

        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}