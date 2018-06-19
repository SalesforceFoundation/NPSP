import logging
import re
import time


from robot.libraries.BuiltIn import BuiltIn
from selenium.common.exceptions import ElementNotInteractableException
from selenium.common.exceptions import StaleElementReferenceException
from selenium.common.exceptions import WebDriverException
from selenium.webdriver.common.keys import Keys
from SeleniumLibrary.errors import ElementNotFound
from simple_salesforce import SalesforceMalformedRequest
from simple_salesforce import SalesforceResourceNotFound
from locator import npsp_lex_locators
#import os
#import sys
#sys.path.append(os.path.abspath(os.path.join('..',
#sys.path.append("/Users/skristem/Documents/GitHub/CumulusCI/cumulusci/robotframework/tests")
#import Salesforce


class NPSP(object):
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = 1.0
 
    def __init__(self, debug=False):
        self.debug = debug
        self.current_page = None
        self._session_records = []
        # Turn off info logging of all http requests 
        logging.getLogger('requests.packages.urllib3.connectionpool').setLevel(logging.WARN)
 
    @property
    def builtin(self):
        return BuiltIn()   
 
    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')
  
    @property
    def selenium(self):
        return self.builtin.get_library_instance('SeleniumLibrary')
            
    def populate_address(self, loc, value):
        """ Populate address with Place Holder aka Mailing Street etc as a locator
            and actual value of the place holder.
        """
        xpath = npsp_lex_locators["mailing_address"].format(loc)
        field = self.selenium.get_webelement(xpath)
        field.send_keys(value)
        
        
    def click_record_button(self, title):
        locator = npsp_lex_locators['record']['button'].format(title)
        self.selenium.set_focus_to_element(locator)
        button = self.selenium.get_webelement(locator)
        button.click()
        time.sleep(5)
        
    def select_tab(self, title):
        locator = npsp_lex_locators['tab'].format(title)
        self.selenium.set_focus_to_element(locator)
        button = self.selenium.get_webelement(locator)
        button.click()
        time.sleep(5)    
        
    def click_special_related_list_button(self, heading, button_title):
        locator = npsp_lex_locators['record']['related']['button'].format(heading, button_title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()
        
    def click_dropdown(self, title):
        locator = npsp_lex_locators['record']['list'].format(title)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click()     
    
    def pick_date(self, value):
        locator = npsp_lex_locators['record']['datepicker'].format(value)
        self.selenium.set_focus_to_element(locator)
        self.selenium.get_webelement(locator).click() 
        
    def select_row(self, value ):
        locators = npsp_lex_locators['name']
        list_ele = self.selenium.get_webelements(locators)
        index= 1
        for locator in list_ele:
            global index
            if locator.text != value:
                index = index+1
            else:
                drop_down = npsp_lex_locators['locate_dropdown'].format(index)
                self.selenium.get_webelement(drop_down).click()
            
           