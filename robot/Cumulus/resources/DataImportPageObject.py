from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.utils import capture_screenshot_on_error
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
import time

@pageobject("Listing", "DataImport__c")
class DataImportPage(BaseNPSPPage, ListingPage):

    def _go_to_page(self, filter_name=None):
        """Adding this go to page keyword as a workaround for namespace issue
        when running NPSP tests in a different repo"""
        url_template = "{root}/lightning/o/{object}/list"
        name = self._object_name
        namespace= self.cumulusci.get_namespace_prefix("Nonprofit Success Pack") or self.cumulusci.get_namespace_prefix("Nonprofit Success Pack Managed Feature Test")
        object_name = "{}{}".format(namespace, name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("DataImport__c",message="Current page is not a DataImport List view")

    def click(self,btn_name):
        """Clicks button with specified name on Data Import Page"""
        self.npsp.click_special_object_button(btn_name)

    def begin_data_import_process_and_verify_status(self,batch,status):
        """On the DI page, clicks the Begin Data Import Process button and waits for specified status to display """
        self.npsp.wait_for_locator("frame","NPSP Data Import")
        self.npsp.select_frame_and_click_element("NPSP Data Import","button","Begin Data Import Process")
        self.npsp.wait_for_batch_to_process(batch,status)

    def click_close_button(self):
        """Click on close button on DI processing page and waits for DI object homepage to load"""
        self.npsp.click_button_with_value("Close")
        self.selenium.wait_until_location_contains("DataImport__c")

    def open_data_import_record(self,di_name):
        """Clicks on the specified data import record to open the record"""
        #self.pageobjects.current_page_should_be("Listing","DataImport__c")
        time.sleep(2)
        self.npsp.click_link_with_text(di_name)
        self.pageobjects.current_page_should_be("Details","DataImport__c")


@pageobject("Details", "DataImport__c")
class DataImportDetailPage(BaseNPSPPage, DetailPage):

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/view",timeout=60, message="Record detail view did not load in 1 min")
        self.selenium.location_should_contain("DataImport__c",message="Current page is not a DataImport detail view")

    @capture_screenshot_on_error
    def edit_record(self):
        """From the actions dropdown select edit action and wait for modal to open"""
        locator=npsp_lex_locators['link-contains'].format("more actions")
        buttons=self.selenium.get_webelements(locator)
        for button in buttons:
            if button.is_displayed():
                self.selenium.click_link(button)
        dd=npsp_lex_locators['data_imports']['actions_dd']
        print(f"locator is {dd}")
        self.selenium.wait_until_page_contains_element(dd, error="Show more actions dropdown didn't open in 30 sec")
        self.selenium.click_link("Edit")
        self.salesforce.wait_until_modal_is_open()


    def save_record(self):
        """clicks the save button on the modal and waits till modal is closed"""
        self.salesforce.click_modal_button("Save")
        self.salesforce.wait_until_modal_is_closed()

    @capture_screenshot_on_error
    def verify_failure_message(self,field,status,value):
        """If status is 'contains' then the specified value should be present in the field
            'does not contain' then the specified value should not be present in the field"""
        locator = npsp_lex_locators['data_imports']['check_status'].format(field)
        self.selenium.wait_until_page_contains_element(locator, error=f"Couldn't find {field} on the page")
        self.selenium.scroll_element_into_view(locator)
        actual_value=self.selenium.get_webelement(locator).text
        print(f"actual value is {actual_value}")
        if status == "contains":
            assert value == actual_value, f"Expected {field} to be {value} but found {actual_value}"
        elif status == "does not contain":
            assert value != actual_value, f"Expected {field} should not contain {value}"
