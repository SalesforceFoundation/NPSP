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
    * @author Salesforce.org
    * @date 2021
    * @description method to return OpportunityContactRole data.
    */
    public List<OpportunityContactRole> getWonOpportunityContactRolesByContactId(Id contactId) {
        return [
            SELECT Id, 
                Opportunity.CloseDate, 
                Opportunity.Amount, 
                Contact.Email, 
                Contact.Name, 
                Role, 
                IsPrimary
            FROM OpportunityContactRole 
            WHERE Opportunity.IsWon = true 
            AND ContactId =:contactId 
            WITH SECURITY_ENFORCED
            ORDER BY Opportunity.CloseDate 
            DESC LIMIT 2000
        ];
    }
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Partial_Soft_Credit__c data.
    */
    public List<Partial_Soft_Credit__c> getPartialSoftCredits(Set<Id> opportunityContactRoleIds) {
        return [
            SELECT 
                Id, 
                Amount__c, 
                Role_Name__c,
                Contact_Role_ID__c 
            FROM Partial_Soft_Credit__c 
            WHERE Contact_Role_ID__c IN :opportunityContactRoleIds
            WITH SECURITY_ENFORCED
        ];
    }   
}
