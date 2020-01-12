from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Details", "Opportunity")
class OpportunityPage(BaseNPSPPage, DetailPage):
    object_name = "Opportunity"

    def _is_current_page(self):
        """ Verify we are on the opportunities listing page
            by verifying that the url contains '/list'
        """
        self.selenium.wait_until_location_contains("/view", timeout=60, message="Detail page did not load in 1 min")
        self.selenium.location_should_contain("/lightning/r/Opportunity/",message="Current page is not a Opportunity detail view")


    def verify_payments_made(self, count):

        self.npsp.select_tab("Related")
        self.salesforce.load_related_list("Payments")
        self.npsp.verify_occurrence("Payments", count)


    def validate_values_under_relatedlist_for(self, listname, **kwargs):
        """

        """
        self.npsp.wait_for_locator("record.related.check_occurrence","Contact Roles", 2)
        self.npsp.select_relatedlist(listname)
        self.npsp.verify_related_list_field_values(**kwargs)

    def make_new_payment(self, **kwargs):
        """
         Make a new payment
        """
        self.salesforce.click_related_list_button("Payments", "New")
        self.selenium.select_window()
        self.npsp.populate_modal_form(**kwargs)
        self.selenium.select_window()
        self.npsp.open_date_picker("Payment Date")
        self.npsp.pick_date("Today")
        self.npsp.click_modal_button("Save")


@pageobject("Listing", "Opportunity")
class OpportunityListingPage(BaseNPSPPage, ListingPage):
    object_name = "Opportunity"

    def _is_current_page(self):
        """ Verify we are on the opportunities listing page
            by verifying that the url contains '/list'
        """
        self.selenium.wait_until_location_contains("/list", timeout=60, message="Opportunities listing page did not load in 1 min")
        self.selenium.location_should_contain("lightning/o/Opportunity/list",message="Current page is not a list page")

    
    
        