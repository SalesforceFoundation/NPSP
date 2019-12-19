*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

***Keywords***
Setup Test Data
    &{account} =          API Create Organization Account 
    Set suite variable    &{account}  
    &{contact} =          API Create Contact                 Email=automation@example.com 
    Set suite variable    &{contact}
    Store Session Record  Account                            &{contact}[AccountId]
 
*** Test Cases ***    
Create Primary Affiliation for Contact
    Go To Page                           Details               Contact                                object_id=&{contact}[Id]
    Select Tab                           Details
    Enter Field Value                    Primary Affiliation    &{account}[Name]
    # Scroll Element Into View  text:Description
    # Click Button  title:Edit Primary Affiliation
    # Wait For Locator  record.edit_form
    # Populate Lookup Field    Primary Affiliation    &{account}[Name]
    # Click Record Button    Save    
    Select Tab                           Related
    Verify Affiliated Contact    Organization Affiliations    &{account}[Name]    Y  
    Click Related Item Link      Organization Affiliations    &{account}[Name]
    Save Current Record ID For Deletion    npe5__Affiliation__c    
