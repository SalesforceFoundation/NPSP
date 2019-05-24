/*
    Copyright (c) 2017, Salesforce.org
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
 * @date 2017
 * @group Cascade Delete
 * @description Cascade deletion extension for Recurring Donation object.
 */
public with sharing class RD_CascadeDeleteLookups_TDTM extends CDL_CascadeDeleteLookups_TDTM {
    /*******************************************************************************************************
    * @description Gets the deleted Recurring Donations CascadeDeleteLoader Object. 
    * @return CDL_CascadeDeleteLookups.CascadeDeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeDeleteLoader getCascadeDeleteLoader() {
        return new CascadeDeleteLoader();
    }

    /*******************************************************************************************************
    * @description Gets the undeleted Recurring Donations CascadeUndeleteLoader Object.
    * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeUndeleteLoader getCascadeUndeleteLoader() {
        return new FirstCascadeUndeleteLoader();
    }

    /*******************************************************************************************************
    * @description Gets the deleted Recurring Donations ChildrenValidator Object.
    * @return CDL_CascadeDeleteLookups.CascadeDeleteValidator.
    ********************************************************************************************************/
    protected override CDL_CascadeDeleteLookups.CascadeDeleteValidator getCascadeDeleteValidator() {
        return new CascadeDeleteValidator();
    }

    /*******************************************************************************************************
    * @description Class that retrieves the children of the deleted Recurring Donations.
    ********************************************************************************************************/
    class CascadeDeleteLoader implements CDL_CascadeDeleteLookups.CascadeDeleteLoader {
        
        /*******************************************************************************************************
        * @description Retrieves the related Opportunities and Allocations of the deleted Recurring Donations.
        * @param Set<Id> The Ids of the deleted Recurring Donations.
        * @return List<SObject> Deleted Recurring Donations' Opportunities and Allocations.
        ****************************************************************************    ****************************/
        public List<SObject> load(Set<Id> recurringDonationIds) {
            List<SObject> result = new List<SObject>();

            List<Opportunity> relatedOpportunities = [
                SELECT Name, npe03__Recurring_Donation__c, IsWon, IsClosed
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :recurringDonationIds
            ];
            result.addAll((List<SObject>) relatedOpportunities);

            List<Allocation__c> relatedAllocations = [
                SELECT Recurring_Donation__c, Opportunity__c, Opportunity__r.npe03__Recurring_Donation__c
                FROM Allocation__c
                WHERE Recurring_Donation__c IN :recurringDonationIds
                OR Opportunity__c IN :relatedOpportunities
            ];
            result.addAll((List<SObject>) relatedAllocations);

            return result;
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the first children group of the undeleted Recurring Donations.
    ********************************************************************************************************/
    class FirstCascadeUndeleteLoader implements CDL_CascadeDeleteLookups.CascadeUndeleteLoader {

        private List<Opportunity> relatedOpportunities;

        /******************************************************************************************************
        * @description The Constructor of FirstCascadeUndeleteLoader.
        */
        FirstCascadeUndeleteLoader() {
            this.relatedOpportunities = new List<Opportunity>();
        }

        /*******************************************************************************************************
        * @description Retrieves the related Opportunities of the undeleted Recurring Donations.
        * @param Set<Id> The Ids of the undeleted Recurring Donations.
        * @return List<SObject> Undeleted Recurring Donations's Opportunities.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> recurringDonationIds) {
            relatedOpportunities = [
                SELECT Name
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :recurringDonationIds
                AND IsDeleted = TRUE
                ALL ROWS
            ];

            return relatedOpportunities;
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is another
        * group of children records (Allocations) to undelete. To retrieve the Allocations, the logic needs the 
        * the Opportunities undeleted (from the load method).
        * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
        ********************************************************************************************************/
        public CDL_CascadeDeleteLookups.CascadeUndeleteLoader next() {
            List<Opportunity> undeletedOpportunities = [
                SELECT Name
                FROM Opportunity
                WHERE Id IN :relatedOpportunities
            ];
            return new SecondCascadeUndeleteLoader(undeletedOpportunities);
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves the second children group of the undeleted Recurring Donations.
    ********************************************************************************************************/
    class SecondCascadeUndeleteLoader implements CDL_CascadeDeleteLookups.CascadeUndeleteLoader {
        private List<Opportunity> relatedOpportunities;

        /*********************************************************************************************************
        * @description The Constructor of SecondCascadeUndeleteLoader.
        * @param List<Opportunity> The Opportunities. 
        */
        SecondCascadeUndeleteLoader(List<Opportunity> relatedOpportunities) {
            this.relatedOpportunities = relatedOpportunities;
        }

        /*******************************************************************************************************
        * @description Retrieves the related Allocations of the undeleted Recurring Donations.
        * @param Set<Id> The Ids of the undeleted Recurring Donations.
        * @return List<SObject> Undeleted Recurring Donations's Allocations.
        ********************************************************************************************************/
        public List<SObject> load(Set<Id> recurringDonationIds) {
            return [
                SELECT Id, Opportunity__c, Opportunity__r.npe03__Recurring_Donation__c
                FROM Allocation__c
                WHERE (Recurring_Donation__c IN :recurringDonationIds OR Opportunity__c IN :relatedOpportunities)
                AND IsDeleted = TRUE
                ALL ROWS
            ];
        }

        /*******************************************************************************************************
        * @description Retrieves the next children records group to be undeleted. In this case, there is no other
        * group of children records to undelete after Opportunities and Allocations undeletion.
        * @return CDL_CascadeDeleteLookups.CascadeUndeleteLoader.
        ********************************************************************************************************/
        public CDL_CascadeDeleteLookups.CascadeUndeleteLoader next() {
            return null;
        }
    }

    /*******************************************************************************************************
    * @description Class that validates the children of the deleted Recurring Donations.
    ********************************************************************************************************/
    class CascadeDeleteValidator implements CDL_CascadeDeleteLookups.CascadeDeleteValidator {

        /*******************************************************************************************************
        * @description validates the children of the Account.
        * @param List<npe03__Recurring_Donation__c> The deleted Recurring Donations.
        * @param List<SObject> The deleted Recurring Donations children to validate.
        * @return void
        ********************************************************************************************************/
        public void validate(List<npe03__Recurring_Donation__c> deletedRecurringDonations, List<SObject> allChildren) {
            for(npe03__Recurring_Donation__c deletedRecurringDonation : deletedRecurringDonations) {
                CDL_CascadeDeleteLookups.Error error = new CDL_CascadeDeleteLookups.Error(deletedRecurringDonation.Name);
                List<Sobject> currentRDChildren = getChildren(deletedRecurringDonation.Id, allChildren);

                for (SObject child : currentRDChildren) {
                    if (isClosedWonOpportunity(child)) {
                        Opportunity closedWonOpportunity = (Opportunity) child;
                        error.addChildError(Label.ClosedWonOpportunities, closedWonOpportunity.Id, closedWonOpportunity.Name);
                    }
                }

                String errorMessage = error.getMessage();
                if (String.isNotBlank(errorMessage)) {
                    deletedRecurringDonation.addError(errorMessage, false);
                }
            }
        }

        /*******************************************************************************************************
        * @description Checks if the record is a Closed Won Opportunity.
        * @param SObject The child record.
        * @param Id The Id of the deleted Recurring Donation.
        * @return Boolean.
        ********************************************************************************************************/
        private Boolean isClosedWonOpportunity(SObject record) {
            return (
                record instanceof Opportunity && 
                ((Opportunity) record).IsClosed && ((Opportunity) record).IsWon
            );
        }

        /*******************************************************************************************************
        * @description Gets the children records fo the given Recurring Donation.
        * @param Id The Id of the deleted Recurring Donation.
        * @param List<SObject> The deleted Recurring Donations children.
        * @return List<SObject> The list of the children records of the given Recurring Donation.
        ********************************************************************************************************/
        private List<SObject> getChildren(Id deletedRecurringDonationId, List<SObject> allChildren) {
            List<SObject> result = new List<SObject>();

            for (SObject child : allChildren) {
                if ((child instanceof Opportunity && ((Opportunity) child).npe03__Recurring_Donation__c == deletedRecurringDonationId) ||
                    (child instanceof Allocation__c && (
                        ((Allocation__c) child).Recurring_Donation__c == deletedRecurringDonationId ||
                        ((Allocation__c) child).Opportunity__r.npe03__Recurring_Donation__c == deletedRecurringDonationId
                    ))
                ) {
                    result.add(child);
                }
            }

            return result;
        }
    }
}