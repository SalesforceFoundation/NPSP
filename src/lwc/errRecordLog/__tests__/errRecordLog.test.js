import { createElement } from 'lwc';
import errRecordLog from 'c/errRecordLog';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { registerSa11yMatcher } from '@sa11y/jest';

import getData from '@salesforce/apex/ERR_Log_CTRL.getData';
jest.mock(
    '@salesforce/apex/ERR_Log_CTRL.getData',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);

const mockGetObjectInfo = require('./data/getObjectInfo.json');
const mockGetData = require('./data/getData.json');



describe('c-err-record-log', () => {
    let component;

    beforeAll(() => {
        registerSa11yMatcher();
    });

    beforeEach(() => {
        component = createElement('c-err-record-log', {
            is: errRecordLog,
        });

        getObjectInfoAdapter.emit(mockGetObjectInfo);
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    /***
    * @description Verifies header is always displayed on the page
    */
    it('should display header', () => {
        document.body.appendChild(component);

        const header = component.shadowRoot.querySelector('h1');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.ERR_RecordLogTitle');
    });


});



// Helpers
//////////////