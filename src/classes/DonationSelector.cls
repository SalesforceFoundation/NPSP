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
* @description Selector class for Donations in NPSP.
*/
public inherited sharing class DonationSelector {

    public List<Opportunity> selectOpportunitiesById(Set<Id> ids) {
        return [SELECT Id,
                Name,
                Amount,
                Account.Name,
                Account.RecordTypeId,
                Account.RecordType.Name,
                Primary_Contact__c,
                Primary_Contact__r.FirstName,
                Primary_Contact__r.LastName,
                (SELECT Id,
                    Role, 
                    ContactId,
                    Contact.FirstName,
                    Contact.LastName,
                    IsPrimary
                FROM OpportunityContactRoles),
                (SELECT Id,
                    Name,
                    Role__c,
                    Amount__c,
                    Account__c
                FROM Account_Soft_Credits__r),
                (SELECT Id,
                    Amount__c,
                    Contact__c,
                    Contact_Name__c,
                    Contact_Role_ID__c,
                    Role_Name__c,
                    Name
                FROM Partial_Soft_Credits__r)
            FROM Opportunity
            WHERE Id IN :ids
            //WITH SECURITY_ENFORCED
        ];
    }
}