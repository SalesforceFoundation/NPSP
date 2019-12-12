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
* Due to the fact that constructors are not inherited by default, any constructors that
* are desired need to be created using the signature as desired, and then in the constructor
* body providing a super method and any params, e.g. super(batchSize);
*
* Where clause can be added by overriding getWhereClause() method
*
* Additional Where Clause can be configured by passing to constructor
*
* If Additional Where Clause is added, it can be validated by executing validateQuery().  If
* it returns null, it is syntactically correct.  If it returns an Exception object, something about the
* query is invalid.  The Additional Where and/or Where clause will be applied to the inner query for
* each batch, if executing in LDV Chunking Mode, and the main batch query if executing in non LDV
* Chunking mode.
*
* Future: Add exception handling, and logging support so implementing clases can inherit.
* Recommend registering a default handler using an interface that can be switched out/overriden
* as desired for specific use cases.
*/
public abstract inherited sharing class UTIL_AbstractChunkingLDV_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /**
     * @description The Maximum LDV Chunk size that is allowed to be used.  If > MAX will use the MAX
     */
    @testVisible private static final Integer MAX_LDV_CHUNK_SIZE = 10000000;
    /**
     * @description Default size to use when chunking records
     */
    @testVisible private static final Integer DEFAULT_LDV_CHUNK_SIZE = 1000000;
    /**
     * @description Default Maximum Size in # of records between min and max Id before it must run in LDV Chunking Mode
     */
    @testVisible private static final Integer DEFAULT_MAX_NON_LDV_SIZE = 1000000;
    /**
     * @description Default size of the batch when re-executing in chunk mode, if not provided
     */
    @testVisible private static final Integer DEFAULT_BATCH_SIZE = 500;

    @testVisible private Id startId;
    @testVisible private Id endId;
    @testVisible private Id currentEndId;
    @testVisible private Boolean endReached = false;
    @testVisible private Integer batchSize = DEFAULT_BATCH_SIZE;
    @testVisible private Integer chunkIteration = 0;
    @testVisible private Boolean ldvMode = null;
    @testVisible private String additionalWhereClause = '';
    @testVisible private Boolean batchJobInProgress = false;

    /**
     * @description No argument constructor
     */
    public UTIL_AbstractChunkingLDV_BATCH() {
    }

    public void setBatchSize(Integer batchSize) {
        if (!this.batchJobInProgress) {
            this.batchSize = batchSize;
        }
    }

    /**
     * @description Sets the ldvMode value.  Only takes the value if the batch job
     *              is not yet in progress, e.g. the start() method has not executed yet
     * @param aldvMode AdditionalWhereClause to be added to the query
     */
    public void setLdvMode(Boolean ldvMode) {
        if (!this.batchJobInProgress) {
            this.ldvMode = ldvMode;
        }
    }

    /**
     * @description Sets the additionalWhereClause value.  Only takes the value if the batch job
     *              is not yet in progress, e.g. the start() method has not executed yet
     * @param additionalWhereClause AdditionalWhereClause to be added to the query
     */
    public void setAdditionalWhereClause(String additionalWhereClause) {
        if (!this.batchJobinProgress) {
            this.additionalWhereClause = additionalWhereClause;
        }
    }

    /**
     * @description start method for the Database batch.  Overloaded to run in LDV Chunking or regular batch mode depending on parameters supplied, and/or
     * record distance between minimum and maximum Id for the main object of the batch.  If in LDV/Chunking mode it will be the querylocator for the
     * current chunk of records
     * @param bc BatchableContext passed from Salesforce
     * @return Database.QueryLocator Querylocator for batch
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Past this point, the initialization member variables cannot be modified from outside the class:
        // ldvMode, batchSize, additionalWhereClause;
        this.batchJobInProgress = true;
        onStart(bc, isFirstChunk());

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
        return 'SELECT Id FROM ' + getSObjectName() + ' LIMIT 0';
    }

    /**
     * @description Determines the query to execute factoring all the different params for where clause, ldv versus non ldv, etc.
     * @param startId starting id of the chunk
     * @return String queryString to execute for Batch
     */
    @testVisible private String getQuery(Id startId) {
        return 'SELECT ' + getQueryFieldList() + ' FROM ' + getSObjectName() + ' ' + getQueryWhereClause() + ' ' + getQueryOrderByAndLimitClause();
    }

    /**
     * @description SOQL Query Fragment: Part of the query between the SELECT and FROM, returning either the ID if in LDV
     * Chunking mode or Subquery is present, or fields to return for the batch Query
     * @return String part of query between the SELECT and the outer FROM
     */
    @testVisible private String getQueryFieldList() {
        return this.ldvMode || isSubQueryPresent() ? 'Id' : getSOQLFullQueryFieldList();
    }

    /**
     * @description SOQL Query Fragment: ORDER BY and LIMIT CLAUSE.  If LDV/Chunking, it will return a default order by ID
     * with a limit of the Chunk Size for the Batch so the query does not time out
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
        String ldvWhere = isFirstChunk() ? getLdvWhereFirstChunk() : getLdvWhereAfterFirstChunk();
        String whereClause = getQueryNonLDVWhereClause();

        String nonLdvWhere =  (String.isNotBlank(whereClause)) ? 'WHERE (' + whereClause + ')' : '';

        return (ldvMode) ? ldvWhere : nonLdvWhere;
    }

    /**
     * @description SOQL Query Fragment: Where LDV Where Clause for first chunk must include the Start Id
     * so it is processed
     * @return String Where clause fragment
     */
    @testVisible private String getLdvWhereFirstChunk() {
        return 'WHERE Id >= \'' + startId + '\'';
    }

    /**
     * @description SOQL Query Fragment: Where LDV Where Clause for all chunks beyond the first should not
     * include the startId of the chunk, as it was already processed
     * @return String Where clause fragment
     */
    @testVisible private String getLdvWhereAfterFirstChunk() {
        return 'WHERE Id > \'' + startId + '\'';
    }

    /**
     * @description SOQL Query Fragment: Calculates the where clause for the inner or non LDV execution of the records
     * @return String Where clause fragment
     */
    @testVisible private String getQueryNonLDVWhereClause() {

        String whereClause = this.getWhereClause();

        Boolean hasMainWhereClause = String.isNotBlank(whereClause);
        Boolean hasAddtlWhereClause = String.isNotBlank(this.additionalWhereClause);
        if (hasMainWhereClause && hasAddtlWhereClause) {
            return '(' + whereClause.trim() + ') AND (' + this.additionalWhereClause.trim() + ')';
        } else if (hasMainWhereClause && !hasAddtlWhereClause) {
            return whereClause.trim();
        } else if (!hasMainWhereClause && hasAddtlWhereClause) {
            return this.additionalWhereClause.trim();
        } else {
            return '';
        }
    }

    /**
     * @description Indicates whether or not this is the first chunk when running in LDV Chunking mode.  Needed for LDV Chunking
     * mode execution, as the first query differs from the rest
     * @return Boolean true if the first chunk and false otherwise
     */
    @testVisible private Boolean isFirstChunk() {
        return (this.chunkIteration == 0);
    }

    /**
     * @description returns the Batch Size the Job was configured with
     * @return Integer Size of each batch of records for the job
     */
    public Integer getBatchSize() {
        return this.batchSize;
    }

    /**
     * @description execute method for the batch, overloaded to do an inner query when necessary and call doExecute with results of
     * either the inner query (if necessary, or the original records returned). doExecute will be the implementing batch
     * classes method instead of execute.
     * @param bc BatchableContext supplied by Salesforce
     * @param records Records returned by salesforce for each batch
     */
    public void execute(Database.BatchableContext bc, List<SObject> records) {

        // Id of last record in batch of records
        Id LastIdInScope = records[records.size() - 1].Id;
        // Record the last record in the list as the current "end" Id, if greater than our current end id value, or if currently unassigned
        this.currentEndId = (this.currentEndId == null || lastIdInScope > currentEndId) ? lastIdInScope : currentEndId;

        List<SObject> innerRecords = getInnerRecords(records);

        if ((innerRecords != null) && (innerRecords.size() > 0)) {
            doExecute(bc, innerRecords);
        }
    }

    /**
     * @description Either returns the records as is, if not executing in LDV Chunking mode, and no subquery was present in the field list,
     * or uses the records passed to execute the "inner query" with all the fields, any additional where clause, etc.
     * @param records Records returned by salesforce for each batch
     * @return List of records to pass to implementing "doExecute" method
     */
   @testVisible private List<SObject> getInnerRecords(List<SObject> records) {
        if (ldvMode || isSubQueryPresent()) {
            String whereClause = getQueryNonLdvWhereClause();
            String query = 'SELECT ' + getSOQLFullQueryFieldList() + ' FROM ' + getSObjectName() + ' WHERE (Id in :records) ' +
                        ((String.isNotBlank(whereClause)) ? ' AND (' + whereClause + ')' : '');

            return Database.query(query);
        } else { // No need to requery if not LDV Chunking mode
            return records;
        }
    }

    /**
     * @description Assembles a query using the object, fields, and parameters, where clause and additional where clause parameters,
     * with a limit of 1 record returned.  This will be used to allow the code to pre validate an additional where clause does not
     * break the batch without executing it, if needed.
     * @return String query to use for validation of batch query
     */
    @testVisible private String getQueryForValidate() {
        String whereClause = getQueryNonLdvWhereClause();
        return 'SELECT ' + getSOQLFullQueryFieldList() + ' FROM ' + getSObjectName() +
                ((String.isNotBlank(whereClause)) ? ' WHERE (' + whereClause + ')' : '') +
                ' LIMIT 1';
    }


    /**
     * @description Executes a query built with the fragments used by the batch to confirm there are no syntactical issues with either
     * the fields/subqueries, etc., the where clause, and the additional where clause if present.  If no errors are found will return ''.
     * If, however, executing the query causes an error, the text of error message will be returned to the caller.
     * @return Exception null, if successfully executed, or the exception that occurred.
     */
    public Exception validateQuery() {
        String query = getQueryForValidate();
        try {
            Database.query(query);
            return null;
        } catch(Exception e) {
            return e;
        }
    }

    /**
     * @description Apex Batch "finish" method called by Salesforce.  Overloaded to call doFinish, passing a boolean indicator to doFinish as
     * to whether it is completely finished (isComplete == true), or needs to execute the batch for additional chunks (isComplete == false).
     * It will also move the startId to the next chunk and re-execute the batch if needed.
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

        List<SObject> recs = Database.query ('SELECT Id FROM ' + getSObjectName() + ' ORDER BY Id ASC LIMIT 1');

        return ((recs != null) && (recs.size() > 0)) ? recs[0].Id : null;
    }

    /**
     * @description A query executed initially to determine the maximum id present in Salesforce (using DESC sort).  This and the start Id will used to determine whether
     * it is theoretically necessary to run in LDV Chunking mode
     * @return Id of last record found in System for object, sorting ids descending
     */
     private Id determineEndId() {
        List<SObject> recs = Database.query ('SELECT Id FROM ' + getSObjectName() + ' ORDER BY Id DESC LIMIT 1');

        return ((recs != null) && (recs.size() > 0)) ? recs[0].Id : null;
    }

    /**
     * @description Returns an indicator indicating whether or not a batch should execute in LDV Chunking mode.  Basically, if the theoretical record distance
     * exceeds either the maximum non LDV size allowed for the job or the LDV Chunk Size, it will return true, and false otherwise.  If the Ids are null, meaning there are no records present,
     * computeRecordDistance returns a negative number.  In all other cases, the record distance is a positive number.
     * @param startId Starting Id of the all records present in the object
     * @param endId Ending Id of the records in the object
     * @return Boolean true, if it appears to be an LDV Chunking circumstance, and false otherwise
     */
    @testVisible private boolean isLDVCircumstance(Id startId, Id endId) {
        Long recordDistance = UTIL_SalesforceID.computeRecordDistance(startId, endId);

        return (recordDistance > getMaxNonLDVSize());
    }

    /**
     * @description Returns a String name for the main object associated with this batch job
     * @return String name of the SObject, or null
     */
    @testVisible private String getSObjectName() {
        SObjectType sOT = this.getSObjectType();

        return (sOT != null) ? sOT.getDescribe().getName() : null;
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
     * @description Returns 1,000,000 by default for chunk size, but can be overriden by implementing class to return a different value
     * @return Integer chunk size to use when running in LDV Chunking mode
     */
    public virtual Integer getLDVChunkSize() {
        return DEFAULT_LDV_CHUNK_SIZE;
    }

    /**
     * @description Returns 1,000,000 by default for the maximum non LDV size, but can be overriden by implementing class to return a different value.  This value will be used
     * in the disctance check between the minimum and the maximum Id of the object when deciding whether to run in regular or LDV mode
     * @return Integer Maximum number of records that be present for the distance check before running in LDV mode
     */
    public virtual Integer getMaxNonLDVSize() {
        return DEFAULT_MAX_NON_LDV_SIZE;
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
     * @return SObjectType of main object to drive query
     */
    public abstract SObjectType getSObjectType();

    /**
     * Overridable method called from the start method for any implementing classes logic just prior to execution of start.  firstChunk will be true
     * if running in non LDV mode, or if it is the first chunk of the batch.  This can be used to trigger logic at the start of the batch, including
     * recording a timestamp for last executed to use in future batches
     * @param bc BatchableContext provided by Salesforce
     * @param firstChunk Boolean indicating this is the first execution of the start method.
     */
    public virtual void onStart(Database.BatchableContext bc, Boolean firstChunk) {

    }

    /**
     * Equivalent to the execute method of a standard batch class.
     * @param bc BatchableContext provided by Salesforce
     * @param records the records returned for that batch
     */
    public abstract void doExecute(Database.BatchableContext bc, List<SObject> records);

    /**
      * Overridable Where Clause to add to the inner query, or non LDV query, if not running in LDV/Chunking mode
      * @return String '' by default, can be overriden with a Where clause, excluding the word "Where"
      */
    public virtual String getWhereClause() {
        return '';
    }

    /**
     * A do nothing equivalent to the finish method of a standard batch class.  Can be overriden by the implementing class.
     * @param bc BatchableContext provided by Salesforce
     * @param isComplete Boolean value indicating whether the batch job is completely finished or must reexecute for additional chunks
     */
    public virtual void doFinish(Database.BatchableContext bc, boolean isComplete) {

    }
}