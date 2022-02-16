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
import DONATION_RECURRING_TYPE from '@salesforce/schema/DataImport__c.Recurring_Donation_Recurring_Type__c';
import DONATION_DAY_OF_MONTH from '@salesforce/schema/DataImport__c.Recurring_Donation_Day_of_Month__c';
import DONATION_INSTALLMENT_FREQUENCY from '@salesforce/schema/DataImport__c.Recurring_Donation_Installment_Frequency__c';
import DONATION_INSTALLMENT_PERIOD from '@salesforce/schema/DataImport__c.Recurring_Donation_Installment_Period__c';
import DONATION_PLANNED_INSTALLMENTS from '@salesforce/schema/DataImport__c.Recurring_Donation_Planned_Installments__c';
import DONATION_EFFECTIVE_DATE from '@salesforce/schema/DataImport__c.Recurring_Donation_Effective_Date__c';
import DONATION_RECURRING_AMOUNT from '@salesforce/schema/DataImport__c.Recurring_Donation_Amount__c';
import DONATION_DATE_ESTABLISHED from '@salesforce/schema/DataImport__c.Recurring_Donation_Date_Established__c';
import RECURRING_DONATION_IMPORT_STATUS from '@salesforce/schema/DataImport__c.RecurringDonationImportStatus__c';

class GiftScheduleService {
    addScheduleTo(fields, scheduleData) {
        return {
            ...fields,
            [DONATION_RECURRING_TYPE.fieldApiName]: scheduleData[RECURRING_TYPE.fieldApiName],
            [DONATION_DAY_OF_MONTH.fieldApiName]: scheduleData[DAY_OF_MONTH.fieldApiName],
            [DONATION_INSTALLMENT_FREQUENCY.fieldApiName]: scheduleData[INSTALLMENT_FREQUENCY.fieldApiName],
            [DONATION_INSTALLMENT_PERIOD.fieldApiName]: scheduleData[INSTALLMENT_PERIOD.fieldApiName],
            [DONATION_PLANNED_INSTALLMENTS.fieldApiName]: scheduleData[PLANNED_INSTALLMENTS.fieldApiName],
            [DONATION_EFFECTIVE_DATE.fieldApiName]: scheduleData[EFFECTIVE_DATE.fieldApiName],
            [DONATION_RECURRING_AMOUNT.fieldApiName]: fields[DONATION_AMOUNT.fieldApiName],
            [DONATION_DATE_ESTABLISHED.fieldApiName]: fields[DONATION_DATE.fieldApiName],
        } 
    }

    removeScheduleFromFields(fields) {
        return {
            ...fields,
            [DONATION_RECURRING_TYPE.fieldApiName]: null,
            [DONATION_DAY_OF_MONTH.fieldApiName]: null,
            [DONATION_INSTALLMENT_FREQUENCY.fieldApiName]: null,
            [DONATION_INSTALLMENT_PERIOD.fieldApiName]: null,
            [DONATION_PLANNED_INSTALLMENTS.fieldApiName]: null,
            [DONATION_EFFECTIVE_DATE.fieldApiName]: null,
            [DONATION_RECURRING_AMOUNT.fieldApiName]: null,
            [DONATION_DATE_ESTABLISHED.fieldApiName]: null,
            [RECURRING_DONATION_IMPORT_STATUS.fieldApiName]: null
        }
    }

    retrieveScheduleFromFields(fields) {
        const hasRecurringType = fields && fields[DONATION_RECURRING_TYPE.fieldApiName];
        if (!hasRecurringType) {
            return {};
        }
        if (hasRecurringType) {
            const schedule = {
                [RECURRING_TYPE.fieldApiName]: fields[DONATION_RECURRING_TYPE.fieldApiName],
                [DAY_OF_MONTH.fieldApiName]: fields[DONATION_DAY_OF_MONTH.fieldApiName],
                [INSTALLMENT_FREQUENCY.fieldApiName]: fields[DONATION_INSTALLMENT_FREQUENCY.fieldApiName],
                [INSTALLMENT_PERIOD.fieldApiName]: fields[DONATION_INSTALLMENT_PERIOD.fieldApiName],
                [PLANNED_INSTALLMENTS.fieldApiName]: fields[DONATION_PLANNED_INSTALLMENTS.fieldApiName],
                [EFFECTIVE_DATE.fieldApiName]: fields[DONATION_EFFECTIVE_DATE.fieldApiName]
            };
            return schedule;
        }
    }
}

export default GiftScheduleService;