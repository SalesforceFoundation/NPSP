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
* @description Enhanced Recurring Donations constants for specific picklist values and logic
*
*/
public inherited sharing class RD2_Constants {
    /***
    * @description Enum to specify behavior of how to handle open opportunities when the related RD is closed
    */
    public enum CloseActions {
        Delete_Open_Opportunities,
        Mark_Opportunities_Closed_Lost,
        No_Action
    }

    /**
    * @description Enum to specify behavior of how to handle installment opportunity auto-creation
    */
    public enum InstallmentCreateOptions {
        Always_Create_Next_Installment,
        Disable_First_Installment,
        Disable_All_Installments
    }

    /**
    * @description Enum to specify asynchronous behavior for the creation of the first installment opportunity
    */
    public enum FirstInstallmentOppCreateOptions {
        Synchronous,
        Asynchronous,
        Asynchronous_When_Bulk
    }

    /**
    * @description Recurring Donation "Installment Period" picklist API values
    */
    public static final String INSTALLMENT_PERIOD_YEARLY = 'Yearly';
    public static final String INSTALLMENT_PERIOD_MONTHLY = 'Monthly';
    public static final String INSTALLMENT_PERIOD_WEEKLY = 'Weekly';
    public static final String INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH = '1st and 15th';
    public static final String INSTALLMENT_PERIOD_DAILY = 'Daily';
    public static final String INSTALLMENT_PERIOD_QUARTERLY = 'Quarterly';

    /**
    * @description Recurring Donation "Day of Month" picklist API values
    */
    public static final String DAY_OF_MONTH_FIRST = '1';
    public static final String DAY_OF_MONTH_FIFTEENTH = '15';
    public static final String DAY_OF_MONTH_LAST_DAY = 'Last_Day';

    /**
    * @description Recurring Donation "Status" picklist API values
    */
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_LAPSED = 'Lapsed';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_PAUSED = 'Paused';
    public static final String STATUS_FAILING = 'Failing';

    /**
    * @description Recurring Donation "Recurring Type" picklist API values
    */
    public static final String RECURRING_TYPE_OPEN = 'Open';
    public static final String RECURRING_TYPE_FIXED = 'Fixed';

    /**
     * @description Recurring Donation "Donor Type" picklist API values
     */
    public static final String DONOR_TYPE_ACCOUNT = 'Account';
    public static final String DONOR_TYPE_CONTACT = 'Contact';

    /**
    * @description Recurring Donation "Closed Reason" picklist API value when Fixed Length is completed
    */
    public static final String FIXED_TYPE_CLOSED_REASON = 'Commitment Completed';


    public static final String PAYMENT_PICKLIST_VALUE_CARD = 'Credit Card';
    public static final String PAYMENT_PICKLIST_VALUE_ACH = 'ACH';

    /**
    * @description Recurring Donation "Change Type" picklist API values
    */
    public static final String CHANGE_TYPE_UPGRADE = 'Upgrade';
    public static final String CHANGE_TYPE_DOWNGRADE = 'Downgrade';

    /**
    * @description Returns all valid Installment Periods
    */
    public static Set<String> allInstallmentPeriods {
        get {
            if (allInstallmentPeriods == null) {
                allInstallmentPeriods = new Set<String>{
                    INSTALLMENT_PERIOD_DAILY,
                    INSTALLMENT_PERIOD_WEEKLY,
                    INSTALLMENT_PERIOD_MONTHLY,
                    INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH,
                    INSTALLMENT_PERIOD_YEARLY
                };
            }
            return allInstallmentPeriods;
        }
        set;
    }

    /**
    * @description Contains default value for the Installment Frequency
    */
    public static final Integer DEFAULT_INSTALLMENT_FREQUENCY = 1;

    /**
    * @description Contains default value for the Next Donation Date Match Range Days field
    */
    public static final Integer DEFAULT_NEXT_DONATION_DATE_MATCH_RANGE_DAYS = 3;

    public static final Map<String, Integer> PERIOD_TO_YEARLY_FREQUENCY = new Map<String, Integer>{
        INSTALLMENT_PERIOD_YEARLY => 1,
        INSTALLMENT_PERIOD_QUARTERLY => 4,
        INSTALLMENT_PERIOD_MONTHLY => 12,
        INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH => 24,
        INSTALLMENT_PERIOD_WEEKLY => 52,
        INSTALLMENT_PERIOD_DAILY => 365
      };
      
}