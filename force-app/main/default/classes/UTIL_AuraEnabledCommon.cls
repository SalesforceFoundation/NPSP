/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
      
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2020
* @group Utilities
* @description Common AuraEnabled methods applicable to multiple domains
*/
public without sharing class UTIL_AuraEnabledCommon {
    
    /***
    * @description Returns org domain details
    * @return OrgDomainInfo
    */
    @AuraEnabled(cacheable=true)
    public static OrgDomainInfo getOrgDomainInfo() {
        OrgDomainInfo domainInfo;
        try {
            String url = System.Url.getOrgDomainUrl().getHost();
            String[] urlParts = url.split('\\.');

            String podName = [SELECT InstanceName FROM Organization].InstanceName.toLowerCase();

            domainInfo = new OrgDomainInfo(urlParts[0], podName);
            domainInfo.communityBaseURL = Site.getBaseUrl();
        } catch (Exception ex) {
            throwAuraHandledException(ex.getMessage());
        }

        return domainInfo;
    }

    /***
    * @description Throws AuraHandledException
    * The wrapping of the error message again is required
    * so the specific message is displayed instead of generic "Script thrown exception".
    * @param errMessage Exception message that needs to be set again
    * @return void
    */
    public static void throwAuraHandledException(String errMessage) {
        throw buildAuraException(errMessage);
    }

    /***
    * @description Creates an AuraHandledException with the specified error message
    * @param errMessage contents of the exception error message
    * @return AuraHandledException
    */
    public static AuraHandledException buildAuraException(String errMessage) {
        AuraHandledException ex = new AuraHandledException(errMessage);
        ex.setMessage(errMessage);
        return ex;
    }


    /***
    * @description Contains org domain and pod name
    */
    public class OrgDomainInfo {
        @AuraEnabled public String orgDomain;
        @AuraEnabled public String podName;
        @AuraEnabled public String communityBaseURL;

        public OrgDomainInfo (String orgDomain, String podName) {
            this.orgDomain = orgDomain;
            this.podName = podName;
        }
    }
}