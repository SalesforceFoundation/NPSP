import time
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators
from logging import exception

@pageobject("Listing", "Batch_Gift_Entry")
class BatchGiftEntryPage(BaseNPSPPage, ListingPage):

    
    def _go_to_page(self, filter_name=None):
        """To go to NPSP Settings page"""
        url_template = "{root}/lightning/n/{object}"
        name = self._object_name
        object_name = "{}{}".format(self.cumulusci.get_namespace_prefix(), name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()
