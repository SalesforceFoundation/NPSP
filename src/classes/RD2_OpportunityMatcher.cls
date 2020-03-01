/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Recurring Donation existing Opportunities and future installments matcher
*
*/
public inherited sharing class RD2_OpportunityMatcher {
    /***
     * @description A flag to mark Closed Lost Opportunities voided by the data migration.
     * The flag is used to exclude such Opps from yearly values as well as in Opp eval service
     * when determining if the next Opp with the same Close Date can be created.
     */
    public static final Integer MIGRATION_INSTALLMENT_NUMBER_FLAG = RD2_DataMigrationBase_BATCH.MIGRATION_INSTALLMENT_NUMBER_FLAG;

    /**
     * @description Current date is the cut off date to evaluate current existing Opportunities.
     * Moreover, it is used to determine projected installments as of the current date.
     * It can be a past date, today or a future date when testing. 
     * The current date is always today when used within RD batch scheduler.
    */
    private Date currentDate;

    /**
     * @description The earliest Close Date on an Opportunity in order to be considered for matching
     * as the current Opportunity (not past)
    */
    private Date cutoffDate {
        get {
            if (cutoffDate == null) {
                cutoffDate = currentDate.addDays(-nextDonationDateMatchDays);
            }

            return cutoffDate;
        }
        private set;
    }

    /***
    * @description Recurring Donation custom settings
    */
    private Integer nextDonationDateMatchDays {
        get {
            if (nextDonationDateMatchDays == null) {
                nextDonationDateMatchDays = new RD2_Settings().nextDonationDateMatchDays;
            }
            return nextDonationDateMatchDays;
        }
        set;
    }

    /***
    * @description Contains all included Opportunities and/or projected installments mapped by their Close Date
    */
    private Map<Date, Record> recordByCloseDate = new Map<Date, Record>();
    private Map<Date, Record> boundaryRecordsByCloseDate = new Map<Date, Record>();


    /***
     * @description Constructor
     * @param currentDate Date representing current date
     */
    public RD2_OpportunityMatcher(Date currentDate) {
        this.currentDate = currentDate;
    }

    /***
     * @description Includes Opportunities matching the provided calendar year regardless if they are open or closed.
     * Opportunities marked as Closed Lost in data migration are ignored.
     * @param opps Recurring Donation Opportunities
     * @param year Year criteria
     * @return RD2_OpportunityMatcher This Opportunity matcher instance
     */
    public RD2_OpportunityMatcher includeByYear(List<Opportunity> opps, Integer year) {
        for (Opportunity opp : opps) {
            if (opp.CloseDate.year() == year && !isClosedLostInMigration(opp)) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    /***
     * @description Includes Open Opportunities with Close Date greater or equal to the current date
     * @param opps Recurring Donation Opportunities
     * @return RD2_OpportunityMatcher This Opportunity matcher instance
     */
    public RD2_OpportunityMatcher includeCurrentAndOpen(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.IsClosed == true) {
                continue;
            }
            if (opp.CloseDate >= currentDate) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));

            } else if (opp.CloseDate >= cutoffDate) {
                boundaryRecordsByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    /***
     * @description Includes Opportunities with Close Date greater or equal to the current date.
     * Opportunities marked as Closed Lost in data migration are ignored.
     * @param opps Recurring Donation Opportunities
     * @return RD2_OpportunityMatcher This Opportunity matcher instance
     */
    public RD2_OpportunityMatcher includeCurrent(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (isClosedLostInMigration(opp)) {
                continue;
            }
            if (opp.CloseDate >= currentDate) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));

            } else if (opp.CloseDate >= cutoffDate) {
                boundaryRecordsByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    /***
     * @description Includes open Opportunities regardless of the Close Date and
     * open/closed Opportunities with Close Date greater or equal to the current date.
     * Opportunities marked as Closed Lost in data migration are ignored.
     * @param opps Recurring Donation Opportunities
     * @return RD2_OpportunityMatcher This Opportunity matcher instance
     */
    public RD2_OpportunityMatcher includeCurrentOrOpen(List<Opportunity> opps) {
        //remove past and closed and unmatched
        for (Opportunity opp : opps) {
            if (isClosedLostInMigration(opp)) {
                continue;
            }
            if (opp.isClosed == false || opp.CloseDate >= currentDate) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));

            } else if (opp.CloseDate >= cutoffDate) {
                boundaryRecordsByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    /***
     * @description Determines if the Opportunity is marked as Closed Lost in data migration
     * @param opp Recurring Donation Opportunity
     * @return Boolean
     */
    private Boolean isClosedLostInMigration(Opportunity opp) {
        return opp.IsClosed
            && !opp.IsWon
            && opp.Recurring_Donation_Installment_Number__c == MIGRATION_INSTALLMENT_NUMBER_FLAG;
    }

    /***
     * @description Matches existing included Opportunities with projected installments
     * and creates resulting Records.
     * @param installments Recurring Donation projected installments
     * @return RD2_OpportunityMatcher This Opportunity matcher instance
     */
    public RD2_OpportunityMatcher match(List<RD2_ScheduleService.Installment> installments) {
        for (RD2_ScheduleService.Installment installment : installments) {
            match(installment);
        }

        return this;
    }

    /***
     * @description Matches today's or future projected installment with existing Opp.
     * If the matching Opp is found, add installment to the record.
     * Otherwise, create a record containing the installment only,
     * @param installment Today's or future projected installment
     * @return void
     */
    private void match(RD2_ScheduleService.Installment installment) {
        Record matched = recordByCloseDate.get(installment.nextDonationDate);

        if (matched != null) {//matches the Opp Close Date exactly
            matched.attachInstallment(installment);
            return;
        }
        
        //if the Installment period is not monthly, do not attempt to match by +/- match days range
        //and add the installment without matching Opp
        if (installment.installmentPeriod != RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
            recordByCloseDate.put(installment.nextDonationDate, new Record(installment));
            return;
        }

        //find a matching Opp with Close Date within the installment Next Donation Date +/- match days range
        Date startDate = installment.nextDonationDate.addDays(-nextDonationDateMatchDays);
        Date endDate = installment.nextDonationDate.addDays(nextDonationDateMatchDays);

        //check if there is any match with an Opp with Close Date < current date
        matched = getFuzzyMatch(boundaryRecordsByCloseDate, startDate, endDate);
        if (matched != null) {
            recordByCloseDate.put(installment.nextDonationDate, new Record(matched.getOpportunity()).attachInstallment(installment));
            return;
        }

        //check if there is any match with an Opp with Close Date >= current date
        matched = getFuzzyMatch(recordByCloseDate, startDate, endDate);
        if (matched != null) {
            matched.attachInstallment(installment);
            return;
        }

        //if the match is not found, add installment as a record without matching Opportunity
        recordByCloseDate.put(installment.nextDonationDate, new Record(installment));
    }

    /***
     * @description Determines if an Opportunity matches a projected installment.
     * Matching is done by the exact Close Date match or when 
     * the Close Date is within the installment Next Donation Date +/- match days range
     * @param recordByCloseDate Record by Close Date map
     * @param startDate Installment range start date 
     * @param endDate Installment range end date 
     * @return record Matched record
     */
    private Record getFuzzyMatch(Map<Date, Record> recordByCloseDate, Date startDate, Date endDate) {

        for (Record record : recordByCloseDate.values()) {  
            if (record.isNew() //the record does not contain an Opp to match the installment with
                || record.getInstallment() != null //the record has a matching installment already
            ) {
                continue;
            }   

            Date closeDate = record.getOpportunity().CloseDate;
            
            if (closeDate >= startDate && closeDate <= endDate) {//TODO, should you find the closest one to the installment NDD?
                return record;
            }
        }

        return null;
    }

    /***
     * @description Returns number of matched records
     * @return Integer
     */
    public Integer size() {
        return recordByCloseDate.size();
    }

    /***
     * @description Returns matched records containting Opportunities and/or installments
     * @return List<Record>
     */
    public List<Record> getRecords() {
        return recordByCloseDate.values();
    }

    /***
     * @description Wrapper for the extracted Opportunity based on the inclusion criteria
     * and/or matching installment. The record can have both Opportunity and installment
     * specified if they are matching, otherwise Opportunity only is specified for records
     * with Close Date < current date and installment only is usually specified for 
     * records with Close Date >= current date unless there is a matching future Opportunity.
     * @return List<Record>
     */
    public class Record {
        /***
        * @description Matching Opportunity (if any) defaulting Amount value to zero
        */
        private Opportunity opp = new Opportunity(
            Amount = 0
        );
        /***
        * @description Matching installment (if any)
        */
        private RD2_ScheduleService.Installment installment;

        /***
        * @description Constructor
        * @param installment Recurring Donation projected installment not matching any existing Opportunity
        */
        public Record(RD2_ScheduleService.Installment installment) {
            this.installment = installment;
        }

        /***
        * @description Constructor
        * @param opp Recurring Donation existing Opportunity
        */
        public Record(Opportunity opp) {
            this.opp = opp;
        }

        /***
        * @description Returns Amount either from the Opportunity if it exists 
        * or from the projected installment.
        * If the future Opportunity is open and amount differs from the matching installment,
        * the future Open Opp Amount has precedence over the installment Amount.
        * @return Decimal
        */
        public Decimal getAmount() {
            Decimal amount = (hasInstallment() && isNew())
                ? installment.installmentAmount
                : (isClosedLost() ? 0 : opp.Amount);

            return amount == null ? 0 : amount;
        }

        /***
        * @description Determines if the record already exists
        * @return Boolean
        */
        public Boolean isNew() {
            return opp.Id == null;
        }

        /***
        * @description Determines if the record is an Open Opportunity
        * @return Boolean
        */
        public Boolean isOpen() {
            return opp.IsClosed == false;
        }

        /***
        * @description Determines if the record is a Closed Lost Opportunity
        * @return Boolean
        */
        public Boolean isClosedLost() {
            return opp.IsClosed == true && opp.IsWon == false;
        }

        /***
        * @description Returns the Opportunity part (if any) of the matched record
        * @return Opportunity
        */
        public Opportunity getOpportunity() {
            return opp;
        }

        /***
        * @description Attaches the future projected installment to an existing Opportunity
        * @return Record This record instance
        */
        public Record attachInstallment(RD2_ScheduleService.Installment installment) {
            this.installment = installment;
            return this;
        }

        /***
        * @description Determines if the record has a matching projected installment
        * @return Boolean
        */
        public Boolean hasInstallment() {
            return installment != null;
        }

        /***
        * @description Returns the matching projected installment (if any)
        * @return RD2_ScheduleService.Installment
        */
        public RD2_ScheduleService.Installment getInstallment() {
            return installment;
        }
    }
}
