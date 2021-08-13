import Settings from 'c/geSettings';
import isElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';

describe('geSettings', () => {

    it('should return undefined for isElevateCustomer', async () => {
        isElevateCustomer.mockResolvedValue();
        await Settings.init();

        expect(Settings.isElevateCustomer()).toBe(undefined);
    });

    it('should return true for isElevateCustomer', async () => {
        isElevateCustomer.mockResolvedValue(true);
        await Settings.init();

        expect(Settings.isElevateCustomer()).toBe(true);
    });

    it('should return false for isElevateCustomer', async () => {
        isElevateCustomer.mockResolvedValue(false);
        await Settings.init();

        expect(Settings.isElevateCustomer()).toBe(false);
    });
});