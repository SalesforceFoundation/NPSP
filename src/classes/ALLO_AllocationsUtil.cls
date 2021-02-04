/*
    Copyright (c) 2020, Salesforce.org
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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Utility class to support shared functionality for Allocations
*/
public inherited sharing class ALLO_AllocationsUtil {

    // Lazy initialization on use to reduce describes for Object Labels
    /** @description Caches The Allocation Object's Label */
    @testVisible private static String allocationObjectLabel {
        get {
            if (allocationObjectLabel == null) {
                allocationObjectLabel = UTIL_Describe.getObjectLabel(UTIL_Namespace.StrTokenNSPrefix('Allocation__c'));
            }
            return allocationObjectLabel;
        }
        private set;
    }

    /** @description Caches The Opportunity Object's Label */
    @testVisible private static String opportunityObjectLabel {
        get {
            if (opportunityObjectLabel == null) {
                opportunityObjectLabel = UTIL_Describe.getObjectLabel('Opportunity');
            }
            return opportunityObjectLabel;
        }
        private set;
    }

    /** @description Caches The Payment Object's Label */
    @testVisible private static String paymentObjectLabel {
        get {
            if (paymentObjectLabel == null) {
                paymentObjectLabel = UTIL_Describe.getObjectLabel('npe01__OppPayment__c');
            }
            return paymentObjectLabel;
        }
        private set;
    }

    /**
     * @description Disables the following Allocation Triggers, on the Allocation, Opportunity,
     *              and npe01__OppPayment__c objects: ALLO_Allocations_TDTM, ALLO_PaymentSync_TDTM (in
     *              memory only)
     */
    public static void disableAllocationTriggers() {
        updateAllocationTriggersState(false);
    }

    /**
     * @description Enables the following Allocation Triggers, on the Allocation, Opportunity,
     *              and npe01__OppPayment__c objects: ALLO_Allocations_TDTM, ALLO_PaymentSync_TDTM (in
     *              memory only)
     */
    public static void enableAllocationTriggers() {
        updateAllocationTriggersState(true);
    }

    /**
     * @description Updates the state of the Allocation triggers in the in memory cache, enabling or
     *              disabling the trigger.  The following triggers are enabled/disabled by this method:
     *              ALLO_Allocations_TDTM, ALLO_PaymentSync_TDTM.
     * @param Boolean state - If true, they are active, if false, they are inactive.
     */
    @testVisible private static void updateAllocationTriggersState(Boolean state) {
        TDTM_ProcessControl.toggleTriggerState('Allocation__c', 'ALLO_Allocations_TDTM', state);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'ALLO_Allocations_TDTM', state);
        TDTM_ProcessControl.toggleTriggerState('npe01__OppPayment__c', 'ALLO_Allocations_TDTM', state);
        TDTM_ProcessControl.toggleTriggerState('Allocation__c', 'ALLO_PaymentSync_TDTM', state);
    }

    /**
     * @description Determines whether this is a Opportunity or a Payment Object, and returns the
     *              Opportunity Id associated with it (either the Opportunities Id, or the Opportunity Id
     *              of the related record if it is a Payment)
     * @return Id (for the Opportunity)
     */
    public static Id getOpportunityIdFor(SObject sObj) {
        if (sObj != null) {
            if (sObj instanceOf Opportunity) {
                return (Id) sObj.Id;
            }
            if (sObj instanceOf npe01__OppPayment__c) {
                return (Id) sObj.get('npe01__Opportunity__c');
            }
        }

        return null;
    }

    /**
     * @description Determines whether this is a Opportunity or a Payment Object, and returns the Amount
     *              associated with it
     * @return Decimal value of the object's amount
     */
    public static Decimal getAmountFor(SObject sObj) {
        if (sObj != null) {
            if (sObj instanceOf Opportunity) {
                return (Decimal) sObj.get('Amount');
            }
            if (sObj instanceOf npe01__OppPayment__c) {
                return (Decimal) sObj.get('npe01__Payment_Amount__c');
            }
        }

        return null;
    }

    /**
     * @description Determines whether this is a Opportunity or a Payment Object, and returns the
     *              appropriate label
     * @return String The Object's Label
     */
    public static String getLabelFor(SObject sObj) {
        return (sObj instanceOf Opportunity) ? opportunityObjectLabel : ((sObj instanceOf npe01__OppPayment__c) ? paymentObjectLabel : ((sObj instanceOf Allocation__c) ? allocationObjectLabel : ''));
    }
}