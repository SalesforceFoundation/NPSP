/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Query Builder class for Customizable Rollups. This is a work-in-progress. For now it only implements
* query building for Detail objects. Batch level QueryLocator queries will be in a future refactor.
*
*/
public without sharing class CRLP_RollupQueryBuilder {

    /** @description Type of rollup being performed */
    private CRLP_RollupProcessingOptions.RollupType rollupType;

    /** @description Define the type of batch job mode - LDV or NonLDV mode */
    private CRLP_RollupProcessingOptions.BatchJobMode mode = CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode;

    private Set<Id> summaryRecordIds;
    private Set<Id> detailRecordIds;
    private String summaryRecordsIdVar;
    private String orderByField;
    private Boolean includePaymentRecords = false;
    private Boolean useIncrementalMode = false;

    public CRLP_RollupQueryBuilder() {}

    public CRLP_RollupQueryBuilder withRollupType(CRLP_RollupProcessingOptions.RollupType rollupType) {
        this.rollupType = rollupType;
        return this;
    }

    public CRLP_RollupQueryBuilder withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode jobMode) {
        this.mode = jobMode;
        return this;
    }


    public CRLP_RollupQueryBuilder withSummaryRecordIds(Set<Id> summaryRecordIds) {
        this.summaryRecordIds = summaryRecordIds;
        return this;
    }

    public CRLP_RollupQueryBuilder withDetailRecordIds(Set<Id> detailRecordIds) {
        this.detailRecordIds = detailRecordIds;
        return this;
    }

    public CRLP_RollupQueryBuilder withSummaryRecordIdsVar(String summaryRecordIdVar) {
        this.summaryRecordsIdVar = summaryRecordIdVar;
        return this;
    }

    public CRLP_RollupQueryBuilder withOrderBy(String orderBy) {
        this.orderByField = orderBy;
        return this;
    }

    public CRLP_RollupQueryBuilder includePaymentRecords() {
        this.includePaymentRecords = true;
        return this;
    }

    public CRLP_RollupQueryBuilder withSummaryRecords(List<SObject> summaryRecords) {
        summaryRecordIds = new Set<Id>();
        for (SObject s : summaryRecords) {
            summaryRecordIds.add((Id)s.get('Id'));
        }
        return this;
    }

    public CRLP_RollupQueryBuilder withDetailRecords(List<SObject> detailRecords) {
        detailRecordIds = new Set<Id>();
        for (SObject s : detailRecords) {
            detailRecordIds.add((Id)s.get('Id'));
        }
        return this;
    }

    /**
    * @description Return true if running in Skew Mode
    */
    private Boolean isSkewMode {
        get {
            return (mode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode);
        }
    }

    /**
     * @description Returns true if executing a SoftCredit rollup type
     */
    private Boolean isSoftCreditRollup {
        get {
            return rollupType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit
                    || rollupType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit
                    || rollupType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit;
        }
    }

    /**
     * @description Returns the SOQL string for a Query against the details object. This is used for a NonSkew job
     * or for the Queueable rollup operation.
     * SummaryRecordId's are required to generate this query.
     * @return SOQL String
     */
    public String buildDetailsQuery() {
        if (isSoftCreditRollup) {
            return buildDetailsQuerySoftCredits();
        } else {
            return buildDetailsQueryHardCredits();
        }
    }

    /**
     * @description Returns the SOQL string for a Query against the details object for the NonSkew HardCredit Rollup.
     * SummaryRecordId's are required to generate this query.
     * @return SOQL String
     */
    private String buildDetailsQueryHardCredits() {
        List<String> whereClauses = new List<String>();
        List<String> orderByFields = new List<String>();

        npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

        SObjectType summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);

        String query = buildFullDetailsQueryForSummaryRecords();

        if (query.containsIgnoreCase('ORDER BY ')) {
            orderByFields.add(query.split('ORDER BY')[1]);
            query = query.split('ORDER BY')[0];
        }

        if (query.containsIgnoreCase(' WHERE ')) {
            whereClauses.add(query.split(' WHERE ')[1]);
            query = query.split(' WHERE ')[0];
        }

        // Identify a common filter that can be applied to the main query to reduce the number of records queried
        String addlFilter = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(summaryObjectType,
                Opportunity.SObjectType, CRLP_Rollup_SEL.getRollupDefinitionsToUse(rollupType, CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        if (!String.isEmpty(addlFilter)) {
            whereClauses.add(addlFilter);
        }

        // Exclude Organization Donations from Contact Hard Credit rollups (where Opp.Account.SYSTEM_IsIndividual=false)
        // When the npo02__Always_Rollup_to_Primary_Contact__c is field is unchecked.
        if (summaryObjectType == Contact.SObjectType && householdSettings.npo02__Always_Rollup_to_Primary_Contact__c == false) {
            whereClauses.add('Account.npe01__SYSTEMIsIndividual__c = True');
        }

        // Force the details query to sort by Ascending CreatedDate so that the records are process
        // in the order in which they were created in the database. Thus the 'first' is truly the first
        // and the last is truly the last.
        orderByFields.add('CreatedDate ASC');

        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        if (!orderByFields.isEmpty()) {
            query += ' ORDER BY ' + String.join(orderByFields, ', ');
        }

        return query;
    }

    /**
     * @description Returns the SOQL string for a Query against the details object for the NonSkew SoftCredit Rollup.
     * SummaryRecordId's are required to generate this query.
     * @return SOQL String
     */
    private String buildDetailsQuerySoftCredits() {
        List<String> whereClauses = new List<String>();
        List<String> orderByFields = new List<String>();

        npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

        SObjectType detailObjectType = CRLP_Rollup_SVC.getDetailObjectType(rollupType);
        SObjectType summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);

        String query = CRLP_Query_SEL.buildDetailObjectQueryForRollup(detailObjectType, new List<SObjectType>());

        String keyFieldOverrideForQuery = CRLP_Rollup_SVC.getParentFieldNameForQuery(rollupType);

        whereClauses.add(keyFieldOverrideForQuery + ' IN : summaryRecords');

        String addlFilter;
        if (rollupType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            addlFilter = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(summaryObjectType, Partial_Soft_Credit__c.SObjectType);
        } else {
            addlFilter = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(summaryObjectType, detailObjectType);
        }
        if (!String.isEmpty(addlFilter)) {
            whereClauses.add(addlFilter);
        }

        if (rollupType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            if (householdSettings.npo02__Always_Rollup_to_Primary_Contact__c == false) {
                whereClauses.add('(IsPrimary = False OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = False)');
            } else {
                whereClauses.add('IsPrimary = False');
            }
        }

        orderByFields.add(keyFieldOverrideForQuery);
        if (rollupType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            orderByFields.add('Opportunity.CreatedDate ASC');
        } else {
            orderByFields.add('Opportunity__r.CreatedDate ASC ');
        }

        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        if (!orderByFields.isEmpty()) {
            query += ' ORDER BY ' + String.join(orderByFields, ', ');
        }

        return query;
    }

    /**
     * @description Returns the SOQL string for a Query against the details object. This is used for a NonSkew job
     * or for the Queueable rollup operation.
     * DetailRecordId's are required to generate this query.
     * @return SOQL String
     */
    public String getRelatedRecordsQueryAsSOQL() {
        String query = '';

        return query;
    }

    /**
     * @description Returns the SOQL string for a QueryLocator query for the specified Job Type (Skew or NonSkew)
     * and RollupType. If there are SummaryRecordId's present, the query is filtered for those specified Id's.
     * @return SOQL String
     */
    /*public String getQueryLocatorAsSOQL() {
        String query = '';

        return query;
    }*/

    /**
     * @description Build a complete SOQL query string from a set of Summary Record Ids, including the required
     * child objects and filtered by the parent record id's
     * @return SOQL
     */
    private String buildFullDetailsQueryForSummaryRecords() {
        SObjectType mainObject = Opportunity.SObjectType;
        String detailKeyField;
        List<SObjectType> childObjects = new List<SObjectType>();

        SObjectType summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);

        // The specific set of 'detail' records is fixed based on the target summary object.
        if (summaryObjectType == Account.SObjectType) {

            if (rollupType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {

                // Opportunity and Payment to Account
                if (includePaymentRecords == true) {
                    childObjects.add(npe01__OppPayment__c.SObjectType);
                }
                detailKeyField = SObjectType.Opportunity.fields.AccountId.getName();
            }

        } else if (summaryObjectType == Contact.SObjectType) {

            // Opportunity and Payment to Contact
            if (includePaymentRecords == true) {
                childObjects.add(npe01__OppPayment__c.SObjectType);
            }
            detailKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();

        } else if (summaryObjectType == npe03__Recurring_Donation__c.SObjectType) {
            detailKeyField = SObjectType.Opportunity.fields.npe03__Recurring_Donation__c.getName();

        }

        // Get the base query
        String detailsQuery = CRLP_Query_SEL.buildDetailObjectQueryForRollup(mainObject, childObjects);

        // Add the appropriate filtering
        detailsQuery += ' WHERE ' + detailKeyField + ' IN :' + summaryRecordsIdVar;

        return detailsQuery;
    }


}