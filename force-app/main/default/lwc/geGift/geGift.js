class Gift {
    _softCredits = {};
    _fields = {};

    constructor(giftView) {
        if (giftView) {
            this._fields = giftView.fields;
            this._softCredits = giftView.softCredits;
        }
    }

    id() {
        return this._fields.Id;
    }

    updateFieldsWith(changes) {
        this._fields = {
            ...this._fields,
            ...changes
        };
    }

    state() {
        return {
            fields: { ...this._fields },
            softCredits: { ...this._softCredits }
        }
    }
}

export default Gift;