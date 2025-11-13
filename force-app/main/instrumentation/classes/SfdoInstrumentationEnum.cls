/*
    Copyright (c) 2022 Salesforce.org
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
* @group Product Instrumentation
* @description Enums of Features, Components and Actions to use with product instrumentation. These ensure consistency
* of values in the Splunk logs.
*
*/
public with sharing class SfdoInstrumentationEnum {

    /**
     * @description High Level product feature for the instrumentation entries. New Features can be added to this list when required.
     * Always be sure to avoid duplicate or ambiguous feature names. Features defined here will be queryable in SFDC's internal system.
     */
    public enum Feature {
        TDTM,
        ErrorHandling,
        Addresses,
        SeasonalAddresses,
        GetStarted,
        AccountModelConversion,
        Settings,
        EnhancedRecurringDonations,
        LegacyRecurringDonations,
        GiftEntry,
        DataImportEngine,
        EngagementPlans,
        Levels,
        Households,
        Payments,
        Allocations,
        ContactRoles,
        Donations,
        Relationships,
        Affiliations,
        SoftCreditAutomation,
        MatchingGifts,
        MajorGifts,
        Memberships,
        Grants,
        PartialSoftCredits,
        CustomizableRollups,
        LegacyRollups,
        PaymentServices,
        LeadConversion,
        RecordMerge,
        ContactMerge,
        ManageHousehold,
        HouseholdNaming
    }

    /**
     * @description Components within a product Feature for the instrumentation entries. New Components can be added to this 
     * list when required. Always be sure to avoid duplicate or ambiguous component names. Components defined here will be 
     * queryable in SFDC's internal system. 
     */
    public enum Component {
        /* LWC, Aura or VF */
        Page,
        /* ASynchronous processing */
        Batch,
        Queueable,
        Schedule,
        Future,
        TriggerAction,
        /* Specific Rollup Job Types */
        Contact_HardCredit, 
        Account_HardCredit,
        Contact_SoftCredit,
        Account_SoftCredit,
        AccountContact_SoftCredit,
        GAU_HardCredit,
        RD_HardCredit,
        API
    }

    /**
     * @description The "Action" being taken to define the instrumentation entry. New Actions can be added to this list when required.
     * Always be sure to avoid duplicate or ambiguous Actions. Actions defined here will be queryable in SFDC's internal system.
     * Note that some Action names are defined to to avoid conflict with Apex internal types (ex: Insert, Delete, etc.)
     */
    public enum Action {
        /* Page Operations*/
        Open,
        Save,
        Cancel,
        Create,
        /* DML Operations */
        Dml_Insert,
        Dml_Delete,
        Dml_Update,
        Dml_Merge,
        Dml_Undelete,
        /* Batch/ASynchronous Operations */
        Duration,
        DMLCount,
        QueryCount,
        BatchCount,
        ProcessedCount,
        ThroughputPerHour,
        /* Trigger Operations */
        BeforeInsert, 
        BeforeUpdate, 
        BeforeDelete, 
        AfterInsert, 
        AfterUpdate, 
        AfterDelete,
        AfterUndelete,
        /* Others */
        Validation,
        Verification,
        /* API Operations */
        Pause,
        QuerySchedules,
        QueryInstallments,
        /* Contact Merge Operations */
        DuplicateRecordSetResultCount,
        ContactMergeResultCount,
        /* Manage Household Operations */
        HouseholdContactNamingExclusionsUpdated,
        HouseholdNamingSettingsUpdated,
        HouseholdMerged,
        HouseholdMemberAdded,
        HouseholdAddressChanged,
        HouseholdNamesUpdated
    }
}
