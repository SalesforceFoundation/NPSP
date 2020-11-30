import psElevateTokenHandler from 'c/psElevateTokenHandler';

const createPostMessageEvent = (type) => {
   switch (type) {
      case 'valid' :
         return {
            origin :'https://flow-connect-2738-dev-ed--c.visualforce.com'
         };
      case 'invalid' :
         return {
            origin : undefined
         };
      default:
   }
}

const buildVFUrls  = (domainInfo, namespace) => {
   return psElevateTokenHandler.getVisualForceOriginURLs(domainInfo, namespace);
}

const mockDomainInfo = () => {
   return {
      orgDomain: 'flow-connect-2738-dev-ed',
      podName: 'CS43'
   }
}

describe('c-ps-Elevate-Token-Handler', () => {

   afterEach(() => {
      clearDOM();
   });

   it('should handle a valid message', () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('valid'));
      expect(isMessageHandled).toBe(true);
   });

   it('should discard an invalid message', () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('invalid'));
      expect(isMessageHandled).toBe(false);

   });

   it('should create four non-namespaced visualforce origin urls', () => {
      const vfURLS = buildVFUrls(mockDomainInfo(), 'c');
      expect(vfURLS.length).toEqual(4);
      vfURLS.forEach(url => {
         expect(url.value.includes('c')).toBe(true);
      })
   });

   it('should create four namespaced visualforce origin urls', () => {
      const vfURLS = buildVFUrls(mockDomainInfo(), 'npsp');
      expect(vfURLS.length).toEqual(4);
      vfURLS.forEach(url => {
         expect(url.value.includes('npsp')).toBe(true);
      })
   });

});
