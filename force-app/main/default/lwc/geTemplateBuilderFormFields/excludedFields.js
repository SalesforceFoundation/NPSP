
import CONTACT1_CONSENT_MESSAGE_FIELD from '@salesforce/schema/DataImport__c.Contact1_Consent_Message__c';
import CONTACT1_CONSENT_OPT_IN_FIELD from '@salesforce/schema/DataImport__c.Contact1_Consent_Opt_In__c';
import DONATION_ELEVATE_RECURRING_ID_FIELD from '@salesforce/schema/DataImport__c.Donation_Elevate_Recurring_ID__c';
import PAYMENT_AUTHORIZATION_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import PAYMENT_AUTHORIZED_DATE_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorized_Date__c';
import PAYMENT_AUTHORIZED_UTC_TIMESTAMP_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorized_UTC_Timestamp__c';
import PAYMENT_CARD_EXPIRATION_MONTH_FIELD from '@salesforce/schema/DataImport__c.Payment_Card_Expiration_Month__c';
import PAYMENT_CARD_EXPIRATION_YEAR_FIELD from '@salesforce/schema/DataImport__c.Payment_Card_Expiration_Year__c';
import PAYMENT_CARD_LAST_4_FIELD from '@salesforce/schema/DataImport__c.Payment_Card_Last_4__c';
import PAYMENT_CARD_NETWORK_FIELD from '@salesforce/schema/DataImport__c.Payment_Card_Network__c';
import PAYMENT_DECLINED_REASON_FIELD from '@salesforce/schema/DataImport__c.Payment_Declined_Reason__c';
import PAYMENT_ELEVATE_CREATED_DATE_FIELD from '@salesforce/schema/DataImport__c.Payment_Elevate_Created_Date__c';
import PAYMENT_ELEVATE_CREATED_UTC_TIMESTAMP_FIELD from '@salesforce/schema/DataImport__c.Payment_Elevate_Created_UTC_Timestamp__c';
import PAYMENT_ELEVATE_ID_FIELD from '@salesforce/schema/DataImport__c.Payment_Elevate_ID__c';
import PAYMENT_ELEVATE_ORIGINAL_PAYMENT_ID_FIELD from '@salesforce/schema/DataImport__c.Payment_Elevate_Original_Payment_ID__c';
import PAYMENT_GATEWAY_ID_FIELD from '@salesforce/schema/DataImport__c.Payment_Gateway_ID__c';
import PAYMENT_GATEWAY_PAYMENT_IDFIELD from '@salesforce/schema/DataImport__c.Payment_Gateway_Payment_ID__c';
import PAYMENT_ORIGIN_ID_FIELD from '@salesforce/schema/DataImport__c.Payment_Origin_ID__c';
import PAYMENT_ORIGIN_NAME_FIELD from '@salesforce/schema/DataImport__c.Payment_Origin_Name__c';
import PAYMENT_ORIGIN_TYPE_FIELD from '@salesforce/schema/DataImport__c.Payment_Origin_Type__c';
import PAYMENT_STATUS_FIELD from '@salesforce/schema/DataImport__c.Payment_Status__c';
import PAYMENT_TYPE_FIELD from '@salesforce/schema/DataImport__c.Payment_Type__c';
import PAYMENT_ACH_LAST_4 from '@salesforce/schema/DataImport__c.Payment_ACH_Last_4__c';
import PAYMENT_ACH_CODE from '@salesforce/schema/DataImport__c.Payment_ACH_Code__c';
import PAYMENT_DONOR_COVER_AMOUNT from '@salesforce/schema/DataImport__c.Payment_Donor_Cover_Amount__c';
import DONATION_CAMPAIGN_SOURCE_FIELD from '@salesforce/schema/DataImport__c.DonationCampaignImported__c';
import RECURRING_DONATION_AMOUNT_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Amount__c';
import RECURRING_DONATION_DATE_ESTABLISHED_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Date_Established__c';
import RECURRING_DONATION_DAY_OF_MONTH_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Day_of_Month__c';
import RECURRING_DONATION_EFFECTIVE_DATE_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Effective_Date__c';
import RECURRING_DONATION_ELEVATE_RECURRING_ID_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Elevate_Recurring_ID__c';
import RECURRING_DONATION_END_DATE_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_End_Date__c';
import RECURRING_DONATION_INSTALLMENT_FREQUENCY_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Installment_Frequency__c';
import RECURRING_DONATION_INSTALLMENT_PERIOD_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Installment_Period__c';
import RECURRING_DONATION_NAME_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Name__c';
import RECURRING_DONATION_PAYMENT_METHOD_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Payment_Method__c';
import RECURRING_DONATION_PLANNED_INSTALLMENTS_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Planned_Installments__c';
import RECURRING_DONATION_RECURRING_TYPE_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Recurring_Type__c';
import RECURRING_DONATION_STATUS_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Status__c';
import RECURRING_DONATION_STATUS_REASON_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Status_Reason__c';
import RECURRING_DONATION_IMPORTED_FIELD from '@salesforce/schema/DataImport__c.RecurringDonationImported__c';
import RECURRING_DONATION_CHANGE_TYPE_FIELD from '@salesforce/schema/DataImport__c.Recurring_Donation_Change_Type__c';
import RECURRING_DONATION_ACH_LAST_4__C from '@salesforce/schema/DataImport__c.Recurring_Donation_ACH_Last_4__c';
import RECURRING_DONATION_CARD_EXPIRATION_MONTH__C from '@salesforce/schema/DataImport__c.Recurring_Donation_Card_Expiration_Month__c';
import RECURRING_DONATION_CARD_EXPIRATION_YEAR__C from '@salesforce/schema/DataImport__c.Recurring_Donation_Card_Expiration_Year__c';
import RECURRING_DONATION_CARD_LAST_4__C from '@salesforce/schema/DataImport__c.Recurring_Donation_Card_Last_4__c';
import RECURRING_DONATION_ELEVATE_EVENT_VERSION__C from '@salesforce/schema/DataImport__c.Recurring_Donation_Elevate_Event_Version__c';

