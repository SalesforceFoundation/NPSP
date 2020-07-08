import { isNotEmpty, validateJSONString } from 'c/utilCommon';
class ExceptionDataError extends Error {

    /*******************************************************************************
    * @description Custom error class to transform any kind of apex exception
    * into something that the `handleCatchOnSave` method in geFormRenderer can
    * consume.
    *
    * @param {object} apexException: An exception of some kind received from apex
    */
    constructor(apexException) {
        super();

        if (isNotEmpty(apexException.body)) {
            const apexExceptionWrapper = validateJSONString(apexException.body.message);

            this.stackTrace = apexException.body.stackTrace;
            this.exceptionType = apexExceptionWrapper.exceptionType;
            this.isUserDefinedException = apexException.body.isUserDefinedException;
            this.DMLErrorMessageMapping = apexExceptionWrapper.DMLErrorMessageMapping;
            this.DMLErrorFieldNameMapping = apexExceptionWrapper.DMLErrorFieldNameMapping;
            this.errorMessage = apexExceptionWrapper.errorMessage;
        } else {
            this.message = apexException;
        }
    }
}

export default ExceptionDataError;