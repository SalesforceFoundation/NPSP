/*
    Copyright (c) 2012, Salesforce.org
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
* @date 2012 (2.0)
* @group Utilities
* @description The controller for the job progress indicator vf component
*/
public with sharing class UTIL_JobProgress_CTRL {

    /**
     * @description Allows the page component to only display jobs started since the component was loaded. Needs to
     * be a string to work properly in JavaScript when passing back into this controller through JS remoting
     */
    public String batchJobStartTimeString {
        get {
            if (batchJobStartTimeString == null) {
                batchJobStartTimeString = Datetime.now().addMinutes(-1).format();
            }
            return batchJobStartTimeString;
        } private set;
    }

    public List<BatchJob> batchJobs;
    public UTIL_JobProgress_CTRL.BatchJob bj {
        get{
            //just kickoff the getter for batchJobs since it will properly populate the bj var for
            // us w/o needing new logic
            getBatchJobs();
            return bj;
        }
        set;
    }

    public Integer numberOfJobs {get; set;}
    public String batchComponentLabel {get; set;}
    public Boolean rerenderoncomplete {get; set;}
    
    public Boolean hasExtendedStatus {
        get {
            //ensure bj loaded!
            if (bj != null) {
                return hasExtendedStatus;
            } else {
                return false;
            }
        }
        set;
    }

    public Boolean allCompleted { 
        get {
           // ensure bj loaded!
           if (bj != null) {
               return allCompleted;
           } else {
               return true;
           }
        }
        set;
    }

    /**
     * @description Initialize the set of batch jobs to be displayed in the component
     * @return List<BatchJob> collection
     */
    public List<BatchJob> getBatchJobs() {
        // Create new list of BatchJobs, a wrapper class that includes the job and percent complete.
        this.batchJobs = new List<BatchJob>();
        this.hasExtendedStatus = false;
        this.allCompleted = false;

        // If number of jobs was not defined, default to 20
        if(this.numberOfJobs== null || this.numberofJobs <= 0) {
            this.numberofJobs = 20;
        }

        if(this.rerenderoncomplete == null)
            this.rerenderoncomplete = false;

        if(this.batchComponentLabel== null) {
            this.batchComponentLabel = 'Batch Apex Jobs';
        }

        Datetime batchJobStartDT = Datetime.parse(batchJobStartTimeString);
        Id currUserId = UserInfo.getUserId();

        Integer completedCount = 0;
        //Query the Batch apex jobs, excluding skew dispatcher jobs (unless the skew mode job is in holding status)
        String skewDispatcherClassName =  CRLP_SkewDispatcher_BATCH.class.getName();
        skewDispatcherClassName = (skewDispatcherClassName.contains('__') ? skewDispatcherClassName.split('__')[1] : skewDispatcherClassName);
        for (AsyncApexJob a : [SELECT TotalJobItems, Status, ExtendedStatus, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id,
                                    CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name, CreatedBy.Name
                                    FROM AsyncApexJob
                                    WHERE JobType='BatchApex'
                                    AND (ApexClass.Name != :skewDispatcherClassName
                                        OR (ApexClass.Name = :skewDispatcherClassName AND Status = 'Holding'))
                                    AND CreatedDate >= :batchJobStartDT
                                    AND CreatedById = :currUserId
                                    ORDER BY CreatedDate DESC, Id LIMIT :numberOfJobs]) {

            BatchJob j = new BatchJob(a);

            if (!String.isEmpty(a.ExtendedStatus)) {
                this.hasExtendedStatus = true;
            }

            if (a.Status == 'Completed') {
                completedCount++; 
            }

            batchJobs.add(j);
        }
        if (completedCount == this.numberOfJobs) {
            this.allCompleted = true;
        }
        if (!batchJobs.isEmpty()) {
            this.bj = batchJobs[0];
        }

        return batchJobs;
    }

    //This is the wrapper class the includes the job itself and a value for the percent complete
    public class BatchJob {
        public AsyncApexJob job {get; set;}
        public Long percentComplete {get; set;}
		
        /**
         * @description Construct from an AsyncApexJob object.  This will
         * extract information from the AsyncApexJob and store it in this class
         * to be serialized, including calculating the percentage of the batch
         * job completed.
         *
         * @param job The AsyncApexJob to gather data from
         */
        public BatchJob(AsyncApexJob job) {
            Integer itemsProcessed = job.JobItemsProcessed;
            Integer totalItems = job.TotalJobItems;
            this.job = job;
            // Determine the percent complete based on the number of batches complete
            this.percentComplete = calculatePercentCompleted(itemsProcessed, totalItems, job.Status);
        }
    }

    /**
     * @description A RemoteAction method for querying the AsyncApexJob table.
     *
     * @param numberOfJobs The limit of number of jobs that should be returned in the query
     * @param batchJobStartString Only retrieve jobs started after this timestamp and started by the current user
     * @return List<BatchJobStatus>
     */
    @RemoteAction
    public static List<BatchJobStatus> getBatchJobsStatus(Integer numberOfJobs, String batchJobStartString) {
        List<AsyncApexJob> jobs = new List<AsyncApexJob>();
        List<BatchJobStatus> jobsStatus = new List<BatchJobStatus>();

        Datetime batchJobStartDT = Datetime.parse(batchJobStartString);
        Id currUserId = UserInfo.getUserId();

        String skewDispatcherClassName =  CRLP_SkewDispatcher_BATCH.class.getName();
        skewDispatcherClassName = (skewDispatcherClassName.contains('__') ? skewDispatcherClassName.split('__')[1] : skewDispatcherClassName);
        jobs = [
            SELECT ApexClass.Name, CreatedBy.Name, CreatedDate, Status, ExtendedStatus, CompletedDate, JobItemsProcessed,
                TotalJobItems, NumberOfErrors
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND (ApexClass.Name != :skewDispatcherClassName
                    OR (ApexClass.Name = :skewDispatcherClassName AND Status = 'Holding'))
                AND CreatedDate >= :batchJobStartDT
                AND CreatedById = :currUserId
            ORDER BY CreatedDate DESC
            LIMIT :numberOfJobs
        ];

        for (AsyncApexJob job : jobs) {
            jobsStatus.add(new BatchJobStatus(job));
        }

        return jobsStatus;
    }

    /**
     * @description inner class used to serialize information queried from the AsyncApexJob table.
     */
    public class BatchJobStatus {
        public String className;
        public String createdByName;
        public Datetime createdDate;
        public String status;
        public String extendedStatus;
        public Datetime completedDate;
        public Integer jobItemsProcessed;
        public Integer totalJobItems;
        public Integer numberOfErrors;
        public Long percentCompleted;

        /**
         * @description Construct from an AsyncApexJob object.  This will
         * extract information from the AsyncApexJob and store it in this class
         * to be serialized, including calculating the percentage of the batch
         * job completed.
         *
         * @param job The AsyncApexJob to gather data from
         */
        public BatchJobStatus(AsyncApexJob job) {
            className = job.ApexClass.Name;
            createdByName = job.CreatedBy.Name;
            createdDate = job.CreatedDate;
            status = job.Status;
            extendedStatus = job.ExtendedStatus;
            completedDate = job.CompletedDate;
            jobItemsProcessed = job.JobItemsProcessed;
            totalJobItems = job.TotalJobItems;
            numberOfErrors = job.NumberOfErrors;

            percentCompleted = calculatePercentCompleted(jobItemsProcessed, totalJobItems, status);
        }
    }

    /**
     * @description Calculate the percentage of the batch job completed.
     * This method maps certain job "Status" values to specified
     * percentages to, for example, show some progress when the job is
     * Queued, and more progress when Preparing, etc.
     *
     * @param jobItemsProcessed The number of job items processed, so far
     * @param totalJobItems The total number of job items in the batch job
     * @param status The status of the job.  Relevant values are "Completed", "Queued", and "Preparing".
     * @return Long (The percentage as a value between 5 and 100).
     */
    private static Long calculatePercentCompleted(Integer jobItemsProcessed, Integer totalJobItems, String status) {
        Long percentCompleted = 5;

        switch on (status) {
            when 'Completed' {
                percentCompleted = 100;
            }
            when 'Preparing' {
                percentCompleted = 10;
            }
            when 'Queued', 'Holding' {
                percentCompleted = 5;
            }
            when else {
                if (totalJobItems != 0) {

                    percentCompleted = Math.max(
                            Math.roundToLong(100 * jobItemsProcessed / totalJobItems),
                            5
                    );
                    // Don't let it go backwards from preparing/queued
                    if (percentCompleted == 0) {
                        percentCompleted = 5;
                    }
                }
            }
        }

        return percentCompleted;
    }
}