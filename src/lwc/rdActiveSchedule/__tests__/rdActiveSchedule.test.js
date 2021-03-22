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
    describe('with 1 schedule record', () => {
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

    });

    describe('with 2 scehdule records', () => {
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
    });

   
});


const assertScheduleRecordIcons = (component, iconCount) => {
    const iconList = component.shadowRoot.querySelectorAll('[data-qa-locator="icon Record Icon"]');
    expect(iconList).not.toBeNull();
    expect(iconList.length).toBe(iconCount);
}

/***
* @description Verifies no error notification is displayed on the widget
*/
const assertNoErrorText = (component) => {
    const notification = getErrorText(component);
    expect(notification).toBeNull();
}

/***
* @description Finds and returns unexpected error message notification if it is displayed on the widget
*/
const getErrorText = (component) => {
    const notification = component.shadowRoot.querySelector('[data-qa-locator="text Error"]');

    return notification;
}