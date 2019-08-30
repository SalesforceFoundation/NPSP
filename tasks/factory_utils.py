import collections
from abc import ABC, abstractmethod
from importlib import import_module

from factory import enums, Factory

from .data_generation_base import BatchDataTask


#  Factoryboy uses "__" and Salesforce uses "__". Luckily Factoryboy makes
#  theirs easy to override!
enums.SPLITTER = "____"


# More flexible than FactoryBoy's sequences because you can create and
# destroy them where-ever you want.
class Adder:
    def __init__(self, x=0):
        self.x = x

    def __call__(self, value):
        self.x += value
        return int(self.x)

    def reset(self, x):
        self.x = x


# Thin collector for the factories and a place to try to achieve better
# scalability than the create_batch function from FactoryBoy.
class Factories:
    unflushed_record_counter = 0

    def __init__(self, session, collection):
        """This class can deal with dicts of factory classes,
           or module namespaces.

           In the namespace-case it will also filter out objects which are
           note FactoryBoy classes."""
        if isinstance(collection, collections.Mapping):
            pass
        else:
            collection = {name: value for name, value in vars(collection)}

        self.factory_classes = {
            key: self.add_session(value, session)
            for key, value in collection.items()
            if isinstance(value, type) and issubclass(value, Factory)
        }

    @staticmethod
    def add_session(fact, session):
        "Attach the session to the factory"
        fact._meta.sqlalchemy_session = session
        fact._meta.sqlalchemy_session_persistence = "commit"
        return fact

    def create_batch(self, classname, batchsize, **kwargs):
        cls = self.factory_classes.get(classname, None)
        assert cls, f"Cannot find a factory class named {classname}. Did you misspell it?"
        for _ in range(batchsize):
            cls.create(**kwargs)

    def __getitem__(self, name):
        return self.factory_classes[name]


class BaseDataFactory(BatchDataTask, ABC):
    """Abstract base class for any FactoryBoy based generator"""
    def generate_data(self, session, engine, base, num_records):
        raw_factories = self.make_factories(base.classes)
        factories = Factories(session, raw_factories)
        self.generate_data_with_factories(num_records, factories)

    @abstractmethod
    def make_factories(self, classes):
        pass

    @abstractmethod
    def generate_data_with_factories(self, num_records, factories):
        pass


class ModuleDataFactory(BaseDataFactory):
    class Models:
        pass

    def make_factories(self, classes):
        global Models
        for cls in classes:
            setattr(Models, cls.__name__, cls)

        assert self.datafactory_classes_module
        module = import_module(self.datafactory_classes_module)
        _reset_Models()  # ensure no leakage
        return vars(module)

    def generate_data_with_factories(self, num_records, factories):
        assert self.datafactory_generator_module
        module = import_module(self.datafactory_generator_module)
        generator_func = getattr(module, "make_records")
        assert generator_func
        return generator_func(num_records, factories)


##  Note: this is used as a mutable global variable to emulate how models
##        in e.g. Django work. This should only be a problem in a
##        multithreaded environment and I believe that CCI is far from being
##        multi-thread compatible.
class Models:
    pass


def _reset_Models():
    global Models

    class Models:
        pass
