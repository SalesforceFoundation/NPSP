/*
    Copyright (c) 2012, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2012 (2.0)
* @description The controller for the VF progress indicator component used in recurring donation update  
*/
public with sharing class UTIL_JobProgress_CTRL {
 
    public List<BatchJob> batchJobs;
    public Integer numberOfJobs {get; set;}
    public String batchComponentLabel {get; set;}
    public Boolean rerenderoncomplete {get; set;}
 
 
    public List<BatchJob> getBatchJobs() {
        //Create new list of BatchJobs, a wrapper class that includes the job and percent complete.
        batchJobs = new List<BatchJob>();
     
        //If number of jobs was not defined, default to 20
        if(numberOfJobs== null || numberofJobs <= 0) {
            numberofJobs = 20;
        }
        
        if(rerenderoncomplete == null)
            rerenderoncomplete = false;
        
        if(batchComponentLabel== null) {
            batchComponentLabel = 'Batch Apex Jobs';
        }
 
        //Query the Batch apex jobs
        for(AsyncApexJob a : [select TotalJobItems, Status, ExtendedStatus, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, 
                                    CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name 
                                    From AsyncApexJob where JobType='BatchApex' order by CreatedDate desc limit :numberOfJobs]) {
            Double itemsProcessed = a.JobItemsProcessed;
            Double totalItems = a.TotalJobItems;
 
            BatchJob j = new BatchJob();
            j.job = a;
 
            //Determine the pecent complete based on the number of batches complete
            if(a.status == 'Completed') {
                j.percentComplete = 100;
            //Determine the pecent complete based on the number of batches complete
            } else if (totalItems == 0) {
                //A little check here as we don't want to divide by 0.
                j.percentComplete = 0;
            } else {
                j.percentComplete = ((itemsProcessed  / totalItems) * 100.0).intValue();
            }
 
            batchJobs.add(j);
        }
        
        return batchJobs;
    }
 
    //This is the wrapper class the includes the job itself and a value for the percent complete
    public Class BatchJob{
        public AsyncApexJob job {get; set;}
        public Integer percentComplete {get; set;}
    }
 

}