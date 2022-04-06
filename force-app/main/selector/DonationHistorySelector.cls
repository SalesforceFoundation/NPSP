/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Donation History Selector class.
*/
public inherited sharing class DonationHistorySelector {
    /**
    * @description method to return Opportunity and Payment data.
    */
  public List<Opportunity> getWonOpportunitiesByContactId( Id contactId, Integer offset ) {
        return [
            SELECT Id, 
                Name, 
                CloseDate, 
                Amount, 
                Primary_Contact__r.Email, 
                Primary_Contact__r.Name,
                (
                    SELECT npe01__Payment_Method__c,
                        npe01__Paid__c
                    FROM npe01__OppPayment__r 
                    ORDER BY CreatedDate
                )
            FROM Opportunity
            WHERE IsWon = true 
            AND Primary_Contact__r.Id =:contactId 
            WITH SECURITY_ENFORCED
            ORDER BY CloseDate 
            DESC LIMIT 50
            OFFSET :offset
        ];
    }

    /**
     * @description Returns the OpportunityContactRole won in a specific year.
     * @param contactId the contact id.
     * @param year Integer filter of year.
     * @return List<OpportunityContactRole>
     */
    public List<Opportunity> getWonOpportunitiesByContactIdAndYear(Id contactId, Integer offset, Integer year) {
        return [
            SELECT  Id, 
                    Name, 
                    CloseDate, 
                    Amount, 
                    Primary_Contact__r.Email, 
                    Primary_Contact__r.Name,
                    (
                        SELECT npe01__Payment_Method__c,
                            npe01__Paid__c
                        FROM npe01__OppPayment__r 
                        ORDER BY CreatedDate
                    ) 
            FROM Opportunity
            WHERE IsWon = true 
                AND Primary_Contact__r.Id =:contactId 
                AND Calendar_Year(CloseDate) = :year
            WITH SECURITY_ENFORCED
            ORDER BY Opportunity.CloseDate 
            DESC LIMIT 50
            OFFSET :offset
        ];
    }

    /**
     * @description Returns the years in which the contact has made at least 1 donation.
     * @param contactId Id the contact id.
     * @returns List<AggregateResult> Selecting the Calenday_Year of the Opportunity.CloseDate
     */
    public List<String> getYearsWithDonationForContact(Id contactId) {
        return convertAggregateResultListToStringList([SELECT   Calendar_Year(CloseDate) closeYear
                FROM     Opportunity 
                WHERE    IsWon = true 
                AND      ContactId =:contactId 
                GROUP BY Calendar_YEAR(CloseDate)
                ORDER BY Calendar_YEAR(CloseDate) DESC]);
    }

    /** 
     * @description method to return total number of record
     */
    public Integer getTotalNumberOfRecords( Id contactId ) {
        Integer totalRecords = [SELECT COUNT()
                                FROM Opportunity
                                WHERE IsWon = true
                                AND Primary_Contact__r.Id =:contactId
                                WITH SECURITY_ENFORCED];
        return totalRecords;
    }



    /** 
    * @description method to return total number of record
    */
    public Integer getTotalNumberOfRecordsWithYear( Id contactId, Integer year ) {
        Integer totalRecords = [SELECT COUNT()
                                FROM Opportunity
                                WHERE IsWon = true
                                AND Primary_Contact__r.Id =:contactId
                                AND Calendar_Year(CloseDate) = :year
                                WITH SECURITY_ENFORCED];
        return totalRecords;
    }

    /**
     * @description converts a List<AggregateResult> in a List<String> .
     * @param result The list with with the aggregate results from the database.
     * @return List<String> the list of the values in the expr0 represented as String.
     */ 
    private List<String> convertAggregateResultListToStringList(List<AggregateResult> results) {
        List<String> aggregateResultsAsStrings = new List<String>();
        for(AggregateResult result : results) {
            aggregateResultsAsStrings.add(String.valueOf(result.get('closeYear')));
        }
        return aggregateResultsAsStrings;
    }
}