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
* @group Elevate Payment Services
* @description Apex Unit Test for Product Metadata
*/
@IsTest(IsParallel=true)
private with sharing class PS_ProductMetadata_TEST {

    /**
    * @description Verifies that metadata properties are included in untyped map
    */
    @isTest
    private static void shouldCreateUntypedMap() {
        String campaignId = UTIL_UnitTestData_TEST.mockId(Campaign.SObjectType);
        String originType = PS_Request.OriginType.CRM.name();
        
        PS_ProductMetadata productMetadata = new PS_ProductMetadata()
            .withCampaign(campaignId)
            .withOrigin(originType);

        Map<String, Object> untypedMetadata = productMetadata.toUntypedMap();

        System.Assert(
            untypedMetadata.containsKey('origin'), 
            'Untyped product metadata should include the origin property'
        );

        System.Assert(
            untypedMetadata.containsKey('campaign'), 
            'Untyped product metadata should include the origin property'
        );

        System.AssertEquals(
            ((PS_ProductMetadata.Origin)untypedMetadata.get('origin')).type,
            originType, 
            'Untyped product metadata origin type should be '+originType
        );

        System.AssertEquals(
            ((PS_ProductMetadata.Campaign)untypedMetadata.get('campaign')).id,
            campaignId, 
            'Untyped product metadata campaign.id should be '+campaignId
        );
    }

    @IsTest
    static void productMetadataShouldPreserveOrigin() {
        String newCampaignId = UTIL_UnitTestData_TEST.mockId(Campaign.SObjectType);
        String serializedProductMetadata = '{"origin":{"type":"CRM"},"campaign":{"id":"701R00000027JNdIAM"}}';
        Map<String, Object> untypedMetadata = (Map<String, Object>) JSON.deserializeUntyped(serializedProductMetadata);

        PS_ProductMetadata productMetadata = new PS_ProductMetadata()
                .withCampaign(newCampaignId);
        Map<String, Object> updatedUntypedMetadata = productMetadata.mergeWithExistingMetadata(untypedMetadata);

        PS_ProductMetadata updatedMetadata = parseUntypedMetadata(updatedUntypedMetadata);
        System.assertEquals(newCampaignId, updatedMetadata.campaign.id);
        System.assertEquals('CRM', updatedMetadata.origin.type);
    }

    @IsTest
    static void productMetadataShouldPreserveAny() {
        String newCampaignId = UTIL_UnitTestData_TEST.mockId(Campaign.SObjectType);
        String serializedProductMetadata = '{"origin":{"type":"CRM"},"campaign":{"id":"701R00000027JNdIAM"},"consent":{"message":"Some message","optin":true}}';
        Map<String, Object> untypedMetadata = (Map<String, Object>) JSON.deserializeUntyped(serializedProductMetadata);

        PS_ProductMetadata productMetadata = new PS_ProductMetadata()
                .withCampaign(newCampaignId);
        Map<String, Object> updatedUntypedMetadata = productMetadata.mergeWithExistingMetadata(untypedMetadata);

        PS_ProductMetadata updatedMetadata = parseUntypedMetadata(updatedUntypedMetadata);
        System.assertEquals(newCampaignId, updatedMetadata.campaign.id);
        System.assertEquals('CRM', updatedMetadata.origin.type);

        Map<String, Object> consentData = (Map<String, Object>) updatedUntypedMetadata.get('consent');

        String consentMessage = (String) consentData.get('message');
        Boolean optin = (Boolean) consentData.get('optin');

        System.assertEquals('Some message', consentMessage);
        System.assertEquals(true, optin);
    }

    @IsTest
    static void productMetadataShouldMergeWhenExistingMetadataIsNull() {
        String newCampaignId = UTIL_UnitTestData_TEST.mockId(Campaign.SObjectType);
        PS_ProductMetadata productMetadata = new PS_ProductMetadata().withCampaign(newCampaignId);

        Test.startTest();
        Map<String, Object> updatedUntypedMetadata = productMetadata.mergeWithExistingMetadata(null);
        Test.stopTest();

        PS_ProductMetadata updatedMetadata = parseUntypedMetadata(updatedUntypedMetadata);

        System.assertEquals(newCampaignId, updatedMetadata.campaign.id);
    }

    /**
     * @param untypedProductMetadata Parse origin and campaign out of productMetadata Map<String, Object>
     *
     *  @return A ProductMetadata class with any origin/campaign data from what was passed in
     */
    static PS_ProductMetadata parseUntypedMetadata(Map<String, Object> untypedProductMetadata) {
        PS_ProductMetadata productMetadata = new PS_ProductMetadata();

        if (untypedProductMetadata.containsKey('origin')) {
            Object origin = untypedProductMetadata.get('origin');
            if (origin instanceof PS_ProductMetadata.Origin) {
                productMetadata.origin = (PS_ProductMetadata.Origin)origin;
            }
            Map<String, Object> untypedOrigin = (Map<String, Object>)origin;
            String originType = (String) untypedOrigin.get('type');
            productMetadata.origin = new PS_ProductMetadata.Origin(originType);
        }

        if (untypedProductMetadata.containsKey('campaign')) {
            Object campaign = untypedProductMetadata.get('campaign');
            if (campaign instanceof PS_ProductMetadata.Campaign) {
                productMetadata.campaign = (PS_ProductMetadata.Campaign)campaign;
            } else {
                Map<String, Object> untypedCampaign = (Map<String, Object>)campaign;
                String campaignId = (String) untypedCampaign.get('id');
                productMetadata.campaign = new PS_ProductMetadata.Campaign(campaignId);
            }
        }

        return productMetadata;
    }
}