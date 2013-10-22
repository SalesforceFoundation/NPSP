#!/usr/bin/python
import os
import time
import ConfigParser
from selenium.webdriver.firefox.webdriver import WebDriver
from selenium.webdriver.common.action_chains import ActionChains
from getpass import getpass

npsp_user = None
npsp_pass = None


def main():
    global npsp_user
    npsp_user = raw_input('Dev Org Username: ')
    global npsp_pass
    npsp_pass = getpass('Dev Org Password: ')

    config_file = os.path.dirname(os.path.abspath(__file__)) + '/cumulus.cfg'

    global config
    config = ConfigParser.ConfigParser()
    config.readfp(open(config_file))

    # Setup selenium session
    wd = WebDriver()
    wd.implicitly_wait(60)

    # Initial login
    wd.get("https://login.salesforce.com/")
    login(wd)

    # Setup an Opportunity Record Type
    create_sales_process(wd)
    create_opp_record_type(wd)

    # Install NPSP Packages
    install_pkg_contactsandorganizations(wd)
    #install_pkg_households(wd)
    install_pkg_relationships(wd)
    install_pkg_affiliations(wd)
    install_pkg_recurringdonations(wd)

# Action methods

def login(wd):
    wd.find_element_by_id("username").click()
    wd.find_element_by_id("username").clear()
    wd.find_element_by_id("username").send_keys(npsp_user)
    wd.find_element_by_id("password").click()
    wd.find_element_by_id("password").clear()
    wd.find_element_by_id("password").send_keys(npsp_pass)
    wd.find_element_by_id("Login").click()

def create_sales_process(wd):
    wd.find_element_by_id("userNavLabel").click()
    wd.find_element_by_link_text("Setup").click()
    wd.find_element_by_css_selector("#Customize_icon > img.setupImage").click()
    wd.find_element_by_css_selector("#Opportunity_icon > img.setupImage").click()
    wd.find_element_by_id("OpportunityProcess_font").click()
    wd.find_element_by_name("new").click()
    wd.find_element_by_id("p3").click()
    wd.find_element_by_id("p3").clear()
    wd.find_element_by_id("p3").send_keys("Default")
    wd.find_element_by_id("p4").click()
    wd.find_element_by_css_selector("#bottomButtonRow > input[name=\"save\"]").click()
    wd.find_element_by_name("save").click()

def create_opp_record_type(wd):
    wd.find_element_by_id("OpportunityRecords_font").click()
    wd.find_element_by_name("new").click()
    wd.find_element_by_id("p2").click()
    wd.find_element_by_id("p2").clear()
    wd.find_element_by_id("p2").send_keys("Default")
    wd.find_element_by_id("p52").click()
    if not wd.find_element_by_xpath("//table[@class='detailList']//select[normalize-space(.)='--None--Default']//option[text()='Default']").is_selected():
        wd.find_element_by_xpath("//table[@class='detailList']//select[normalize-space(.)='--None--Default']//option[text()='Default']").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_name("save").click()
    if not wd.find_element_by_xpath("//div[@class='pbWizardBody']/table[1]/tbody/tr[1]/td[2]/select//option[text()='Opportunity Layout']").is_selected():
        wd.find_element_by_xpath("//div[@class='pbWizardBody']/table[1]/tbody/tr[1]/td[2]/select//option[text()='Opportunity Layout']").click()
    wd.find_element_by_css_selector("div.pbWizardBody").click()
    wd.find_element_by_name("save").click()

def install_pkg_contactsandorganizations(wd):
    wd.get(config.get('npe01','install_url'))
    #login(wd)
    wd.find_element_by_id("InstallPackagePage:InstallPackageForm:InstallBtn").click()
    wd.find_element_by_css_selector("label").click()
    if not wd.find_element_by_id("simpleDialog0checkbox").is_selected():
        wd.find_element_by_id("simpleDialog0checkbox").click()
    wd.find_element_by_id("simpleDialog0button0").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_xpath("//table[@class='selectSecurity']//label[.='*Grant access to all users']").click()
    wd.find_element_by_id("p201FULL").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_name("save").click()

def install_pkg_households(wd):
    wd.get(config.get('npo2','install_url'))
    #login(wd)
    wd.find_element_by_id("InstallPackagePage:InstallPackageForm:InstallBtn").click()
    wd.find_element_by_xpath("//div[@id='simpleDialog0Content']/table/tbody/tr/td[2]/div").click()
    if not wd.find_element_by_id("simpleDialog0checkbox").is_selected():
        wd.find_element_by_id("simpleDialog0checkbox").click()
    wd.find_element_by_id("simpleDialog0button0").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_xpath("//table[@class='selectSecurity']//label[.='*Grant access to all users']").click()
    wd.find_element_by_id("p201FULL").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_name("save").click()

def install_pkg_relationships(wd):
    wd.get(config.get('npe4','install_url'))
    #login(wd)
    wd.find_element_by_id("InstallPackagePage:InstallPackageForm:InstallBtn").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_xpath("//table[@class='selectSecurity']//label[.='*Grant access to all users']").click()
    wd.find_element_by_id("p201FULL").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_name("save").click()

def install_pkg_affiliations(wd):
    wd.get(config.get('npe5','install_url'))
    #login(wd)
    wd.find_element_by_id("InstallPackagePage:InstallPackageForm:InstallBtn").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_xpath("//table[@class='selectSecurity']//label[.='*Grant access to all users']").click()
    wd.find_element_by_id("p201FULL").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_name("save").click()

def install_pkg_recurringdonations(wd):
    wd.get(config.get('npe03','install_url'))
    #login(wd)
    wd.find_element_by_id("InstallPackagePage:InstallPackageForm:InstallBtn").click()
    #wd.find_element_by_css_selector("label").click()
    #if not wd.find_element_by_id("simpleDialog0checkbox").is_selected():
    #    wd.find_element_by_id("simpleDialog0checkbox").click()
    #wd.find_element_by_id("simpleDialog0button0").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_xpath("//table[@class='selectSecurity']//label[.='*Grant access to all users']").click()
    wd.find_element_by_id("p201FULL").click()
    wd.find_element_by_name("goNext").click()
    wd.find_element_by_name("save").click()

if __name__ == '__main__':
  main()
