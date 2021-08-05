
class SoftCredits {
    _all = [];

    constructor(softCredits) {
        this._indexSoftCredits(softCredits);
    }

    all() {
        return this._all;
    }

    addNew() {
        this._indexSoftCredits([{ Role: '', ContactId: '' }]);
    }

    add(softCredit) {
        this._indexSoftCredits([softCredit]);
    }

    addAll(softCredits) {
        this._indexSoftCredits(softCredits);
    }

    remove(key) {
        this._all.splice(key, 1);
        this._reIndexSoftCredits(this._all);
    }

    update(softCreditWithChange) {
        if (!softCreditWithChange) return;

        this._all.forEach(function(softCredit, index, allSoftCredits) {
            if (softCredit.key === softCreditWithChange.key) {
                allSoftCredits[index] = softCreditWithChange;
            }
        });
    }

    _indexSoftCredits(softCredits) {
        if (!softCredits) return;

        softCredits.forEach(softCredit => {
            this._all.push({
                ...softCredit,
                key: this._all.length
            });
        });
    }

    _reIndexSoftCredits(softCredits) {
        if (!softCredits) return;

        this._all = [];
        this._indexSoftCredits(softCredits);
    }
}

export default SoftCredits;