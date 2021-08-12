
class SoftCredits {
    _unprocessedSoftCredits = [];
    _processedSoftCredits = [];

    constructor(softCredits) {
        this._indexSoftCredits(softCredits);
    }

    all() {
        return this._unprocessedSoftCredits;
    }

    processedSoftCredits() {
        return this._processedSoftCredits;
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

    addProcessedSoftCredits(processedSoftCredits) {
        this._processedSoftCredits = [ ...processedSoftCredits ];
    }

    clearProcessedSoftCredits() {
        this._processedSoftCredits = [];
    }

    hasProcessedSoftCredits() {
        return this._processedSoftCredits.length > 0;
    }

    remove(key) {
        this._unprocessedSoftCredits.splice(key, 1);
        this._reIndexSoftCredits(this._unprocessedSoftCredits);
    }

    update(softCreditWithChange) {
        if (!softCreditWithChange) return;

        this._unprocessedSoftCredits.forEach(function(softCredit, index, allSoftCredits) {
            if (softCredit.key === softCreditWithChange.key) {
                allSoftCredits[index] = softCreditWithChange;
            }
        });
    }

    _indexSoftCredits(softCredits) {
        if (!softCredits) return;

        softCredits.forEach(softCredit => {
            this._unprocessedSoftCredits.push({
                ...softCredit,
                key: this._unprocessedSoftCredits.length
            });
        });
    }

    _reIndexSoftCredits(softCredits) {
        if (!softCredits) return;

        this._unprocessedSoftCredits = [];
        this._indexSoftCredits(softCredits);
    }
}

export default SoftCredits;