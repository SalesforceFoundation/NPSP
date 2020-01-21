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
* @description Recurring Donation matcher for existing Opportunities and future installments
*
*/
public inherited sharing class RD2_OpportunityMatcher {
    /***
     * @description A flag to mark Closed Lost Opps that are voided by the data migration. 
     * The flag is used to exclude (ignore) such Opps by the Opp service
     * when determining if the next Opp with the same Close Date can be created.
     */
    public static final Integer MIGRATION_INSTALLMENT_NUMBER_FLAG = RD2_DataMigrationBase_BATCH.MIGRATION_INSTALLMENT_NUMBER_FLAG;

    private Date currentDate;
    private Map<Date, Record> recordByCloseDate = new Map<Date, Record>();//TODO more than one Opp on the same Close Date?
    private Map<Integer, Record> currentRecordByOrder {
        get {
            if (currentRecordByOrder == null) {
                currentRecordByOrder = new Map<Integer, Record>();
                Integer i = 0;
                List<Date> closeDates = new List<Date>(recordByCloseDate.keySet());
                closeDates.sort();
                for (Date closeDate : closeDates) {
                    if (closeDate >= currentDate) {
                        currentRecordByOrder.put(i++, recordByCloseDate.get(closeDate));
                    }
                }
            }
            return currentRecordByOrder;
        }
        set;
    } 

    public RD2_OpportunityMatcher(Date currentDate) {
        this.currentDate = currentDate;
    }

    public RD2_OpportunityMatcher filterByYear(List<Opportunity> opps, Integer year) { 
        for (Opportunity opp : opps) {
            if (opp.CloseDate.year() == year && !isClosedLostInMigration(opp)) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    public RD2_OpportunityMatcher filterOpen(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.IsClosed == false && opp.CloseDate >= currentDate) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    public RD2_OpportunityMatcher filterCurrent(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.CloseDate >= currentDate && !isClosedLostInMigration(opp)) {
                recordByCloseDate.put(opp.CloseDate, new Record(opp));
            }
        }
        return this;
    }

    private Boolean isClosedLostInMigration(Opportunity opp) {
        return opp.isClosed 
            && !opp.IsWon 
            && opp.Recurring_Donation_Installment_Number__c == MIGRATION_INSTALLMENT_NUMBER_FLAG;
    }

    public RD2_OpportunityMatcher match(List<RD2_ScheduleService.Installment> installments) {
        for (Integer i = 0, size = installments.size(); i < size; i++) {
            RD2_ScheduleService.Installment installment = installments[i];
            Record matched = getMatchFor(installment.nextDonationDate, i);

            if (matched == null) {
                recordByCloseDate.put(installment.nextDonationDate, new Record(installment));
            } else {
                matched.attachInstallment(installment);
            }
        }

        return this;
    }

    private Record getMatchFor(Date closeDate, Integer order) {
        Record matched = recordByCloseDate.get(closeDate);

        if (matched != null) {
            return matched;
        }

        return currentRecordByOrder.get(order);
    }

    public Integer size() {
        return recordByCloseDate.size();
    }

    public List<Record> getRecords() {
        return recordByCloseDate.values();
    }

    public class Record {
        private Opportunity opp = new Opportunity(
            Amount = 0
        );
        private RD2_ScheduleService.Installment installment;

        public Record(RD2_ScheduleService.Installment installment) {
            this.installment = installment;
        }

        public Record(Opportunity opp) {
            this.opp = opp;
        }

        public Decimal getAmount() {
            Decimal amount = hasInstallment() && (isNew() || isOpen())
                ? installment.installmentAmount
                : opp.Amount;
            
            return amount == null ? 0 : amount;
        }

        public Boolean isNew() {
            return opp.Id == null;
        }

        public Boolean isOpen() {
            return opp.isClosed == false;
        }

        public Boolean isClosedLost() {
            return opp.isClosed == true && opp.isWon == false;
        }

        public Opportunity getOpportunity() {
            return opp;
        }

        public void attachInstallment(RD2_ScheduleService.Installment installment) {
            this.installment = installment;
        }

        public Boolean hasInstallment() {
            return installment != null;
        }

        public RD2_ScheduleService.Installment getInstallment() {
            return installment;
        }
    }
}