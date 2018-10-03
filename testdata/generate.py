# Requirements:
# - faker
# - psycopg2-binary
# - Create an empty postgres db using "createdb testdata"

from collections import defaultdict
from datetime import date
from datetime import timedelta
import csv
import os
import random
import tempfile

from cumulusci.core.tasks import BaseTask
from cumulusci.core.utils import process_bool_arg
import faker
import psycopg2

fake = faker.Faker()


class WeightedChooser(object):
    def __init__(self, choices):
        choices = choices.items()
        self.total = sum(weight for value, weight in choices)
        self.choices = choices

    def __call__(self):
        value = random.uniform(0, self.total)
        upto = 0
        for choice, weight in self.choices:
            if upto + weight >= value:
                return choice
            upto += weight


class Generator(object):
    table = None
    columns = ("id",)
    generators = {}
    started = False

    def __init__(self, conn, logger, distribution=None):
        self.conn = conn
        self.logger = logger
        self.counter = 0
        if distribution:
            self.choose_count = WeightedChooser(distribution)
        self.init_subgenerators()

    def init_subgenerators(self):
        pass

    def __enter__(self):
        self.started = True

        # create subgenerators
        self.teardown = []
        for gen in self.generators.values():
            if not gen.started:
                gen.__enter__()
                self.teardown.append(gen)

        # open temporary csv file
        self.output = tempfile.TemporaryFile("w+")
        self.writer = csv.DictWriter(self.output, self.columns)
        return self

    def make_id(self):
        id = self.counter
        self.counter += 1
        return id

    def make_one(self, **kw):
        attrs = {"id": self.make_id()}
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs

    def __exit__(self, exc=None, t=None, tb=None):
        self.logger.info("Writing {} {}".format(self.counter, self.table))

        # create table
        cursor = self.conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS {}".format(self.table))
        create = "CREATE TABLE {} (id text primary key, {})".format(
            self.table,
            ", ".join("{} text".format(c) for c in self.columns if c != "id"),
        )
        cursor.execute(create)

        # copy data to db
        self.output.seek(0)
        cursor.copy_expert(
            "COPY {} ({}) FROM STDIN WITH (FORMAT CSV)".format(
                self.table, ",".join(self.columns)
            ),
            self.output,
        )

        # close output
        self.output.close()

        # exit subgenerators
        for gen in self.teardown:
            gen.__exit__()

        self.started = False


class ContactGenerator(Generator):
    table = "contacts"
    columns = (
        "id",
        "account_id",
        "primary_affiliation_id",
        "salutation",
        "first_name",
        "last_name",
        "email",
        "phone",
        "job_title",
    )

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs["first_name"] = fake.first_name()
        attrs["last_name"] = fake.last_name()
        attrs["salutation"] = fake.prefix()
        attrs["email"] = fake.email()
        attrs["phone"] = fake.phone_number()
        attrs["job_title"] = fake.job()
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


class AddressGenerator(Generator):
    table = "addresses"
    columns = (
        "id",
        "household_id",
        "street",
        "city",
        "state",
        "zip",
        "start_month",
        "start_day",
        "end_month",
        "end_day",
    )

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs["street"] = fake.street_address()
        attrs["city"] = fake.city()
        attrs["state"] = fake.state_abbr()
        attrs["zip"] = fake.zipcode()
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


today = date.today()
this_year = today.year
this_month = today.month
ten_years_ago = today.replace(year=this_year - 10)
MONTHS = range(1, 13)


class OpportunityContactRoleGenerator(Generator):
    table = "oppcontactroles"
    columns = ("id", "contact_id", "opportunity_id", "role", "is_primary")

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs["role"] = "Donor"
        attrs["is_primary"] = True
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


class PaymentGenerator(Generator):
    table = "payments"
    columns = ("id", "opportunity_id", "amount", "payment_date")

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


class PartialSoftCreditGenerator(Generator):
    table = "partialsoftcredits"
    columns = ("id", "contact_id", "opportunity_id", "role", "amount")

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


class GAUGenerator(Generator):
    table = "gaus"
    columns = ("id", "name")

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs["name"] = fake.catch_phrase()
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


