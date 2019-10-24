from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators

@pageobject("Listing", "DataImport__c")
class DataImportPage(ListingPage):

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
    
        
    def click(self,btn_name):
        """Clicks button with specified name on Data Import Page"""
        self.npsp.click_special_object_button(btn_name)
        
    def click_begin_data_import_process(self):
        """On the DI page, clicks the Begin Data Import Process button and waits for batch processing to complete"""
        self.npsp.wait_for_locator("frame","NPSP Data Import")
        self.npsp.select_frame_and_click_element("NPSP Data Import","button","Begin Data Import Process")
        self.npsp.wait_for_batch_to_complete("data_imports.status","Completed")
        
    def click_close_button(self):
        """Click on close button on DI processing page and waits for DI object homepage to load"""
        self.npsp.click_button_with_value("Close")
        self.npsp.wait_until_url_contains("DataImport__c")    
        
        