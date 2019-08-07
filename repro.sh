{
    export org=dev_namespaced_test2
    sh build_org.sh $org
    rm /tmp/temp_db.db.db
    # should fail
    cci task run performance_tests_CO -o vars "field_mapping_method:Data Import Field Mapping,cleanup_first:none"
    sh dump_csv.sh /tmp/temp_db.db.db
    echo "CSV Files Created"
    say "Done"
} 2>&1 | tee repro.log

cci task run download_debug_logs -o debug_log_dir /tmp/repologs

# should succeed
# cci task run performance_tests_CO -o vars "field_mapping_method:Data Import Field Mapping,cleanup_first:all"
