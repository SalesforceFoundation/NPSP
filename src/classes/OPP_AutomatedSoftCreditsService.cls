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
    private static final sObjectField FIELD_NAME_RELATIONSHIP_RELATED_CONTACT = npe4__Relationship__c.npe4__RelatedContact__c;
    private static final sObjectField FIELD_NAME_AFFILIATION_CONTACT = npe5__Affiliation__c.npe5__Contact__c;


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
    * @param primaryContactIdToOpportunityIds Map of Primary Contact to List of Opportunities.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @return List<OpportunityContactRole> The newly created Opportunity Contact Role records.
    **********************************************************************************************************/
    public static List<OpportunityContactRole>  createRelationshipOCRs(Map<Id, List<Id>> primaryContactIdToOpportunityIds, Map<Id, List<OpportunityContactRole>> transactionOCRs) {
        // Retrieve Relationships for Primary Contact
        Map<Id, List<npe4__Relationship__c>> primaryContactToRelatedContacts = retrieveRelationships(primaryContactIdToOpportunityIds.keySet());

        // Create Opportunity Contact Roles (OCR) records for the Related Contacts
        List<OpportunityContactRole> relationshipOCRs = buildRelationshipOCRs(primaryContactIdToOpportunityIds, primaryContactToRelatedContacts, transactionOCRs);

        return relationshipOCRs;
    }


    /*********************************************************************************************************
    * @description Retrieves the Relationship records for the Opportunity's associated Primary Contact.
    * @param primaryContactIds The Opportunities' Primary Contacts.
    * @return Map<Id, List<npe4__Relationship__c>> Map of the Primary Contact to its Relationship records.
    **********************************************************************************************************/
    @testVisible
    private static Map<Id, List<npe4__Relationship__c>> retrieveRelationships(Set<Id> primaryContactIds) {
        Map<Id, List<npe4__Relationship__c>> primaryContactToRelationships = new Map<Id, List<npe4__Relationship__c>>();

        if (primaryContactIds.isEmpty()) {
            return primaryContactToRelationships;
        }

        List<npe4__Relationship__c> allRelationships
            = new List<npe4__Relationship__c>([SELECT Id, Name, npe4__Contact__c, npe4__RelatedContact__c, Related_Opportunity_Contact_Role__c
                                                FROM npe4__Relationship__c
                                                WHERE npe4__Contact__c IN :primaryContactIds
                                                ORDER BY CreatedDate DESC]);

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

        Map<Id, List<npe4__Relationship__c>> uniquePrimaryContactToRelationships = removeDuplicateAssociatedRecords(primaryContactToRelationships, FIELD_NAME_RELATIONSHIP_RELATED_CONTACT);

        return uniquePrimaryContactToRelationships;
    }


    /*********************************************************************************************************
    * @description Builds Opportunity Contact Role records for the Primary Contact's Relationships.
    * @param primaryContactIdToOpportunityIds Map of Primary Contact to List of Opportunities.
    * @param primaryContactToRelatedContacts Map of Primary Contact to Relationship records.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @return List<OpportunityContactRole> List of the Opportunity Contact Role records for Related Contacts.
    **********************************************************************************************************/
    @testVisible
    private static List<OpportunityContactRole> buildRelationshipOCRs(Map<Id, List<Id>> primaryContactIdToOpportunityIds,
                                                                      Map<Id, List<npe4__Relationship__c>> primaryContactToRelatedContacts,
                                                                      Map<Id, List<OpportunityContactRole>> transactionOCRs) {
        List<OpportunityContactRole> relationshipOCRs = new List<OpportunityContactRole>();

        if (primaryContactIdToOpportunityIds.isEmpty()) {
            return relationshipOCRs;
        }

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR
            = retrieveOpportunityContactRoles(primaryContactIdToOpportunityIds.values(), transactionOCRs.values());

        for (Id primaryContactKey : primaryContactToRelatedContacts.keySet()) {
            List<Id> opportunityIds = primaryContactIdToOpportunityIds.get(primaryContactKey);
            for (npe4__Relationship__c eachRelationship : primaryContactToRelatedContacts.get(primaryContactKey)) {
                for (Id eachOpportunityId : opportunityIds) {
                    if (!isDuplicateOCR(opportunityIdToOCR.get(eachOpportunityId),
                                        eachRelationship.npe4__RelatedContact__c)) {
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
    * @description Calls the methods that handle creating Opportunity Contact Roles for Affiliation records.
    * @param accountIdToOpportunityIds Map of Account Id to List of Opportunities.
    * @return List<OpportunityContactRole> The newly created Opportunity Contact Role records.
    **********************************************************************************************************/
    public static List<OpportunityContactRole> createAffiliationOCRs(Map<Id, List<Id>> accountIdToOpportunityIds, Map<Id, List<OpportunityContactRole>> transactionOCRs) {
        // Retrieve Affiliations for Account
        Map<Id, List<npe5__Affiliation__c>> accountToRelatedContacts = retrieveAffiliations(accountIdToOpportunityIds.keySet());

        // Create Opportunity Contact Roles (OCR) records for the Related Contacts
        List<OpportunityContactRole> affiliationOCRs = buildAffiliationOCRs(accountIdToOpportunityIds, accountToRelatedContacts, transactionOCRs);

        return affiliationOCRs;
    }


    /*********************************************************************************************************
    * @description Retrieves the Affiliation records for the Opportunity's associated Account.
    * @param accountIds The Opportunities' Account Ids.
    * @return Map<Id, List<npe5__Affiliation__c>> Map of the Account to its Affiliation records.
    **********************************************************************************************************/
    @testVisible
    private static Map<Id, List<npe5__Affiliation__c>> retrieveAffiliations(Set<Id> accountIds) {
        Map<Id, List<npe5__Affiliation__c>> accountToAffiliations = new Map<Id, List<npe5__Affiliation__c>>();

        if (accountIds.isEmpty()) {
            return accountToAffiliations;
        }

        List<npe5__Affiliation__c> allAffiliations
            = new List<npe5__Affiliation__c>([SELECT Id, Name, npe5__Organization__c, npe5__Contact__c, Related_Opportunity_Contact_Role__c
                                                FROM npe5__Affiliation__c
                                                WHERE npe5__Organization__c IN :accountIds
                                                ORDER BY CreatedDate DESC]);

        // Process the records that have a value in the Related_Opportunity_Contact_Role__c field
        for (npe5__Affiliation__c eachAffiliation : allAffiliations) {
            if (eachAffiliation.Related_Opportunity_Contact_Role__c != null
                && !eachAffiliation.Related_Opportunity_Contact_Role__c.containsIgnoreCase(RELATED_OPPORTUNITY_CONTACT_ROLE_NONE)) {
                if (accountToAffiliations.containsKey(eachAffiliation.npe5__Organization__c)) {
                    List<npe5__Affiliation__c> affiliations = accountToAffiliations.get(eachAffiliation.npe5__Organization__c);
                    affiliations.add(eachAffiliation);
                } else {
                    accountToAffiliations.put(eachAffiliation.npe5__Organization__c, new List<npe5__Affiliation__c>{ eachAffiliation });
                }
            }
        }

        Map<Id, List<npe5__Affiliation__c>> uniqueAccountToAffiliations = removeDuplicateAssociatedRecords(accountToAffiliations, FIELD_NAME_AFFILIATION_CONTACT);

        return uniqueAccountToAffiliations;
    }


    /*********************************************************************************************************
    * @description Builds Opportunity Contact Role records for the Account's Affiliations.
    * @param accountIdToOpportunityIds Map of Account to List of Opportunities.
    * @param accountToRelatedContacts Map of Account to Affiliation records.
    * @param transactionOCRs Contains the OCRs that will be evaluated to ensure compliance with the OCR hierarchy.
    * @return List<OpportunityContactRole> List of the Opportunity Contact Role records for Related Contacts.
    **********************************************************************************************************/
    @testVisible
    private static List<OpportunityContactRole> buildAffiliationOCRs(Map<Id, List<Id>> accountIdToOpportunityIds,
                                                                     Map<Id, List<npe5__Affiliation__c>> accountToRelatedContacts,
                                                                     Map<Id, List<OpportunityContactRole>> transactionOCRs) {
        List<OpportunityContactRole> affiliationOCRs = new List<OpportunityContactRole>();

        if (accountIdToOpportunityIds.isEmpty()) {
            return affiliationOCRs;
        }

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR
            = retrieveOpportunityContactRoles(accountIdToOpportunityIds.values(), transactionOCRs.values());

        for (Id accountKey : accountToRelatedContacts.keySet()) {
            List<Id> opportunityIds = accountIdToOpportunityIds.get(accountKey);
            for (npe5__Affiliation__c eachAffiliation : accountToRelatedContacts.get(accountKey)) {
                for (Id eachOpportunityId : opportunityIds) {
                    if (!isDuplicateOCR(opportunityIdToOCR.get(eachOpportunityId),
                                        eachAffiliation.npe5__Contact__c)) {
                        OpportunityContactRole ocr = new OpportunityContactRole();
                        ocr.OpportunityId = eachOpportunityId;
                        ocr.ContactId = eachAffiliation.npe5__Contact__c;
                        ocr.Role = eachAffiliation.Related_Opportunity_Contact_Role__c;
                        affiliationOCRs.add(ocr);
                    }
                }
            }
        }

        return affiliationOCRs;
    }


    /*********************************************************************************************************
    * @description Removes duplicate Relationship/Affiliation records based on the Contact Id.
    * @param sourceIdToAssociatedRecords Map of Primary Contact/Account to its related records.
    * @return Map<Id, List<sObject>> Map of unique Relationship records based on Contact Id.
    **********************************************************************************************************/
    @testVisible
    private static Map<Id, List<sObject>> removeDuplicateAssociatedRecords(Map<Id, List<sObject>> sourceIdToAssociatedRecords, sObjectField fieldName) {
        Map<Id, List<sObject>> sourceIdToUniqueAssociatedRecords = new Map<Id, List<sObject>>();

        for (Id sourceId : sourceIdToAssociatedRecords.keySet()) {
            Map<Id, sObject> cleanedRelatedRecords = new Map<Id, sObject>();
            List<sObject> uniqueAssociatedRecords = new List<sObject>();
            List<sObject> relatedRecords = sourceIdToAssociatedRecords.get(sourceId);
            for (sObject eachAssociatedRecord : relatedRecords) {
                if (!cleanedRelatedRecords.containsKey((Id)eachAssociatedRecord.get(fieldName))) {
                    cleanedRelatedRecords.put((Id)eachAssociatedRecord.get(fieldName), eachAssociatedRecord);
                    uniqueAssociatedRecords.add(eachAssociatedRecord);
                }
            }

            sourceIdToUniqueAssociatedRecords.put(sourceId, uniqueAssociatedRecords);
        }

        return sourceIdToUniqueAssociatedRecords;
    }


    /*********************************************************************************************************
    * @description Retrieves the Opportunity Contact Role records related to the Opportunities.
    * @param opportunityIds List of Lists of Opportunity Ids.
    * @return Map<Id, List<OpportunityContactRole>> Map of the Opportunity to Opportunity Contact Roles.
    **********************************************************************************************************/
    @testVisible
    private static Map<Id, List<OpportunityContactRole>> retrieveOpportunityContactRoles(List<List<Id>> opportunityIds, List<List<OpportunityContactRole>> transactionOCRs) {
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

        for (List<OpportunityContactRole> eachTransactionOCRs : transactionOCRs) {
            allOCRs.addAll(eachTransactionOCRs);
        }

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
    * @return Boolean The result of determining if the currentRelationship record is a duplicate.
    **********************************************************************************************************/
    @testVisible
    private static Boolean isDuplicateOCR(List<OpportunityContactRole> currentOCRs, Id relatedContact) {
        Boolean isDuplicate = false;

        if (currentOCRs == null || currentOCRs.isEmpty()) {
            return isDuplicate;
        }

        for (OpportunityContactRole eachOCR : currentOCRs) {
            if (eachOCR.ContactId == relatedContact) {
                isDuplicate = true;
                break;
            }
        }

        return isDuplicate;
    }


}