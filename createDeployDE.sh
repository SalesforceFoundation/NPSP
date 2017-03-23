export CUMULUSCI_KEY=Sayonara12345678
virtualenv ~/cumulusci_venv
. ~/cumulusci_venv/bin/activate
cci org default dev
cci org list
cci flow run dev_org
cci task run update_admin_profile
cci flow run test_data_dev_org
cci task run run_tests
