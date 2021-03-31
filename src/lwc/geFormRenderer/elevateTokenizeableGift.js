class ElevateTokenizeabledGift {

    constructor(firstName, lastName, amount, currencyCode) {
        this.amount = amount;
        this.firstName = firstName;
        this.lastName = lastName;
        this.currencyCode = currencyCode;
        this.token = null;
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
                this.token = tokenResponse[0].Payment_Authorization_Token__c;
                return tokenResponse[0];
            }
        }
    }

}

export default ElevateTokenizeabledGift;