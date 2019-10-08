from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "ManageAdvancedMapping")
class AdvancedMappingPage(BasePage):

    
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    def create_new_field_mapping(self,src_fld,tgt_fld):
        self.selenium.wait_until_page_contains("Field Mappings", timeout=60)
        self.selenium.scroll_element_into_view(npsp_lex_locators['adv_mappings']['button'])
        btns=npsp_lex_locators['adv_mappings']['button']
        self.selenium.click_button(btns)
        self.selenium.wait_until_page_contains_element(npsp_lex_locators['adv_mappings']["modal_open"], timeout=15, error="New Field Mapping Modal did not open in 15 seconds")
        src_loc=npsp_lex_locators['adv_mappings']['field_mapping'].format("sourceFieldLabel")
        self.selenium.click_element(src_loc)
        self.selenium.wait_until_page_contains_element(npsp_lex_locators['adv_mappings']['combobox'], error="Source field dropdown did not open")
        src_ele=npsp_lex_locators['span'].format(src_fld)
        element = self.selenium.driver.find_element_by_xpath(src_ele)
        self.selenium.driver.execute_script('arguments[0].click()', element) 
        target=npsp_lex_locators['adv_mappings']['field_mapping'].format("targetFieldLabel")
        self.selenium.click_element(target)
        self.selenium.wait_until_page_contains_element(npsp_lex_locators['adv_mappings']['combobox'], error="Target field dropdown did not open")
        self.selenium.click_element(npsp_lex_locators['span'].format(tgt_fld))
        self.selenium.click_button("Save")
        self.selenium.wait_until_page_does_not_contain_element(npsp_lex_locators['adv_mappings']["modal_open"], timeout=15, error="New Field Mapping Modal did not close in 15 seconds")
        self.selenium.wait_until_page_contains("Success", timeout=180)
    
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
        target=npsp_lex_locators['adv_mappings']['field_mapping'].format("targetFieldLabel")
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
        
    def delete_mapping_if_mapping_exists(self,obj_label):
        try:
            locator=npsp_lex_locators['adv_mappings']['field-label'].format(obj_label)
            self.selenium.page_should_contain_element(locator, message=obj_label+' was not found on the page')
            self.delete_mapping(obj_label)
            return
        except Exception:
            return    