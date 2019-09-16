/**
* @description Validates that Recurring Donations 2 has been enabled in an org. Throws an exception if it hasn't been.
* Note that this needs to work when a full Managed NPSP package is installed in an org.
* @author Michael Smith
* @date 2019-09-17
*/
public class SettingsException extends Exception {}

public static Boolean validateRd2Enabled() {
    npe03__Recurring_Donations_Settings__c rdSettings = npe03__Recurring_Donations_Settings__c.getInstance();
    if (rdSettings == null) {
        rdSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
    }
    if (rdSettings == null || rdSettings.IsRecurringDonations2Enabled__c != true) {
        throw new SettingsException('Enhanced Recurring Donations must be enabled in this org in order to continue');
    }

    return true;
}
