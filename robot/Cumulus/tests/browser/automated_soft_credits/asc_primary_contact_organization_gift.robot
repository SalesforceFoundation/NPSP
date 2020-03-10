*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/OpportunityContactRolePageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{account} =  API Create Organization Account   
    Set suite variable                   &{account}
    &{contact} =  API Create Contact     Email=test@example.com 
    Store Session Record                 Account               &{contact}[AccountId]
    Set suite variable                   &{contact}
    ${ns} =  Get NPSP Namespace Prefix
    &{opportunity} =  API Create Opportunity    &{account}[Id]    Donation    Name=&{account}[Name] $50 donation    Amount=50    ${ns}Primary_Contact__c=&{contact}[Id]
    Set suite variable    &{opportunity}
 
*** Test Cases ***    
Create ASC for Primary Contact on Organization Gift
    [Documentation]            Create a contact, Org Account and Opportunity for acct with contact as primary via API.
    ...                        Verify contact shows under contact role with Role as soft credit. 
    ...                        After running donations batch job verify contact gets soft credits
    [tags]                     feature:Automated Soft Credits        W-039819
    
    Go To Page                              Details                              Opportunity                                
    ...                                     object_id=&{opportunity}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Wait For Page Object                    Custom                               OpportunityContactRole
    Verify Related List Field Values
    ...                                     &{contact}[FirstName] &{contact}[LastName]=Soft Credit
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact}[Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        &{opportunity}[Name]
    Run Donations Batch Process
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $50.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $50.00    section=Soft Credit Total
