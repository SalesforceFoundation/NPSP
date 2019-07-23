public with sharing class UTIL_Allocation_Helper {

    public static Map<Id, List<Allocation__c>> addAllocationToMap(Map<Id, List<Allocation__c>> mapToAddTo, Allocation__c allocationToAdd) {
        List<Allocation__c> mappedAllocationList = new List<Allocation__c>();

        if (mapToAddTo.containsKey(allocationToAdd.General_Accounting_Unit__c)) {
            mappedAllocationList = mapToAddTo.get(allocationToAdd.General_Accounting_Unit__c);
        }

        mappedAllocationList.add(allocationToAdd);

        mapToAddTo.put(allocationToAdd.General_Accounting_Unit__c, mappedAllocationList);

        return mapToAddTo;
    }

    public static Map<Id, List<Allocation__c>> opportunityAllocationsByGAU(List<Allocation__c> allocationList) {
        Map<Id, List<Allocation__c>> opportunityAllocationsByGAU = new Map<Id, List<Allocation__c>>();

        for (Allocation__c allocation : allocationList) {

            // We only want to map the allocations that are opportunities.
            if (allocation.Opportunity__c != null) {
                opportunityAllocationsByGAU = addAllocationToMap(opportunityAllocationsByGAU, allocation);
            }
        }

        return opportunityAllocationsByGAU;
    }

    public static Map<Id, List<Allocation__c>> paymentAllocationsByGAU(List<Allocation__c> allocationList) {
        Map<Id, List<Allocation__c>> paymentAllocationsByGAU = new Map<Id, List<Allocation__c>>();

        for (Allocation__c allocation : allocationList) {

            // We only want to map the allocations that are payments.
            if (allocation.Payment__c != null) {
                paymentAllocationsByGAU = addAllocationToMap(paymentAllocationsByGAU, allocation);
            }
        }

        return paymentAllocationsByGAU;
    }

    public static Map<Id, Decimal> addAllocationAmountToMap(Map<Id, Decimal> mapToAdd, Allocation__c allocationToAdd) {
        Decimal totalOppAmount = 0;

        if (mapToAdd.containsKey(allocationToAdd.General_Accounting_Unit__c)) {
            totalOppAmount = mapToAdd.get(allocationToAdd.General_Accounting_Unit__c);
        }

        totalOppAmount += allocationToAdd.Amount__c;

        mapToAdd.put(allocationToAdd.General_Accounting_Unit__c, totalOppAmount);

        return mapToAdd;
    }

    public static Map<Id, Decimal> totalOpportunityAllocationsByGAU(List<Allocation__c> allocationList) {
        Map<Id, Decimal> totalOppAmountByGAU = new Map<Id, Decimal>();

        for (Allocation__c allocation : allocationList) {
            if (allocation.Opportunity__c != null) {
                totalOppAmountByGAU = addAllocationAmountToMap(totalOppAmountByGAU, allocation);
            }
        }

        return totalOppAmountByGAU;
    }

    public static Map<Id, Decimal> totalPaymentAllocationsByGAU(List<Allocation__c> allocationList) {
        Map<Id, Decimal> totalPaymentAmountByGAU = new Map<Id, Decimal>();

        for (Allocation__c allocation : allocationList) {
            if (allocation.Payment__c != null) {
                totalPaymentAmountByGAU = addAllocationAmountToMap(totalPaymentAmountByGAU, allocation);
            }
        }

        return totalPaymentAmountByGAU;
    }


    public static List<Allocation__c> getAllocationsWithPayment(List<Allocation__c> allocationList) {
        List<Allocation__c> queriedAllocationList = [SELECT Id, Amount__c, General_Accounting_Unit__c,
                                                        Percent__c, Payment__c, Payment__r.npe01__Paid__c,
                                                        Payment__r.npe01__Payment_Amount__c
                                                FROM Allocation__c
                                                WHERE Id in: allocationList];

        return queriedAllocationList;
    }

    public static Map<Id, Decimal> totalPaidPaymentAllocationsByGAU(List<Allocation__c> allocationList) {
        List<Allocation__c> queriedAllocationList = getAllocationsWithPayment(allocationList);
        Map<Id, Decimal> paidPaymentAmountByGAU = new Map<Id, Decimal>();


        for (Allocation__c allocation : queriedAllocationList) {
            if (allocation.Payment__r.npe01__Paid__c == true) {

            }
        }

        return paidPaymentAmountByGAU;
    }



    public static Decimal totalOfPaidPayments(List<Allocation__c> allocationList) {
        List<Allocation__c> queriedAllocationList = getAllocationsWithPayment(allocationList);
        Decimal totalPaidAmount = 0;

        for (Allocation__c allocation : allocationList) {
            if (allocation.Payment__r.npe01__Paid__c == true) {
                totalPaidAmount += allocation.Payment__r.npe01__Payment_Amount__c;
            }
        }

        return totalPaidAmount;
    }

    public static Decimal totalOfUnpaidPayments(List<Allocation__c> allocationList) {
        List<Allocation__c> queriedAllocationList = getAllocationsWithPayment(allocationList);
        Decimal totalUnpaidAmount = 0;

        for (Allocation__c allocation : allocationList) {
            if (allocation.Payment__r.npe01__Paid__c == false) {
                totalUnpaidAmount += allocation.Payment__r.npe01__Payment_Amount__c;
            }
        }

        return totalUnpaidAmount;
    }

    public static Decimal totalPaidUnpaidPayments(List<Allocation__c> allocationList) {
        List<Allocation__c> queriedAllocationList = getAllocationsWithPayment(allocationList);
        Decimal totalPaymentAllocationAmount = 0;

        for (Allocation__c allocation : allocationList) {
            totalPaymentAllocationAmount += allocation.Payment__r.npe01__Payment_Amount__c;
        }

        return totalPaymentAllocationAmount;
    }
}