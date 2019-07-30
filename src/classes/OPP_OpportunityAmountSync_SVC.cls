public class OPP_OpportunityAmountSync_SVC {

    /**
     * Put the fields needed in the query in the description.
     * @param opportunitiesByIds
     * @return
     */
    public List<Opportunity> syncOppAmountWithTotalPaidPaymentAmount(Map<Id, Opportunity> opportunitiesByIds) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : opportunitiesByIds.values()) {
            Decimal totalPaid = 0;

            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                if (pmt.npe01__Paid__c) {
                    totalPaid += pmt.npe01__Payment_Amount__c == null ? 0 : pmt.npe01__Payment_Amount__c;
                }
            }

            Boolean addOppToList = (OPP_StageMappingUtil.determineOppStateFromOppStage(opp.StageName) == 'FINALIZED' && opp.Amount != totalPaid) ||
                    (OPP_StageMappingUtil.determineOppStateFromOppStage(opp.StageName) != 'FINALIZED' && opp.Amount < totalPaid);

            if (addOppToList) {
                opp.Amount = totalPaid;
                oppsToUpdate.add(opp);
            }
        }

        return oppsToUpdate;
    }

}