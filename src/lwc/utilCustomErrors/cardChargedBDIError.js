class CardChargedBDIError extends Error {
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