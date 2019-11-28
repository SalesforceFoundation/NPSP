*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Variables
Suite Teardown  Delete Records and Close Browser

*** Keywords ***
Setup Variables
    ${first_name1} =           Generate Random String
    Set suite variable    ${first_name1}
    ${last_name1} =            Generate Random String
    Set suite variable    ${last_name1}
    ${first_name2} =           Generate Random String
    Set suite variable    ${first_name2}
    ${last_name2} =            Generate Random String*
    Set suite variable    ${last_name2}
    ${first_name} =           Generate Random String
    Set suite variable    ${first_name}
    ${last_name} =            Generate Random String*
    Set suite variable    ${last_name}


** Test Cases ***

Create Household With Name Only
    [Documentation]                       Creates a contact with lastname and firstname. Verifies that the toast message appears    
    ...                                   Verifies that contact is created and displays under recently viewed contacts
    [tags]                                W-037650    feature:Contacts and Accounts

    #Create contact with only name
    Go To Page                            Listing                             Contact
    Click Object Button                   New
    Populate Form
    ...                                   First Name=${first_name}
    ...                                   Last Name=${last_name}
    Save Form
    Current Page Should Be                Details        Contact
    Verify Toast Message Contains           created
    
    #Verify contact is created and shows under recently viewed
    ${contact_id} =                       Save Session Record For Deletion   Contact
    Verify Record Is Created In Database  Contact                             ${contact_id} 
    Header Field Value                    Account Name                        ${last_name} Household
    Go To Object Home                     Contact
    Verify Record                         ${first_name} ${last_name}

    
Create Household With additional details
    [Documentation]                       Create a contact with lastname, firstname and email and click save & new and 
    ...                                   create another contact with name and address. Verifies that the toast message appears
    ...                                   Verifies that contacts created and displays under recently viewed contacts
    [tags]                                W-037650    feature:Contacts and Accounts
    # Create a contact with name and email
    Go To Page                            Listing     Contact
    Click Object Button                   New
    Populate Contact Form
    ...                                   First Name=${first_name1}
    ...                                   Last Name=${last_name1}
    ...                                   Work Email=skristem@salesforce.com
    Click Modal Button                    Save & New
    
    # Create a contact with name and address  
    Populate Contact Form
    ...                                   First Name=${first_name2}
    ...                                   Last Name=${last_name2}
    ...                                   Primary Address Type=Work
    ...                                   Mailing Street=50 Fremont Street
    ...                                   Mailing City=San Francisco
    ...                                   Mailing Zip/Postal Code=95320
    ...                                   Mailing State/Province=CA
    ...                                   Mailing Country=USA
    Save Form
    Current Page Should Be                Details                             Contact
    Verify Toast Message Contains         created
    
    # Verify records are saved and displayed in recently viewed contact list
    ${contact_id2} =                       Save Session Record For Deletion   Contact
    Verify Record Is Created In Database  Contact                             ${contact_id2}
    Header Field Value                    Account Name                        ${last_name2} Household
    Page Should Contain                   50 Fremont Street
    Go To Page                            Listing                             Contact
    Verify Record                         ${first_name2} ${last_name2}
    Verify Record                         ${first_name1} ${last_name1}
    Click Link                            ${first_name1} ${last_name1}
    Select Tab                            Details 
    Confirm Field Value                   Work Email                          skristem@salesforce.com        Y
    
