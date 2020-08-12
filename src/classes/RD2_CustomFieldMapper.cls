/*
    Copyright (c) 2020 Salesforce.org
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
* @group Recurring Donations
* @description Applies actions based on the custom field mapping from Recurring Donation to related Opportunities
*
*/
public inherited sharing class RD2_CustomFieldMapper {

    /***
    * @description Contains the current custom field mappings used to copy specified fields
    * on Recurring Donation to mapped fields onto related Opportunity records
    */
    private Map<String, npe03__Custom_Field_Mapping__c> settings {
        get {
            if (settings == null) {
                settings = UTIL_ListCustomSettingsFacade.getMapCustomFieldMappings();
            }
            return settings;
        } 
        set;
    }

    /***
    * @description Contains mapped field names on the Recurring Donation SObject
    */
    @TestVisible
    private Set<String> rdFieldNames {
        get {
            if (rdFieldNames == null) {
                extractFieldNames();
            }
            return rdFieldNames;
        }
        set;
    }

    /***
    * @description Contains mapped field names on the Opportunity SObject
    */
    @TestVisible
    private Set<String> oppFieldNames {
        get {
            if (oppFieldNames == null) {
                extractFieldNames();
            }
            return oppFieldNames;
        }
        set;
    }

    /**
     * @description Extracts field names on Recurring Donation SObject and
     * mapped field names on Opportunity SObject and store them in their respective variables
     * @return void
     */
    private void extractFieldNames() {
        rdFieldNames = new Set<String>();
        oppFieldNames = new Set<String>();

        for (npe03__Custom_Field_Mapping__c mapping : settings.values()) {
            rdFieldNames.add(mapping.npe03__Recurring_Donation_Field__c);
            oppFieldNames.add(mapping.npe03__Opportunity_Field__c);
        }
    }

    /**
     * @description Returns mapped field names on Recurring Donation SObject
     * @return Set<String>
     */
    public Set<String> getRdFieldNames() {
        return rdFieldNames;
    }

    /**
     * @description Returns mapped field names on Opportunity SObject
     * @return Set<String>
     */
    public Set<String> getOpportunityFieldNames() {
        return oppFieldNames;
    }

    /**
     * @description Returns true if any of the key fields on Recurring Donation 
     * used to create or manage installment Opportunities have been changed.
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public Boolean hasKeyFieldChanged(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        for (npe03__Custom_Field_Mapping__c mapping : settings.values()) {
            String fieldName = mapping.npe03__Recurring_Donation_Field__c;
            if (rd.get(fieldName) != oldRd.get(fieldName)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Copies values from Recurring Donation fields 
     * into mapped fields on the related Opportunity to be created
     * @param opp Opportunity on the Recurring Donation
     * @param rd Recurring Donation
     * @return void
     */
    public void populateOpportunityFields(Opportunity opp, npe03__Recurring_Donation__c rd) {
        for (npe03__Custom_Field_Mapping__c mapping : settings.values()) {
            opp.put(mapping.npe03__Opportunity_Field__c, rd.get(mapping.npe03__Recurring_Donation_Field__c));
        }
    }

    /**
     * @description Copies values from Recurring Donation fields 
     * into mapped fields on the related Opportunity to be updated
     * @param opp Opportunity on the Recurring Donation
     * @param rd Recurring Donation
     * @return Boolean Indicates if any mapped field on Opportunity has been changed
     */
    public Boolean syncOpportunityFields(Opportunity opp, npe03__Recurring_Donation__c rd) {
        Boolean isChanged = false;

        for (npe03__Custom_Field_Mapping__c mapping : settings.values()) {
            String rdFieldName = mapping.npe03__Recurring_Donation_Field__c;
            String oppFieldName = mapping.npe03__Opportunity_Field__c;

            if (opp.get(oppFieldName) != rd.get(rdFieldName)) {
                opp.put(oppFieldName, rd.get(rdFieldName));
                isChanged = true;
            }
        }

        return isChanged;
    }

}
