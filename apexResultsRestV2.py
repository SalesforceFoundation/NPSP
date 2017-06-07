#!/usr/bin/env python
# encoding: utf-8
'''
apexResults -- Connects to Org and queries ApexTestResults and save results in CSV

apexResults is a script that issues a SOQL query to query the ApexTestResults.
It is designed to be used with SFDX and can use the Session ID that is returned by sfdx force:org:open to authenticate against the ScratchOrg

@author:     Robert Frankus

@copyright:  2017 Salesforce. All rights reserved.

@contact:    rfrankus@salesforce.com
'''

import pandas as pd
import time
import sys, getopt
import json
import requests
from pandas.io.json import json_normalize

def extract_json (value):
    if value.get('Name'):
        return value['Name']
    elif value.get('EndTime'):
        return value['EndTime']

def extract_json1 (value,attrib):
    if value.get(attrib):
        return value[attrib]

def setCliParameters():
    # Get CLI arguments
    try:
        # Parse CLI arguments
        opts, args = getopt.getopt(sys.argv[1:], 'hs:u:p:a:i:d:z:x:y:v', ['help','sessionfile','username','password','app','sessionid','database','pod','client_id','client_secret'])
    except getopt.GetoptError:
        print 'apexResultsRest.py -s <sessionfile> -i <sessionid> -u <username> -p <password> -a <application> -d <database> -z <pod> -x <client_id> -y <client_secret> '
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
                print 'apexResultsRest.py -s <sessionfile> -i <sessionid> -u <username> -p <password> -a <application> -d <database>  -z <pod> -x <client_id> -y <client_secret> '
                sys.exit()
        elif opt in ("-s", "--sessionfile"):
                global sessionfile
                sessionfile = arg
        elif opt in ("-u", "--username"):
                global user
                user = arg
        elif opt in ("-p", "--password"):
                global password
                password = arg
        elif opt in ("-a", "--app"):
                global app
                app = arg
        elif opt in ("-i", "--sessionid"):
                global sessionId
                sessionId = arg
        elif opt in ("-d", "--database"):
                global db
                db = arg
        elif opt in ("-z", "--pod"):
                global pod
                pod = arg
        elif opt in ("-x", "--client_id"):
                global client_id
                client_id = arg
        elif opt in ("-y", "--client_secret"):
                global client_secret
                client_secret = arg
            
def queryWithUser(pod,client_id,client_secret,user,password,query):
    print 'Using username and password to authenticate'
    url = pod+'/services/oauth2/token'
    print 'Url:',url
    querystring = json.loads('{"grant_type":"password","client_id":"'+client_id+'","client_secret":"'+client_secret+'","username":"'+user+'","password":"'+password+'"}')
    
    headers = {'cache-control': "no-cache"}
    response = requests.request("POST", url, headers=headers, params=querystring).json()
    token = response['access_token']
    instance_url = response['instance_url']
    print 'Instance:',instance_url
    print 'Access Token:',token
    
    endpoint = instance_url+serviceUrl+query
    
    headers = json.loads('{"Authorization": "Bearer '+token+'"}')
    query_result = requests.get(endpoint,data=data,headers=headers).json()
    return query_result

def queryWithSession(sessionfile,sessionId):
    if len(sessionfile)>0:
        print 'Using Session file ',sessionfile,' to authenticate'
        txt = open(sessionfile)
        sessionId = txt.read()
    print 'Using Session ID:', sessionId, ' and Server:',endpoint
    global headers
    headers = json.loads('{"Authorization":"OAuth '+sessionId+'"}')
    query_result = requests.get(endpoint,data=data,headers=headers).json()
    return query_result

def getAllQueryResults(query_result,instance_url,headers):
    total_records = query_result['totalSize'] + 0

    records = query_result['records']
    merged_records = records
    while query_result['done'] is False and len(merged_records) < total_records:
        nextRecords = query_result['nextRecordsUrl']
        endpoint = instance_url+nextRecords
        print 'ServiceUrl:',endpoint
        print 'Records: '+str(len(merged_records))+' of Total:'+str(total_records)
        query_result = requests.get(endpoint,data=data,headers=headers).json()
        records = query_result['records']
        merged_records = merged_records + records
    return merged_records

