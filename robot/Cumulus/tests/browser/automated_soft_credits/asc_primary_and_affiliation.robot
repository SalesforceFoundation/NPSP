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
    &{account} =          API Create Organization Account 
    Set suite variable    &{account}  
    &{contact1} =         API Create Contact                   Email=test@example.com 
    Store Session Record  Account                              &{contact1}[AccountId]
    Set suite variable    &{contact1}
    &{contact2} =         API Create Contact                   Email=test@example.com
    Store Session Record  Account                              &{contact2}[AccountId]
    Set suite variable    &{contact2}
    ${ns} =               Get NPSP Namespace Prefix
    &{affiliation1} =     API Create Secondary Affiliation    &{account}[Id]    &{contact1}[Id]    ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
    &{affiliation2} =     API Create Secondary Affiliation    &{account}[Id]    &{contact2}[Id]    ${ns}Related_Opportunity_Contact_Role__c=Solicitor
    &{opportunity} =      API Create Opportunity              &{account}[Id]    Donation           Name=&{account}[Name] $50 donation    
    ...                   Amount=50                           ${ns}Primary_Contact__c=&{contact1}[Id]
    Set suite variable    &{opportunity}

 
*** Test Cases ***    
Create ASC Test for Primary and Affiliations
    [Documentation]            Create 2 contacts, Org Account and affiliations to Org Account with Contact1 role as Soft Credit 
    ...                        Contact2 as Solicitor  via API.Create Opportunity for org acct with contact1 as primary and 
    ...                        verify contact roles. Verify opportunity shows under both contact records 
    ...                        After running donations batch job verify contact1 gets soft credits and contact2 doesn't
    [tags]                                  feature:Automated Soft Credits       W-039819
    
    #Check opportunity contact roles
    Go To Page                              Details                              Opportunity                                
    ...                                     object_id=&{opportunity}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Wait For Page Object                    Custom                               OpportunityContactRole
    Verify Related List Field Values
    ...                                     &{contact1}[FirstName] &{contact1}[LastName]=Soft Credit
    ...                                     &{contact2}[FirstName] &{contact2}[LastName]=Solicitor
    
    #verify opportunity exists on both contacts
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact1}[Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        &{opportunity}[Name]
    
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact2}[Id]
    Select Tab                              Related
    Check Record Related Item               Opportunities                        &{opportunity}[Name]
    
    #Run batch job and verify soft credits on contacts
    Run Donations Batch Process
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact1}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $50.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $50.00    section=Soft Credit Total
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact2}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $0.00     section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $0.00     section=Soft Credit Total
