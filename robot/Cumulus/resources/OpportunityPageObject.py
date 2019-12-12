from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from Basenpspobjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Detail", "Opportunity")
class OpportunityPage(DetailPage, BaseNPSPPage):
    object_name = "Opportunity"

    
    
    
        