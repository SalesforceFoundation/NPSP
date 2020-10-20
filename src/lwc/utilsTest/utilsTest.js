// ================================================================================
// COMMON TEST UTILITY METHODS
// ================================================================================
/**
 * Returns the shadowRoot property of a given Lightning web component.
 * Originally sourced from lightning-global repo.
 *
 * @param {LWCElement} element The Lightning web component element to retrieve
 * the shadowRoot property off of
 * @returns {ShadowRoot} The shadow root of the given element
 */
export const getShadowRoot = (element) => {
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

/**
 * Non-recursively queries the template of the provided element using the
 * provided selector.
 *
 * @param {LWCElement} element The Lightning web component element for which we 
 * want to query the template.
 * @param {String} selector The selector used to match the descendant element.
 * @returns {Element}
 */
export const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}