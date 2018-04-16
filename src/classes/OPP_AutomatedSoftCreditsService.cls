/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Opportunity
* @description Handles Automated Soft Credits for Individual and Organizational gifts.
*/

public class OPP_AutomatedSoftCreditsService {

    private static final String RELATED_OPPORTUNITY_CONTACT_ROLE_NONE = '--None--';


    /*********************************************************************************************************
    * @description Determines if the Account is an Organization based on its account classification, 
    *               e.g., Individual.
    * @param accountClassification The classification of an Opportunity's associated Account.
    * @return Boolean
    **********************************************************************************************************/
    public static Boolean isOrganizationalAccount(Boolean accountClassification) {
        return (accountClassification == false);
    }


    /*********************************************************************************************************
    * @description Calls the methods that handle creating Opportunity Contact Roles for Relationship records.
    * @param primaryContactIdToOpportunityId Map of Primary Contact to List of Opportunities.
    * @return List<OpportunityContactRole> The newly created Opportunity Contact Role records.
    **********************************************************************************************************/
    public static List<OpportunityContactRole>  createRelationshipOCRs(Map<Id, List<Id>> primaryContactIdToOpportunityIds) {
        // Retrieve Relationships for Primary Contact
        Map<Id, List<npe4__Relationship__c>> primaryContactToRelatedContacts = retrieveRelationships(primaryContactIdToOpportunityIds.keySet());

        // Create Opportunity Contact Roles (OCR) records for the Related Contacts
        List<OpportunityContactRole> relationshipOCRs = buildRelationshipOCRs(primaryContactIdToOpportunityIds, primaryContactToRelatedContacts);

        return relationshipOCRs;
    }


    /*********************************************************************************************************
    * @description Retrieves the Relationship records for the Opportunity's associated Primary Contact.
    * @param primaryContactIds The Opportunities' Primary Contacts.
    * @return Map<Id, List<npe4__Relationship__c>> Map of the Primary Contact to its Relationship records.
    **********************************************************************************************************/
    public static Map<Id, List<npe4__Relationship__c>> retrieveRelationships(Set<Id> primaryContactIds) {
        Map<Id, List<npe4__Relationship__c>> primaryContactToRelationships = new Map<Id, List<npe4__Relationship__c>>();

        if (primaryContactIds.isEmpty()) {
            return primaryContactToRelationships;
        }

        List<npe4__Relationship__c> allRelationships
            = new List<npe4__Relationship__c>([SELECT Id, Name, npe4__Contact__c, npe4__RelatedContact__c, Related_Opportunity_Contact_Role__c
                                                FROM npe4__Relationship__c
                                                WHERE npe4__Contact__c IN :primaryContactIds]);

        // Process the records that have a value in the Related_Opportunity_Contact_Role__c field
        for (npe4__Relationship__c eachRelationship : allRelationships) {
            if (eachRelationship.Related_Opportunity_Contact_Role__c != null
                && !eachRelationship.Related_Opportunity_Contact_Role__c.containsIgnoreCase(RELATED_OPPORTUNITY_CONTACT_ROLE_NONE)) {
                if (primaryContactToRelationships.containsKey(eachRelationship.npe4__Contact__c)) {
                    List<npe4__Relationship__c> relationships = primaryContactToRelationships.get(eachRelationship.npe4__Contact__c);
                    relationships.add(eachRelationship);
                } else {
                    primaryContactToRelationships.put(eachRelationship.npe4__Contact__c, new List<npe4__Relationship__c>{ eachRelationship });
                }
            }
        }

        return primaryContactToRelationships;
    }


