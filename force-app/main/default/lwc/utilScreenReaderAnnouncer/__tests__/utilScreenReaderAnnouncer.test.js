import { createElement } from 'lwc';
import UtilScreenReaderAnnouncer from 'c/utilScreenReaderAnnouncer';

describe('c-util-screen-reader-announcer', () => {

    afterEach(clearDOM);

    it('should have live region with default priority set to polite', () => {
        const element = createElement('c-util-screen-reader-announcer', {
            is: UtilScreenReaderAnnouncer
        });
        document.body.appendChild(element);

        const announcer = element.shadowRoot.querySelector('div');
        expect(announcer.getAttribute('aria-live')).toBe('polite');
    });

    it('should have live region with priority explicitly set to assertive', () => {
        const element = createElement('c-util-screen-reader-announcer', {
            is: UtilScreenReaderAnnouncer
        });
        element.priority = 'assertive'
        document.body.appendChild(element);

        const announcer = element.shadowRoot.querySelector('div');
        expect(announcer.getAttribute('aria-live')).toBe('assertive');
    });

    it('should default to empty message', () => {
        const element = createElement('c-util-screen-reader-announcer', {
            is: UtilScreenReaderAnnouncer
        });
        document.body.appendChild(element);

        const announcer = element.shadowRoot.querySelector('div');
        expect(announcer.innerHTML).toBe('');
    });

    it('should have provided message', () => {
        const element = createElement('c-util-screen-reader-announcer', {
            is: UtilScreenReaderAnnouncer
        });
        document.body.appendChild(element);
        element.announce('dummy message');

        const announcer = element.shadowRoot.querySelector('div');
        expect(announcer.innerHTML).toBe('dummy message');
    });
});
