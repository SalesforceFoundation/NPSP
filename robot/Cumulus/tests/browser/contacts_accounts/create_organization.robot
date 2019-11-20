*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/AccountPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Organization Foundation
    [Documentation]                    This test creates and Organization account and verifies that the account shows under 
    ...                                Recently Viewed, Organization Accounts, My Accounts and does not show under Household Accounts
    #Create Organization account  
    ${account_name} =                  Generate Random String
    Go To Page                         Listing    Account
    Click Object Button                New
    Select Record Type                 Organization
    Populate Form
    ...                                Account Name=${account_name}
    ...                                Phone=1234567
    ...                                Billing Street=50 Fremont st
    #...                                Description=Account created with Robot Automation
    ${loc}                             Get NPSP Locator    object.field    Description
    Press Keys                         ${loc}     Account created with Robot Automation 
    Save Form
    ${account_id} =                    Get Current Record Id
    Store Session Record               Account    ${account_id}
    &{account} =  Salesforce Get       Account    ${account_id}
    Should Not Be Empty                ${account}
    Select Tab                               Details 
    Confirm Field Value                      Phone              1234567                                          Y
    Confirm Field Value                      Billing Address    50 Fremont st                                    Y
    Confirm Field Value                      Description        Account created with Robot Automation            Y
    
    
    #Verify Account is only displayed in expected views
    Go To Page                         Listing    Account
    Verify Record                      &{account}[Name]
    Change Object View                 Organization Accounts
    Verify Record   	               &{account}[Name]
    Change Object View                 My Accounts
    Search Field By Value              Search this list     &{account}[Name]
    Verify Record   	               &{account}[Name]
    Change Object View                 Household Accounts
    Page Should Not Contain            &{account}[Name]
