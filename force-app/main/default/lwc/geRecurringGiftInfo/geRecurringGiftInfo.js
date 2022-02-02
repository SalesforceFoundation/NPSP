import { LightningElement, api } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';

import RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import EFFECTIVE_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';

import commonEdit from '@salesforce/label/c.commonEdit';
import geRemoveSchedule from '@salesforce/label/c.geRemoveSchedule';
import geOpenEndedGiftSchedule from '@salesforce/label/c.geOpenEndedGiftSchedule';
import geFixedGiftSchedule from '@salesforce/label/c.geFixedGiftSchedule';
import geRecurringScheduleInformation from '@salesforce/label/c.geRecurringScheduleInformation';

import { format } from 'c/utilCommon';

const OPEN = 'Open';
const FIXED = 'Fixed';

export default class GeRecurringGiftInfo extends LightningElement {
    @api giftInView;

    labels = {
        commonEdit,
        geRemoveSchedule,
        geRecurringScheduleInformation,
    };

    get scheduleText() {
        if (!this.giftInView || !this.giftInView.schedule) {
            return '';
        }

        const recurringType = this.recurringType();
        if (recurringType === OPEN) {
            return this.formattedLabelForOpenEndedSchedule();
        }
        if (recurringType === FIXED) {
            return this.formattedLabelForFixedSchedule();
        }
    }

    handleEdit() {
        const customEvent = new CustomEvent('editschedule', {});
        this.dispatchEvent(customEvent);
    }

    handleRemoveSchedule() {
        const customEvent = new CustomEvent('removeschedule', {});
        this.dispatchEvent(customEvent);
    }

    formattedLabelForOpenEndedSchedule() {
        return format(geOpenEndedGiftSchedule, [
            this.localizedDonationAmount(),
            this.installmentPeriod(),
            this.localizedEffectiveDate()
        ]);
    }

    formattedLabelForFixedSchedule() {
        return format(geFixedGiftSchedule, [
            this.localizedDonationAmount(),
            this.installmentPeriod(),
            this.localizedEffectiveDate(),
            this.installments()
        ]);
    }

    recurringType() {
        const scheduleFields = this.giftInView?.schedule;
        const recurringType = scheduleFields[RECURRING_TYPE.fieldApiName];
        return recurringType;
    }

    localizedDonationAmount() {
        const donationAmount = this.giftInView?.fields[DONATION_AMOUNT.fieldApiName] || 0;
        const localizedDonationAmount = new Intl.NumberFormat(LOCALE,
            {
                style: 'currency',
                currency: CURRENCY,
                currencyDisplay: 'symbol'
            })
            .format(donationAmount);
        return localizedDonationAmount;
    }

    localizedEffectiveDate() {
        const scheduleFields = this.giftInView?.schedule;
        const effectiveDate = scheduleFields[EFFECTIVE_DATE.fieldApiName];
        const i18nOptions = {
            timeZone: 'UTC',
            dateStyle: 'long',
        };
        const localizedEffectiveDate = new Intl.DateTimeFormat(LOCALE, i18nOptions)
            .format(new Date(effectiveDate));
        return localizedEffectiveDate;
    }

    installmentPeriod() {
        const scheduleFields = this.giftInView?.schedule;
        return scheduleFields[INSTALLMENT_PERIOD.fieldApiName]?.toLowerCase();
    }

    installments() {
        const scheduleFields = this.giftInView?.schedule;
        return scheduleFields[INSTALLMENTS.fieldApiName];
    }
}
