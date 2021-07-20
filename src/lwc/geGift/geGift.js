class Gift {
    softCredits = {};
    fields = {};

    constructor(giftView) {
        this.softCredits = giftView.softCredits;
        this.fields = giftView.fields;
    }
}

export default Gift;