    /*********************************************************************************************************
    * @description Builds Opportunity Contact Role records for the Primary Contact's Relationships.
    * @param primaryContactIdToOpportunity Map of Primary Contact to List of Opportunities.
    * @param primaryContactToRelatedContacts Map of Primary Contact to Relationship records.
    * @return List<OpportunityContactRole> List of the Opportunity Contact Role records for Related Contacts.
    **********************************************************************************************************/
    public static List<OpportunityContactRole> buildRelationshipOCRs(Map<Id, List<Id>> primaryContactIdToOpportunityIds,
                                                                     Map<Id, List<npe4__Relationship__c>> primaryContactToRelatedContacts) {
        List<OpportunityContactRole> relationshipOCRs = new List<OpportunityContactRole>();

        if (primaryContactIdToOpportunityIds.isEmpty()) {
            return relationshipOCRs;
        }

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = retrieveOpportunityContactRoles(primaryContactIdToOpportunityIds.values());

        for (Id primaryContactKey : primaryContactToRelatedContacts.keySet()) {
            List<Id> opportunityIds = primaryContactIdToOpportunityIds.get(primaryContactKey);
            for (npe4__Relationship__c eachRelationship : primaryContactToRelatedContacts.get(primaryContactKey)) {
                for (Id eachOpportunityId : opportunityIds) {
                    if (!isDuplicateOCR(opportunityIdToOCR.get(eachOpportunityId),
                                        eachRelationship.npe4__RelatedContact__c, eachRelationship.Related_Opportunity_Contact_Role__c)) {
                        OpportunityContactRole ocr = new OpportunityContactRole();
                        ocr.OpportunityId = eachOpportunityId;
                        ocr.ContactId = eachRelationship.npe4__RelatedContact__c;
                        ocr.Role = eachRelationship.Related_Opportunity_Contact_Role__c;

                        relationshipOCRs.add(ocr);
                    }
                }
            }
        }

        return relationshipOCRs;
    }


    /*********************************************************************************************************
    * @description Retrieves the Opportunity Contact Role records related to the Opportunities.
    * @param opportunityIds List of Lists of Opportunity Ids.
    * @return Map<Id, List<OpportunityContactRole>> Map of the Opportunity to Opportunity Contact Roles.
    **********************************************************************************************************/
    public static Map<Id, List<OpportunityContactRole>> retrieveOpportunityContactRoles(List<List<Id>> opportunityIds) {
        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = new Map<Id, List<OpportunityContactRole>>();
        List<Id> allOpportunityIds = new List<Id>();

        if (opportunityIds.isEmpty()) {
            return opportunityIdToOCR;
        }

        for (List<Id> eachOpptyIds : opportunityIds) {
            allOpportunityIds.addAll(eachOpptyIds);
        }

        List<OpportunityContactRole> allOCRs = [SELECT OpportunityId, ContactId, Role
                                                FROM OpportunityContactRole
                                                WHERE OpportunityId IN :allOpportunityIds];

        for (OpportunityContactRole eachOCR : allOCRs) {
            if (opportunityIdToOCR.containsKey(eachOCR.OpportunityId)) {
                List<OpportunityContactRole> ocrs = opportunityIdToOCR.get(eachOCR.OpportunityId);
                ocrs.add(eachOCR);
            } else {
                opportunityIdToOCR.put(eachOCR.OpportunityId, new List<OpportunityContactRole>{ eachOCR });
            }
        }

        return opportunityIdToOCR;
    }


    /*********************************************************************************************************
    * @description Determines if a record is a duplicate Opportunity Contact Role for a specific Opportunity
    *               based on the Contact and Role values.
    * @param currentOCRs The Opportunity Contact Role records for an Opportunity.
    * @param relatedContact The related Contact's Id being evaluated in the duplicate check.
    * @param role The role value that's being evaluated in the duplicate check.
    * @return Boolean The result of determining if the currentRelationship record is a duplicate.
    **********************************************************************************************************/
    public static Boolean isDuplicateOCR(List<OpportunityContactRole> currentOCRs, Id relatedContact, String role) {
        Boolean isDuplicateRelationship = false;

        if (currentOCRs.isEmpty()) {
            return isDuplicateRelationship;
        }

        for (OpportunityContactRole eachOCR : currentOCRs) {
            if (eachOCR.ContactId ==  relatedContact
                && eachOCR.Role == role) {
                isDuplicateRelationship = true;
                break;
            }
        }

        return isDuplicateRelationship;
    }


}