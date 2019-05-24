/*
    Copyright (c) 2014 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @description Performance Analysis Logging class for the Batch Data Importer.
*/
public with sharing class BDI_PerfLogger extends UTIL_PerfLogger {

    public static final string METHOD = UTIL_PerfLogger.METHOD;
    public static final string QUERY = UTIL_PerfLogger.QUERY;
    private Id batchId;

    /*******************************************************************************************************
    * @description constructor, that starts the logger's timer for the given Batch
    * @param batchId the NPSP Data Import batch to be analyzed
    * @param countRecords the number of records that will be analyzed
    */
    public BDI_PerfLogger(ID batchId, Integer countRecords) {
        super(countRecords);
        this.batchId = batchId;
    }

    /*******************************************************************************************************
    * @description override-able factory for create a new PerfLog class, thus allowing us to create a new
    * BDI_PerfLogger.PerfLog
    * @return UTIL_PerfLogger.PerfLog, a newly constructed PerfLog (BDI subclass)
    */
    public override UTIL_PerfLogger.PerfLog perfLogFactory() {
        return new PerfLog();
    }

    /*******************************************************************************************************
    * @description creates or updates an existing METHOD PerfLog for the supplied label, and starts its timer.
    * @param label the label for the new PerfLog (typically a method name)
    * @return PerfLog, a new or updated PerfLog
    */
    public PerfLog newPerfLog(String label) {
        return newPerfLog(label, METHOD);
    }

    /*******************************************************************************************************
    * @description creates or updates an existing PerfLog for the supplied label, and starts its timer.
    * @param label the label for the new PerfLog (typically a method name)
    * @param logType the type of Log, either METHOD or QUERY
    * @return PerfLog, a new or updated PerfLog
    */
    public PerfLog newPerfLog(String label, String logType) {
        Perflog pl = (PerfLog)super.newPerfLog('BDI', label, logType);
        SObject sobj = pl.getPerfLogSObject();
        if (sobj != null) {
            sobj.put('BDI_Batch__c', batchId);
        }
        return pl;
    }

    /*******************************************************************************************************
    * @description BDI's subclass of a specific PerfLog record.  while this subclass adds no additional
    * members or methods, it allows BDI code to use a BDI_PerfLogger, and not know or care about the
    * superclass UTIL_PerfLogger.
    */
    public with sharing class PerfLog extends UTIL_PerfLogger.PerfLog {

        /*******************************************************************************************************
        * @description constructor
        */
        public PerfLog() {
            super();
        }
    }
}