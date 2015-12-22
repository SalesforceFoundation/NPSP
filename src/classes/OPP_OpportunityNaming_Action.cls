/**
* @author Christian Carter @cdcarter
* @date 2015 (12.25)
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description Provides an action to generate Opportunity names for lists of opps
*/
global class OPP_OpportunityNaming_Action {
    /*******************************************************************************************************
    * @description invocable method to update the opportunity names for the specified Opps
    * @param oppIds the list of opportunity IDs
    * @return void
    */

	@InvocableMethod(label='Rename Opportunities' description='Runs automatic opportunity naming for the selected opportunity IDs.')
  	global static void renameOpportunities(List<ID> oppIds) {
    	Savepoint sp = Database.setSavepoint();
        try {
            List<Opportunity> oppsToUpdate = [SELECT Id FROM Opportunity WHERE Id IN :oppIds];
            oppsToUpdate = OPP_OpportunityNaming.getOppNamesAfterInsert(oppsToUpdate);
            update oppsToUpdate;
        } catch(Exception e) {
        	Database.rollback(sp);
        	ERR_Handler.processError(e, ERR_Handler_API.Context.OPP);
        }
  	}
}
