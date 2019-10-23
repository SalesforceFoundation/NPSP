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
* @description Data Migration Job to convert RD1 format records to RD2
*
*/
public class RD2_DataMigration {

    private npe03__Recurring_Donation__c rd;
    private List<Opportunity> opps;

    /**
     * @description Builder method with the Recurring Donation to be converted to RD2 format
     */
    public RD2_DataMigration withRecurringDonation(npe03__Recurring_Donation__c rd) {
        this.rd = rd;
        return this;
    }

    /**
     * @description Builder method with the collection of all related opportunities for this RD
     */
    public RD2_DataMigration withRelatedOpportunities(List<Opportunity> opps) {
        this.opps = opps;
        return this;
    }

    /**
     * @description Converts the RD record to RD2 format by updating the new and existing fields
     * on the record as required.
     * @return The updated record (or null if there is an exception?)
     */
    public npe03__Recurring_Donation__c convertToRD2Format() {
        return null;
    }

    /**
     * @description Update Opportunities associated with this RD as required - For Pilot-1 this
     * involves marking (somehow) the record as "to be deleted".
     * TODO How will this work?
     * @return List<Opportunity> Opps to be updated
     */
    public List<Opportunity> updateOpportunities() {
        return new List<Opportunity>();
    }

    /**
     * @description Generate the RDSchedule Record(s) for the Recurring Donation
     * @return List<RecurringDonationSchedule__c> Schedule records to insert
     */
    public List<RecurringDonationSchedule__c> getScheduleRecords() {
        return new List<RecurringDonationSchedule__c>();
    }

    /**
     * @description Returns true if the RD record is already in RD2 format
     */
    private Boolean hasAlreadyBeenConverted() {
        return rd.Status__c != null;
    }
}