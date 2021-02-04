global.flushPromises = () => new Promise(resolve => setImmediate(resolve));

global.clearDOM = () => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
};