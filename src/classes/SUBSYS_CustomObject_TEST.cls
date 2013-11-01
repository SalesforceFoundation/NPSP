@isTest
public with sharing class SUBSYS_CustomObject_TEST {

	public static testmethod void integrationTest() {
		//Define which classes (and in which order) should run when a change is made to
		//a record our test trigger is pointing to
		
		//The SYBSYS_SampleClass should be run when a new record of type Campaign is inserted
		//or updated
		
		//Make a change that makes our test trigger run
		Test.startTest();
		insert new Campaign(Name='TestCampaign');
		Test.stopTest();
		
		//Verify that the class run - that is, that the database change that the class makes
		//was performed
	}
}