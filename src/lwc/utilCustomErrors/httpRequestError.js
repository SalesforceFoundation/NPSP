class HttpRequestError extends Error {
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