import { createElement } from 'lwc';
import rd2ElevateInformation from 'c/rd2ElevateInformation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getNavigateCalledWith } from "lightning/navigation";
import { registerSa11yMatcher } from '@sa11y/jest';
import getRecurringData from '@salesforce/apex/RD2_EntryFormController.getRecurringData';
import getData from '@salesforce/apex/RD2_ElevateInformation_CTRL.getPermissionData';
import getError from '@salesforce/apex/RD2_ElevateInformation_CTRL.getLatestErrorMessage';

jest.mock(
    '@salesforce/apex/RD2_ElevateInformation_CTRL.getPermissionData',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/RD2_ElevateInformation_CTRL.getLatestErrorMessage',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_EntryFormController.getRecurringData',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

const mockGetObjectInfo = require('./data/getObjectInfo.json');
const mockGetRecord = require('./data/getRecord.json');
const mockGetAchRecord = require('./data/getAchRecord.json');
const mockGetData = require('./data/getData.json');

const ELEVATE_ID_FIELD_NAME = 'CommitmentId__c';
const CC_LAST_4_FIELD_NAME = 'CardLast4__c';
const ACH_LAST_4_FIELD_NAME = 'ACH_Last_4__c';
const EXPIRATION_YEAR_FIELD_NAME = 'CardExpirationYear__c';
const STATUS_REASON_FIELD_NAME = 'ClosedReason__c';
const ICON_NAME_ERROR = 'utility:error';
const ICON_NAME_SUCCESS = 'utility:success';



describe('c-rd2-elevate-information', () => {
    let component;

    beforeAll(() => {
        registerSa11yMatcher();
    });

    beforeEach(() => {
        component = createElement('c-rd2-elevate-information', {
            is: rd2ElevateInformation,
        });

        getObjectInfo.emit(mockGetObjectInfo);
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    /***
    * @description Verifies header is always displayed on the widget
    */
    it('should display header', () => {
        document.body.appendChild(component);

        const header = component.shadowRoot.querySelector('h2');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.RD2_ElevateInformationHeader');
    });


    /***
    * @description Verifies the widget when the Recurring Donation has no error
    * or there is no error after the latest successful payment
    */
    describe('on credit card payment data load when no errors', () => {
        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getError.mockResolvedValue(null);
            getRecurringData.mockResolvedValue({
                "DonorType": "Contact",
                "Period": "Monthly",
                "Frequency": 1,
                "RecurringType": "Open"
            });

            getRecord.emit(mockGetRecord);

            document.body.appendChild(component);
        });

        it('should display success icon and message', async () => {
            return global.flushPromises().then(async () => {
                assertStatusIconAndMessage(component, ICON_NAME_SUCCESS, 'c.RD2_ElevateInformationStatusSuccess');

                assertNoErrorNotification(component);
            });
        });

        it('should display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                assertElevateRecurringIdIsPopulated(component, mockGetRecord);
            });
        });

        it('should display Credit Card Last 4', async () => {
            return global.flushPromises().then(async () => {
                assertLastFourDigitsIsPopulated(component, mockGetRecord);
            });
        });

        it('should display Expiration Date', async () => {
            return global.flushPromises().then(async () => {
                assertExpirationDateIsPopulated(component, mockGetRecord);
            });
        });

        it('should display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });

        it('should not display any illustration', async () => {
            return global.flushPromises().then(async () => {
                assertNoIllustrationIsDisplayed(component);
            });
        });

        it('should populate donor type for edit payment information modal', async () => {
            await flushPromises();
            const updatePaymentButton = component.shadowRoot.querySelector('lightning-button[data-qa-locator="link Update Payment Information"]');
            expect(getData).toHaveBeenCalled();

            expect(updatePaymentButton).toBeTruthy();
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });

    describe('on ach payment data load when no errors', () => {
        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getError.mockResolvedValue(null);
            getRecurringData.mockResolvedValue({
                "DonorType": "Contact",
                "Period": "Monthly",
                "Frequency": 1,
                "RecurringType": "Open"
            });

            getRecord.emit(mockGetAchRecord);

            document.body.appendChild(component);
        });

        it('should display ACH Last 4', async () => {
            return global.flushPromises().then(async () => {
                assertLastFourACHIsPopulated(component, mockGetAchRecord);
            });
        });

        it('should not display Expiration Date', async () => {
            return global.flushPromises().then(async () => {
                const expDate = getExpirationDate(component);
                expect(expDate).toBeFalsy();
            });
        });
    });


    /***
    * @description Verifies the widget when the latest payment failed
    * and an error has been logged for the Recurring Donation.
    */
    describe('on data load when the latest payment failed', () => {
        const errorMessage = 'Card declined';

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getError.mockResolvedValue(errorMessage);
            getRecord.emit(mockGetRecord);

            document.body.appendChild(component);
        });

        it('should display error icon and message', async () => {
            return global.flushPromises().then(async () => {
                assertStatusIconAndMessage(component, ICON_NAME_ERROR, errorMessage);

                assertNoErrorNotification(component);
            });
        });

        it('should display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                assertElevateRecurringIdIsPopulated(component, mockGetRecord);
            });
        });

        it('should display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });

        it("should navigate to the record Error Log page", async () => {
            return global.flushPromises()
                .then(async () => {
                    const errorLogButton = getViewErrorLogButton(component);
                    expect(errorLogButton).not.toBeNull();

                    dispatchClickEvent(errorLogButton);
                })
                .then(async () => {
                    const { pageReference } = getNavigateCalledWith();

                    expect(pageReference.type).toBe("standard__component");
                    expect(pageReference.state.c__recordId).toBe(component.recordId);
                    expect(pageReference.attributes.componentName).toContain("ERR_RecordLog");
                });
        });

        it('should not display any illustration', async () => {
            return global.flushPromises().then(async () => {
                assertNoIllustrationIsDisplayed(component);
            });
        });
    });


    /***
    * @description Verifies the widget when the user closed Recurring Donation
    * and the cancel commitment process is in progress
    */
    describe('on data load when Elevate cancel is in progress', () => {
        let mockGetRecordCancelInProgress = JSON.parse(JSON.stringify(mockGetRecord));
        mockGetRecordCancelInProgress.fields[STATUS_REASON_FIELD_NAME].value = 'c.RD2_ElevatePendingStatus';

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getError.mockResolvedValue(null);
            getRecord.emit(mockGetRecordCancelInProgress);

            document.body.appendChild(component);
        });

        it('should display progress ring and pending Elevate cancel message', async () => {
            return global.flushPromises().then(async () => {
                const progressRing = component.shadowRoot.querySelector('[data-qa-locator="progress ring"]');
                expect(progressRing).not.toBeNull();
                expect(progressRing.localName).toBe('lightning-progress-ring');
                expect(progressRing.value).toBe('75');

                assertStatusMessage(component, 'c.RD2_ElevateCancelInProgress');

                assertNoErrorNotification(component);
            });
        });

        it('should display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                assertElevateRecurringIdIsPopulated(component, mockGetRecord);
            });
        });

        it('should display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });

        it('should not display any illustration', async () => {
            return global.flushPromises().then(async () => {
                assertNoIllustrationIsDisplayed(component);
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });


    /***
    * @description Verifies the widget when an Elevate commitment cannot be created
    * for the Recurring Donation and the record has a temp commitment Id.
    * An error is logged when the commitment create request failed.
    */
    describe('on data load when commitment failed to be created', () => {
        const errorMessage = 'Unauthorized endpoint';

        let mockGetRecordFailedCommitment = JSON.parse(JSON.stringify(mockGetRecord));
        mockGetRecordFailedCommitment.fields[ELEVATE_ID_FIELD_NAME].value = '_PENDING_123TempCommitmentId';

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getError.mockResolvedValue(errorMessage);
            getRecord.emit(mockGetRecordFailedCommitment);

            document.body.appendChild(component);
        });

        it('should display error status and error notification', async () => {
            return global.flushPromises().then(async () => {
                assertStatusIconAndMessage(component, ICON_NAME_ERROR, errorMessage);

                assertErrorNotification(component, 'c.geHeaderPageLevelError', 'c.RD2_ElevateRecordCreateFailed');
            });
        });

        it('should not display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                const elevateId = getElevateRecurringId(component);
                expect(elevateId).toBeNull();
            });
        });

        it('should display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });

        it('should not display any illustration', async () => {
            return global.flushPromises().then(async () => {
                assertNoIllustrationIsDisplayed(component);
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });


    /***
    * @description Verifies the widget when the user has not permission on required fields
    */
    describe('on data load when user has no permission', () => {
        const mockGetDataNoPermission = { "isElevateCustomer": true, "hasFieldPermissions": false };

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetDataNoPermission);
            getError.mockResolvedValue(null);
            getRecord.emit(mockGetRecord);

            document.body.appendChild(component);
        });

        it('should display error notification and no status icon', async () => {
            return global.flushPromises().then(async () => {
                const icon = getStatusIcon(component);
                expect(icon).toBeNull();

                assertErrorNotification(component, 'c.geErrorFLSHeader', 'c.RD2_EntryFormMissingPermissions');
            });
        });

        it('should not display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                const elevateId = getElevateRecurringId(component);
                expect(elevateId).toBeNull();
            });
        });

        it('should not display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                const errorLogButton = getViewErrorLogButton(component);
                expect(errorLogButton).toBeNull();
            });
        });

        it('should not display any illustration', async () => {
            return global.flushPromises().then(async () => {
                assertNoIllustrationIsDisplayed(component);
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });


    /***
    * @description Verifies "No Data" illustration is displayed when
    * Recurring Donation is not an Elevate commitment record
    */
    describe('on data load when Recurring Donation is not an Elevate commitment', () => {
        let mockGetRecordNoCommitment = JSON.parse(JSON.stringify(mockGetRecord));
        mockGetRecordNoCommitment.fields[ELEVATE_ID_FIELD_NAME].value = null;

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getError.mockResolvedValue(null);
            getRecord.emit(mockGetRecordNoCommitment);

            document.body.appendChild(component);
        });

        it('should not display any icon', async () => {
            return global.flushPromises().then(async () => {
                const icon = getStatusIcon(component);
                expect(icon).toBeNull();

                assertNoErrorNotification(component);
            });
        });

        it('should not display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                const elevateId = getElevateRecurringId(component);
                expect(elevateId).toBeNull();
            });
        });

        it('should not display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                const errorLogButton = getViewErrorLogButton(component);
                expect(errorLogButton).toBeNull();
            });
        });

        it('should display "No Data" illustration', async () => {
            return global.flushPromises().then(async () => {
                const illustration = getNoDataIllustration(component);
                expect(illustration).not.toBeNull();

                const messageDiv = component.shadowRoot.querySelector('div.slds-text-longform');
                expect(messageDiv).toBeDefined();
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });


    /***
    * @description Verifies "No Access" illustration is displayed when
    * the org is not connected to Elevate
    */
    describe('on data load when org is not connected to Elevate', () => {
        let mockGetDataNoElevate = JSON.parse(JSON.stringify(mockGetData));
        mockGetDataNoElevate.isElevateCustomer = false;

        let mockGetRecordNoCommitment = JSON.parse(JSON.stringify(mockGetRecord));
        mockGetRecordNoCommitment.fields[ELEVATE_ID_FIELD_NAME].value = null;

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetDataNoElevate);
            getError.mockResolvedValue(null);
            getRecord.emit(mockGetRecordNoCommitment);

            document.body.appendChild(component);
        });

        it('should not display any icon', async () => {
            return global.flushPromises().then(async () => {
                const icon = getStatusIcon(component);
                expect(icon).toBeNull();

                assertNoErrorNotification(component);
            });
        });

        it('should not display Elevate Recurring Id', async () => {
            return global.flushPromises().then(async () => {
                const elevateId = getElevateRecurringId(component);
                expect(elevateId).toBeNull();
            });
        });

        it('should not display View Error Log button', async () => {
            return global.flushPromises().then(async () => {
                const errorLogButton = getViewErrorLogButton(component);
                expect(errorLogButton).toBeNull();
            });
        });

        it('should display "No Access" illustration', async () => {
            return global.flushPromises().then(async () => {
                const illustration = getNoAccessIllustration(component);
                expect(illustration).not.toBeNull();

                const messageDiv = component.shadowRoot.querySelector('div.slds-text-longform');
                expect(messageDiv).toBeDefined();
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });

});



// Helpers
//////////////

/***
* @description Verifies the Last Four Digits value displayed on the widget
* and has the same value as the Recurring Donation record
*/
const assertLastFourDigitsIsPopulated = (component, mockRecord) => {
    const last4Digits = getLastFourDigits(component);
    expect(last4Digits).not.toBeNull();
    expect(last4Digits.value).toBe(mockRecord.fields[CC_LAST_4_FIELD_NAME].value);
}

const assertLastFourACHIsPopulated = (component, mockRecord) => {
    const last4Digits = getLastFourDigits(component);
    expect(last4Digits).not.toBeNull();
    expect(last4Digits.value).toBe(mockRecord.fields[ACH_LAST_4_FIELD_NAME].value);
}

/***
 * @description Finds and returns the Last 4 digits value as displayed in the widget
 */
const getLastFourDigits = (component) => {
    const last4Digits = component.shadowRoot.querySelector('[data-qa-locator="text Last Four Digits"]');

    return last4Digits;
}

/***
* @description Verifies the Expiration Date value displayed on the UI contains the year from the field
* on the Recurring Donation record
*/
const assertExpirationDateIsPopulated = (component, mockRecord) => {
    const expDate = getExpirationDate(component);
    const fieldValue = mockRecord.fields[EXPIRATION_YEAR_FIELD_NAME].value;
    expect(expDate).not.toBeNull();
    expect(fieldValue).not.toBeNull();
    expect(expDate.value).toContain(fieldValue)
}

/***
 * @description Finds and returns the expiration date from the widget UI
 */
const getExpirationDate = (component) => {
    const expDate = component.shadowRoot.querySelector('[data-qa-locator="text Expiration Date"]');

    return expDate;
}

/***
* @description Verifies the Elevate Recurring Id is displayed on the widget
* and has the same value as the Recurring Donation record
*/
const assertElevateRecurringIdIsPopulated = (component, mockRecord) => {
    const elevateId = getElevateRecurringId(component);
    expect(elevateId).not.toBeNull();
    expect(elevateId.value).toBe(mockRecord.fields[ELEVATE_ID_FIELD_NAME].value);
}

/***
* @description Finds and returns Elevate Recurring Id if it is displayed on the widget
*/
const getElevateRecurringId = (component) => {
    const elevateId = component.shadowRoot.querySelector('[data-qa-locator="text Elevate Recurring Id"]');

    return elevateId;
}

/***
* @description Verifies the status icon name and the message displayed on the widget
*/
const assertStatusIconAndMessage = (component, iconName, statusMessage) => {
    const icon = getStatusIcon(component);
    expect(icon).not.toBeNull();
    expect(icon.iconName).toBe(iconName);

    assertStatusMessage(component, statusMessage);
}

/***
* @description Finds and returns the status icon if it is displayed on the widget
*/
const getStatusIcon = (component) => {
    const icon = component.shadowRoot.querySelector('[data-qa-locator="icon Status"]');

    return icon;
}

/***
* @description Verifies the status message displayed on the widget
*/
const assertStatusMessage = (component, statusMessage) => {
    const message = component.shadowRoot.querySelector('[data-qa-locator="text Status Message"]');
    expect(message).not.toBeNull();
    expect(message.value).toBe(statusMessage);
}

/***
* @description Verifies the "View Error Log" button is displayed and has expected label
*/
const assertViewErrorLogIsDisplayed = (component) => {
    const errorLogButton = getViewErrorLogButton(component);
    expect(errorLogButton).not.toBeNull();
    expect(errorLogButton.label).toBe('c.commonViewErrorLog');
}

/***
* @description Finds and returns View Error Log button if it is displayed on the widget
*/
const getViewErrorLogButton = (component) => {
    const errorLogButton = component.shadowRoot.querySelector('lightning-button[data-qa-locator="link View Error Log"]');

    return errorLogButton;
}

/***
* @description Verifies no illustration is displayed
*/
const assertNoIllustrationIsDisplayed = (component) => {
    const noDataIllustration = getNoDataIllustration(component);
    expect(noDataIllustration).toBeNull();

    const noAccessIllustration = getNoAccessIllustration(component);
    expect(noAccessIllustration).toBeNull();
}

/***
* @description Finds and returns No Data illustration if it is displayed on the widget
*/
const getNoDataIllustration = (component) => {
    const illustration = component.shadowRoot.querySelector('[data-qa-locator="div illustration NoData"]');

    return illustration;
}

/***
* @description Finds and returns No Access illustration if it is displayed on the widget
*/
const getNoAccessIllustration = (component) => {
    const illustration = component.shadowRoot.querySelector('[data-qa-locator="illustration NoAccess"]');

    return illustration;
}


/***
* @description Verifies no error notification is displayed on the widget
*/
const assertNoErrorNotification = (component) => {
    const notification = getErrorNotification(component);
    expect(notification).toBeNull();
}

/***
* @description Verifies an error notification with expected title and subtitle is displayed on the widget
*/
const assertErrorNotification = (component, title, subtitle) => {
    const notification = getErrorNotification(component);
    expect(notification).not.toBeNull();
    expect(notification.iconName).toBe(ICON_NAME_ERROR);
    expect(notification.subtitle).toBe(subtitle);

    const notificationTitle = notification.shadowRoot.querySelector('h2');
    expect(notificationTitle.textContent).toBe(title);
}

/***
* @description Finds and returns unexpected error message notification if it is displayed on the widget
*/
const getErrorNotification = (component) => {
    const notification = component.shadowRoot.querySelector('[data-qa-locator="error Notification"]');

    return notification;
}

/***
* @description Dispatch event when user clicks on the element
*/
const dispatchClickEvent = (element) => {
    element.dispatchEvent(
        new CustomEvent('click')
    );
}