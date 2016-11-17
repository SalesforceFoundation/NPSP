/**
* @author Christian Carter @cdcarter
* @date 2015 (12.25)
* @group Households
* @description Provides an action to generatehousehold names for lists of households
* NOTE: This class handles both household naming for the Household__c object
* as well as for HH Account objects.
*/
global class HH_HouseholdNaming_Action {
    /*******************************************************************************************************
    * @description invocable method to update the household names for the specified households
    * @param hhids the list of household Id's (either Household__c or Account Id's)
    * @return void
    */

	@InvocableMethod(label='Rename Households' description='Runs automatic household naming for the selected household IDs.')
  	global static void renameHouseholds(List<ID> hhids) {
  		HH_HouseholdNaming hn = new HH_HouseholdNaming();
    	Savepoint sp = Database.setSavepoint();
        try {
            hn.UpdateNames(hhids);
        } catch(Exception e) {
        	Database.rollback(sp);
        	ERR_Handler.processError(e, ERR_Handler_API.Context.HH);
        }
  	}
}
