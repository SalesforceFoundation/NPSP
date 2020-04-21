from robot.libraries.BuiltIn import BuiltIn


class BaseNPSPPage:
    
    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    @property
    def pageobjects(self):
        return self.builtin.get_library_instance("cumulusci.robotframework.PageObjects")