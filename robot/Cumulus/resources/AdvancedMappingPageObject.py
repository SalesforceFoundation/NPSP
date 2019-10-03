from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "ManageAdvancedMapping")
class AdvancedMappingPage(BasePage):

    
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    def view_field_mappings(self,obj):
        self.selenium.wait_until_page_contains("Object Groups", timeout=60)
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(obj)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("View Field Mappings", timeout=60)
        self.selenium.click_link("View Field Mappings")
        self.selenium.wait_until_page_contains("Field Mappings", timeout=60)
        
    def edit_field_mappings(self,obj_name):
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(obj_name)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("Edit", timeout=60)
        self.selenium.click_link("Edit")
#         self.salesforce.wait_until_modal_is_open()  