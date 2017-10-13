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
public with sharing class BDI_PerfLogger {

    public static final string METHOD = 'method';
    public static final string QUERY = 'query';

    private List<PerfLog> perflogs;
    private Id batchId;
    private Integer countRecords;
    private Long tmStart;
    private Long tmEnd;

    public BDI_PerfLogger(ID batchId, Integer countRecords) {
        tmStart = System.now().getTime();
        perfLogs = new List<PerfLog>();
        this.batchId = batchId;
        this.countRecords = countRecords;
    }

    public void stop() {
        tmEnd = System.now().getTime();
    }

    public PerfLog newPerfLog(String label) {
        return newPerfLog(label, METHOD);
    }

    public PerfLog newPerfLog(String label, String logType) {
        PerfLog pl = new PerfLog('BDI', batchId, label, logType, countRecords);
        perfLogs.add(pl);
        return pl;
    }

    public void save() {
        Long duration = tmEnd - tmStart;
        List<PerfLog__c> listPL = new list<PerfLog__c>();
        for (PerfLog pl : perfLogs) {
            listPL.add(pl.prepare(duration));
        }

        insert listPL;
    }

    public with sharing class PerfLog {

        private PerfLog__c pl;
        private Long tmStart;
        private Long tmEnd;
        private Long durationParent;

        PerfLog(String component, ID batchId, String label, String logType, Integer countRecords) {
            pl = new PerfLog__c();
            tmStart = System.now().getTime();
            pl.Component__c = component;
            pl.BDI_Batch__c = batchId;
            pl.label__c = label;
            pl.Log_Type__c = logType;
            pl.Number_of_Records__c = countRecords;
        }

        public void stop() {
            tmEnd = System.now().getTime();
        }

        public PerfLog__c prepare(Long durationParent) {
            if (tmEnd == null) {
                stop();
            }
            pl.Duration__c = tmEnd - tmStart;
            pl.Parent_Duration__c = durationParent;
            return pl;
        }
    }


}