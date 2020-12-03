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
* @description Recurring Donations Donor record and gateway classes
*
*/
public inherited sharing class RD2_Donor {

    /***
    * @description Donor Gateway interface
    */
    public interface IGateway {
        Map<Id, Record> getDonors(List<npe03__Recurring_Donation__c> rds);
    }

    /***
    * @description Donor Record
    */
    public class Record {
        public Id recordId { get; private set; }
        public String name { get; private set; }
        public Id recordTypeId { get; private set; }

        /***
        * @description Constructor
        * @param recordId Account/Contact SObject Id
        * @param name Account/Contact name
        */
        public Record(Id recordId, String name) {
            this.recordId = recordId;
            this.name = name;
        }

        /***
        * @description Constructor
        * @param recordId Account/Contact SObject Id
        * @param name Account/Contact name
        * @param recordTypeId Account recordTypeId
        */
        public Record(Id recordId, String name, String recordTypeId) {
            this.recordId = recordId;
            this.name = name;
            this.recordTypeId = recordTypeId;
        }
    }

    /***
    * @description Gateway to retrieve donor information
    *   Use without sharing context so Guest Site User can retrieve Account infos
    */
    public without sharing class Gateway implements IGateway {

        /***
        * @description Returns donor information for provided Recurring Donation records
        * @param rds Recurring Donation records
        * @return Map<Id, Record> Donor records by Id
        */
        public Map<Id, Record> getDonors(List<npe03__Recurring_Donation__c> rds) {
            Map<Id, Record> donorById = new Map<Id, Record>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();

            for (npe03__Recurring_Donation__c rd : rds) {
                accountIds.add(rd.npe03__Organization__c);
                contactIds.add(rd.npe03__Contact__c);
            }
            accountIds.remove(null);
            contactIds.remove(null);

            for (Account acc : [
                SELECT Name, RecordTypeId
                FROM Account
                WHERE Id IN :accountIds
            ]) {
                donorById.put(acc.Id, new Record(acc.Id, acc.Name, acc.RecordTypeId));
            }

            for (Contact c : [
                SELECT Name
                FROM Contact
                WHERE Id IN :contactIds
            ]) {
                donorById.put(c.Id, new Record(c.Id, c.Name));
            }

            return donorById;
        }
    }

}