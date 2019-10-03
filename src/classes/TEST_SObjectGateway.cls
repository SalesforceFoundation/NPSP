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
* @group Test API
* @description Classes used to retrieve specific SObjects created in tests
*
*/
@isTest
public class TEST_SObjectGateway {

    /***
    * @description Retrieves Recurring Donation record(s)
    */
    public class RecurringDonationGateway {

        /***
        * @description Retrieves Recurring Donation record for the specified Id
        * @param rdId Id of the recurring donation
        * @return npe03__Recurring_Donation__c
        */
        public npe03__Recurring_Donation__c getRecord(Id rdId) {
            return getRecords(new Set<Id>{ rdId })[0];
        }

        /***
        * @description Retrieves Recurring Donation records for the specified records
        * @param List<npe03__Recurring_Donation__c> Recurring donations
        * @return List<npe03__Recurring_Donation__c>
        */
        public List<npe03__Recurring_Donation__c> getRecords(List<npe03__Recurring_Donation__c> rds) {
            if (rds == null || rds.isEmpty()) {
                return new List<npe03__Recurring_Donation__c>();
            }

            return getRecords(new Map<Id, npe03__Recurring_Donation__c>(rds).keySet());
        }

        /***
        * @description Retrieves Recurring Donation records for the specified Ids
        * @param rdIds Ids of the recurring donations
        * @return List<npe03__Recurring_Donation__c>
        */
        public List<npe03__Recurring_Donation__c> getRecords(Set<Id> rdIds) {
            return [
                SELECT 
                    Name, 
                    npe03__Organization__c,
                    npe03__Contact__c,
                    npe03__Amount__c,
                    npe03__Paid_Amount__c,
                    npe03__Next_Payment_Date__c, 
                    npe03__Last_Payment_Date__c
                FROM npe03__Recurring_Donation__c 
                WHERE Id IN :rdIds
            ];
        }
    }
}