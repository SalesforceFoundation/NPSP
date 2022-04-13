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
* @description Supports Elevate product metadata, as referenced in several request types
*/
public inherited sharing class PS_ProductMetadata {
    public Origin origin;
    public Campaign campaign;

    /**
    * @description Sets origin info
    * @param type origin type
    * @return productMetadata This product metadata instance
    */
    public PS_ProductMetadata withOrigin(String type) {
        this.origin = new Origin(type);
        return this;
    }

    /**
    * @description Sets campaign info
    * @param campaignId campaign Id
    * @return productMetadata This product metadata instance
    */
    public PS_ProductMetadata withCampaign(Id campaignId) {
        if (campaignId != null) {
            this.campaign = new Campaign(campaignId);
        }

        return this;
    }

    private Boolean hasCampaign() {
        return this.campaign?.id != null;
    }

    private Boolean hasOrigin() {
        return this.origin?.type != null;
    }

    public Map<String, Object> mergeWithExistingMetadata(final Map<String, Object> existingMetadata) {
        Map<String, Object> updatedMetadata = this.toUntypedMap();
        Map<String, Object> mergedMetadata = new Map<String, Object>();

        if (existingMetadata != null) {
            mergedMetadata.putAll(existingMetadata);
        }

        mergedMetadata.putAll(updatedMetadata);

        return mergedMetadata;
    }

    public Map<String, Object> toUntypedMap() {
        Map<String, Object> productMetadataMap = new Map<String, Object>();

        if (hasOrigin()) {
            productMetadataMap.put('origin', this.origin);
        }

        if (hasCampaign()) {
            productMetadataMap.put('campaign', this.campaign);
        }

        return productMetadataMap;
    }

    /***
    * @description Origin property on the commitment product metadata request
    */
    public class Origin {
        public String type;

        public Origin(String type) {
            this.type = type;
        }
    }

    /***
    * @description Campaign property on the commitment product metadata request
    */
    public class Campaign {
        public String id;

        public Campaign(Id campaignId) {
            this.id = campaignId;
        }
    }    
}