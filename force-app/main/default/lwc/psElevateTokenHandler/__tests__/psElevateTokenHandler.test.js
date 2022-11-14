import psElevateTokenHandler from '../psElevateTokenHandler';
import getOriginUrls from '@salesforce/apex/GE_PaymentServices.getOriginUrls';

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
      case 'stringifiedJSON' :
         return {
            origin : "https://flow-connect-2738-dev-ed--c.visualforce.com",
            data : "{action: mount, error: false}"
         }
      default:
   }
}
jest.mock(
    '@salesforce/apex/GE_PaymentServices.getOriginUrls',
    () => {
       return {
          default: jest.fn()
       };
    },
    { virtual: true }
);


const buildVFUrls = async(domainInfo, namespace) => {
   return await psElevateTokenHandler.getVisualForceOriginURLs(domainInfo, namespace);

}

const mockDomainInfo = () => {
   return {
      orgDomain: 'flow-connect-2738-dev-ed',
      podName: 'CS43'
   }
}

const mockDomainInfoExperienceSite = () => {
   return {
      communityBaseURL: "https://flow-innovation-4700-dev-ed.my.site.com",
      orgDomain: 'flow-connect-2738-dev-ed',
      podName: 'CS43'
   }
}

describe('c-ps-Elevate-Token-Handler', () => {

   afterEach(() => {
      clearDOM();
   });

   it('should discard an invalid message', async() => {
      getOriginUrls.mockResolvedValue({
         visualForceOriginUrl: 'https://flow-connect-2738-dev-ed--c.vf.force.com',
         lightningOriginUrl: 'https://flow-connect-2738-dev-ed--c.lightning.force.com'
      });
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      await flushPromises();
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('invalid'));
      expect(isMessageHandled).toBe(false);
   });

   it('should discard an invalid JSON data from right origin', async () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      await flushPromises();
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('invalidJSON'));
      expect(isMessageHandled).toBe(false);
   });

   it('should discard an invalid form JSON', async () => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfo());
      await flushPromises();
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('stringifiedJSON'));
      expect(isMessageHandled).toBe(false);
   });

   it('should create one non-namespaced visualforce origin urls', async () => {
      const vfURLS = buildVFUrls(mockDomainInfo(), 'c');
      return vfURLS.then(data => {
         expect(data.length).toEqual(2);
      });
   });

   it('should create one namespaced visualforce origin urls', () => {
      const vfURLS = buildVFUrls(mockDomainInfo(), 'npsp');
      return vfURLS.then(data => {
         expect(data.length).toEqual(2);
      });
   });

   it('should discard an invalid message on Experience Sites', async() => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfoExperienceSite());
      await flushPromises();
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('invalid'));
      expect(isMessageHandled).toBe(false);
   });

   it('should discard an invalid JSON data from right origin on Experience Sites', async() => {
      psElevateTokenHandler.setVisualforceOriginURLs(mockDomainInfoExperienceSite());
      await flushPromises();
      const isMessageHandled =
          psElevateTokenHandler.shouldHandleMessage(
              createPostMessageEvent('invalidJSON'));
      expect(isMessageHandled).toBe(false);
   });

   it('should create two non-namespaced visualforce origin urls on Experience Sites', () => {
      const vfURLS = buildVFUrls(mockDomainInfoExperienceSite(), 'c');
      return vfURLS.then(data => {
         expect(data.length).toEqual(3);
         expect(data[1].value.includes('c')).toBe(true);
      });
   });

});
