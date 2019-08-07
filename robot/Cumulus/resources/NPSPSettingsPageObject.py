import time

from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from locators_46 import npsp_lex_locators
from logging import exception

@pageobject("Custom", "NPSPSettings")
class NPSPSettingsPage(BasePage):
    object_name = None

    
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
    def _go_to_page(self, filter_name=None):
        """To go to NPSP Settings page"""
        url= self.cumulusci.org.lightning_base_url+"/lightning/n/NPSP_Settings"
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.npsp.wait_for_locator("frame","Nonprofit Success Pack Settings")
        self.npsp.choose_frame("Nonprofit Success Pack Settings")
        
    def open_main_menu(self,title): 
        """Waits for the menu item to load and clicks to expand menu""" 
        self.selenium.wait_until_page_contains("System Tools")  
        self.npsp.click_link_with_text("System Tools")
        
   
    def click_toggle_button(self, page_name):
        """ specify the partial id of submenu under which the checkbox exists """
        locator = npsp_lex_locators["npsp_settings"]["checkbox"].format(page_name)
        self.selenium.wait_until_element_is_enabled(locator,error="Checkbox could not be found on the page")
        self.selenium.get_webelement(locator).click()
        time.sleep(5)
    
    def wait_until_advanced_mapping_is_enabled(self):
        """Waits for the text 'Advanced Mapping is enabled' to be displayed on the page for 1 min"""
        i=0
        while True:
            if i<=12:
                try:
                    self.selenium.page_should_contain("Advanced Mapping is enabled")
                    break
                except Exception:
                    time.sleep(5)
                    i += 1
            else:
                raise AssertionError(
                    "Timed out waiting for Configure Advanced Mapping button to display"
                )