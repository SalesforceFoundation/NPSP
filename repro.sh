{
    export org=dev_namespaced_test2
    sh build_org.sh $org
    # should fail
    cci task run performance_tests_CO -o vars "field_mapping_method:Data Import Field Mapping,cleanup_first:none"
    say "Done"
} 2>&1 | tee repro.log

cci task run download_debug_logs -o debug_log_dir /tmp/repologs

# should succeed
# cci task run performance_tests_CO -o vars "field_mapping_method:Data Import Field Mapping,cleanup_first:all"