class AllocationGenerator(Generator):
    table = "allocations"
    columns = ("id", "opportunity_id", "gau_id", "percent")

    def __init__(self, conn, logger, distribution=None, gau_count=100):
        super(AllocationGenerator, self).__init__(conn, logger, distribution)
        self.gau_count = gau_count

    def __enter__(self):
        super(AllocationGenerator, self).__enter__()

        # generate GAUs
        self.gaus = []
        with GAUGenerator(self.conn, self.logger) as gau_gen:
            for x in range(self.gau_count):
                if x == 0:
                    kw = {"name": "General Fund"}
                else:
                    kw = {}
                self.gaus.append(gau_gen.make_one(**kw))

        return self

    def make_one(self, **kw):
        attrs = {}
        attrs["id"] = self.make_id()
        attrs["percent"] = 100
        attrs["gau_id"] = random.choice(self.gaus)["id"]
        attrs.update(kw)
        self.writer.writerow(attrs)
        return attrs


class OpportunityGenerator(Generator):
    table = "opportunities"
    columns = (
        "id",
        "name",
        "amount",
        "stage_name",
        "close_date",
        "dont_create_payments",
        "account_id",
        "contact_id",
        "recurring_donation_id",
        "campaign_id",
    )

    def init_subgenerators(self):
        self.generators = {
            "oppconroles": OpportunityContactRoleGenerator(self.conn, self.logger),
            "payments": PaymentGenerator(
                self.conn, self.logger, {1: 200, 2: 1, 3: 1, 4: 1}
            ),
            "partialsoftcredits": PartialSoftCreditGenerator(
                self.conn, self.logger, {0: 200, 1: 1}
            ),
            "allocations": AllocationGenerator(self.conn, self.logger, {1: 9, 2: 1}),
        }

    def make_one(self, contacts, **kw):
        attrs = {}
        attrs["id"] = id = self.make_id()
        attrs["amount"] = amount = random.randrange(100, 1100, 100)
        close_date = fake.date_between_dates(ten_years_ago, today)
        attrs["close_date"] = close_date.isoformat()
        attrs["stage_name"] = "Closed Won"
        attrs["dont_create_payments"] = False
        attrs["recurring_donation_id"] = None
        attrs["campaign_id"] = None
        attrs.update(kw)
        contact = contacts[0]
        attrs["name"] = "{} {} Donation ({})".format(
            contact["first_name"], contact["last_name"], attrs["close_date"]
        )

        # opportunity contact roles
        oppconrole_gen = self.generators["oppconroles"]
        first = True
        for contact in contacts:
            oppconrole_gen.make_one(
                opportunity_id=id,
                contact_id=contact["id"],
                role="Donor" if first else "Influencer",
                is_primary=first,
            )
            first = False

        # payments
        payment_gen = self.generators["payments"]
        payment_count = payment_gen.choose_count()
        payment_amount = round(amount / payment_count, 2)
        for n in range(payment_count):
            payment_gen.make_one(
                opportunity_id=id,
                payment_date=(close_date + timedelta(days=n * 30)).isoformat(),
                amount=payment_amount,
            )

        # partial soft credits
        psc_gen = self.generators["partialsoftcredits"]
        psc_count = psc_gen.choose_count()
        if psc_count:
            psc_amount = round(amount / psc_count, 2)
            for contact in contacts:
                psc_gen.make_one(
                    opportunity_id=id,
                    contact_id=contact["id"],
                    role="Matched Donor",
                    amount=psc_amount,
                )

        # allocations
        allocation_gen = self.generators["allocations"]
        allocation_count = allocation_gen.choose_count()
        for x in range(allocation_count):
            allocation_gen.make_one(
                opportunity_id=id, percent=round(100 / allocation_count)
            )

        self.writer.writerow(attrs)
        return attrs


class RecurringDonationGenerator(Generator):
    table = "recurring_donations"
    columns = ("id", "contact_id", "name", "amount", "start_date", "open_ended")

    def __init__(self, conn, logger, distribution, opportunity_generator):
        super(RecurringDonationGenerator, self).__init__(conn, logger, distribution)
        self.generators["opportunities"] = opportunity_generator

    def make_one(self, account, contacts, **kw):
        attrs = {}
        attrs["id"] = id = self.make_id()
        contact = contacts[0]
        attrs["contact_id"] = contact["id"]
        attrs["name"] = "{} {} Recurring Donation".format(
            contact["first_name"], contact["last_name"]
        )
        attrs["amount"] = amount = random.randrange(25, 225, 25)
        year = random.randrange(this_year - 10, this_year + 1)
        attrs["start_date"] = "{}-01-01".format(year)
        attrs["open_ended"] = year == this_year
        attrs.update(kw)

        opp_gen = self.generators["opportunities"]
        for month in MONTHS:
            is_past = year < this_year or month < this_month
            opp_gen.make_one(
                contacts,
                account_id=account["id"],
                contact_id=contact["id"],
                recurring_donation_id=id,
                amount=amount,
                stage_name="Closed Won" if is_past else "Pledged",
                close_date="{}-{:02d}-01".format(year, month),
                dont_create_payments=False,
            )

        self.writer.writerow(attrs)
        return attrs


