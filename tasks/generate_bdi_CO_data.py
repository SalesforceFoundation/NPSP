import math
from datetime import date, datetime

import factory
from .factory_utils import Adder, ModuleDataFactory


class GenerateBDIData_CO(ModuleDataFactory):
    """Generate data specific to the Honeybees test cases"""
    datafactory_generator_module = datafactory_classes_module = "tasks.bdi_CO_factories"
