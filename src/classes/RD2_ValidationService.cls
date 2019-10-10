/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Recurring Donations Validation Service
*
*/
public with sharing class RD2_ValidationService {

    /***
    * @description Validates missing data on Recurring Donation
    * @param rds the Recurring Donation to validate
    */
    public void validateRecurringDonationsData(List<npe03__Recurring_Donation__c> rds) {

        Set<Id> setAccountId = new Set<Id>();
        Map<Id,Account> mapAccountIdAccount = null;
        Boolean contactExists = false;

        for (npe03__Recurring_Donation__c rd : rds) {
            if (rd.npe03__Organization__c != null) {
                setAccountId.add(rd.npe03__Organization__c);
            }
        }
        mapAccountIdAccount = new Map<Id,Account>([
            SELECT Id, npe01__SYSTEMIsIndividual__c, (select id from Contacts)
            FROM Account
            WHERE Id IN :setAccountId
            ]);

        for (npe03__Recurring_Donation__c rd : rds) {
            System.debug('Contact account id is' + rd.npe03__Contact__r.Accountid);
            if (rd.npe03__Organization__c == null && rd.npe03__Contact__c == null) {
                rd.addError(System.Label.RD_ValidateAccountAndContactMissing);
            }

            if (mapAccountIdAccount.containsKey(rd.npe03__Organization__c)) {
                System.debug('value please '+ rd.npe03__Contact__c);
                if (mapAccountIdAccount.get(rd.npe03__Organization__c).npe01__SYSTEMIsIndividual__c && rd.npe03__Contact__c == null) {
                    rd.addError(System.Label.RD_ValidateContactMissingForAccount);
                }

                for (Contact con:mapAccountIdAccount.get(rd.npe03__Organization__c).Contacts ) {
                    if (con.id == rd.npe03__Contact__c ) {
                        contactExists = true;
                        break;
                    }
                }
                if  (mapAccountIdAccount.get(rd.npe03__Organization__c).npe01__SYSTEMIsIndividual__c && rd.npe03__Contact__c != null && !contactExists) {
                    rd.addError(System.Label.RD_ValidateIfContactNotRelatedWithAccount);

                }
            }
        }
    }

}


