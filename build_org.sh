export org=dev_namespaced_test2
echo $org
cci org scratch_delete $org
cci org scratch --days 7 --default dev_namespaced $org
time cci flow run qa_org_namespaced --org $org
cci task run turn_on_debug_logs --org $org
