import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';

const numberFormat = (locale, currency) => {
    return new Intl.NumberFormat(locale, {
        style: 'currency',
        currency: currency,
        currencyDisplay: 'symbol'
    });
}

/*******************************************************************************
* @description Format the provided number into a localized currency string
* based on the logged in user's locale and currency.
*
* @param {integer} number: Number to format into currency
*/
const getNumberAsLocalizedCurrency = (number) => {
    return numberFormat(LOCALE, CURRENCY).format(number);
}

/*******************************************************************************
* @description Format the provided number into a localized currency string
* based on the logged in user's locale and the provided currency code.
*
* @param {integer} number: Number to format into currency
* @param {string} currencyCode: ISO 4217 currency code to provide the currency
* symbol
*/
const getNumberAsCurrencyByCode = (amount, currencyCode) => {
    return numberFormat(LOCALE, currencyCode).format(amount);
}

export {
    getNumberAsLocalizedCurrency,
    getNumberAsCurrencyByCode
}