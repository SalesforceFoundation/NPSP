export $(dbus-launch)
export NODE_TLS_REJECT_UNAUTHORIZED=0
export CUMULUSCI_KEY=Sayonara12345678
virtualenv ~/cumulusci_venv
. ~/cumulusci_venv/bin/activate
export SFDX_ORG_CREATE_ARGS="-e prototype"

cci org scratch dev scratch
cci flow run dev_org --org scratch
cci task run update_admin_profile --org scratch
cci flow run test_data_dev_org --org scratch
cci task run run_tests --org scratch

sfdx force:org:list | tail -1 | sed 's/\(scratchorg[0-9]*@npsp-jenkinsworkspace.com\).*/\1/' > scratch_user.txt
SCRATCHUSER=$(cat scratch_user.txt  | sed -n 1p | sed 's/\s*\(.*\)$/\1/')
echo $SCRATCHUSER
sfdx force:config:set defaultusername=$SCRATCHUSER

echo "Get Org URL"
sfdx force:org:open -r > scratch_session.txt 
sleep 10s
SCRATCHSESS=$(cat scratch_session.txt  | sed -n 1p | sed 's/.*sid=\(.*\)$/\1/')
echo $SCRATCHSESS

echo "Get Apex Test Results"
python apexResultsRest.py -a Foundation -i $SCRATCHSESS
