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
import beatbox
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
# Pod
pod = "https://login.salesforce.com"
client_id = '3MVG9nwRZX60mjQra5yKwxXiTWGuvvMQuX5vqNtgXUQAl5lDXoyBBKU66oRTBZKeW.Exu5rRx8_nxdGbbODYh'
client_secret = '4292478741080167126'

# Get CLI arguments
try:
    # Parse CLI arguments
    opts, args = getopt.getopt(sys.argv[1:], 'hs:u:p:a:i:d:p:x:y:v', ['help','sessionfile','username','password','app','sessionid','database','pod','client_id','client_secret'])
except getopt.GetoptError:
    print 'apexResultsRest.py -s <sessionfile> -i <sessionid> -u <username> -p <password> -a <application> -d <database> -p <pod>'
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
            print 'apexResultsRest.py -s <sessionfile> -i <sessionid> -u <username> -p <password> -a <application> -d <database>'
            sys.exit()
    elif opt in ("-s", "--sessionfile"):
            sessionfile = arg
    elif opt in ("-u", "--username"):
            user = arg
    elif opt in ("-p", "--password"):
            password = arg
    elif opt in ("-a", "--app"):
            app = arg
    elif opt in ("-i", "--sessionid"):
            sessionId = arg
    elif opt in ("-d", "--database"):
            db = arg
    elif opt in ("-p", "--pod"):
            pod = arg
    elif opt in ("-x", "--client_id"):
            client_id = arg
    elif opt in ("-y", "--client_secret"):
            client_secret = arg

query = "SELECT ApexClass.Name,ApexClassId,ApexLogId,AsyncApexJobId,Id,Message,MethodName,Outcome,RunTime,QueueItemId,StackTrace,SystemModstamp,TestTimestamp,ApexTestRunResult.ClassesCompleted,ApexTestRunResult.ClassesEnqueued,ApexTestRunResult.CreatedDate,ApexTestRunResult.EndTime,ApexTestRunResult.MethodsCompleted,ApexTestRunResult.MethodsEnqueued,ApexTestRunResult.MethodsFailed,ApexTestRunResult.Source,ApexTestRunResult.StartTime,ApexTestRunResult.Status,ApexTestRunResult.TestTime FROM ApexTestResult"

serviceUrl ='/services/data/v39.0/query/?q='

endpoint = pod+serviceUrl+query
print 'Endpoint:',endpoint
data = {"ip":"1.1.2.3"}
headers = ''
query_results = ''

# Authenticate using username or session ID
if len(user)>0 and len(password)>0:
    print 'Using username and password to authenticate'
    url = pod+"/services/oauth2/token"
    print 'Url:',url
    querystring = json.loads('{"grant_type":"password","client_id":"'+client_id+'","client_secret":"'+client_secret+'","username":"'+user+'","password":"'+password+'"}')
    print 'QueryString:',querystring
    headers = {'cache-control': "no-cache"}
    response = requests.request("POST", url, headers=headers, params=querystring).json()
    token = response['access_token']

    print 'Access Token:',token

    headers = json.loads('{"Authorization": "Bearer '+token+'"}')
    query_result = requests.get(endpoint,data=data,headers=headers).json()
    #service.login(user, password)  # login using your sf credentials
elif len(sessionfile)>0 or len(sessionId)>0:
    if len(sessionfile)>0:
        print 'Using Session file ',sessionfile,' to authenticate'
        txt = open(sessionfile)
        sessionId = txt.read()
    print 'Using Session ID:', sessionId, ' and Server:',endpoint
    headers = json.loads('{"Authorization":"OAuth '+sessionId+'"}')
    query_result = requests.get(endpoint,data=data,headers=headers).json()
else:
    print 'Provide a username/password, a session file or a session ID'
    sys.exit(2)
total_records = query_result['totalSize'] + 0
print 'ServiceUrl:',serviceUrl
print 'Header:',headers

records = query_result['records']
merged_records = records
while query_result['done'] is False and len(merged_records) < total_records:
    nextRecords = query_result['nextRecordsUrl']
    endpoint = "https://gs1.salesforce.com"+nextRecords
    print 'ServiceUrl:',endpoint
    print 'Records: '+str(len(merged_records))+' of Total:'+str(total_records)
    query_result = requests.get(endpoint,data=data,headers=headers).json()
    records = query_result['records']
    merged_records = merged_records + records 

    
# Writing Apex Results to CSv file
#print 'Writing ',total_records,' Apex Test Results to file'

# Exit if there are no Apex Results
#if total_records == 0:
#    exit()

print 'Total Records:',str(len(merged_records))

elevations = json.dumps(merged_records)


# Load records into a DataFrame
df = pd.read_json(elevations)

# Create new column for ClassName and extract JSON object
df['ClassName'] = df['ApexClass'].apply(extract_json1, args=('Name',))
#df['EndTime'] = df['ApexTestRunResult'].apply(extract_json1, args=('EndTime',))
#print df['ApexTestRunResult'][0]
for item in df['ApexTestRunResult'][0]:
    #print item
    df[item] = df['ApexTestRunResult'].apply(extract_json1, args=(item,))
df['JobDate'] = pd.to_datetime(df.EndTime).dt.strftime('%m-%d-%Y')
#df.loc[df.JobDate == 'NaT', 'JobDate'] = ''
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
# Delete empty column
#del df['Unnamed: 0']

print 'Fail:',str(df[df["Outcome"]=='Fail'].count()["Outcome"])
print 'Pass:',str(df[df["Outcome"]=='Pass'].count()["Outcome"])
print 'Unique Jobs:',str(df["AsyncApexJobId"].nunique())
currentDate = time.strftime("%m-%d-%y")
csvFileName = "apexTestResult-"+app+"-"+currentDate+".csv"
df.to_csv(csvFileName, encoding='utf-8')

print 'Writing Apex results to:', csvFileName


