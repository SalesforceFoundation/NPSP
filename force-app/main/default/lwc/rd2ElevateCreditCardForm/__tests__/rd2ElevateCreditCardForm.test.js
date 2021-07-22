import { createElement } from 'lwc';
import rd2ElevateCreditCardForm from 'c/rd2ElevateCreditCardForm';
import { registerSa11yMatcher } from '@sa11y/jest';
import getOrgDomainInfo from '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo';

const PATH_GE_TOKENIZE_CARD = '/apex/GE_TokenizeCard';
const DISABLED_MESSAGE = 'c.RD2_ElevateDisabledMessage';
const ALERT_MESSAGE = 'Test alert message';

const createWidget = () => {
    let element = createElement(
        'c-rd2-elevate-credit-card-form',
        { is: rd2ElevateCreditCardForm }
    );
    return element;
}

jest.mock(
    '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const GET_ORG_DOMAIN_ERROR = {
    body: { message: ALERT_MESSAGE },
    ok: false,
    status: 400,
    statusText: 'Bad Request'
};

describe('c-rd2-elevate-credit-card-form', () => {

    beforeAll(() => {
        registerSa11yMatcher();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('should display error', async () => {
        getOrgDomainInfo.mockRejectedValue(GET_ORG_DOMAIN_ERROR);

        const element = createWidget();
        document.body.appendChild(element);

        return global.flushPromises()
            .then(() => {
                expect(alertMessage(element)).toBeTruthy();
                expect(alertMessage(element).message).toBe(ALERT_MESSAGE);
            });
    });

    it('should display isLoading spinner', async () => {
        getOrgDomainInfo.mockRejectedValue(GET_ORG_DOMAIN_ERROR);

        const element = createWidget();
        document.body.appendChild(element);

        return global.flushPromises()
            .then(() => {
                expect(isLoadingSpinner(element)).toBeTruthy();
            });
    });

    it('should allow disabling and enabling of widget', async () => {
        const element = createWidget();
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                expect(iframe(element)).toBeTruthy();
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
                doNotUseElevateButton(element).click();
            })
            .then(() => {
                expect(iframe(element)).toBeFalsy();
                expect(spanDisabledMessage(element).value).toBe(DISABLED_MESSAGE);

                useElevateButton(element).click();
            })
            .then (() => {
                expect(iframe(element)).toBeTruthy();
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
            });
    });

    it("should be accessible", async () => {
        const element = createWidget();
        document.body.appendChild(element);

        return global.flushPromises().then(async () => {
            await expect(element).toBeAccessible();
        });
    });
});

const useElevateButton = (element) => {
    return shadowQuerySelector(element, '[data-qa-locator="button Use Elevate Now"]');
}

const doNotUseElevateButton = (element) => {
    return shadowQuerySelector(element, '[data-qa-locator="button Do Not Use Elevate"]');
}

const iframe = (element) => {
    return shadowQuerySelector(element, '.payment-services-iframe');
}

const spanDisabledMessage = (element) => {
    return shadowQuerySelector(element, '[data-qa-locator="richtext Elevate Disabled Message"]');
}

const alertMessage = (element) => {
    return shadowQuerySelector(element, '[data-qa-locator="alert Message"]');
}

const isLoadingSpinner = (element) => {
    return shadowQuerySelector(element, 'lightning-spinner');
}

const getShadowRoot = (element) => {
    if (!element || !element.shadowRoot) {
        const tagName =
            element && element.tagName && element.tagName.toLowerCase();
        throw new Error(
            `Attempting to retrieve the shadow root of '${tagName || element}'
            but no shadowRoot property found`
        );
    }
    return element.shadowRoot;
}

const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}
