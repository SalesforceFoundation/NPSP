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
        
    def edit_field_mappings(self,field_name,target_field):
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(field_name)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("Edit", timeout=60)
        self.selenium.click_link("Edit")
        self.selenium.wait_until_page_contains_element(npsp_lex_locators['adv_mappings']["modal_open"], timeout=15, error="Edit Field Mapping Modal did not open in 15 seconds")
        target=npsp_lex_locators['adv_mappings']['target_field']
        self.selenium.click_element(target)
        self.selenium.wait_until_page_contains_element(npsp_lex_locators['adv_mappings']['combobox'], error="Target field dropdown did not open")
        self.selenium.click_element(npsp_lex_locators['span'].format(target_field))
        self.selenium.click_button("Save")
        self.selenium.wait_until_page_does_not_contain_element(npsp_lex_locators['adv_mappings']["modal_open"], timeout=15, error="Edit Field Mapping Modal did not close in 15 seconds")
        self.selenium.wait_until_page_contains("Success", timeout=180)
        
    def delete_mapping(self,obj_name):
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(obj_name)    
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("Delete", timeout=60)
        self.selenium.click_link("Delete")
        self.selenium.wait_until_page_does_not_contain(obj_name, timeout=60)
        
    def delete_mapping_if_mapping_exists(self,obj_name):
        try:
            self.selenium.Page_should_contain("obj_name")
            self.delete_mappings(obj_name)
            return
        except Exception:
            return    