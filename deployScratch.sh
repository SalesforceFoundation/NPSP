export SFDX_ORG_CREATE_ARGS="-e prototype"
cci org scratch dev scratch
cci flow run dev_org --org scratch
