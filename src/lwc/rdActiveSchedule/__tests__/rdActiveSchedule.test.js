import { createElement } from 'lwc';
import rdActiveSchedule from 'c/rdActiveSchedule';
import { getRecord } from 'lightning/uiRecordApi';
import { registerSa11yMatcher } from '@sa11y/jest';

import getSchedules from '@salesforce/apex/RD2_VisualizeScheduleController.getSchedules';
jest.mock(
    '@salesforce/apex/RD2_VisualizeScheduleController.getSchedules',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import SystemModstamp from '@salesforce/schema/AcceptedEventRelation.SystemModstamp';

const getRecordAdapter = registerLdsTestWireAdapter(getRecord);

const mockGetRecord = require('./data/getRecord.json');
const mockGetSchedule = require('./data/getSchedule.json');
const mockGetSchedules = require('./data/getSchedules.json');

describe('c-rd-active-schedule', () => {
    let component;

    beforeAll(() => {
        registerSa11yMatcher();
    });

    beforeEach(() => {
        component = createElement('c-rd-active-schedule', {
            is: rdActiveSchedule,
        });
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
        expect(header.textContent).toBe('c.RD2_ScheduleLWCTitle');
    });

    /***
    * @description Verifies the schedules information are properly displayed
    *  when there is no error
    */
    describe('on data load with 1 schedule record', () => {
        beforeEach(() => {
            component.recordId = mockGetRecord.id;
            getSchedules.mockResolvedValue(mockGetSchedule);
            getRecordAdapter.emit(mockGetRecord);

            document.body.appendChild(component);
        });

        it('should dipslay 1 schedule record icons', async () => {
            return global.flushPromises().then(async () => {
                assertNoErrorText(component);
                assertScheduleRecordIcons(component, 1);
                
            });
        });

        it('should display every field specified in the predefined schedule table column', async () => {
            return global.flushPromises().then(async () => {
                assertNoErrorText(component);

                const displayedFields = getScheduleRecordDisplayFields(component);
                expect(displayedFields.length).toBe(8);
                assertAllFieldsAreDisplayed(displayedFields);
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });

    });

    describe('on data load with 2 scehdule records', () => {
        beforeEach(() => {
            component.recordId = mockGetRecord.id;
            getSchedules.mockResolvedValue(mockGetSchedules);
            getRecordAdapter.emit(mockGetRecord);

            document.body.appendChild(component);
        });

        it('should dipslay 2 schedule record icons', async () => {
            return global.flushPromises().then(async () => {
                assertNoErrorText(component);
                assertScheduleRecordIcons(component, 2);
                
            });
        });

        it('should display every field specified in the predefined schedule table column', async () => {
            return global.flushPromises().then(async () => {
                assertNoErrorText(component);

                const displayedFields = getScheduleRecordDisplayFields(component);
                expect(displayedFields.length).toBe(16);
                assertAllFieldsAreDisplayed(displayedFields);
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });
});

/**
* @description Verifies The schedule record icons are display on the component.
*/
const assertScheduleRecordIcons = (component, iconCount) => {
    const iconList = component.shadowRoot.querySelectorAll('[data-qa-locator="icon Record Icon"]');
    expect(iconList).not.toBeNull();
    expect(iconList.length).toBe(iconCount);
}

/***
* @description Verifies no error errors is displayed on the widget
*/
const assertNoErrorText = (component) => {
    const errors = getErrorText(component);
    expect(errors).toBeNull();
}

/***
* @description Finds and returns unexpected error message errors if it is displayed on the widget
*/
const getErrorText = (component) => {
    const errors = component.shadowRoot.querySelector('[data-qa-locator="text Error"]');

    return errors;
}

/**
* @description Verifies all schedule fields are displayed
*/
const assertAllFieldsAreDisplayed = (displayedFields) => {
    getExpectedFieldLabels().forEach(expectedField => {
        expect(displayedFields).toContain(expectedField);
    });
}

/**
* @description Get all the displayed field labels on the component
*/
const getScheduleRecordDisplayFields = (component) => {
    const displayedFields = [];
    component.shadowRoot.querySelectorAll('[data-qa-locator="text Field Label"]').forEach(field => {
        displayedFields.push(field.value);
    });

    return displayedFields;
}

/**
* @description Constrcut the expected field labels from mockGetSchedule json
*/
const getExpectedFieldLabels = () => {
    const expectedLabels = mockGetSchedule.dataTable.columns.map(column => {
       return column.label;
    }).filter (label => {
        return label !== undefined;
    });

    return expectedLabels;
}