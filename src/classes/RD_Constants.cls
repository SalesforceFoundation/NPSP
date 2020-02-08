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
* @description Legacy Recurring Donations constants for specific picklist values. This is necessary to
* allow the legacy custom labels for picklist values in the NPE03 (RecurringDonations) package to be
* fully deprecated.
*
*/
public class RD_Constants {

    /**
    * @description Recurring Donation "Schedule Type" picklist API values
    */
    public static final String SCHEDULE_TYPE_DIVIDE_BY = 'Divide By';
    public static final String SCHEDULE_TYPE_MULTIPLY_BY = 'Multiply By';

    /**
    * @description Recurring Donation "Schedule Type" picklist API values
    */
    public static final String OPEN_ENDED_STATUS_OPEN = 'Open';
    public static final String OPEN_ENDED_STATUS_CLOSED = 'Closed';
    public static final String OPEN_ENDED_STATUS_NONE = 'None';

    /**
    * @description Recurring Donation "Installment Period" picklist API values
    */
    public static final String INSTALLMENT_PERIOD_YEARLY = 'Yearly';
    public static final String INSTALLMENT_PERIOD_MONTHLY = 'Monthly';
    public static final String INSTALLMENT_PERIOD_WEEKLY = 'Weekly';
    public static final String INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH = '1st and 15th';
    public static final String INSTALLMENT_PERIOD_DAILY = 'Daily';
    public static final String INSTALLMENT_PERIOD_QUARTERLY = 'Quarterly';

}