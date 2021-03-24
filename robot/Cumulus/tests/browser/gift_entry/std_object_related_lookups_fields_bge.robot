*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
	[Documentation]		  Creates leads, contact and account via API and sets template name and NS
	&{CONTACT} =          API Create Contact    FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{CONTACT}
	&{ACCOUNT} =          API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{ACCOUNT}
	#Create lead records with first name, last name, and company name
	&{DEFAULT_LEAD} =     API Create Lead		FirstName=${faker.first_name()}    LastName=${faker.last_name()}	Company=Default Lead, Inc.
	Set suite variable    ${DEFAULT_LEAD}
	&{FIRST_LEAD} =       API Create Lead		FirstName=${faker.first_name()}	   LastName=${faker.last_name()}	Company=First Lead, Inc.
	Set suite variable    ${FIRST_LEAD}
	&{SECOND_LEAD} =      API Create Lead		FirstName=${faker.first_name()}	   LastName=${faker.last_name()}	Company=Second Lead, Inc.
	Set suite variable    ${SECOND_LEAD}
	${TEMPLATE_NAME} =    Generate Random String
	Set suite variable    ${TEMPLATE_NAME}
	${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}


*** Test Cases ***
Verify Fields Related to Lookups Populate on Batch Gift Entry Form
	[Documentation]          After creating required data via API, create a object group and field mappings for Lead fields.
	...						 create template with lead fields, set batch level default for leadlookup while creating the batch using template
	...						 and verify that other related fields automatically load on the gift entry form. Remove default from batch and verify
	...						 leads fields are not autopopulated. Create a gift using new lead in lookup and verify correct related values load
	...						 automatically and on save batch table has correct lead values. create another gift with different lead and verify
	...						 lead values load and save correctly. Open previous gift from table and verify correct lead info loads on form
	[tags]                                        feature:GE        W-043224
	# Create object and field mappings in Advanced Mapping
	Click Configure Advanced Mapping
	Create New Object Group                       Lead
	...                                           objectName=Lead (Lead)
	...                                           relationshipToPredecessor=Child
	...                                           ofThisMappingGroup=Account 1
	...                                           throughThisField=Account Lookup (Account_Lookup__c)
	...                                           importedRecordFieldName=Lead Lookup (Lead_Lookup__c)
	...                                           importedRecordStatusFieldName=Lead Imported Status (Lead_Imported_Status__c)
	View Field Mappings Of The Object             Lead
	Create Mapping If Doesnt Exist                Lead Company (Lead_Company__c)  	  	Company (Company)
	Create Mapping If Doesnt Exist                Lead Last Name (Lead_Last_Name__c)    Last Name (LastName)
	Reload Page
	#Create a template with newly mapped lead lookup, company and lastname fields and add fields to batch table
	Go To Page                                    Landing                GE_Gift_Entry
	Click Link                                    Templates
	Click Gift Entry Button                       Create Template
	Current Page Should Be                        Template               GE_Gift_Entry
	Enter Value In Field
	...                                           Template Name=${TEMPLATE_NAME}
	...                                           Description=This template is created by an automation script.
	Click Gift Entry Button                       Next: Form Fields
	Perform Action on Object Field                select  				 Lead           Lead Lookup
	Perform Action on Object Field                select  				 Lead           Company
	Perform Action on Object Field                select  				 Lead           Last Name
	Click Gift Entry Button						  Next: Batch Settings
	Add Batch Table Columns          		      Lead: Company     	 Lead: Last Name       Data Import: Lead Lookup
	Click Gift Entry Button          			  Save & Close
	Current Page Should Be           			  Landing                GE_Gift_Entry
	Click Link                                	  Templates
    Wait Until Page Contains                  	  ${TEMPLATE_NAME}
    Store Template Record Id                  	  ${TEMPLATE_NAME}
	#create a batch with new template and set a batch level default for lead lookup and verify other lead fields autopopulate on form load
	Click Gift Entry Button          			  New Batch
	Wait Until Modal Is Open
    Select Template                      		  ${TEMPLATE_NAME}
    Load Page Object                     		  Form                   Gift Entry
    Fill Gift Entry Form
    ...                                  		  Batch Name=Lookups Test Automation Batch
    ...                                  		  Batch Description=This is a test batch created via automation script
    Click Gift Entry Button              		  Next
	Fill Gift Entry Form				 		  Lead Lookup=${DEFAULT_LEAD}[Name]
    Click Gift Entry Button              		  Save
    Current Page Should Be               		  Form                   Gift Entry		title=Gift Entry Form
    ${batch_id} =                        		  Save Current Record ID For Deletion   ${NS}DataImportBatch__c
	Verify Field Default Value
	...											  Lead Lookup=${DEFAULT_LEAD}[Name]
    ...                              	 		  Lead: Company=${DEFAULT_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${DEFAULT_LEAD}[LastName]
	#edit batch info and remove default lead and verify form is clear when loaded
	Click Gift Entry Button						  Edit Batch Info
	Click Gift Entry Button              		  Next
	Clear Lookup Value							  Data Import: Lead Lookup
	Click Gift Entry Button              		  Wizard Save
	Wait Until Modal Is Closed
    Current Page Should Be               		  Form                   Gift Entry		title=Gift Entry Form
	Page Should Not Contain						  ${DEFAULT_LEAD}[Name]
	Page Should Not Contain						  ${DEFAULT_LEAD}[Company]
	Page Should Not Contain						  ${DEFAULT_LEAD}[LastName]
	#create a new gift with first lead and verify related fields autopopulate and save to table correctly
	Fill Gift Entry Form
    ...                                  		  Data Import: Donation Donor=Contact1
    ...                                  		  Data Import: Contact1 Imported=${CONTACT}[Name]
	...                                  		  Opportunity: Amount=5
    ...                                  	      Opportunity: Close Date=Today
	...											  Lead Lookup=${FIRST_LEAD}[Name]
	Verify Field Default Value
    ...                              	 		  Lead: Company=${FIRST_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${FIRST_LEAD}[LastName]
    Click Gift Entry Button                       Save & Enter New Gift
	Verify Table Field Values         			  ${CONTACT}[Name]   True
    ...											  Data Import: Lead Lookup=${FIRST_LEAD}[Name]
    ...                              	 		  Lead: Company=${FIRST_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${FIRST_LEAD}[LastName]
	#create a new gift with second lead and verify related fields autopopulate and save to table correctly
	Fill Gift Entry Form
    ...                                  		  Data Import: Donation Donor=Account1
    ...                                  		  Data Import: Account1 Imported=${ACCOUNT}[Name]
	...                                  		  Opportunity: Amount=10
    ...                                  	      Opportunity: Close Date=Today
	...											  Lead Lookup=${SECOND_LEAD}[Name]
	Verify Field Default Value
    ...                              	 		  Lead: Company=${SECOND_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${SECOND_LEAD}[LastName]
    Click Gift Entry Button                       Save & Enter New Gift
	Verify Table Field Values         			  ${ACCOUNT}[Name]   True
    ...											  Data Import: Lead Lookup=${SECOND_LEAD}[Name]
    ...                              	 		  Lead: Company=${SECOND_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${SECOND_LEAD}[LastName]
	#open first gift from the gifts table and verify first lead info is loaded in the form
	Perform Action On Datatable Row   			  ${CONTACT}[Name]          Open
	Verify Field Default Value
	...											  Lead Lookup=${FIRST_LEAD}[Name]
    ...                              	 		  Lead: Company=${FIRST_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${FIRST_LEAD}[LastName]