@isTest
public with sharing class STG_UninstallScript_TEST {

    public testmethod static void rununinstall() {
    	//Run install script
    	Test.testInstall(new STG_InstallScript(), null);
    	
    	//Check job was scheduled
    	List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name = :UTIL_GlobalSchedulable.jobName and CronJobDetail.JobType = '7'];
    	System.assertEquals(1, scheduledJobs.size());
    	
    	//Run uninstall script
    	Test.testUninstall(new STG_UninstallScript());
    	
    	//Confirm scheduled job was deleted
    	scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name = :UTIL_GlobalSchedulable.jobName and CronJobDetail.JobType = '7'];
        System.assertEquals(0, scheduledJobs.size());
    }
}