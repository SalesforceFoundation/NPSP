class AuthorizedGift {

    constructor(authorizationToken, authorizationExpiresBy, transactionId) {
        this.authorizationToken = authorizationToken;
        this.authorizationExpiresBy = authorizationExpiresBy;
        this.transactionId = transactionId;
    }

}

export default AuthorizedGift;