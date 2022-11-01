/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Donation
* @description Controller class for Recurring Donations LWC.
*/
public with sharing class RD2_ETableController {
    
    private final String STATUS_FAILING = 'Failing';
    private final String STATUS_REJECTED = 'Rejected';
    private final String STATUS_PAYMENT_IN_PROGRESS = 'Payment in Progress';
    private final String STATUS_CLOSED = 'Closed';

    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if(permissions == null) {
                permissions = UTIL_Permissions.getInstance();
            }
            return permissions;
        }
        set;
    }

    @TestVisible
    private static RD2_ETableController controller {
        get {
            if (controller == null) {
                controller = new RD2_ETableController();
            }
            return controller;
        }
        set {
            controller = value;
        }
    }

    @TestVisible
    private static RD2_ERecurringDonationsSelector selector {
        get {
            if(selector == null) {
                selector = new RD2_ERecurringDonationsSelector();
            }
            return selector;
        }
        set { 
            selector = value;
        }
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description Recurring Donations inner class.
    */
    public class TableView {
        @AuraEnabled public npe03__Recurring_Donation__c recurringDonation;
        @AuraEnabled public String frequency;
        @AuraEnabled public String status;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public String nextDonation;
        @AuraEnabled public Date finalDonation;
        public TableView(npe03__Recurring_Donation__c recurringDonation, String frequency, String status, String paymentMethod, String nextDonation) {
            this.recurringDonation = recurringDonation;
            this.frequency = frequency;
            this.status = status;
            this.paymentMethod = paymentMethod;
            this.nextDonation = nextDonation;
        }
    }

    /**
    * @description returns a list of processed recurring donations
    * @return List<TableView> List of processed recurring donation records
    */
    @AuraEnabled(cacheable=false)
    public static List<TableView> retrieveTableView(String elevateFilter) {
        try {
            return controller.getTableViews(elevateFilter);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
    * @description upsert a recurring donations record.
    */
    @AuraEnabled
    public static void upsertDonation(npe03__Recurring_Donation__c recurringDonation) {
        try {
            if(controller.hasAccessToRecurringDonation()) {
                upsert recurringDonation; 
            } else {
                throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** 
    * @author Salesforce.org
    * @date 2022
    * @description method to return Recurring Donation list.
    * @return List<RD2_ETableController.TableView> returns processed Recurring Donations.
    */
    private List<RD2_ETableController.TableView> getTableViews(String elevateFilter) {
        List<RD2_ETableController.TableView> recurringDonations = new List<RD2_ETableController.TableView>();
        if(RD2_EnablementService.isRecurringDonations2Enabled) {
            if(controller.hasAccessToRecurringDonation()) {
                recurringDonations = controller.getProcessedTableViews(selector.getRecurringDonations(elevateFilter));
            } else {
                throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
            }
        }

        return recurringDonations;
      
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation records to build the TableViews data.
    * @param List<recurringDonation> recurring donation records
    * @return ListRD2_ETableController.TableView> returns TableView data.
    */
    private List<RD2_ETableController.TableView> getProcessedTableViews(List<npe03__Recurring_Donation__c> rdRecords) {
        RD2_StatusMapper statusMapper = RD2_StatusMapper.getInstance();
        
        Map<Id, RD2_ETableController.TableView> recurringDonations = new Map<Id,RD2_ETableController.TableView>();
        Map<Id,npe03__Recurring_Donation__c> fixedRecurringDonations = new Map<Id,npe03__Recurring_Donation__c>(); 
        for(npe03__Recurring_Donation__c recDonation : rdRecords) {
            recurringDonations.put( recDonation.Id, new RD2_ETableController.TableView( recDonation,
                                                                        controller.getFrequency(recDonation),
                                                                        controller.getStatus(recDonation),
                                                                        controller.getPaymentMethod(recDonation),
                                                                        controller.getNextDonation(recDonation)));

            if(recDonation.RecurringType__c == RD2_Constants.RECURRING_TYPE_FIXED 
                && statusMapper.getState(recDonation.Status__c) != RD2_Constants.STATUS_CLOSED) {
                fixedRecurringDonations.put(recDonation.Id,recDonation);
            }
        }

        if(!fixedRecurringDonations.isEmpty()) {
            RDScheduleClass rDSchedule = new RDScheduleClass();
            Map<Id, List<RecurringDonationSchedule__c>> mapRDSchedule = rDSchedule.queryRows(fixedRecurringDonations.keySet());
            Map<ID, Date> mapRDFinalDate = getFinalDonations(fixedRecurringDonations.values(), mapRDSchedule);
            for(Id rdID : mapRDFinalDate.keySet()) {
                RD2_ETableController.TableView tableView = recurringDonations.get(rdID);
                tableView.finalDonation = mapRDFinalDate.get(rdID);
                recurringDonations.put(rdID, tableView);
            }
        }

        return recurringDonations.values();
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the frequency string.
    * @param recurringDonation recurring donation record
    * @return String returns the frequency string.
    */
    private String getFrequency(npe03__Recurring_Donation__c recurringDonation) {

        String frequency = '';

        Map<String, String> mapDayOfMonth = new Map<String, String>();
        for(Schema.PicklistEntry ple : Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_of_Month__c.getPicklistValues()){
            mapDayOfMonth.put(ple.getValue(), ple.getLabel());
        }

        if(recurringDonation.InstallmentFrequency__c == 1) {
            if(recurringDonation.npe03__Installment_Period__c.isAlpha()) {
                if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
                    frequency = String.format(System.Label.RD_frequencyPeriodOnTheDayOfTheMonth, new List<String>{recurringDonation.npe03__Installment_Period__c, mapDayOfMonth.get(recurringDonation.Day_of_Month__c).ToLowerCase()});
                } else {
                    frequency = recurringDonation.npe03__Installment_Period__c;
                }
            } else {
                frequency = String.format(System.Label.RD_frequencyOnThePeriod, new List<String>{recurringDonation.npe03__Installment_Period__c});
            }
        } else {
            if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
                frequency = String.format(System.Label.RD_frequencyMonthly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c), mapDayOfMonth.get(recurringDonation.Day_of_Month__c).ToLowerCase()});
            } else if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_YEARLY) {
                frequency = String.format(System.Label.RD_frequencyYearly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c)});
            } else if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY) {
                frequency = String.format(System.Label.RD_frequencyWeekly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c)});
            } else if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH){
                frequency = String.format(System.Label.RD_frequencyFirstAndFifteenth, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c), String.valueOf(recurringDonation.npe03__Installment_Period__c)});
            }
        }

        if(frequency.right(1).isNumeric()) {
            switch on frequency.right(1) {
                when '1' {
                    frequency += System.Label.RD_firstOrdinalNumber;
                }
                when '2' {
                    frequency += System.Label.RD_secondOrdinalNumber;
                }
                when '3' {
                    frequency += System.Label.RD_thirdOrdinalNumber;
                }
                when else {
                    frequency += System.Label.RD_otherOrdinalNumber;
                }
            }
        }
        
        return frequency;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donaion record to build the status string.
    * @param recurringDonation recurring donation record
    * @return String returns the Status string.
    */
    private String getStatus(npe03__Recurring_Donation__c recurringDonation) {
        RD2_StatusMapper statusMapper = RD2_StatusMapper.getInstance();
        String status = '';

        Map<String, String> mapStatus = new Map<String, String>();
        for(Schema.PicklistEntry ple : Schema.SObjectType.npe03__Recurring_Donation__c.fields.Status__c.getPicklistValues()){
            mapStatus.put(ple.getValue(), ple.getLabel());
        }

        if(recurringDonation.Status__c == RD2_Constants.STATUS_PAUSED) {
            status = mapStatus.get(RD2_Constants.STATUS_PAUSED);
        } else {
            status = statusMapper.getState(recurringDonation.Status__c);
        }
        return status;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the payment method string.
    * @param recurringDonation recurring donation record
    * @return String returns the PaymentMethod string.
    */
    private String getPaymentMethod(npe03__Recurring_Donation__c recurringDonation) {
        String paymentMethod = '';

        if(GE_GiftEntryController.isElevateCustomer() && String.IsBlank(recurringDonation.CommitmentId__c) || !GE_GiftEntryController.isElevateCustomer()) {
            //Non-Elevate RD
            paymentMethod = recurringDonation.PaymentMethod__c;
        
        } else {
            //Elevate RD
            if(recurringDonation.PaymentMethod__c == RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD) {
                paymentMethod = String.format(System.Label.RD_creditCardElevatePayment, new List<String>{recurringDonation.PaymentMethod__c, recurringDonation.CardLast4__c, recurringDonation.CardExpirationMonth__c, recurringDonation.CardExpirationYear__c});
            } else {
                paymentMethod = String.format(System.Label.RD_achElevatePayment, new List<String>{recurringDonation.PaymentMethod__c, recurringDonation.ACH_Last_4__c});
            }
        }

        return paymentMethod;
    }


    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the Next Donation string.
    * @param recurringDonation recurring donation record
    * @return String returns the NextDonation string.
    */
    private String getNextDonation(npe03__Recurring_Donation__c recurringDonation) {
        String nextDonation = '';
		String nextDonationStringDate = String.valueOf(recurringDonation.npe03__Next_Payment_Date__c);
        if(recurringDonation.RecurringType__c == RD2_Constants.RECURRING_TYPE_FIXED && !String.isEmpty(nextDonationStringDate) ) {
			nextDonation = System.Label.RD2_PaidInstallments + ' ' + String.valueOf(recurringDonation.npe03__Total_Paid_Installments__c) +'/'+ String.valueOf(recurringDonation.npe03__Installments__c) + '<br/>' + System.Label.RD2_NextDonationDate + ' ' + recurringDonation.npe03__Next_Payment_Date__c.format();
        } else {
			nextDonation = (recurringDonation.npe03__Next_Payment_Date__c != null && String.valueOf(recurringDonation.npe03__Next_Payment_Date__c) != '') ? recurringDonation.npe03__Next_Payment_Date__c.format() : null;
        }
        return nextDonation;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the payment method string.
    * @param fixedRecurringDonations Fixed recurring donations
    * @param mapRDSchedule Map<Id, List<RecurringDonationSchedule__c>> Map recurring donation Ids with the list of recurring donation schedules
    * @return Map<Id, Date> Map Recurring Donation Ids with the related final date
    */
    private Map<Id, Date> getFinalDonations(List<npe03__Recurring_Donation__c> fixedRecurringDonations, Map<Id, List<RecurringDonationSchedule__c>> mapRDSchedule) {
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        Map<Id, Date> mapRDLastDonation = new Map<Id, Date>();
        for(npe03__Recurring_Donation__c rds : fixedRecurringDonations) {
            RD2_RecurringDonation rd = new RD2_RecurringDonation(rds);
            List<RD2_ScheduleService.Installment> installments = scheduleService.getAllVisualizedInstallments(RD2_ScheduleService.currentDate, 100, mapRDSchedule.get(rds.Id));
            mapRDLastDonation.put(rds.Id, Date.valueOf(installments[rd.getPlannedInstallments()-1].nextDonationDate));
        }
        return mapRDLastDonation;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description method to check recurring donation permissions.
    * @return Boolean returns access to Recurring Donations.
    */
    private Boolean hasAccessToRecurringDonation() {

        Set<SObjectField> fields = new Set<SObjectField>{
            npe03__Recurring_Donation__c.npe03__Amount__c,
            npe03__Recurring_Donation__c.npe03__Installment_Period__c,
            npe03__Recurring_Donation__c.InstallmentFrequency__c,
            npe03__Recurring_Donation__c.Day_of_Month__c,
            npe03__Recurring_Donation__c.Status__c,
            npe03__Recurring_Donation__c.PaymentMethod__c,
            npe03__Recurring_Donation__c.npe03__Installments__c,
            npe03__Recurring_Donation__c.npe03__Total_Paid_Installments__c,
            npe03__Recurring_Donation__c.Lastmodifieddate,
            npe03__Recurring_Donation__c.npe03__Date_Established__c,
            npe03__Recurring_Donation__c.RecurringType__c,
            npe03__Recurring_Donation__c.npe03__Contact__c,
            npe03__Recurring_Donation__c.npe03__Last_Payment_Date__c,
            npe03__Recurring_Donation__c.npe03__Next_Payment_Date__c
        };

        if(GE_GiftEntryController.isElevateCustomer()) {
            fields.add(npe03__Recurring_Donation__c.CommitmentId__c);
            fields.add(npe03__Recurring_Donation__c.CardLast4__c);
            fields.add(npe03__Recurring_Donation__c.CardExpirationYear__c);
            fields.add(npe03__Recurring_Donation__c.CardExpirationMonth__c);
            fields.add(npe03__Recurring_Donation__c.ACH_Last_4__c);
        }
        
        return permissions.canRead(npe03__Recurring_Donation__c.SObjectType, fields);
    }

    private without sharing class RDScheduleClass {
        public Map<Id, List<RecurringDonationSchedule__c>> queryRows(Set<Id> recordIds) {
            Map<Id, List<RecurringDonationSchedule__c>> mapRDSchedule = new Map<Id, List<RecurringDonationSchedule__c>>();
            for(RecurringDonationSchedule__c schedule : [   SELECT Active__c, 
                                                                Campaign__c, 
                                                                Campaign__r.Name, 
                                                                StartDate__c, 
                                                                EndDate__c, 
                                                                DayOfMonth__c, 
                                                                InstallmentAmount__c, 
                                                                InstallmentFrequency__c, 
                                                                InstallmentPeriod__c, 
                                                                PaymentMethod__c, 
                                                                RecurringDonation__c, 
                                                                IsPause__c, 
                                                                StatusReason__c 
                                                            FROM RecurringDonationSchedule__c
                                                            WHERE RecurringDonation__c IN :recordIds ]) {
                List<RecurringDonationSchedule__c> schedules = mapRDSchedule.get(schedule.RecurringDonation__c);
                if(schedules == NULL) {
                    schedules = new List<RecurringDonationSchedule__c>();
                }
                schedules.add(schedule);
                mapRDSchedule.put(schedule.RecurringDonation__c, schedules);
            }
            return mapRDSchedule;
        }
    }
}