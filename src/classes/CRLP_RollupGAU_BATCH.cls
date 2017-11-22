public class CRLP_RollupGAU_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /*******************************************************************************************************
    * @description Stateful collection of Rollups to process
    */
    public List<CRLP_Rollup> statefulRollups;
    public Id currentGAUId;

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_RollupGAU_BATCH() {
        // Init the stateful rollups collection
        this.statefulRollups = new List<CRLP_Rollup>();
    }

    /*******************************************************************************************************
    * @description Query all Allocation records for the rollups. Using Allocations as the primary object to
    * fully support LDV orgs and data skew scenarios.
    * @param bc BatchableContext passed by the system call
    * @return database.Querylocator
    */
    public database.Querylocator start(Database.BatchableContext bc) {
        // Build a query string of the Allocation__c object. By default this query will include all Opportunity
        // fields referred to by any rollup against the Allocation object.
        String query = CRLP_Query_SEL.getDetailsQuery(Allocation__c.SObjectType, new List<SObjectType>()) +
                ' WHERE Opportunity__c != null';
        // TODO Review the above query to ensure it's fully selective. Could consider using RecurringDonation = Null ...
        return Database.getQueryLocator(query);
    }

    /*******************************************************************************************************
    * @description Handle each group of Allocation records to roll-up. A Stateful collection of CRLP_Rollup
    * instances is used to allow for potentially more than 50k Allocation records attached to a single GAU.
    * @param bc BatchableContext passed by the system call
    * @param scope List of Allocation__c records
    */
    public void execute(Database.BatchableContext bc, List<Allocation__c> scope) {
        List<General_Accounting_Unit__c> gausToUpdate = processBatchOfAllocations(scope);
        if (gausToUpdate.size() > 0) {
            // TODO Implement AllOrNothing logic
            database.update(gausToUpdate);
        }
    }

    public void finish(Database.BatchableContext bc) {

    }

    // ================================================================================================================
    // ================================================================================================================

    /*******************************************************************************************************
    * @description Does the actual work needed to roll-up a group of Allocation Records to a GAU. The Stateful
    * collection of CRLP_Rollup instances is either reset or passed to a new instance of the CRLP_RollupGAU_SVC
    * class.
    * @param allocations List of Allocation__c records
    * @return General_Accounting_Unit__c[] List of GAU records to be updated.
    */
    public List<General_Accounting_Unit__c> processBatchOfAllocations(List<Allocation__c> allocations) {
        // Get the Parent GeneralAccountingUnit records referenced by the Allocation recors in the query scope
        Set<Id> gauIds = new Set<Id>();
        for (Allocation__c alloc : allocations) {
            gauIds.add(alloc.General_Accounting_Unit__c);
        }
        String gauQuery = CRLP_Query_SEL.getResultsQuery(General_Accounting_Unit__c.SObjectType) +
                ' WHERE Id IN :gauIds';
        Map<Id, General_Accounting_Unit__c> parentGAUMap = new Map<Id, General_Accounting_Unit__c>( (List<General_Accounting_Unit__c>)database.query(gauQuery) );

        // Loop through the batch of Allocations to handle
        List<General_Accounting_Unit__c> gausToUpdate = new List<General_Accounting_Unit__c>();
        List<Allocation__c> allocsToRollupForOneGAU = new List<Allocation__c>();
        for (Allocation__c alloc : allocations) {
            if (this.currentGAUId == null) {
                // First time through!
                this.currentGAUId = alloc.General_Accounting_Unit__c;

            } else if (this.currentGAUId != alloc.General_Accounting_Unit__c) {
                // Has the GauId changed for this allocation record? If so, then call the completeAllocationRollup()
                // method to finalize the rollup for that GAU

                General_Accounting_Unit__c updatedGau = completeAllocationRollup(allocsToRollupForOneGAU, parentGAUMap.get(this.currentGAUId));
                if (updatedGau != null) {
                    gausToUpdate.add(updatedGau);
                }

                // Initiate the next GAU Id add add the record to the collection for the next loop around
                this.currentGAUId = alloc.General_Accounting_Unit__c;

                // Clear the collection of allocations that are passed to the completeAllocationRollup() methodl
                allocsToRollupForOneGAU.clear();
            }
            // Add the current Allocation record to the list for the current GAU.
            allocsToRollupForOneGAU.add(alloc);
        }

        // If there are Allocations not yet rolled up, initiate the rollup of these records and allow the
        // Rollup data to be saved in the Stateful vars. The next batch iteration will see that there are more
        // records to process for this GAU and continue the process.
        if (allocsToRollupForOneGAU.size() > 0) {
            // Initiate the next GAU Id add add the record to the collection for the next loop around,
            // but DO NOT add the updated GAU to the list of records to update (yet?)
            // TODO WHAT IF THIS IS THE LAST RECORD IN THE ENTIRE BATCH?
            General_Accounting_Unit__c updatedGau = completeAllocationRollup(allocsToRollupForOneGAU, parentGAUMap.get(this.currentGAUId));
            if (updatedGau != null) {
                gausToUpdate.add(updatedGau);
            }
        }
        return gausToUpdate;
    }

    private General_Accounting_Unit__c completeAllocationRollup(List<Allocation__c> allocs, General_Accounting_Unit__c gau) {
        // The GAU.Id has changed, so initiate the rollup and
        CRLP_RollupGAU_SVC handler;
        if (this.statefulRollups.size() == 0) {
            handler = new CRLP_RollupGAU_SVC(this.currentGAUId);
        } else {
            handler = new CRLP_RollupGAU_SVC(this.currentGAUId, this.statefulRollups);
        }
        // gauRollup.setCurrencyCode();
        handler.processRollups(allocs);
        General_Accounting_Unit__c updatedGAU = (General_Accounting_Unit__c)handler.getPopulatedSObject();
        if (CRLP_Rollup_SVC.resultsNeedUpdate(gau, updatedGAU, handler.rollups)) {
            return updatedGAU;
        } else {
            System.Debug(LoggingLevel.ERROR, '*** NO UPDATE IS NEEDED FOR ' + this.currentGAUId + ' ***');
            return null;
        }

    }
}