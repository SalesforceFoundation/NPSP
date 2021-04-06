import time
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Listing", "Batch_Gift_Entry")
class BatchGiftEntryListPage(BaseNPSPPage, ListingPage):


    def _go_to_page(self, filter_name=None):
        """To go to Batch Gift Entry List View page"""
        url_template = "{root}/lightning/n/{object}"
        name = self._object_name
        namespace= self.cumulusci.get_namespace_prefix("Nonprofit Success Pack") or self.cumulusci.get_namespace_prefix("Nonprofit Success Pack Managed Feature Test")
        object_name = "{}{}".format(namespace, name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()


@pageobject("Details", "DataImportBatch__c")
class BatchGiftEntryDetailPage(BaseNPSPPage, DetailPage):


    def _is_current_page(self):
        """ Verify we are on the BGE detail page
            by verifying that the url contains 'DataImportBatch__c'
        """
        self.selenium.wait_until_location_contains("DataImportBatch__c/",message="Current page is not a BGE batch record detail view")
        self.npsp.wait_for_locator("bge.title","Batch Gift Entry")