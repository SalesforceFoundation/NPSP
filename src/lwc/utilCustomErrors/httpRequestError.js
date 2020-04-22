class HttpRequestError extends Error {
    constructor(message, status, statusCode) {
        super(message);
        this.status = status;
        this.statusCode = statusCode;
        // workaround for handleCatchOnSave in geFormRenderer
        // delete when/if we refactor handleCatchOnSave
        this.body = {
            message: `{"errorMessage": "${message}"}`
        }
    }

    toJSON() {
        return {
            error: {
                name: this.name,
                message: this.message,
                stacktrace: this.stack,
                status: this.status,
                statusCode: this.statusCode,
                body: {
                    message: `{"errorMessage": "${this.message}"}`
                }
            }
        }
    }
}

export default HttpRequestError;