const EXCLUDED_FIELD_MAPPINGS_BY_SOURCE_API_NAME = [
    CONTACT1_CONSENT_MESSAGE_FIELD.fieldApiName,
    CONTACT1_CONSENT_OPT_IN_FIELD.fieldApiName,
    DONATION_ELEVATE_RECURRING_ID_FIELD.fieldApiName,
    PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName,
    PAYMENT_AUTHORIZED_DATE_FIELD.fieldApiName,
    PAYMENT_AUTHORIZED_UTC_TIMESTAMP_FIELD.fieldApiName,
    PAYMENT_CARD_EXPIRATION_MONTH_FIELD.fieldApiName,
    PAYMENT_CARD_EXPIRATION_YEAR_FIELD.fieldApiName,
    PAYMENT_CARD_LAST_4_FIELD.fieldApiName,
    PAYMENT_CARD_NETWORK_FIELD.fieldApiName,
    PAYMENT_DECLINED_REASON_FIELD.fieldApiName,
    PAYMENT_ELEVATE_CREATED_DATE_FIELD.fieldApiName,
    PAYMENT_ELEVATE_CREATED_UTC_TIMESTAMP_FIELD.fieldApiName,
    PAYMENT_ELEVATE_ID_FIELD.fieldApiName,
    PAYMENT_ELEVATE_ORIGINAL_PAYMENT_ID_FIELD.fieldApiName,
    PAYMENT_GATEWAY_ID_FIELD.fieldApiName,
    PAYMENT_GATEWAY_PAYMENT_IDFIELD.fieldApiName,
    PAYMENT_ORIGIN_ID_FIELD.fieldApiName,
    PAYMENT_ORIGIN_NAME_FIELD.fieldApiName,
    PAYMENT_ORIGIN_TYPE_FIELD.fieldApiName,
    PAYMENT_STATUS_FIELD.fieldApiName,
    PAYMENT_TYPE_FIELD.fieldApiName,
    PAYMENT_ACH_LAST_4.fieldApiName,
    PAYMENT_ACH_CODE.fieldApiName,
    PAYMENT_DONOR_COVER_AMOUNT.fieldApiName,
    DONATION_CAMPAIGN_SOURCE_FIELD.fieldApiName,
    RECURRING_DONATION_AMOUNT_FIELD.fieldApiName,
    RECURRING_DONATION_DATE_ESTABLISHED_FIELD.fieldApiName,
    RECURRING_DONATION_DAY_OF_MONTH_FIELD.fieldApiName,
    RECURRING_DONATION_EFFECTIVE_DATE_FIELD.fieldApiName,
    RECURRING_DONATION_ELEVATE_RECURRING_ID_FIELD.fieldApiName,
    RECURRING_DONATION_END_DATE_FIELD.fieldApiName,
    RECURRING_DONATION_INSTALLMENT_FREQUENCY_FIELD.fieldApiName,
    RECURRING_DONATION_INSTALLMENT_PERIOD_FIELD.fieldApiName,
    RECURRING_DONATION_NAME_FIELD.fieldApiName,
    RECURRING_DONATION_PAYMENT_METHOD_FIELD.fieldApiName,
    RECURRING_DONATION_PLANNED_INSTALLMENTS_FIELD.fieldApiName,
    RECURRING_DONATION_RECURRING_TYPE_FIELD.fieldApiName,
    RECURRING_DONATION_STATUS_FIELD.fieldApiName,
    RECURRING_DONATION_STATUS_REASON_FIELD.fieldApiName,
    RECURRING_DONATION_IMPORTED_FIELD.fieldApiName,
    RECURRING_DONATION_CHANGE_TYPE_FIELD.fieldApiName,
    RECURRING_DONATION_ACH_LAST_4__C.fieldApiName,
    RECURRING_DONATION_CARD_EXPIRATION_MONTH__C.fieldApiName,
    RECURRING_DONATION_CARD_EXPIRATION_YEAR__C.fieldApiName,
    RECURRING_DONATION_CARD_LAST_4__C.fieldApiName,
    RECURRING_DONATION_ELEVATE_EVENT_VERSION__C.fieldApiName,
];

export { EXCLUDED_FIELD_MAPPINGS_BY_SOURCE_API_NAME };