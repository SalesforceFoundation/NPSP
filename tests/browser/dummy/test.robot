*** Settings ***
Library             SeleniumLibrary
Library             BuiltIn
Library        OperatingSystem
Library     SeleniumLibrary
Resource        tests/NPSP.robot
Library        tests/locator_backup_91118.py
#Suite Setup     Open Test Browser


*** Variable ***
${URL}            https://cs21.lightning.force.com/lightning/o/Account/list?filterName=00B15000009VHelEAG
# ${title}          Welcome: Mercury Tours
# ${timeout}        3s
${first}    //*[@id="SortCanvas"]/li[2]/div/div[1]
${second}    //*[@id="SortCanvas"]/li[1]/div/div[1]
${xpath}        //tbody/tr[8]/td/span//div/a/lightning-icon
*** Test Cases ***
Open Mercury Website in Chrome and Maximize
    ${value}    get locator npsp   record.related.button    hello    world
    log to console    ${value}