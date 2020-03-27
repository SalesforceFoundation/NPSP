# Cumulus Automation Inventory

## Key Workflows

This section summarizes the key workflows for developers, QEs, and technical
writers.

| Workflow                 | Flow                           | Org Type       | Managed | Namespaced |
| ------------------------ | ------------------------------ | -------------- | ------- | ---------- |
| Development              | `dev_org`                      | `dev`            |         |            |
| Development (Namespaced) | `dev_org_namespaced`           | `dev_namespaced` |         | ✔          |
| QA                       | `qa_org`                       | `dev`            |         |            |
| QA (Namespaced)          | `qa_org_namespaced`            | `dev_namespaced`            |         | ✔          |
| Regression               | `regression_org`               | `beta`     | ✔       |            |
| Trial (Clone of TSO)     | None (`cci org browser trial`) | `trial`          | ✔       |            |

### Org Definitions

NPSP includes many org definitions tailored for testing - in particular, beta testing - of the product in a variety of org shapes.

Differences between these orgs are relatively slight. All orgs specify a required core set of features for NPSP:

 - Chatter
 - Enhanced Notes
 - Lightning

Additionally, depending on the intended use case of the org, features for development may be enabled:

 - Translation Workbench (Dev, Feature, Enterprise, and Prelease)
 - Disabled Lightning cache (Dev and Feature)
 - Disabled parallel Apex testing (All)
 - Enable Admin to Login As Any User (Dev, Feature and Beta)
 - Enhanced Profile UI (Dev, Feature and Beta)

as well as many other features needed to define the workspace for the org's intended purpose.

| Org Shape                 | Namespaced | Managed Installs | Description                                                             |
| ------------------------- | ---------- | ---------------- | ----------------------------------------------------------------------- |
| `dev`                     |            | No               | Development org                                                         |
| `dev_multicurrency`       |            | No               | Development org with multicurrency available                            |
| `dev_namespaced`          | ✔          | No               | Development org with namespace                                          |
| `beta`                    |            | Yes              | Regular beta org.                                                       |
| `beta_middlesuffix`       |            | Yes              | Beta test org with Middle Name and Suffix enabled.                      |
| `beta_multicurrency`      |            | Yes              | Beta test org with Multicurrency enabled.                               |
| `beta_personaccounts`     |            | Yes              | Beta test org with Person Accounts enabled.                             |
| `beta_platformencryption` |            | Yes              | Beta test org with Platform Encryption active for specific core fields. |
| `beta_prerelease`         |            | Yes              | Beta test org on Prerelease pod.                                        |
| `beta_statecountry`       |            | Yes              | Beta test org with State and Country Picklists enabled.                 |
| `enterprise`              |            | Yes              | Enterprise Edition org.                                                 |
| `feature`                 |            | No               | Feature test org.                                                       |
| `prerelease`              |            | No              | Feature test org on Prerelease pod.                                     |
| `trial`                   |            | Yes              | Clone of TSO.                                                           |



## Utility Tasks and Flows

### Multicurrency

| Name                   | Type | Description                                       |
| ---------------------- | ---- | ------------------------------------------------- |
| `config_multicurrency` | Task | Add CAD as a 2nd currency for a multicurrency org |

### Customizable Rollups

| Name                          | Type | Description                                                                                  |
| ----------------------------- | ---- | -------------------------------------------------------------------------------------------- |
| `enable_customizable_rollups` | Task | Enable the NPSP Customizable Rollups feature (unmanaged deploys only)                        |
| `enable_incremental_rollups`  | Task | Configure NPSP Customizable Rollups to activate Incremental Rollups (unmanaged deploys only) |

### Static Analysis
| Name  | Type | Description                                                                                                                     |
| ----- | ---- | ------------------------------------------------------------------------------------------------------------------------------- |
| `pmd` | Task | Run Apex code analysis with PMD. This task assumes that PMD is available in PATH. On MacOS PMD is available to install in brew. |


### Performance Testing
| Name               | Type | Description                                   |
| ------------------ | ---- | --------------------------------------------- |
| `test_performance` | Flow | Creates a BDI org and runs a performance test |

### LDV Testing
| Name        | Type | Description                |
| ----------- | ---- | -------------------------- |
| `ldv_tests` | Flow | Deploys and runs LDV tests |

### Pilot Enablement

| Name                          | Type | Description                                                                         |
| ----------------------------- | ---- | ----------------------------------------------------------------------------------- |
| `enable_pilot_in_scratch_org` | Task | Initialize the PilotEnabled Feature Parameter override in a Scratch Org environment |

