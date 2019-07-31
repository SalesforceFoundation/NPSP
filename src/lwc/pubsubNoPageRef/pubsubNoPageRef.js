/**
 * A basic pub-sub mechanism for sibling component communication
 *
 * TODO - adopt standard flexipage sibling communication mechanism when it's available.
 */

const events = {};

/**
 * Registers a callback for an event
 * @param {string} eventName - Name of the event to listen for.
 * @param {function} callback - Function to invoke when said event is fired.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
const registerListener = (eventName, callback, thisArg) => {

    if (!events[eventName]) {
        events[eventName] = [];
    }

    const duplicate = events[eventName].find(listener => {
        return listener.callback === callback && listener.thisArg === thisArg;
    });

    if (!duplicate) {
        events[eventName].push({ callback, thisArg });
    }
};

/**
 * Unregisters a callback for an event
 * @param {string} eventName - Name of the event to unregister from.
 * @param {function} callback - Function to unregister.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
const unregisterListener = (eventName, callback, thisArg) => {
    if (events[eventName]) {
        events[eventName] = events[eventName].filter(
            listener =>
                listener.callback !== callback || listener.thisArg !== thisArg
        );
    }
};

/**
 * Unregisters all event listeners bound to an object.
 * @param {object} thisArg - All the callbacks bound to this object will be removed.
 */
const unregisterAllListeners = thisArg => {
    Object.keys(events).forEach(eventName => {
        events[eventName] = events[eventName].filter(
            listener => listener.thisArg !== thisArg
        );
    });
};

/**
 * Fires an event to listeners.
 * @param {object} pageRef - Reference of the page that represents the event scope.
 * @param {string} eventName - Name of the event to fire.
 * @param {*} payload - Payload of the event to fire.
 */
const fireEvent = (pageRef, eventName, payload) => {
    if (events[eventName]) {
        const listeners = events[eventName];
        listeners.forEach(listener => {
            try {
                listener.callback.call(listener.thisArg, payload);
            } catch (error) {
                // fail silently
            }
        });
    }
};

export {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
};