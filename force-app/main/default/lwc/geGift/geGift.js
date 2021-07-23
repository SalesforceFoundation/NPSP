class Gift {
    softCredits = {};
    fields = {};

    constructor(giftView) {
        this.softCredits = giftView.softCredits;
        this.fields = giftView.fields;
    }

    view() {
        return {
            ...this.fields
        }
    }
}

export default Gift;