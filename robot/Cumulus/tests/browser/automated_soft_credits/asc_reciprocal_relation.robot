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
    &{contact1} =  API Create Contact    Email=skristem@robot.com 
    Store Session Record  Account                              &{contact1}[AccountId]
    Set suite variable    &{contact1}
    &{contact2} =  API Create Contact    AccountId=&{contact1}[AccountId]
    Set suite variable    &{contact2}
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    &{relation1} =  API Create Relationship    &{contact1}[Id]    &{contact2}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
    &{opportunity1} =  API Create Opportunity    &{contact2}[AccountId]    Donation    Name=Reciprocal test $500 donation    Amount=500    ${ns}Primary_Contact__c=&{contact2}[Id]  
    Set suite variable    &{opportunity1}
    &{contact3} =  API Create Contact    Email=skristem@robot.com 
    Store Session Record  Account                              &{contact3}[AccountId]
    Set suite variable    &{contact3}
    &{contact4} =  API Create Contact    AccountId=&{contact3}[AccountId]
    Set suite variable    &{contact4}
    ${ns} =  Get NPSP Namespace Prefix
    &{relation2} =  API Create Relationship    &{contact3}[Id]    &{contact4}[Id]    Coworker    ${ns}Related_Opportunity_Contact_Role__c=Soft Credit
 
*** Test Cases ***    
ASC Reciprocal Relationship Test Case 1
    [tags]                                  feature:Automated Soft Credits       W-039819
    Go To Page                              Details                              Opportunity                                
    ...                                     object_id=&{opportunity1}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Verify Related List Field Values
    ...                                     &{contact2}[FirstName] &{contact2}[LastName]=Donor
    ...                                     &{contact1}[FirstName] &{contact1}[LastName]=Household Member
    Run Donations Batch Process
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact1}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $500.00    section=Soft Credit Total
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact2}[Id]
    Navigate To And Validate Field Value    Total Gifts This Year                contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Total Gifts                          contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit This Year                contains    $0.00      section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total                    contains    $0.00      section=Soft Credit Total
    
Test Case 2
    [tags]                                  feature:Automated Soft Credits       W-039819
    
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{contact4}[Id]
    Select Tab  Related
    Click Related Table Item Link           Relationships                        &{contact3}[FirstName] &{contact3}[LastName]
    Edit Record Dropdown Value             	Related Opportunity Contact Role     Soft Credit
    Save Record
    &{opportunity2} =                       API Create Opportunity               &{contact3}[AccountId]    Donation    
    ...                                     Name=Reciprocal test $500 donation    
    ...                                     Amount=500    
    ...                                     ${ns}Primary_Contact__c=&{contact3}[Id]  
    Go To Page                              Details                              Opportunity                                
    ...                                     object_id=&{opportunity2}[Id]
    Select Tab                              Related
    Select Relatedlist                      Contact Roles
    Verify Related List Field Values
    ...                                     &{contact3}[FirstName] &{contact3}[LastName]=Donor
    ...                                     &{contact4}[FirstName] &{contact4}[LastName]=Soft Credit
    Run Donations Batch Process
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact4}[Id]
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $500.00    section=Soft Credit Total
    Go To Page                              Details                              Contact                                
    ...                                     object_id=&{Contact3}[Id]
    Navigate To And Validate Field Value    Total Gifts This Year    contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Total Gifts              contains    $500.00    section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit This Year    contains    $0.00      section=Soft Credit Total
    Navigate To And Validate Field Value    Soft Credit Total        contains    $0.00      section=Soft Credit Total
