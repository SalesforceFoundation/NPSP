class CardChargedBDIError extends Error {

    /*******************************************************************************
    * @description Custom error class for the error scenario in which a Payment
    * Services purchase transaction has succeeded, but BDI processing fails.
    *
    * @param {object} apexException: An exception of some kind received from apex
    */
    constructor(apexException) {
        super();
        this.apexException = apexException;
    }

    toJSON() {
        return {
            error: {
                name: this.name,
                message: this.message,
                stacktrace: this.stack,
                apexException: this.apexException
            }
        }
    }
}

export default CardChargedBDIError;