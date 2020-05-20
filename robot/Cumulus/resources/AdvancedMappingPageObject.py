from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Custom", "BDI_ManageAdvancedMapping")
class AdvancedMappingPage(BaseNPSPPage, BasePage):

    
    def _is_current_page(self):
        """
        Verifies that current page is BDI Manage Advanced Mapping page
        """
        self.selenium.wait_until_location_contains("BDI_ManageAdvancedMapping", timeout=60, 
                                                   message="Manage Advanced Mapping page did not open in 1 min")
    
    @capture_screenshot_on_error   
    def create_new_field_mapping(self,src_fld,tgt_fld):
        """Click on Create New Field Mapping button on the page 
           select 'src_fld' arg in Source Field Label box
           'tgt_fld' arg in Target Field Label box"""
        self.selenium.wait_until_page_contains("Field Mappings", timeout=60)
        btns=npsp_lex_locators['adv_mappings']['button']
        self.selenium.scroll_element_into_view(btns)
        self.selenium.click_button(btns)
        mdl_open=npsp_lex_locators['adv_mappings']["modal_open"]
        self.selenium.wait_until_page_contains_element(mdl_open, timeout=15, 
                                                       error="New Field Mapping Modal did not open in 15 seconds")
        src_loc=npsp_lex_locators['adv_mappings']['field_mapping'].format("sourceFieldLabel")
        self.selenium.click_element(src_loc)
        dd=npsp_lex_locators['adv_mappings']['combobox']
        self.selenium.wait_until_page_contains_element(dd, error="Source field dropdown did not open")
        src_ele=npsp_lex_locators['span'].format(src_fld)
        element = self.selenium.driver.find_element_by_xpath(src_ele)
        self.selenium.driver.execute_script('arguments[0].click()', element) 
        target=npsp_lex_locators['adv_mappings']['field_mapping'].format("targetFieldLabel")
        self.selenium.click_element(target)
        self.selenium.wait_until_page_contains_element(dd, error="Target field dropdown did not open")
        self.selenium.click_element(npsp_lex_locators['span'].format(tgt_fld))
        self.selenium.click_button("Save")
        self.selenium.wait_until_page_does_not_contain_element(mdl_open, timeout=15, 
                                                               error="New Field Mapping Modal did not close in 15 seconds")
        self.selenium.wait_until_page_contains("Success", timeout=180)
    
    @capture_screenshot_on_error
    def view_field_mappings_of_the_object(self,obj):
        """Click the dropdwon for obj and select View Field Mappings and verify that field mappings page is open"""
        self.selenium.wait_until_page_contains("Object Groups", timeout=60)
        self.selenium.wait_until_page_contains(obj, timeout=30, error=f"{obj} did not load in 30 seconds")
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(obj)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("View Field Mappings", timeout=60)
        self.selenium.click_link("View Field Mappings")
        self.selenium.wait_until_page_contains("Field Mappings", timeout=60)
    
    @capture_screenshot_on_error    
    def edit_field_mappings(self,fld_name,tgt_field):
        """Click the dropdown for fieldname and select edit and wait for model is open. 
           Once modal is open click on Target field to open a dropdown and select 'target_field' from available options"""
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(fld_name)
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("Edit", timeout=60)
        self.selenium.click_link("Edit")
        mdl_open=npsp_lex_locators['adv_mappings']["modal_open"]
        self.selenium.wait_until_page_contains_element(mdl_open, timeout=15, 
                                                       error="Edit Field Mapping Modal did not open in 15 seconds")
        target=npsp_lex_locators['adv_mappings']['field_mapping'].format("targetFieldLabel")
        self.selenium.click_element(target)
        dd=npsp_lex_locators['adv_mappings']['combobox']
        self.selenium.wait_until_page_contains_element(dd, error="Target field dropdown did not open")
        self.selenium.click_element(npsp_lex_locators['span'].format(tgt_field))
        self.selenium.click_button("Save")
        self.selenium.wait_until_page_does_not_contain_element(mdl_open, timeout=15, 
                                                               error="Edit Field Mapping Modal did not close in 15 seconds")
        self.selenium.wait_until_page_contains("Success", timeout=180)
    
    @capture_screenshot_on_error    
    def delete_field_mapping(self,fld_name):
        """Click the dropdown for fld_name and select Delete and wait for field mapping to not present on the page."""
        locator=npsp_lex_locators['adv_mappings']['dropdown'].format(fld_name)
        deleted=npsp_lex_locators['adv_mappings']['field-label'].format(fld_name)    
        self.selenium.scroll_element_into_view(locator)
        self.selenium.click_button(locator)
        self.selenium.wait_until_page_contains("Delete", timeout=60)
        self.selenium.click_link("Delete")
        self.selenium.wait_until_page_contains("Success", timeout=180)
        self.selenium.wait_until_page_does_not_contain_element(deleted, timeout=60)
    
    @capture_screenshot_on_error    
    def delete_mapping_if_mapping_exists(self,fld_label):
        """Checks if mapping with fld_label exists and if exists deletes the mapping. If not then does nothing"""
        locator=npsp_lex_locators['adv_mappings']['field-label'].format(fld_label)
        if self.npsp.check_if_element_exists(locator):
            self.delete_field_mapping(fld_label)
