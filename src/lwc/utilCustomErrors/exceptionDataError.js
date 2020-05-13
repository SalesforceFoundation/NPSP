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
        if (apexException.body && apexException.body.exceptionType) {
            this.exceptionType = apexException.body.exceptionType;
            this.errorMessage = apexException.body.message;
            this.stackTrace = apexException.body.stackTrace;
            this.isUserDefinedException = apexException.body.isUserDefinedException;
            this.DMLErrorMessageMapping = {};
            this.DMLErrorFieldNameMapping = {};

        } else if (apexException.body && apexException.body.message) {
            // This looks like an instance of the apex wrapper class ERR_ExceptionData
            const apexExceptionWrapper = JSON.parse(apexException.body.message);
            this.exceptionType = apexExceptionWrapper.exceptionType;
            this.errorMessage = apexExceptionWrapper.errorMessage;
            this.DMLErrorMessageMapping = apexExceptionWrapper.DMLErrorMessageMapping;
            this.DMLErrorFieldNameMapping = apexExceptionWrapper.DMLErrorFieldNameMapping;

        } else {
            this.message = apexException;
        }
    }
}

export default ExceptionDataError;