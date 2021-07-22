import psElevateTokenHandler from '../psElevateTokenHandler';

const createPostMessageEvent = (type) => {
   switch (type) {
      case 'valid' :
         return {
            origin : "https://flow-connect-2738-dev-ed--c.visualforce.com",
            data : {
               isLoaded:true
            }
         };
      case 'invalid' :
         return {
            origin : "https://test.com",
            data : {
               post_robot:"seuur93msdksy4mds"
            }
         };
      case 'token' :
         return {
            origin : "https://flow-connect-2738-dev-ed--c.visualforce.com",
            data : {
               token: "246656543seuur93msdksy4mds"
            }
         };
      case 'error' :
         return {
            origin : "https://flow-connect-2738-dev-ed--c.visualforce.com",
            data : {
               error: "Invalid Request"
            }
         };
      case 'invalidJSON' :
         return {
            origin : "https://flow-connect-2738-dev-ed--c.visualforce.com",
            data : undefined
         }
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

   it('should handle a token message', () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('token'));
      expect(isMessageHandled).toBe(true);

   });

   it('should discard an error message', () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('error'));
      expect(isMessageHandled).toBe(true);

   });

   it('should discard an invalid JSON data from right origin', () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('invalidJSON'));
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
