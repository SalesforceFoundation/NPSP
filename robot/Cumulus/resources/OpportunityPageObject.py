from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from locators_46 import npsp_lex_locators

@pageobject("Detail", "Opportunity")
class OpportunityPage(DetailPage):
    object_name = "Opportunity"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
    
        