class HttpRequestError extends Error {

    /*******************************************************************************
    * @description Custom error class for http request errors.
    *
    * @param {string} message: Error message
    * @param {string} status: Http response status message
    * @param {string} statusCode: Http response status code (expected codes 400 - 599)
    */
    constructor(message, status, statusCode) {
        super(message);
        this.status = status;
        this.statusCode = statusCode;
    }

    toJSON() {
        return {
            error: {
                name: this.name,
                message: this.message,
                stacktrace: this.stack,
                status: this.status,
                statusCode: this.statusCode
            }
        }
    }
}

export default HttpRequestError;