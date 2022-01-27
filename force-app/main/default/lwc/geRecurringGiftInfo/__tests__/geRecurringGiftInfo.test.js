import { createElement } from 'lwc';
import GeRecurringGiftInfo from 'c/GeRecurringGiftInfo';

describe('c-ge-modal-recurring-donation', () => {
    afterEach(() => {
        clearDOM();
    });

    const setup = (schedule) => {
        const infoCard = createElement('c-ge-modal-recurring-donation', {
            is: GeRecurringGiftInfo
        });
        infoCard.schedule = schedule;
        document.body.appendChild(infoCard);
        return infoCard;
    }

    describe('render behavior', () => {
        it('renders schedule data', async () => {

        });

        it('renders edit and remove recurrence buttons', async () => {

        });
    });

    describe('event behavior', () => {
        it('should dispatch event to parent when edit button is clicked', async () => {

        });

        it('should dispatch event to parent when remove recurrence button is clicked', async () => {

        });
    });
});