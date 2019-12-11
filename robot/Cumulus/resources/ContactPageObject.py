from cumulusci.robotframework.pageobjects import ListingPage
from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from NPSP import npsp_lex_locators



@pageobject("Listing", "Contact")
class ContactListingPage(ListingPage):
    object_name = "Contact"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')
   
    def click_delete_account_button(self):
        """Clicks on Delete Account button inside the iframe"""
        self.npsp.wait_until_url_contains("/delete")
        self.npsp.select_frame_and_click_element("vfFrameId","button","Delete Account")    

@pageobject("Details", "Contact")
class ContactDetailPage(DetailPage):
    object_name = "Contact"

    def _is_current_page(self):
        """ Verify we are on the Contact detail page
            by verifying that the url contains '/view'
        """
        self.npsp.wait_until_url_contains("/view")
        
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')

    @property
    def cumulusci(self):
        return self.builtin.get_library_instance('cumulusci.robotframework.CumulusCI')

    def update_field_value(self,field_name,old_value,new_value):
        """Delete the old value in specified field by clicking on delete icon and update with new value"""
        locator=npsp_lex_locators['delete_icon'].format(field_name,old_value)
        self.selenium.get_webelement(locator).click() 
        self.salesforce.populate_lookup_field(field_name,new_value)
        
    