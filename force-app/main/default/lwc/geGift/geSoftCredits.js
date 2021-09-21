
class SoftCredits {
    _unprocessedSoftCredits = [];
    _processedSoftCredits = [];

    constructor(softCredits) {
        this._indexSoftCredits(this._parseIfString(softCredits));
    }

    forSave() {
        return this._unprocessedSoftCredits
            .filter(softCredit => {
                return softCredit.Role != '' && softCredit.ContactId != ''
            });
    }

    unprocessedSoftCredits() {
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
        this._processedSoftCredits = this._parseIfString(processedSoftCredits);
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
            if (softCredit.Id) {
                this._processedSoftCredits.push({
                    ...softCredit
                });
            } else {
                this._unprocessedSoftCredits.push({
                    ...softCredit,
                    key: this._unprocessedSoftCredits.length
                });
            }
        });
    }

    _reIndexSoftCredits(softCredits) {
        if (!softCredits) return;

        this._unprocessedSoftCredits = [];
        this._indexSoftCredits(softCredits);
    }

    _parseIfString(object) {
        if (typeof object === 'string') {
            return JSON.parse(object);
        }
        return object;
    }
}

export default SoftCredits;