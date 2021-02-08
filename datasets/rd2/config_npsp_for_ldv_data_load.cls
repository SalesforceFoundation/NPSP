/**
* @description Configure NPSP Enhanced Recurring Donation Settings for bulk loading via SnowFakery.
* This script assumes that the all NPSP Settings objects have been properly seeded with default values
* either by loading the NPSP Settings page or running the default_npsp_settings cci task.
* @author Michael Smith
* @date 2020-08-11
*/

/**
 * @description Before the data load:
 * - Validate the RD2 is enabled in the org
 * - Set "First Installment" to never to allow bulk data loading without impacting cpu
 * - Configure automatic naming so that all new RD's are named nicely
 * - Mock the migration just to avoid any validation errors
 * - Configuring the Household Naming format as "{Lastname} {FirstName} Household" so that it's easier to.
 *   read when there are duplicate households with the same last name.
 * - Disable Household Address auto creation
 */
public static void before_data_load() {

    npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
    npe01__Contacts_And_Orgs_Settings__c cAndOSettings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
    %%%NAMESPACE%%%Household_Naming_Settings__c namingSettings = %%%NAMESPACE%%%Household_Naming_Settings__c.getOrgDefaults();

    if (rdSettings.%%%NAMESPACE%%%IsRecurringDonations2Enabled__c == false) {
        String taskName = 'enable_rd2';
        throw new InitException('Enhanced Recurring Donations must be enabled to continue. Execute the "' + taskName + '" first.');
    }

    // Block the first installment from being created to avoid lock errors during the bulk insert
    rdSettings.%%%NAMESPACE%%%DisableRollupsWhenCreatingInstallments__c = true;
    rdSettings.%%%NAMESPACE%%%InstallmentOppFirstCreateMode__c = 'Synchronous';
    rdSettings.%%%NAMESPACE%%%InstallmentOppAutoCreateOption__c = 'Disable_First_Installment';

    // Performance Settings for the RD batch job
    rdSettings.%%%NAMESPACE%%%DisableRollupsWhenCreatingInstallments__c = true;
    rdSettings.%%%NAMESPACE%%%Recurring_Donation_Batch_Size__c = 200;

    // Enable and configure automatic naming for the data load
    rdSettings.%%%NAMESPACE%%%EnableAutomaticNaming__c = true;
    rdSettings.%%%NAMESPACE%%%RecurringDonationNameFormat__c = '{!npe03__Donor_Name__c} {!npe03__Installment_Period__c} $RECURRING_OBJECT_NAME$ - {!npe03__Amount__c}';

    // Mock the migration/enablement state so that the application "thinks" RD2 was fully enabled
    rdSettings.%%%NAMESPACE%%%RecurringDonations2MigrationState__c = '{"run":{"total":1,"processed":0,"failed":1,"batchId":"7076300001YReRcAAL"}}';
    rdSettings.%%%NAMESPACE%%%RecurringDonations2EnablementState__c = '{"isReady":false,"isMigrationEnabled":true,"isMetaLaunched":true,"isMetaConfirmed":true,"isEnabled":true,"isDryRun2":false,"isConfirmed":true,"dryRunLimit":7}';

    upsert rdSettings;

    // Configure the Household Naming default
    namingSettings.%%%NAMESPACE%%%Household_Name_Format__c = '{!LastName} {!{!FirstName}} Household';
    upsert namingSettings;

    // Disable address creation to improve data-load performance significantly
    cAndOSettings.%%%NAMESPACE%%%Household_Account_Addresses_Disabled__c = true;
    upsert cAndOSettings;
}

/**
 * @description: After the data load:
 * - Update RD2 settings to Always create the next installment
 * - Re-enable Household Address Management
 */
public static void after_data_load() {

    npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
    npe01__Contacts_And_Orgs_Settings__c cAndOSettings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();

    // Reset first installment to always
    rdSettings.%%%NAMESPACE%%%DisableRollupsWhenCreatingInstallments__c = false;
    rdSettings.%%%NAMESPACE%%%InstallmentOppFirstCreateMode__c = 'Asynchronous_When_Bulk';
    rdSettings.%%%NAMESPACE%%%InstallmentOppAutoCreateOption__c = 'Always_Create_Next_Installment';
    upsert rdSettings;

    // Re-enable address management after the data load has fully completed.
    cAndOSettings.%%%NAMESPACE%%%Household_Account_Addresses_Disabled__c = false;
    upsert cAndOSettings;
}

public class InitException extends Exception {}