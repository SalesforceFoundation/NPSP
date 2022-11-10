// Import fields from Recurring Donation SObject
import RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import PLANNED_INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import EFFECTIVE_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';

// Import Recurring Donation related fields from Data Import SObject
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE from '@salesforce/schema/DataImport__c.Donation_Date__c';
import RECURRING_DONATION_RECURRING_TYPE from '@salesforce/schema/DataImport__c.Recurring_Donation_Recurring_Type__c';
import RECURRING_DONATION_DAY_OF_MONTH from '@salesforce/schema/DataImport__c.Recurring_Donation_Day_of_Month__c';
import RECURRING_DONATION_INSTALLMENT_FREQUENCY from '@salesforce/schema/DataImport__c.Recurring_Donation_Installment_Frequency__c';
import RECURRING_DONATION_INSTALLMENT_PERIOD from '@salesforce/schema/DataImport__c.Recurring_Donation_Installment_Period__c';
import RECURRING_DONATION_PLANNED_INSTALLMENTS from '@salesforce/schema/DataImport__c.Recurring_Donation_Planned_Installments__c';
import RECURRING_DONATION_EFFECTIVE_DATE from '@salesforce/schema/DataImport__c.Recurring_Donation_Effective_Date__c';
import RECURRING_DONATION_RECURRING_AMOUNT from '@salesforce/schema/DataImport__c.Recurring_Donation_Amount__c';
import RECURRING_DONATION_DATE_ESTABLISHED from '@salesforce/schema/DataImport__c.Recurring_Donation_Date_Established__c';
import RECURRING_DONATION_IMPORT_STATUS from '@salesforce/schema/DataImport__c.RecurringDonationImportStatus__c';
import RECURRING_DONATION_PAYMENT_METHOD
    from '@salesforce/schema/DataImport__c.Recurring_Donation_Payment_Method__c';
import RECURRING_DONATION_ACH_LAST_4
    from '@salesforce/schema/DataImport__c.Recurring_Donation_ACH_Last_4__c';
import RECURRING_DONATION_END_DATE
    from '@salesforce/schema/DataImport__c.Recurring_Donation_End_Date__c';
import RECURRING_DONATION_NAME
    from '@salesforce/schema/DataImport__c.Recurring_Donation_Name__c';
import RECURRING_DONATION_STATUS
    from '@salesforce/schema/DataImport__c.Recurring_Donation_Status__c';
import RECURRING_DONATION_STATUS_REASON
    from '@salesforce/schema/DataImport__c.Recurring_Donation_Status_Reason__c';
import RECURRING_DONATION_IMPORTED
    from '@salesforce/schema/DataImport__c.RecurringDonationImported__c';
import PAYMENT_METHOD from '@salesforce/schema/DataImport__c.Payment_Method__c';

class GiftScheduleService {
    addScheduleTo(fields, scheduleData) {
        return {
            ...fields,
            [RECURRING_DONATION_RECURRING_TYPE.fieldApiName]: scheduleData[RECURRING_TYPE.fieldApiName],
            [RECURRING_DONATION_DAY_OF_MONTH.fieldApiName]: scheduleData[DAY_OF_MONTH.fieldApiName],
            [RECURRING_DONATION_INSTALLMENT_FREQUENCY.fieldApiName]: scheduleData[INSTALLMENT_FREQUENCY.fieldApiName],
            [RECURRING_DONATION_INSTALLMENT_PERIOD.fieldApiName]: scheduleData[INSTALLMENT_PERIOD.fieldApiName],
            [RECURRING_DONATION_PLANNED_INSTALLMENTS.fieldApiName]: scheduleData[PLANNED_INSTALLMENTS.fieldApiName],
            [RECURRING_DONATION_EFFECTIVE_DATE.fieldApiName]: scheduleData[EFFECTIVE_DATE.fieldApiName],
            [RECURRING_DONATION_RECURRING_AMOUNT.fieldApiName]: fields[DONATION_AMOUNT.fieldApiName],
            [RECURRING_DONATION_DATE_ESTABLISHED.fieldApiName]: fields[DONATION_DATE.fieldApiName],
            [RECURRING_DONATION_PAYMENT_METHOD.fieldApiName]: fields[PAYMENT_METHOD.fieldApiName],
        }
    }

    removeScheduleFromFields(fields) {
        return {
            ...fields,
            [RECURRING_DONATION_RECURRING_TYPE.fieldApiName]: null,
            [RECURRING_DONATION_DAY_OF_MONTH.fieldApiName]: null,
            [RECURRING_DONATION_INSTALLMENT_FREQUENCY.fieldApiName]: null,
            [RECURRING_DONATION_INSTALLMENT_PERIOD.fieldApiName]: null,
            [RECURRING_DONATION_PLANNED_INSTALLMENTS.fieldApiName]: null,
            [RECURRING_DONATION_EFFECTIVE_DATE.fieldApiName]: null,
            [RECURRING_DONATION_RECURRING_AMOUNT.fieldApiName]: null,
            [RECURRING_DONATION_DATE_ESTABLISHED.fieldApiName]: null,
            [RECURRING_DONATION_IMPORT_STATUS.fieldApiName]: null,
            [RECURRING_DONATION_PAYMENT_METHOD.fieldApiName]: null,
            [RECURRING_DONATION_ACH_LAST_4.fieldApiName]: null,
            [RECURRING_DONATION_END_DATE.fieldApiName]: null,
            [RECURRING_DONATION_NAME.fieldApiName]: null,
            [RECURRING_DONATION_STATUS.fieldApiName]: null,
            [RECURRING_DONATION_STATUS_REASON.fieldApiName]: null,
            [RECURRING_DONATION_IMPORTED.fieldApiName]: null
        }
    }

    retrieveScheduleFromFields(fields) {
        const hasRecurringType = fields && fields[RECURRING_DONATION_RECURRING_TYPE.fieldApiName];
        if (!hasRecurringType) {
            return {};
        }
        if (hasRecurringType) {
            const schedule = {
                [RECURRING_TYPE.fieldApiName]: fields[RECURRING_DONATION_RECURRING_TYPE.fieldApiName],
                [DAY_OF_MONTH.fieldApiName]: fields[RECURRING_DONATION_DAY_OF_MONTH.fieldApiName],
                [INSTALLMENT_FREQUENCY.fieldApiName]: fields[RECURRING_DONATION_INSTALLMENT_FREQUENCY.fieldApiName],
                [INSTALLMENT_PERIOD.fieldApiName]: fields[RECURRING_DONATION_INSTALLMENT_PERIOD.fieldApiName],
                [PLANNED_INSTALLMENTS.fieldApiName]: fields[RECURRING_DONATION_PLANNED_INSTALLMENTS.fieldApiName],
                [EFFECTIVE_DATE.fieldApiName]: fields[RECURRING_DONATION_EFFECTIVE_DATE.fieldApiName]
            };
            return schedule;
        }
    }
}

export default GiftScheduleService;