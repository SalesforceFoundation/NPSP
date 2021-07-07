public inherited sharing class SfdoInstrumentationEnum {

    public enum Feature {
        TDTM,
        RecurringDonations,
        GiftEntry,
        DataImportEngine,
        EngagementPlans,
        Households,
        Payments,
        Allocations,
        ContactRoles,
        Donations,
        Relationships,
        Affiliations,
        SoftCreditAutomation,
        CustomizableRollups,
        PaymentServices,
        LeadConversion,
        RecordMerge,
        ErrorHandling,
        Addresses,
        MatchingGifts,
        PartialSoftCredits,
        GetStarted,
        Settings
    }

    public enum Component {
        Account,
        Contact,
        Opportunity,
        Lead,
        Campaign,
        Payment,
        ContactRole,
        GAU,
        Page,
        Batch,
        Queueable,
        TriggerAction
    }

    public enum Action {
        Open,
        Save,
        Cancel,
        Create,
        Dml_Insert,
        Dml_Delete,
        Dml_Update,
        Dml_Merge,
        Dml_Undelete,
        Duration,
        DML_Count,
        Query_Count,
        Batch_Count,
        Processed_Count
    }
}
