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
* @description This class is meant to be inherited by batch jobs requiring enhanced batch
* functionality, including LDV Support
*/
public abstract with sharing class UTIL_AbstractCommon_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer MAX_LDV_CHUNK_SIZE = 99999;
    private static final Integer DEFAULT_BATCH_SIZE = 500;
    private String additionalWhereClause;
    private Id startId;
    private Id endId;
    private Id currentEndId;
    private Object obj;
    private Boolean endReached;
    private Integer batchSize;
    private Integer chunkIteration;

    // Think about initializing Start Id to first possible id in object using id computation from pkChunk.
    public UTIL_AbstractCommon_BATCH() {
        // AdditionalWhereClause, startId, endId, ldvModeEnabled, ldvChunkSize, obj
        this('', null, null, null, DEFAULT_BATCH_SIZE);
    }

    public UTIL_AbstractCommon_BATCH(String additionalWhereClause) {
        // AdditionalWhereClause, startId, endId, ldvModeEnabled, ldvChunkSize, obj
        this(additionalWhereClause, null, null, null, DEFAULT_BATCH_SIZE);
    }

    public UTIL_AbstractCommon_BATCH(Integer batchSize) {
        // AdditionalWhereClause, startId, endId, ldvModeEnabled, ldvChunkSize, obj
        this('', null, null, null, batchSize);
    }

    public UTIL_AbstractCommon_BATCH(String additionalWhereClause, Integer batchSize) {
        // AdditionalWhereClause, startId, endId, ldvModeEnabled, ldvChunkSize, obj
        this(additionalWhereClause, null, null, null, batchSize);
    }

    public UTIL_AbstractCommon_BATCH(String additionalWhereClause, Object obj) {
        // AdditionalWhereClause, startId, endId, ldvModeEnabled, ldvChunkSize, obj
        this(additionalWhereClause, null, null, obj, DEFAULT_BATCH_SIZE);
    }

    public UTIL_AbstractCommon_BATCH(String additionalWhereClause, Object obj, Integer batchSize) {
        // AdditionalWhereClause, startId, endId, ldvModeEnabled, ldvChunkSize, obj
        this(additionalWhereClause, null, null, obj, batchSize);
    }

    public UTIL_AbstractCommon_BATCH(String additionalWhereClause, Id startId, Id endId, Object obj, Integer batchSize) {
        this.additionalWhereClause = additionalWhereClause;
        this.startId = startId;
        this.endId = endId;
        this.obj = obj;
        this.endReached = false;
        this.batchSize = batchSize;
        this.chunkIteration = 0;
    }

    public Database.Querylocator start(Database.BatchableContext bc) {

        if (startId == null) {
            this.startId = determineStartId();
            this.endId = determineEndId();
        }

        Database.QueryLocator ql = null;
        Database.QueryLocatorIterator qli = null;

        if (startId != null) {
            ql = Database.getQueryLocator(getQuery(startId));
            qli = (ql != null) ? ql.iterator() : null;
        }

        if ((qli == null) || (!qli.hasNext())) {
            ql = Database.getQueryLocator(getQueryLimitZero());
            this.endReached = true;
        }

        return ql;
    }

    private String getQueryLimitZero() {
        return 'SELECT ID FROM ' + getSOQLObjectName() + ' LIMIT 0';
    }


    private String getQuery(Id startId) {
        if (isFirstChunk()) {
            return 'SELECT ID FROM ' + getSOQLObjectName() + ' WHERE Id >= \'' + startId + '\' ORDER BY ID ASC LIMIT ' + getLDVChunkSize();
        } else {
            return 'SELECT ID FROM ' + getSOQLObjectName() + ' WHERE Id > \'' + startId + '\' ORDER BY ID ASC LIMIT ' + getLDVChunkSize();
        }
    }

    private Boolean isFirstChunk() {
        return (this.chunkIteration == 0);
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {

        // Record the last record in the list as the current "end" Id.
        this.currentEndId = records[records.size() - 1].Id;

        List<SObject> innerRecords = getInnerRecords(records);

        if ((innerRecords != null) && (innerRecords.size() > 0)) {
            doExecute(bc, innerRecords);
        }
    }

    private List<SObject> getInnerRecords(List<SObject> records) {

        String query = 'SELECT ' + getSOQLInnerQueryFieldList() + ' FROM ' + getSOQLObjectName() + ' WHERE Id in :records ' +
                       (((this.additionalWhereClause != null) && (this.additionalWhereClause.trim().length() > 0)) ? 'and (' + this.additionalWhereClause + ')' : '');

        return Database.query(query);
    }

    public void finish(Database.BatchableContext bc) {
        if ((!this.endReached) && (this.currentEndId != this.endId)) {
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

    private Id determineStartId() {
        Id startId = null;

        String queryString = 'SELECT ID FROM ' + getSOQLObjectName() + ' ORDER BY ID ASC LIMIT 1';
        List<SObject> recs = Database.query (queryString);
        if ((recs != null) && (recs.size() > 0)) {
            startId = recs[0].Id;
        }
        return startId;
    }

    private Id determineEndId() {
        Id endId = null;

        String queryString = 'SELECT ID FROM ' + getSOQLObjectName() + ' ORDER BY ID DESC LIMIT 1';
        List<SObject> recs = Database.query (queryString);
        if ((recs != null) && (recs.size() > 0)) {
        endId = recs[0].Id;
        }
        return endId;
    }

    public virtual Integer getLDVChunkSize() {
        return MAX_LDV_CHUNK_SIZE;
    }

    public virtual String getSOQLInnerQueryFieldList() {
        return 'ID';
    }

    public abstract String getSOQLObjectName();
    public abstract void doExecute(Database.BatchableContext bc, List<SObject> records);
    public abstract void doFinish(Database.BatchableContext bc, boolean isComplete);


}