#!/bin/bash

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 1k_rest
mv report.html report_loadtest_1k.html

## --------------------------------

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 10k_rest
mv report.html report_loadtest_10k_rest.html

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 10k_bulk
mv report.html report_loadtest_10k_bulk.html

## --------------------------------

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 100k_rest
mv report.html report_loadtest_100k_rest.html

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 100k_bulk
mv report.html report_loadtest_100k_bulk.html

## --------------------------------

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 500k_rest
mv report.html report_loadtest_500k_rest.html

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 500k_bulk
mv report.html report_loadtest_500k_bulk.html

## --------------------------------

cci task run test_contact_insert_vanilla_performance --org perftest1 -o include 1M_bulk
mv report.html report_loadtest_1m_bulk.html