def enrichDataFrame(df):
    # Create new column for ClassName and extract JSON object
    df['ClassName'] = df['ApexClass'].apply(extract_json1, args=('Name',))
    
    for item in df['ApexTestRunResult'][0]:
        #print item
        df[item] = df['ApexTestRunResult'].apply(extract_json1, args=(item,))
    df['JobDate'] = pd.to_datetime(df.EndTime).dt.strftime('%m-%d-%Y')
    
    df.JobDate.replace('NaT','', inplace=True)
    # Reorder the ClassName column to put at beginning
    cols = list(df)
    cols.insert(2, cols.pop(cols.index('ClassName')))
    df = df.ix[:, cols]
    # Add App Name column
    df['App'] = pd.Series(app, index=df.index)
    # Add Database column
    df['Database'] = pd.Series(db, index=df.index)
    # Delete JSON object
    del df['ApexClass']
    del df['attributes']
    del df['ApexTestRunResult']
    return df

# File that contains SFDC Session ID which is returned by sfdx force:org:open
sessionfile = ''
# Org session id which is returned by sfdx force:org:open. Needs to be provided in single quotes
sessionId = ''
# Org user name where Apex Test are run
user = ''
# Org password where Apex Test are run
password = ''
# App name to insert column and generate file name
app = 'generic'
# Database system by default SDB
db = 'SDB'
# Pod with login URL, e.g. https://login.salesforce.com
pod = "https://gs1.salesforce.com"
# Instance url e.g. https://na37.salesforce.com
instance_url = pod
# Consumer key of connected app
client_id = '3MVG9nwRZX60mjQra5yKwxXiTWGuvvMQuX5vqNtgXUQAl5lDXoyBBKU66oRTBZKeW.Exu5rRx8_nxdGbbODYh'
# Client secret of connected app
client_secret = '4292478741080167126'
# Apex query
query = "SELECT ApexClass.Name,ApexClassId,ApexLogId,AsyncApexJobId,Id,Message,MethodName,Outcome,RunTime,QueueItemId,StackTrace,SystemModstamp,TestTimestamp,ApexTestRunResult.ClassesCompleted,ApexTestRunResult.ClassesEnqueued,ApexTestRunResult.CreatedDate,ApexTestRunResult.EndTime,ApexTestRunResult.MethodsCompleted,ApexTestRunResult.MethodsEnqueued,ApexTestRunResult.MethodsFailed,ApexTestRunResult.Source,ApexTestRunResult.StartTime,ApexTestRunResult.Status,ApexTestRunResult.TestTime FROM ApexTestResult"
# REST API service url
serviceUrl ='/services/data/v39.0/query/?q='
# Dummy data
data = {"ip":"1.1.2.3"}
# Headers for authentication
headers = ''
# Query results from SOQL query
query_results = ''
# URL for SOQL REST API call
endpoint = instance_url+serviceUrl+query

# Get CLI arguments
setCliParameters()
 
# Authenticate using username or session ID
if len(user)>0 and len(password)>0:
    # Authenticate user with username and password
    print 'Using username and password to authenticate'
    url = pod+'/services/oauth2/token'
    print 'Url:',url
    querystring = json.loads('{"grant_type":"password","client_id":"'+client_id+'","client_secret":"'+client_secret+'","username":"'+user+'","password":"'+password+'"}')
    
    headers = {'cache-control': "no-cache"}
    response = requests.request("POST", url, headers=headers, params=querystring).json()
    token = response['access_token']
    instance_url = response['instance_url']
    print 'Instance:',instance_url
    print 'Access Token:',token
    
    endpoint = instance_url+serviceUrl+query
    
    headers = json.loads('{"Authorization": "Bearer '+token+'"}')
    query_result = requests.get(endpoint,data=data,headers=headers).json()
elif len(sessionfile)>0 or len(sessionId)>0:
    # Authenticate user with sessionid
    query_result = queryWithSession(sessionfile,sessionId)
else:
    print 'Provide a username/password, a session file or a session ID'
    sys.exit(2)

# Execute SOQL query and return all results    
merged_records = getAllQueryResults(query_result,instance_url,headers) 

print 'Total Records:',str(len(merged_records))

elevations = json.dumps(merged_records)

# Load records into a DataFrame
df = pd.read_json(elevations)

# Transform dataframe
df = enrichDataFrame(df)

print 'Fail:',str(df[df["Outcome"]=='Fail'].count()["Outcome"])
print 'Pass:',str(df[df["Outcome"]=='Pass'].count()["Outcome"])
print 'Unique Jobs:',str(df["AsyncApexJobId"].nunique())
currentDate = time.strftime("%m-%d-%y")
csvFileName = "apexTestResult-"+app+"-"+currentDate+".csv"
df.to_csv(csvFileName, encoding='utf-8')

print 'Writing Apex results to:', csvFileName


