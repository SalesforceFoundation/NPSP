from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from locators_46 import npsp_lex_locators

@pageobject("Listing", "DataImport__c")
class DataImportPage(ListingPage):
    object_name = "DataImport__c"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
    
        
    def click(self,btn_name):
        """Clicks button with specified name on Data Import Page"""
        self.npsp.click_special_object_button(btn_name)
        
    def click_begin_data_import_process(self):
        self.npsp.wait_for_locator("frame","NPSP Data Import")
        self.npsp.select_frame_and_click_element("NPSP Data Import","button","Begin Data Import Process")
        self.npsp.wait_for_batch_to_complete("data_imports.status","Completed")
        
    def click_close_button(self):
        self.npsp.click_button_with_value("Close")    
        
    def select_import_record(self,record_name):
        self.selenium.page_should_contain_link(record_name)
        locator=npsp_lex_locators['data_imports']['checkbox'].format(record_name) 
        self.selenium.click_element(locator)   
        