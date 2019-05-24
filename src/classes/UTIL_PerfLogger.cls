/*
    Copyright (c) 2017 Salesforce.org
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
* @group Utilities
* @description Performance Analysis Logging class for NPSP.
*/
public virtual with sharing class UTIL_PerfLogger {

    public static final string METHOD = 'method';
    public static final string QUERY = 'query';

    private Integer countRecords;
    private Long tmStart;
    private Long tmEnd;
    private Map<String, PerfLog> mapPerfLogByComponentLabel;

    /*******************************************************************************************************
    * @description constructor, that starts the logger's timer
    * @param countRecords the number of records that will be analyzed
    */
    public UTIL_PerfLogger(Integer countRecords) {
        tmStart = System.currentTimeMillis();
        this.countRecords = countRecords;
        mapPerfLogByComponentLabel = new Map<String, PerfLog>();
    }

    /*******************************************************************************************************
    * @description stops the loggers timer
    * @return void
    */
    public void stop() {
        tmEnd = System.currentTimeMillis();
    }

    /*******************************************************************************************************
    * @description override-able factory for create a new PerfLog class, thus allowing subclasses of the
    * PerfLogger to have their own subclass of PerfLog as well.
    * @return PerfLog, a newly constructed PerfLog
    */
    public virtual PerfLog perfLogFactory() {
        return new PerfLog();
    }

    /*******************************************************************************************************
    * @description creates or updates an existing PerfLog for the supplied component and label, and starts
    * its timer.
    * @param component the component using this PerfLog
    * @param label the label for the new PerfLog (typically a method name)
    * @param logType the type of PerfLog
    * @return PerfLog, a new or updated PerfLog
    */
    public virtual PerfLog newPerfLog(String component, String label, String logType) {
        // see if we already have a log for this component:label
        PerfLog pl = mapPerfLogByComponentLabel.get(component + ':' + label);
        if (pl == null) {
            pl = perfLogFactory();
            pl.initPerfLog(component, label, logType, countRecords);
            mapPerfLogByComponentLabel.put(component + ':' + label, pl);
        }
        pl.start();
        return pl;
    }

    /*******************************************************************************************************
    * @description prepares all perfLogs for this PerfLogger, and saves them to the database
    * @return void
    */
    public void save() {
        if (tmEnd == null) {
            stop();
        }
        Long loggerDuration = tmEnd - tmStart;
        List<SObject> listPL = new list<SObject>();
        for (PerfLog pl : mapPerfLogByComponentLabel.values()) {
            SObject sobj = pl.prepare(loggerDuration);
            if (sobj != null) {
                listPL.add(sobj);
            }
        }

        if (listPL.size() > 0) {
            insert listPL;
        }
    }

    /*******************************************************************************************************
    * @description we attempt to dynamically see if the PerfLog__c object exists (either in our namespace
    * or without a namespace).
    */
    private static boolean hasTriedSchemaPerfLog = false;
    private static Schema.SObjectType sObjectTypePerfLog {
        get {
            if (!hasTriedSchemaPerfLog) {
                // first we try in our namespace, and then without a namespace
                sObjectTypePerfLog = Schema.getGlobalDescribe().get(UTIL_Namespace.StrTokenNSPrefix('PerfLog__c'));
                if (sObjectTypePerfLog == null) {
                    sObjectTypePerfLog = Schema.getGlobalDescribe().get('PerfLog__c');
                }
                hasTriedSchemaPerfLog = true;
            }
            return sObjectTypePerfLog;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description encapsulates a specific PerfLog record
    */
    public virtual with sharing class PerfLog {

        private SObject plSObject;
        private Long tmStart;
        private Long tmEnd;

        /*******************************************************************************************************
        * @description the total times this PerfLog has been started
        */
        public Integer countCalls { get; private set; }

        /*******************************************************************************************************
        * @description the total duration the PerfLog's timer has been running
        */
        public Long duration { get; private set; }

        /*******************************************************************************************************
        * @description constructor
        */
        public PerfLog() {

            // dyamically create a PerfLog__c if it exists.
            if (sObjectTypePerfLog != null) {
                plSObject = sObjectTypePerfLog.newSObject();
            }

            countCalls = 0;
            duration = 0;
        }

        /*******************************************************************************************************
        * @description initializes PerfLog data
        * @param component the component using this PerfLog
        * @param label the label for the new PerfLog (typically a method name)
        * @param logType the type of PerfLog
        * @param countRecords the number of records being operated on during this PerfLog
        * @return void
        */
        public void initPerfLog(String component, String label, String logType, Integer countRecords) {
            if (plSObject != null) {
                plSObject.put('Component__c', component);
                plSObject.put('label__c', label);
                plSObject.put('Log_Type__c', logType);
                plSObject.put('Number_of_Records__c', countRecords);
            }
        }

        /*******************************************************************************************************
        * @description returns the underlying SObject encapsulated by the PerfLog
        * @return SObject
        */
        public SObject getPerfLogSObject() {
            return plSObject;
        }

        /*******************************************************************************************************
        * @description starts the PerfLog's timer
        * @return void
        */
        public void start() {
            tmStart = System.currentTimeMillis();
            countCalls++;
        }

        /*******************************************************************************************************
        * @description stops the PerfLog's timer, and adds to its duration
        * @return void
        */
        public void stop() {
            tmEnd = System.currentTimeMillis();
            duration += tmEnd - tmStart;
        }

        /*******************************************************************************************************
        * @description prepares data in the PerfLog before it can be saved, stopping the timer if needed
        * @param durationParent the elapsed time of the entire parent operation
        * @return SObject the SObject to save in the database
        */
        private SObject prepare(Long durationParent) {
            if (tmEnd == null) {
                stop();
            }
            if (plSObject != null) {
                plSObject.put('Duration__c', (Double)duration);
                plSObject.put('Number_of_Calls__c', countCalls);
                plSObject.put('Parent_Duration__c', (Double)durationParent);
            }
            return plSObject;
        }
    }

}