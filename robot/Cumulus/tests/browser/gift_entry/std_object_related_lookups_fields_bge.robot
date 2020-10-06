*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
	[Documentation]			Creates fields on Lead and NPSP Data Import objects
	...						creates a lead via API and sets template name and NS
	Create Customfield In Object Manager
	...                                                    Object=Lead
	...                                                    Field_Type=Lookup
	...                                                    Related_To=Account
	...                                                    Field_Name=Account Lookup

	Create Customfield In Object Manager
	...                                                    Object=NPSP Data Import
	...                                                    Field_Type=Text
	...                                                    Field_Name=Lead Imported Status

	Create Customfield In Object Manager
	...                                                    Object=NPSP Data Import
	...                                                    Field_Type=Text
	...                                                    Field_Name=Lead Company

	Create Customfield In Object Manager
	...                                                    Object=NPSP Data Import
	...                                                    Field_Type=Text
	...                                                    Field_Name=Lead Last Name

	Create Customfield In Object Manager
	...                                                    Object=NPSP Data Import
	...                                                    Field_Type=Lookup
	...                                                    Related_To=Lead
	...                                                    Field_Name=Lead Lookup

	#Create lead record with first name, last name, and company name
	&{OPP_LEAD} =         API Create Lead
	...                   FirstName=${faker.first_name()}
	...                   LastName=${faker.last_name()}
	...                   Company=Generated Leads, Inc.
	Set suite variable    ${OPP_LEAD}
	${TEMPLATE_NAME} =    Generate Random String
	Set suite variable    ${TEMPLATE_NAME}
	${NS} =              Get NPSP Namespace Prefix
    Set suite variable   ${NS}


*** Test Cases ***
Verify Fields Related to Lookups Populate on Batch Gift Entry Form
	[Documentation]                               To be filled in
	...                                           at a later date.
	[tags]                                        unstable      feature:GE        W-043224
	#Create object and field mappings in Advanced Mapping
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
	#Create a template with newly mapped lead lookup, company and lastname fields
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
	Click Gift Entry Button          			  Save & Close
	Current Page Should Be           			  Landing                GE_Gift_Entry
	Click Link                                	  Templates
    Wait Until Page Contains                  	  ${TEMPLATE_NAME}
    Store Template Record Id                  	  ${TEMPLATE_NAME}
	#create a batch with new template and verify lead fields autopopulate on selecting value from lead lookup
	Click Gift Entry Button          			  New Batch
	Wait Until Modal Is Open
    Select Template                      		  ${TEMPLATE_NAME}
    Load Page Object                     		  Form                   Gift Entry
    Fill Gift Entry Form
    ...                                  		  Batch Name=Lookups Test Automation Batch
    ...                                  		  Batch Description=This is a test batch created via automation script
    Click Gift Entry Button              		  Next
    Click Gift Entry Button              		  Save
    Current Page Should Be               		  Form                   Gift Entry		title=Gift Entry Form
    ${batch_id} =                        		  Save Current Record ID For Deletion   ${NS}DataImportBatch__c
	Fill Gift Entry Form				 		  Lead Lookup=${OPP_LEAD}[Name]
	Verify Field Default Value
    ...                              	 		  Lead: Company=${OPP_LEAD}[Company]
    ...                              	 		  Lead: Last Name=${OPP_LEAD}[LastName]