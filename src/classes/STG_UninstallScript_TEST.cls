@isTest
public with sharing class STG_UninstallScript_TEST {

    public testmethod static void rununinstall() {
    	//The scheduled jobs are being set when the settings page loads
    	STG_SettingsManager_CTRL ctrl = new STG_SettingsManager_CTRL(); 
    	ctrl.setTriggerSchedConfig();
    	
    	//Check jobs were scheduled
    	List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name IN :UTIL_MasterSchedulableHelper.scheduledJobs and CronJobDetail.JobType = '7'];
    	System.assertEquals(3, scheduledJobs.size());
    	
    	//Run uninstall script
    	Test.testUninstall(new STG_UninstallScript());
    	
    	//Confirm scheduled job was deleted
    	scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name IN :UTIL_MasterSchedulableHelper.scheduledJobs  and CronJobDetail.JobType = '7'];
        System.assertEquals(0, scheduledJobs.size());
    }
}