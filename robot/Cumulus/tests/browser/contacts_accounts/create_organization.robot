*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/AccountPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Organization Foundation
    [Documentation]                        This test creates an Organization account and verifies that the account shows under 
    ...                                    Recently Viewed, Organization Accounts, My Accounts and does not show under Household Accounts
    [tags]                                 W-037650    feature:Contacts and Accounts
    #Create Organization account  
    ${account_name} =                      Generate Random String
    Go To Page                             Listing                            Account
    Click Object Button                    New
    Select Record Type                     Organization
    Wait For Modal                         New                                Account                                     expected_heading=New Account: Organization
    Populate Form
    ...                                    Account Name=${account_name}
    ...                                    Phone=1234567
    ...                                    Billing Street=50 Fremont st
    #...                                   Description=Account created with Robot Automation
    ${loc}                                 Get NPSP Locator                   object.field                                Description
    Press Keys                             ${loc}                             Account created with Robot Automation 
    Click Modal Button                     Save
    Wait Until Modal Is Closed
    Current Page Should Be                 Details                            Account
    ${account_id}                          Save Session Record For Deletion   Account
    Verify Record Is Created In Database   Account                            ${account_id}    
    Select Tab                             Details 
    Confirm Field Value                    Phone                              1234567                                     Y
    Confirm Field Value                    Billing Address                    50 Fremont st                               Y
    Confirm Field Value                    Description                        Account created with Robot Automation       Y
    
    #Verify Account is only displayed in expected views
    Go To Page                             Listing                            Account
    Verify Record                          ${account_name}
    Change View To                         Organization Accounts
    Verify Record   	                   ${account_name}
    Change View To                         My Accounts
    Search Field By Value                  Search this list                   ${account_name}
    Verify Record   	                   ${account_name}
    Change View To                         Household Accounts
    Page Should Not Contain                ${account_name}
