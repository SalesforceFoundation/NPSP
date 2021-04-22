import CURRENCY from '@salesforce/i18n/currency';
import PAYMENT_AUTHORIZE_TOKEN from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';

class ElevateTokenizeabledGift {

    constructor(fullName, amount) {
        this.amount = amount;
        this.firstName = fullName.firstName;
        this.lastName = fullName.lastName;
        this.currencyCode = CURRENCY;
        this.paymentMethodToken = null;
    }

    async tokenize(sections) {
        let widgetValues = [];
        sections.forEach(section => {
            if (section.isPaymentWidgetAvailable) {
                widgetValues = widgetValues.concat(
                    section.paymentToken
                );
            }
        });

        if (widgetValues) {
            const tokenResponse = await Promise.all(
                [widgetValues[0].payload]
            );

            if (tokenResponse) {
                this.paymentMethodToken = tokenResponse[0][PAYMENT_AUTHORIZE_TOKEN.fieldApiName];
                return tokenResponse[0];
            }
        }
    }

}

export default ElevateTokenizeabledGift;