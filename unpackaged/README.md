## Unpackaged NPSP Configuration

This folder contains various sets of _unpackaged_ metadata which can be used to configure the NPSP package for use in different scenarios.

* `pre`: Deployed after NPSP dependencies but before NPSP itself is installed, in all scenarios -- including when CumulusCI is installing NPSP as a dependency of something else.

  * `account_record_types`: Ensures that the HH_Account and Organization record types of Account exist.
  * `opportunity_record_types`: Ensures that record types are enabled for Opportunities by creating an `NPSP_Default` record type if no record types exist yet.

* `post`: Deployed after NPSP in all scenarios -- including when CumulusCI is installing NPSP as a dependency of something else.

  * `first`: Adds quick actions to the global layout, and the Household_Accounts list view.

* `config`: 

  * `acctsc_rollups`: Deploys some sample customizable rollups for account soft credits. Used by the `config_acctsc_rollups` flow which can be run manually when desired.

  * `delete`: Deletes standard Salesforce Sales/Marketing/Support layouts and profiles. Used by all of the config flows.

  * `dev`: Configures NPSP for use by developers, including opportunity record types, picklist values for contact roles and opportunity stages, assigning page layouts to standard objects, and making tabs visible to the Admin profile. Used by the `config_dev` flow (and by extension, `dev_org`). This set of metadata should not include any components that might be accidentally retrieved and included in the NPSP package.

  * `offsetfiscal`: Enables an offset fiscal year starting in December. Used by the `config_offsetfiscal` flow, which is in turn used for the offset fiscal beta test org.

  * `qa`: Deploys components used only for QA purposes, such as custom fields. Used by the `config_qa` flow (and by extension, `qa_org`) as an addition _after_ the `trial` metadata has been deployed.

  * `trial`: Deploys various configuration to turn the raw NPSP package into the trial experience, including page layouts and lightning record pages, picklist values, opportunity record types, custom fields, list views, quick actions, the lightning app, and enabling workflow rules. The metadata in this folder uses namespace tokens (`%%%NAMESPACE%%%` and `___NAMESPACE___`) to support both managed and unmanaged NPSP. Used by the `config_qa`/`qa_org` and `config_managed`/`install_prod`/`install_beta` flows.
