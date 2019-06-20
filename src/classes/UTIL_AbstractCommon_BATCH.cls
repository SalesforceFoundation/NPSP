/*
    Copyright (c) 2019 Salesforce.org
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
/**
* @author Salesforce.org
* @date 2019
* @group Utilities
* @description This class is meant to be extended by batch jobs requiring enhanced batch
* functionality, including LDV Chunking Support, and support for automatically retrieving
* subqueries for batches properly.  It is meant to switch between LDV Chunking mode or
* non LDV Chunking mode, depending on the # of records in the object the batch is iterating
* over.  The main limitation of this implementation is that it will not be possible to
* provide an order to the records returned because it has to execute in a specific order
* when running in LDV Chunking Mode.
*
* Future: Add exception handling, and logging support so implementing clases can inherit.
* Recommend registering a default handler using an interface that can be switched out/overriden
* as desired for specific use cases.
*/
public abstract with sharing class UTIL_AbstractCommon_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer MAX_LDV_CHUNK_SIZE = 99999;
    private static final Integer DEFAULT_BATCH_SIZE = 500;
    private String additionalWhereClause;
    private Id startId;
    private Id endId;
    private Id currentEndId;
    private Boolean endReached;
    private Integer batchSize;
    private Integer chunkIteration;
    private Boolean ldvMode = null;

    /**
     * @description No argument constructor that assumes no additional where clause, default batch size of 500, and that ldvMode will be
     * determined by record distance between min and max Id for main object of batch
     */
    public UTIL_AbstractCommon_BATCH() {
        // additionalWhereClause, batchSize
        this('', DEFAULT_BATCH_SIZE, null);
    }

    /**
     * @description Constructor with default batch size of 500, and that ldvMode will be
     * determined by record distance between min and max Id for main object of batch
     * @param additionalWhereClause constraint to apply to child records for filtering purposes
     */
    public UTIL_AbstractCommon_BATCH(String additionalWhereClause) {
        // additionalWhereClause, batchSize, ldvMode
        this(additionalWhereClause, DEFAULT_BATCH_SIZE, false);
    }

    /**
     * @description Constructor with default batch size of 500, if ldvMode is false/null it will
     * use the default logic to determine whether to run in LDV Chunking mode, calculating record distance between the min and
     * max Id for the object
     * @param additionalWhereClause constraint to apply to child records for filtering purposes
     * @param ldvMode Boolean, if true will execute in LDV Chunking mode by default
     */
    public UTIL_AbstractCommon_BATCH(String additionalWhereClause, Boolean ldvMode) {
        // additionalWhereClause, batchSize, ldvMode
        this(additionalWhereClause, DEFAULT_BATCH_SIZE, ldvMode);
    }

    /**
     * @description Constructor that assumes no additional where clause, and that ldvMode will be
     * determined by record distance between min and max Id for main object of batch
     * @param batchSize Integer Size of each batch
     */
    public UTIL_AbstractCommon_BATCH(Integer batchSize) {
        // additionalWhereClause, batchSize, ldvMode
        this('', batchSize, false);
    }

    /**
     * @description Constructor that assumes no additional where clause, if ldvMode is false/null it will
     * use the default logic to determine whether to run in LDV Chunking mode, calculating record distance between the min and
     * max Id for the object
     * @param batchSize Integer Size of each batch
     * @param ldvMode Boolean, if true will execute in LDV Chunking mode by default
     */
    public UTIL_AbstractCommon_BATCH(Integer batchSize, Boolean ldvMode) {
        this('', batchSize, ldvMode);
    }

    /**
     * @description Constructor, if ldvMode is false/null it will
     * use the default logic to determine whether to run in LDV Chunking mode, calculating record distance between the min and
     * max Id for the object
     * @param additionalWhereClause constraint to apply to child records for filtering purposes
     * @param batchSize Integer Size of each batch
     * @param ldvMode Boolean, if true will execute in LDV Chunking mode by default
     */
    public UTIL_AbstractCommon_BATCH(String additionalWhereClause, Integer batchSize, boolean ldvMode) {
        this.additionalWhereClause = additionalWhereClause;
        this.endReached = false;
        this.batchSize = batchSize;
        this.chunkIteration = 0;
        this.ldvMode = ldvMode;
    }

    /**
     * @description start method for the Database batch.  Overloaded to run in LDV Chunking or regular batch mode depending on parameters supplied, and/or
     * record distance between minimum and maximum Id for the main object of the batch.  If in LDV/Chunking mode it will be the querylocator for the
     * current chunk of records
     * @param bc BatchableContext passed from Salesforce
     * @return Database.QueryLocator Querylocator for batch
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (startId == null) {
            this.startId = determineStartId();
            this.endId = determineEndId();
            this.ldvMode = (ldvMode != true) ? isLDVCircumstance(this.startId, this.endId) : ldvMode;
        }

        Database.QueryLocator ql = null;
        Database.QueryLocatorIterator qli = null;

        // If startId is null, there were no records present in the object
        if (startId != null) {
            ql = Database.getQueryLocator(getQuery(startId));
            qli = (ql != null) ? ql.iterator() : null;
        }

        // If no records were present/returned, it will execute a limited query with a LIMIT 0 in order to avoid
        // Iterable errors
        if ((qli == null) || (!qli.hasNext())) {
            ql = Database.getQueryLocator(getQueryLimitZero());
            this.endReached = true;
        }

        return ql;
    }

    /**
     * @description Query to be used if object has no records to prevent not iterable error
     * @return String queryString to execute for Object, limited to 0 records
     */
    @testVisible private String getQueryLimitZero() {
        return 'SELECT Id FROM ' + getSOQLObjectName() + ' LIMIT 0';
    }

    /**
     * @description Determines the query to execute factoring all the different params for where clause, ldv versus non ldv, etc.
     * @param startId starting id of the chunk
     * @return String queryString to execute for Batch
     */
    @testVisible private String getQuery(Id startId) {
        return 'SELECT ' + getQueryFieldList() + ' FROM ' + getSOQLObjectName() + getQueryWhereClause() + getQueryOrderByAndLimitClause();
    }

    /**
     * @description SOQL Query Fragment: Part of the query between the SELECT and FROM, returning either the ID if in LDV Chunking mode or Subquery is present, or fields to return for the batch Query
     * @return String part of query between the SELECT and the outer FROM
     */
    @testVisible private String getQueryFieldList() {
        return this.ldvMode || isSubQueryPresent() ? 'Id' : getSOQLFullQueryFieldList();
    }

    /**
     * @description SOQL Query Fragment: ORDER BY and LIMIT CLAUSE.  If LDV/Chunking, it will return a default order by ID with a limit of the Chunk Size for the Batch so the query does not time out
     * @return String SQOL Query Fragment for the ORDER BY and LIMIT fragment if needed
     */
    @testVisible private String getQueryOrderByANDLimitClause() {
        return this.ldvMode ? ' ORDER BY Id ASC LIMIT ' + getValidLDVChunkSize() : '';
    }

    /**
     * @description SOQL Query Fragment: Calculates the where clause for the batch driver in LDV Chunking and non LDV mode
     * @return String Where clause fragment
     */
    @testVisible private String getQueryWhereClause() {
        String ldvWhere = isFirstChunk() ? ' WHERE Id >= \'' + startId + '\'' : ' WHERE Id > \'' + startId + '\'';
        String nonLdvWhere =  ((this.additionalWhereClause != null) && (this.additionalWhereClause.trim().length() > 0)) ? ' WHERE (' + this.additionalWhereClause + ')' : '';

        return (ldvMode) ? ldvWhere : nonLdvWhere;
    }

    /**
     * @description Indicates whether or not this is the first chunk when running in LDV Chunking mode.  Needed for LDV Chunking mode execution, as the first query differs from the rest
     * @return Boolean true if the first chunk and false otherwise
     */
    @testVisible private Boolean isFirstChunk() {
        return (this.chunkIteration == 0);
    }

    /**
     * @description execute method for the batch, overloaded to do an inner query when necessary and call doExecute with results of either the inner query (if necessary, or the original records returned).
     * doExecute will be the implementing batch classes method instead of execute.
     * @param bc BatchableContext supplied by Salesforce
     * @param records Records returned by salesforce for each batch
     */
    public void execute(Database.BatchableContext bc, List<SObject> records) {

        // Id of last record in batch of records
        Id proposedCurrentEndId = records[records.size() - 1].Id;
        // Record the last record in the list as the current "end" Id, if greater than our current end id value, or if currently unassigned
        this.currentEndId = (this.currentEndId == null || proposedCurrentEndId > currentEndId) ? proposedCurrentEndId : currentEndId;

        List<SObject> innerRecords = getInnerRecords(records);

        if ((innerRecords != null) && (innerRecords.size() > 0)) {
            doExecute(bc, innerRecords);
        }
    }

    /**
     * @description Either returns the records as is, if not executing in LDV Chunking mode, and no subquery was present in the field list, or uses the records passed to
     * execute the "inner query" with all the fields, any additional where clause, etc.
     * @param records Records returned by salesforce for each batch
     * @return List of records to pass to implementing "doExecute" method
     */
   @testVisible private List<SObject> getInnerRecords(List<SObject> records) {
        if (ldvMode || isSubQueryPresent()) {
            String query = 'SELECT ' + getSOQLFullQueryFieldList() + ' FROM ' + getSOQLObjectName() + ' WHERE Id in :records ' +
                        (((this.additionalWhereClause != null) && (this.additionalWhereClause.trim().length() > 0)) ? ' AND (' + this.additionalWhereClause + ')' : '');

            return Database.query(query);
        } else { // No need to requery if not LDV Chunking mode
            return records;
        }
    }

    /**
     * @description Apex Batch "finish" method called by Salesforce.  Overloaded to call doFinish, passing an indicated to doFinish as to whether it is completely finished (isComplete == true),
     * or needs to execute the batch for additional chunks (isComplete == false).  It will also move the startId to the next chunk and re-execute the batch if needed.
     * @param bc BatchableContext supplied by Salesforce
     */
    public void finish(Database.BatchableContext bc) {
        if ((!this.endReached) && (this.currentEndId != this.endId) && (this.ldvMode)) {
            doFinish(bc, false);

            // Move StartId to Id of Last Record processed
            this.startId = this.currentEndId;
            this.chunkIteration++;

            // Execute Batch Again...
            Database.executeBatch(this, this.batchSize);
        } else {
           doFinish(bc, true);
        }
    }

    /**
     * @description A query executed initially to determine the minimum id present in Salesforce (using ASC sort).  This and the end Id will used to determine whether
     * it is theoretically necessary to run in LDV Chunking mode
     * @return Id of first record found in System for object, sorting ids ascending
     */
    private Id determineStartId() {

        List<SObject> recs = Database.query ('SELECT Id FROM ' + getSOQLObjectName() + ' ORDER BY Id ASC LIMIT 1');

        return ((recs != null) && (recs.size() > 0)) ? recs[0].Id : null;
    }

    /**
     * @description A query executed initially to determine the maximum id present in Salesforce (using DESC sort).  This and the start Id will used to determine whether
     * it is theoretically necessary to run in LDV Chunking mode
     * @return Id of last record found in System for object, sorting ids descending
     */
     private Id determineEndId() {
        List<SObject> recs = Database.query ('SELECT Id FROM ' + getSOQLObjectName() + ' ORDER BY Id DESC LIMIT 1');

        return ((recs != null) && (recs.size() > 0)) ? recs[0].Id : null;
    }

    /**
     * @description Returns an indicator indicating whether or not a batch should execute in LDV Chunking mode.  Basically, if the theoretical record distance
     * exceeds the LDV Chunk Size, it will return true, and false otherwise.  If the Ids are null, meaning there are no records present,
     * computeRecordDistance returns a negative number.  In all other cases, the record distance is a positive number.
     * @param startId Starting Id of the all records present in the object
     * @param endId Ending Id of the records in the object
     * @return Boolean true, if it appears to be an LDV Chunking circumstance, and false otherwise
     */
    @testVisible private boolean isLDVCircumstance(Id startId, Id endId) {
        Long recordDistance = UTIL_SalesforceID.computeRecordDistance(startId, endId);

        return recordDistance > getValidLDVChunkSize();
    }

    /**
     * @description Indicates whether fields to return text includes the " from " keyword, indicating a subquery is present.
     * @return Boolean true, if subquery is present and false otherwise
     */
    @testVisible private boolean isSubQueryPresent() {
        String soqlFields = getSOQLFullQueryFieldList();

        return  (soqlFields != null) ? soqlFields.containsIgnoreCase(' FROM ') : false;
    }

    /**
     * @description If the implementing class specifies an invalid chunk size (either too large (> 100,000) or too small (<= 0)) the default
     * chunk size of 100,000 will be returned and used instead
     * @return Integer Chunk size to use when running in LDV Chunking mode
     */
    @testVisible private Integer getValidLDVChunkSize() {
        Integer ldvChunkSize = getLDVChunkSize();

        return ((ldvChunkSize == null) || (ldvChunkSize <= 0) || (ldvChunkSize > MAX_LDV_CHUNK_SIZE)) ? MAX_LDV_CHUNK_SIZE : ldvChunkSize;
    }

    /**
     * @description Returns 100,000 by default for chunk size, but can be overriden by implementing class to return a different value
     * @return Integer chunk size to use when running in LDV Chunking mode
     */
    public virtual Integer getLDVChunkSize() {
        return MAX_LDV_CHUNK_SIZE;
    }

    /**
     * Returns ID by default.  Can be modified to return other fields, and subQueries instead
     * @return String SOQL Query fragment consisting of fields and subqueries to retrieve, part between outer select and from
     */
    public virtual String getSOQLFullQueryFieldList() {
        return 'Id';
    }

    /**
     * Indicates the main object to query/retrieve data from.  A valid value must be supplied by the implementing class
     * @return String SOQL Object Name
     */
    public abstract String getSOQLObjectName();

    /**
     * Equivalent to the execute method of a standard batch class.
     * @param bc BatchableContext provided by Salesforce
     * @param records the records returned for that batch
     */
    public abstract void doExecute(Database.BatchableContext bc, List<SObject> records);

    /**
     * A do nothing equivalent to the finish method of a standard batch class.  Can be overriden by the implementing class.
     * @param bc BatchableContext provided by Salesforce
     * @param isComplete Boolean value indicating whether the batch job is completely finished or must reexecute for additional chunks
     */
    public virtual void doFinish(Database.BatchableContext bc, boolean isComplete) {

    }
}