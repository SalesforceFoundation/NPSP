import time
from cumulusci.robotframework.utils import capture_screenshot_on_error
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "NPSP_Settings")
class NPSPSettingsPage(BaseNPSPPage, BasePage):

    
    def _go_to_page(self, filter_name=None):
        """To go to NPSP Settings page"""
        url_template = "{root}/lightning/n/{object}"
        name = self._object_name
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
        self.npsp.wait_for_locator("frame","Nonprofit Success Pack Settings")
        self.npsp.choose_frame("Nonprofit Success Pack Settings")
        
    def open_main_menu(self,title): 
        """Waits for the menu item to load and clicks to expand menu""" 
        self.selenium.wait_until_page_contains(title, 
                                               error=f"{title} link was not found on the page")  
        self.npsp.click_link_with_text(title)
        
    @capture_screenshot_on_error
    def click_toggle_button(self, page_name):
        """ specify the partial id of submenu under which the checkbox exists """
        locator = npsp_lex_locators["npsp_settings"]["checkbox"].format(page_name)
        self.selenium.wait_until_element_is_enabled(locator,error="Checkbox could not be found on the page")
        self.selenium.scroll_element_into_view(locator)
        self.selenium.get_webelement(locator).click()
    

    def wait_for_message(self,message):
        """Waits for the text passed in message to be displayed on the page for 6 min"""
        i=0
        while True:
            if i<=12:
                try:
                    self.selenium.page_should_contain(message)
                    break
                except Exception:
                    time.sleep(10)
                    i += 1
            else:
                raise AssertionError(
                    f"Timed out waiting for {message} to display"
                )
            
    def click_configure_advanced_mapping(self):
        """clicks on Configure Advanced Mapping and waits for Manage Advanced Mapping page to load 
           and loads the page object for that page"""
        locator=npsp_lex_locators['id'].format("navigateAdvancedMapping")
        self.selenium.click_element(locator)
        self.pageobjects.current_page_should_be("Custom", "BDI_ManageAdvancedMapping")
        self.selenium.wait_until_page_contains("Account",timeout=30, error="Objects did not load in 30 seconds")
    
    def verify_advanced_mapping_is_not_enabled(self):
        """Verifies that advanced mapping is not enabled by default 
           By checking 'Configure Advanced Mapping' is not visible on the page"""
        locator=npsp_lex_locators['id'].format("navigateAdvancedMapping")
        if self.npsp.check_if_element_exists(locator):
            ele=self.selenium.get_webelement(locator)
            classname=ele.get_attribute("class") 
            if 'slds-hide' in classname:
                self.builtin.log("As expected Advanced Mapping is not enabled by default")
            else:
                raise Exception("Advanced Mapping is already enabled. Org should not have this enabled by default")                  