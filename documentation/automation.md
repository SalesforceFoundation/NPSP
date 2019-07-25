# Cumulus Automation Inventory

## Key Workflows

This section describes the key workflows for developers, QEs, and technical
writers.

| Workflow                 | Flow                 | Org Type       | Managed | Namespaced |
| ------------------------ | -------------------- | -------------- | ------- | ---------- |
| Development              | `dev_org`            | dev            |         |            |
| Development (Namespaced) | `dev_org_namespaced` | dev_namespaced |         | ✔          |
| QA                       | `qa_org`             | dev            |         |            |
| QA (Namespaced)                      | `qa_org_namespaced`             | dev            |         |            |
| Regression               | `regression_org`     | regression     | ✔       |            |
| Trial (Clone of TSO)     | None                 | trial          |         |            |

## Utility Tasks and Flows

### Multicurrency

    config_multicurrency:
        description: Add CAD as a 2nd currency for a multicurrency org


### Customizable Rollups

    enable_customizable_rollups:
        description: Enable the NPSP Customizable Rollups feature (unmanaged deploys only)
    enable_incremental_rollups:
        description: Configure NPSP Customizable Rollups to activate Incremental Rollups (unmanaged deploys only)


### Static Analysis

    pmd:
        description: Run Apex code analysis with PMD. This task assumes that PMD is available in PATH. On MacOS PMD is available to install in brew.


### Performance Testing

    test_performance:
        description: 'Creates a BDI org and runs a performance test'

### LDV Testing

    ldv_tests:
        description: 'Deploys and runs LDV tests'



| Purpose                            | Flow           | Applicable Orgs |
| ---------------------------------- | -------------- | --------------- |
| Install Managed EDA                | `download_ldv_tests`  | Non-namespaced  |
| Install Managed NPSP and Test Data | `deploy_ldv_tests` | Non-namespaced  |

### Test Data

test_data_dev_org
        description: 'WARNING: This flow deletes all data first, then loads the complete test data set based on 100 Contacts into the target org.'
    test_data_dev_org_managed:
        description: 'WARNING: This flow deletes all data first, then loads the complete test data set based on 100 Contacts into the target org.'
    test_data_1k:
        description: 'WARNING: This flow deletes all data first, then loads the complete test data set based on 1,024 Contacts into the target org.'


## Unpackaged Metadata

Cumulus's unpackaged configuration is used as follows:

| Directory        | Purpose                                            | Deploy task                | Retrieve task |
| ---------------- | -------------------------------------------------- | -------------------------- | ------------- |
| `crlp_testing/`  | QA metadata for CRLPs.                             | via `deploy_rollup_testing`   |               |
| `delete/`        | Removes default org metadata.                      | `deploy_dev_config_delete` |               |
| `dev/`           | Minimal configuration changes for development.     | `deploy_dev_config`        |               |
| `offsetfiscal/`  | Configures a fiscal year starting in December.     | via `config_offsetfiscal`  |               |
| `perf/`          | Metadata for performance testing.                  | via `test_performance`     |               |
| `qa/`            | Metadata for QA and Robot tests.                   | `deploy_qa_config`         |               |
| `qa_namespaced/` | Corrects Help Text mappings in namespaced QA orgs. | via `qa_org_namespaced`    |               |
| `reports/`       | Reports and dashboards.                            | `deploy_reports`           |               |
| `trial/`         | Trial-style experience metadata.                   | `deploy_trial_config`      |               |

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

The SQLite data set is not included in the repo due to its size. For now, you need to copy the results of the 100k build jobs from [NPSP-Test-Data](https://github.com/SalesforceFoundation/NPSP-Test-Data) into `datasets/100k/test_data.db`

| Deploy Task      | Capture Task | Delete Task        |
| ---------------- | ------------ | ------------------ |
| `test_data_100k` |              | `test_data_delete` |

For managed orgs, the mapping must be manually set to `datasets/mapping-managed.yml`.

### BDI Benchmark Data Set

This data set is generated dynamically for BDI performance testing.

| Deploy Task     | Capture Task | Delete Task |
| --------------- | ------------ | ----------- |
| `test_data_bdi` |              |             |

### XXL Data Set

This data set is not stored in the repo, but lives in a Postgres database on Heroku due to its size. This data set can only be deployed to LDV performance testing sandboxes. Such deployments should be planned in advance with Release Engineering.