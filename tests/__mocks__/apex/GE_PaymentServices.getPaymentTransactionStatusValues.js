const paymentTransactionStatusValues = require('./data/paymentTransactionStatusValues.json');

const response = JSON.stringify(paymentTransactionStatusValues)

const mockedGetPaymentTransactionStatusValues = jest.fn().mockResolvedValue(response);

export default mockedGetPaymentTransactionStatusValues;