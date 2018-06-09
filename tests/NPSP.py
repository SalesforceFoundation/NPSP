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
        
    def choose_frame(self, title):
        """ Selects a NPSP Frame using a title.
        """
        xpath = npsp_lex_locators["iframe"].format(title)
        field = self.selenium.get_webelement(xpath).click()
        
        
        
