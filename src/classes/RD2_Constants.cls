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
* @description Constants related to specific picklist values and other
*
*/
public class RD2_Constants {

    /** 
     * @description Api Values of the npe03_RecurringDonation.Installment_Frequency__c picklist
     * To support spaces in the api name of the FirstAndFifteenth option, this is configured
     * as a class with public string properties rather than an Enum.
     * String still start with a capital letter to be consistent in usage
     */
    public class Schedule {
        public static final String Monthly = 'Monthly';
        public static final String Weekly = 'Weekly';
        public static final String Yearly = 'Yearly';
        public static final String FirstAndFifteenth = '1st and 15th'; 
    }

    /** 
     * @description Api Values of the npe03_RecurringDonation.Day_Of_Month__c picklist
     * To support a numeric value in the api name of the options, this is configured
     * as a class with public string properties rather than an Enum.
     * String still start with a capital letter to be consistent in usage
     */
   public class DayOfMonth {
        public static final String First = '1';
        public static final String Fifteenth = '15';
        public static final String LastDay = 'Last_Day';
    }

    /** 
     * @description Api Values of the npe03_RecurringDonation.Status__c picklist
     */
    public enum Status {
        Active,
        Lapsed,
        Closed
    }

    /** 
     * @description Api Values of the npe03__RecurringDonation.RecurringType__c picklist
     */
    public enum Type {
        Open
    }

    public static final Integer DEFAULT_MIGRATION_JOB_BATCH_SIZE = 200;
}