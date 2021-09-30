const DISABLE_TOKENIZE_WIDGET_EVENT_NAME = 'disableGeFormWidgetTokenizeCard';
const LABEL_NEW_LINE = '/0x0A/';

// http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
const HTTP_CODES = Object.freeze({
    OK: 200,
    Created: 201,
    Bad_Request: 400,
    Request_Timeout: 408,
});

const ACCOUNT_HOLDER_TYPES = Object.freeze({
    INDIVIDUAL: 'INDIVIDUAL',
    BUSINESS: 'BUSINESS'
});
const ACCOUNT_HOLDER_BANK_TYPES = Object.freeze({
    CHECKING: 'CHECKING',
    SAVINGS: 'SAVINGS'
});

const ACH_CODE = 'WEB';
const PAYMENT_METHOD_CREDIT_CARD = 'Credit Card';
const PAYMENT_METHOD_ACH = 'ACH';
const PAYMENT_UNKNOWN_ERROR_STATUS = 'UNKNOWN ERROR';
const FAILED = 'Failed';

const TOKENIZE_CREDIT_CARD_EVENT_ACTION = 'createToken';
const TOKENIZE_ACH_EVENT_ACTION = 'createAchToken';

const PAYMENT_METHODS = Object.freeze({
    ACH: 'ACH',
    CREDIT_CARD: 'CARD'
});
export {
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    LABEL_NEW_LINE,
    HTTP_CODES,
    ACCOUNT_HOLDER_TYPES,
    ACCOUNT_HOLDER_BANK_TYPES,
    PAYMENT_METHODS,
    PAYMENT_UNKNOWN_ERROR_STATUS,
    FAILED,
    ACH_CODE,
    PAYMENT_METHOD_CREDIT_CARD,
    PAYMENT_METHOD_ACH,
    TOKENIZE_ACH_EVENT_ACTION,
    TOKENIZE_CREDIT_CARD_EVENT_ACTION
};