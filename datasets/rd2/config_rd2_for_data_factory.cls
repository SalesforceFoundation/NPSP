/**
* @description Configure NPSP Enhanced Recurring Donation Settings for bulk loading via SnowFakery. This
* script assumes that the default_npsp_settings task was previously executed against the org.
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
 */
public static void before_data_load() {

    npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
    %%%NAMESPACE%%%Household_Naming_Settings__c namingSettings = %%%NAMESPACE%%%Household_Naming_Settings__c.getOrgDefaults();

    if (rdSettings.IsRecurringDonations2Enabled__c == false) {
        throw new InitException('Enhanced Recurring Donations must be enabled to continue. Execute the "enable_rd2" first.');
    }

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

    // Configure the Household Naming default
    namingSettings.Household_Name_Format__c = '{!LastName} {!{!FirstName}} Household';
    upsert namingSettings;
}

/**
 * @description: After the data load:
 * - Update RD2 settings to Always create the next installment
 */
public static void after_data_load() {

    npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();

    // Reset first installment to always
    rdSettings.DisableRollupsWhenCreatingInstallments__c = false;
    rdSettings.InstallmentOppFirstCreateMode__c = 'Asynchronous_When_Bulk';
    rdSettings.InstallmentOppAutoCreateOption__c = 'Always_Create_Next_Installment';

    upsert rdSettings;
}

public class InitException extends Exception {}