class HouseholdGenerator(Generator):
    table = "accounts"
    columns = ("id", "name", "record_type")

    def __init__(self, conn, logger, include_skew=False):
        super(HouseholdGenerator, self).__init__(conn, logger)
        self.include_skew = include_skew

    def init_subgenerators(self):
        opportunity_generator = OpportunityGenerator(
            self.conn,
            self.logger,
            {0: 2, 1: 3, 2: 2, 3: 2, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 9: 1, 10: 1},
        )
        self.generators = {
            "contacts": ContactGenerator(
                self.conn, self.logger, {1: 10, 2: 10, 3: 1, 4: 1, 5: 1}
            ),
            "addresses": AddressGenerator(self.conn, self.logger, {1: 50, 2: 1}),
            "recurring_donations": RecurringDonationGenerator(
                self.conn, self.logger, {1: 1, 0: 4}, opportunity_generator
            ),
            "opportunities": opportunity_generator,
        }

    def make_one(self, n):
        id = self.make_id()
        attrs = {"id": id, "record_type": "HH_Account"}

        # contacts
        contact_gen = self.generators["contacts"]
        num_contacts = contact_gen.choose_count()
        contacts = []
        for x in range(num_contacts):
            contacts.append(contact_gen.make_one(account_id=id))
        # name household based on contacts
        attrs["name"] = self.name_household(contacts)

        # addresses (some seasonal)
        address_gen = self.generators["addresses"]
        num_addresses = address_gen.choose_count()
        if num_addresses == 1:
            address_gen.make_one(household_id=id)
        else:
            address_gen.make_one(
                household_id=id, start_month=6, start_day=1, end_month=8, end_day=31
            )
            address_gen.make_one(
                household_id=id, start_month=9, start_day=1, end_month=5, end_day=31
            )

        # recurring donations
        rd_gen = self.generators["recurring_donations"]
        num_rds = rd_gen.choose_count()
        if num_rds:
            rd_gen.make_one(attrs, contacts)

        # one-off opportunities
        opp_gen = self.generators["opportunities"]
        if self.include_skew and n == 1:
            num_opps = 50000
            attrs["name"] = "50k Opp Household"
        elif self.include_skew and n < 10:
            num_opps = 5000
            attrs["name"] = "5k Opp Household"
        else:
            num_opps = opp_gen.choose_count()
        for x in range(num_opps):
            opp_gen.make_one(contacts, account_id=id)

        self.writer.writerow(attrs)
        return attrs

    def make_many(self, count, **kw):
        i = 0
        while i < count:
            i += 1
            self.make_one(i, **kw)
            if not i % 1000:
                self.logger.info(i)

    def name_household(self, children):
        return "{} Household".format(
            "/".join(set(contact["last_name"] for contact in children))
        )


class GenerateFakeData(BaseTask):

    task_options = {
        "count": {
            "description": "How many households to generate. Related objects will be generated proportionally.",
            "required": True,
        },
        "database_url": {
            "description": "The database url for an empty postgres database to write data to.",
            "required": True,
        },
        "include_skew": {
            "description": "If true, include a few households with thousands of opportunities.",
            "required": False,
        },
    }

    def _init_options(self, kw):
        super(GenerateFakeData, self)._init_options(kw)
        self.options["count"] = int(self.options["count"])
        self.options["include_skew"] = process_bool_arg(
            self.options.get("include_skew")
        )

    def _run_task(self):
        database_url = self.options["database_url"]
        count = self.options["count"]

        # patch faker for performance
        self._install_faker_patch()

        self.logger.info("Connecting to {}".format(database_url))
        conn = psycopg2.connect(database_url)
        self.logger.info("Generating {} households".format(count))
        with HouseholdGenerator(
            conn, self.logger, include_skew=self.options["include_skew"]
        ) as gen:
            gen.make_many(count)
        conn.commit()
        conn.close()

    def _install_faker_patch(self):
        from faker.providers import BaseProvider

        def random_element(self, elements=("a", "b", "c")):
            if isinstance(elements, dict):
                return self.generator.random.choice(tuple(elements.keys()))
            else:
                return self.generator.random.choice(elements)
            return self.random_elements(elements, length=1)[0]

        BaseProvider.random_element = random_element
