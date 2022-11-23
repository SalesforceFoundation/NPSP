import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';
import { isNull } from 'c/util';

// map for translating the currency amt into the lowest denominator; e.g. dollars into cents
const DEFAULT_MULTIPLIER = 100;
const currencyMultiplier = new Map([['USD', DEFAULT_MULTIPLIER]]);

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

/*******************************************************************************
* @description Formats the provided number into the lowest common denominator by currency as a string
* based on the logged in user's locale and currency.
*
* @param number: Number to convert into lowest common denominator
*/
const getCurrencyLowestCommonDenominator = (number) => {
    let multiplier = isNull(currencyMultiplier.get(CURRENCY)) ? DEFAULT_MULTIPLIER : currencyMultiplier.get(CURRENCY);
    return parseInt(parseFloat(number) * multiplier, 10);
}

export {
    getNumberAsLocalizedCurrency,
    getNumberAsCurrencyByCode,
    getCurrencyLowestCommonDenominator
}