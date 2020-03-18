import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "CustomSettings")
class CustomSettingsPage(BaseNPSPPage, BasePage):

    
    def _go_to_page(self, filter_name=None):
        """Go to Custom Settings page"""
        url = self.cumulusci.org.lightning_base_url
        url = "{}/lightning/setup/CustomSettings/home".format(url)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.npsp.wait_for_locator("frame_new","Custom Settings","Custom Settings")
        
    def select_settings_option(self,setting_name,value): 
        """selects frame with setting_name and clicks on the option 
           identified by value for the given setting and unselects frame"""
        self.npsp.choose_frame("Custom Settings")
        locator = npsp_lex_locators['custom_settings']['link'].format(setting_name,value)
        self.selenium.wait_until_element_is_visible(locator, timeout=60)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_element(locator)
        self.selenium.unselect_frame()
        self.salesforce.wait_until_loading_is_complete()
           
    def verify_page_and_select_frame(self,page_name):
        """verify page contains page_name and select frame identified with page_name"""
        self.selenium.page_should_contain(page_name)
        self.npsp.choose_frame(page_name)
        
        