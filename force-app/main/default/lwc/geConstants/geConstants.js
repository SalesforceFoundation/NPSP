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
const GIFT_STATUSES = {
    READY_TO_PROCESS: 'Ready to Process',
    IMPORTED: 'Imported',
    DRY_RUN_VALIDATED: 'Dry Run - Validated',
    DRY_RUN_ERROR: 'Dry Run - Error',
    FAILED: 'Failed',
    PROCESSING: 'Processing'
};
const PAYMENT_STATUSES = {
    AUTHORIZED: 'AUTHORIZED',
    PENDING: 'PENDING',
    UNKNOWN_ERROR: 'UNKNOWN ERROR'
};

const TOKENIZE_CREDIT_CARD_EVENT_ACTION = 'createToken';
const TOKENIZE_ACH_EVENT_ACTION = 'createAchToken';

const PAYMENT_METHODS = Object.freeze({
    ACH: 'ACH',
    CREDIT_CARD: 'CARD'
});

const CLICKED_UP = 'clicked-up';
const CLICKED_DOWN = 'clicked-down';
const DOWN = 'down';
const UP = 'up';

export {
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    LABEL_NEW_LINE,
    HTTP_CODES,
    ACCOUNT_HOLDER_TYPES,
    ACCOUNT_HOLDER_BANK_TYPES,
    PAYMENT_METHODS,
    PAYMENT_UNKNOWN_ERROR_STATUS,
    GIFT_STATUSES,
    PAYMENT_STATUSES,
    FAILED,
    ACH_CODE,
    PAYMENT_METHOD_CREDIT_CARD,
    PAYMENT_METHOD_ACH,
    TOKENIZE_ACH_EVENT_ACTION,
    TOKENIZE_CREDIT_CARD_EVENT_ACTION,
    CLICKED_UP,
    CLICKED_DOWN,
    DOWN,
    UP
};