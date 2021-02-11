from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import BasePage
from cumulusci.robotframework.pageobjects import pageobject
from cumulusci.robotframework.pageobjects import BasePage
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators


@pageobject("Listing", "General_Accounting_Unit__c")
class GAUListPage(BaseNPSPPage, ListingPage):

    def _go_to_page(self, filter_name=None):
        """Adding this go to page keyword as a workaround for namespace issue
        when running with 2GP orgs"""
        url_template = "{root}/lightning/o/{object}/list"
        name = self._object_name
        namespace= self.npsp.get_npsp_namespace_prefix()
        object_name = "{}{}".format(namespace, name)
        url = url_template.format(root=self.cumulusci.org.lightning_base_url, object=object_name)
        self.selenium.go_to(url)
        self.salesforce.wait_until_loading_is_complete()

    def _is_current_page(self):
        """
        Waits for the current page to be a Data Import list view
        """
        self.selenium.wait_until_location_contains("/list",timeout=60, message="Records list view did not load in 1 min")
        self.selenium.location_should_contain("General_Accounting_Unit__c",message="Current page is not a GAU List view")



@pageobject("Custom", "ManageAllocations")
class GauAllocationPage(BaseNPSPPage, BasePage):

    def _is_current_page(self):
        """
        Waits for the GAU Allocations iframe to load
        """
        self.selenium.wait_until_location_contains("/one/one.app",timeout=60, message="Manage Allocations page did not load in 1 min")
        self.npsp.wait_for_locator('frame','Manage Allocations')
        self.npsp.choose_frame('Manage Allocations')

    def set_gau_allocation(self,**kwargs):
        """
        Allocates the values for the GAU names as specified by the values passed in kwargs
        """
        for key, value in kwargs.items():
            if 'General Accounting Unit' in key:
                self.npsp.select_search(key, value)
            else:
                self.add_gau_allocation(key, value)


    def add_gau_allocation(self,field, value):
        """Enter an allocation of sepecified 'value' in the given 'field'"""
        locator = npsp_lex_locators["gaus"]["input_field"].format(field)
        self.salesforce._populate_field(locator,value)