### User Setup

| Name                          | Type | Description                                                                         |
| ----------------------------- | ---- | ----------------------------------------------------------------------------------- |
| `create_testing_user`         | Flow | Creates a testing User assigned a new NPSP_Standard_User profile with access to all NPSP objects & fields. Perfect for testing security with a non-system admin type User. **Only Use with the qa_org Flow** |

### Translation XML Cleanup

| Name                           | Type | Description                                                                         |
| ------------------------------ | ---- | ----------------------------------------------------------------------------------- |
| `cleanup_translation_metadata` | Task | Delete extraneous and translation-excluded metadata from translation files after using retrieve_unpackaged to pull down cleaned translations from a scratch org. |


## Unpackaged Metadata

Cumulus's unpackaged configuration is used as follows:

| Directory                     | Purpose                                                                       | Deploy task                                     | Retrieve task |
| ----------------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------- | ------------- |
| `crlp_testing/`               | QA metadata for CRLPs.                                                        | via `deploy_rollup_testing`                     |               |
| `delete/`                     | Removes default org metadata.                                                 | `deploy_dev_config_delete`                      |               |
| `dev/`                        | Minimal configuration changes for development.                                | `deploy_dev_config`                             |               |
| `offsetfiscal/`               | Configures a fiscal year starting in December.                                | via `config_offsetfiscal`                       |               |
| `perf/`                       | Metadata for performance testing.                                             | via `test_performance`                          |               |
| `platformencryption_fields/`  | Metadata to enable Platform Encryption for specific fields.                   | `platformencryption_deploy_field_configuration` |               |
| `platformencryption_permset/` | Permission Set to allow managing Platform Encryption tenant secrets.          | `platformencryption_create_tenant_secret`       |               |
| `qa/`                         | Metadata for QA and Robot tests.                                              | `deploy_qa_config`                              |               |
| `qa_bdi_custom_metadata/`     | Custom Metadata suite for testing BDI. Can only be deployed to unmanaged orgs | `deploy_qa_bdi_metadata_config`                 |               |
| `qa_namespaced/`              | Corrects Help Text BDI mappings in namespaced QA orgs.                        | via `qa_org_namespaced`                         |               |
| `rd2_post_config/`            | Configuration to complete enablement of Enhanced Recurring Donations.         | `deploy_rd2_config`                             |               |
| `reports/`                    | Reports and dashboards.                                                       | `deploy_reports`                                |               |
| `trial/`                      | Trial-style experience metadata.                                              | `deploy_trial_config`                           |               |
| `trial_translations/`         | Translations for Trial-style experience metadata.                             | `deploy_trial_translations`                     |               |
| `npsp_standard_user_profile/` | Base Non-Admin User Proile for testing                                        | via `create_testing_user`           |               |

## Data Sets

### Dev Org Data Set

This data set includes most NPSP objects and is scaled based on 100 Contacts.

| Deploy Task         | Capture Task | Delete Task        |
| ------------------- | ------------ | ------------------ |
| `test_data_dev_org` |              | `test_data_delete` |

For managed orgs, the mapping must be manually set to `datasets/mapping-managed.yml`.

### 1K Data Set

This data set includes most NPSP objects and is scaled based on 1024 Contacts.

| Deploy Task    | Capture Task | Delete Task        |
| -------------- | ------------ | ------------------ |
| `test_data_1k` |              | `test_data_delete` |

For managed orgs, the mapping must be manually set to `datasets/mapping-managed.yml`.

### 100K Data Set

This data set includes most NPSP objects and is scaled based on 102,400 Contacts. This data set will not fit in a standard scratch org, which holds approximately 100,000 total records.

The SQLite data set is not included in the repo due to its size. It is present in the persistent `LDV100k` org.

| Deploy Task      | Capture Task | Delete Task        |
| ---------------- | ------------ | ------------------ |
| `test_data_100k` |              | `test_data_delete` |

For managed orgs, the mapping must be manually set to `datasets/mapping-managed.yml`.

### BDI Benchmark Data Set

This data set is generated dynamically for BDI performance testing. No data set is stored.

| Deploy Task     | Capture Task | Delete Task |
| --------------- | ------------ | ----------- |
| `test_data_bdi` |              |             |

### XXL Data Set

This data set is not stored in the repo, but lives in a Postgres database on Heroku due to its size. This data set can only be deployed to LDV performance testing sandboxes. Such deployments should be planned in advance with Release Engineering.
