/**
* @description Configure NPSP Enhanced Recurring Donation Settings for bulk loading via SnowFakery. This
* script assumes that the default_npsp_settings task was previously executed against the org.
* @author Michael Smith
* @date 2020-08-11
*/
public static void initialize_RD2_Settings() {

    npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();

    // Block the first installment from being created to avoid lock errors during the bulk insert
    rdSettings.DisableRollupsWhenCreatingInstallments__c = true;
    rdSettings.InstallmentOppFirstCreateMode__c = 'Asynchronous_When_Bulk';
    rdSettings.InstallmentOppAutoCreateOption__c = 'Disable_First_Installment';

    // Enable and configure automatic naming
    rdSettings.EnableAutomaticNaming__c = true;
    rdSettings.RecurringDonationNameFormat__c = '{!npe03__Donor_Name__c} {!npe03__Installment_Period__c} $RECURRING_OBJECT_NAME$ - {!npe03__Amount__c}';

    // Mock the migration/enablement state so that the application "thinks" RD2 was fully enabled
    rdSettings.RecurringDonations2MigrationState__c = '{"run":{"total":1,"processed":0,"failed":1,"batchId":"7076300001YReRcAAL"}}';
    rdSettings.RecurringDonations2EnablementState__c = '{"isReady":false,"isMigrationEnabled":true,"isMetaLaunched":true,"isMetaConfirmed":true,"isEnabled":true,"isDryRun2":false,"isConfirmed":true,"dryRunLimit":7}';

    upsert rdSettings;
}