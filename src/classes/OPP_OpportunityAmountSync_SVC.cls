/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2019
* @group Payments
* @description service class used by PMT_Payment_TDTM to set the opportunity amount to match the paid payment amounts
*/

public class OPP_OpportunityAmountSync_SVC {

    /**
     * @description updates the opportunity amount based on the paid payment amounts if there is a mismatch; this method does not process
     * dml, the list returned contains the opportunities to be updated
     * @param Map<Id, Opportunity> map of opportunities by Id opportunitiesByIds
     * @return List<Opportunity>
     */
    public List<Opportunity> syncOppAmountWithTotalPaidPaymentAmount(Map<Id, Opportunity> opportunitiesByIds) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : opportunitiesByIds.values()) {
            Decimal totalPaid = getTotalPaidPaymentsAmount(opp);

            Boolean addOppToList = (OPP_StageMappingUtil.isOpportunityFinalized(opp) && opp.Amount != totalPaid) ||
                    (!OPP_StageMappingUtil.isOpportunityFinalized(opp) && opp.Amount < totalPaid);

            if (addOppToList) {
                opp.Amount = totalPaid;
                oppsToUpdate.add(opp);
            }
        }

        return oppsToUpdate;
    }

    /**
     * @description calculates the total amount from the paid payments on opportunity
     * @param Opportunity with list of attached payments
     * @return Decimal totalPaid: the sum of the amounts for the paid payments on this opportunity
     */
    public static Decimal getTotalPaidPaymentsAmount(Opportunity oppWithPayment) {
      Decimal totalPaid = 0;

      for (npe01__OppPayment__c pmt : oppWithPayment.npe01__OppPayment__r) {
          totalPaid += (pmt.npe01__Paid__c && pmt.npe01__Payment_Amount__c != null) ? pmt.npe01__Payment_Amount__c : 0;
      }

      return totalPaid;
    }

}