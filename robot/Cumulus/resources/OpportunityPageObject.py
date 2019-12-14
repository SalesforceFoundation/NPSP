from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from BaseObjects import BaseNPSPPage
from NPSP import npsp_lex_locators

@pageobject("Detail", "Opportunity")
class OpportunityPage(BaseNPSPPage, DetailPage):
    object_name = "Opportunity"

    
    
    
        