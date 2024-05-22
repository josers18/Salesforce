# Web Engagement Kinesis Tutorial

This doc explains the resources used to create a file to generate web engagements for a contact record or account record,  output to CSV, and then use that as the source to push the CSV file into a kinesis stream that loads into Data Cloud.

## Resources

I primarily followed this video from PM to figure out how to setup the connection and basically what to do

* [SF PM Kinesis Demo](https://drive.google.com/file/d/1y_6QAarSc-fQ8lB2nPW8wxG42qjXh7FU/view)

I used the following Quip doc as inspiration to generate the script

* [Quip Guide on Kinesis Connector](https://salesforce.quip.com/djqlARYH9bao)

I used the following AWS Doc to figure out the URLs for the connector since the documentation is lacking in this part

* [AWS Endpoint Listing](https://docs.aws.amazon.com/general/latest/gr/ak.html)

Official Kinesis Connector Doc:

* [Kinesis Connector Doc](https://help.salesforce.com/s/articleView?id=sf.c360_a_amazon_kinesis_connector.htm&type=5)

### Transaction Generator Script

```python
import pandas as pd
import random
import uuid
from datetime import datetime, timedelta

# Sample variable lists
contacts = ['003al000002AkZ4AAK']
case_ids = []
email_addresses = ['zach.acme@example.com']
engagement_channels = ['Web Chat', 'Email', 'Social Media']
engagement_channel_actions = ['Click', 'Submit', 'View']
engagement_channel_types = ['Inbound', 'Outbound']
engagement_types = ['Sales', 'Support', 'Marketing']
accounts = ['001al00000EkcjlAAB']
names = ['Page Visit', 'Form Submission', 'Live Chat']
referrers = ['Google', 'Direct', 'Social Media']

# Function to generate a random IP address
def generate_ip_address():
    return ".".join(str(random.randint(0, 255)) for _ in range(4))

# Function to generate a random datetime within a range
def generate_random_datetime(start_date, end_date):
    delta = end_date - start_date
    seconds = random.randint(0, delta.total_seconds())
    return start_date + timedelta(seconds=seconds)

# Function to generate a random UUID
def generate_uuid():
    return str(uuid.uuid4())

# Number of rows to generate (user-defined)
num_rows = 6

# Current date and time
current_datetime = datetime.now()

# Generate data and populate DataFrame
data = []
for _ in range(num_rows):
    created_date = generate_random_datetime(current_datetime - timedelta(days=5), current_datetime)
    website_visit_end_time = generate_random_datetime(created_date, created_date + timedelta(minutes=15))
    data.append({
        'Account_Contact': random.choice(contacts),
        'Case': random.choice(case_ids) if case_ids else '',
        'Contact_Point': random.choice(email_addresses),
        'Created_Date': created_date,
        'Device_Ip_Address': generate_ip_address(),
        'Engagement_Channel': random.choice(engagement_channels),
        'Engagement_Channel_Action': random.choice(engagement_channel_actions),
        'Engagement_Channel_Type': random.choice(engagement_channel_types),
        'Engagement_Type': random.choice(engagement_types),
        'Engagement_Date_Time': created_date,
        'Individual': random.choice(accounts),
        'IP_Address': generate_ip_address(),
        'Name': random.choice(names),
        'Referrer': random.choice(referrers),
        'Session': generate_uuid(),
        'Website_Engagement_ID': generate_uuid(),
        'Website_Visit_Start_Time': created_date,
        'Website_Visit_End_Time': website_visit_end_time
    })

# Create DataFrame
df = pd.DataFrame(data)
print(df)
path = '/Users/jsifontes/Documents/Dev/DataSet Creation/Data Cloud/'

# Export DataFrame to CSV
df.to_csv(path + 'web_engagements.csv', index=False)
print("CSV file generated successfully.")
```

### Script Explanation

This Python script generates a sample dataset of web engagements and saves it to a CSV file. Here's a simple explanation of what each part of the script does:

1. Import Libraries:

    * pandas: For creating and manipulating data frames.
    * random: For generating random numbers and selecting random items.
    * uuid: For generating unique identifiers.
    * datetime and timedelta: For working with dates and times.

2. Sample Data:

    * Defines lists of possible values for various fields, such as contacts, email_addresses, engagement_channels, etc.

3. Utility Functions:

    * generate_ip_address(): Creates a random IP address.
    * generate_random_datetime(start_date, end_date): Generates a random datetime between two given dates.
    * generate_uuid(): Generates a random unique identifier (UUID).

4. Configuration:

    * num_rows: Number of rows of data to generate.
    * current_datetime: The current date and time.

5. Data Generation:

    * Creates an empty list data to hold the generated records.
    * Uses a loop to generate num_rows records.
        * For each record, it randomly selects values from the sample lists.
        * Uses the utility functions to generate random IP addresses, dates, and UUIDs.
        * Creates a dictionary for each record with fields such as Account_Contact, Case, Contact_Point, Created_Date, etc.
        * Appends the dictionary to the data list.

6. DataFrame Creation and Export:

    * Converts the data list into a pandas DataFrame.
    * Prints the DataFrame.
    * Defines a file path.
    * Exports the DataFrame to a CSV file at the specified path.
    * Prints a message indicating that the CSV file was generated successfully.

### Explanation of Key Steps

1. Creating Random Data:

    * IP Address: Generates four random numbers between 0 and 255 and joins them to form an IP address.
    * Random DateTime: Calculates a random number of seconds within the range between start_date and end_date and adds this to the start_date to get a random datetime.
    * UUID: Uses uuid.uuid4() to create a random unique identifier.

2. Generating Records:

    * For each record, a random value is chosen from the lists for fields like contacts, email_addresses, etc.
    * Random dates are generated for Created_Date and Website_Visit_End_Time.
    * Random IP addresses and UUIDs are generated for the respective fields.
    * Each record is a dictionary that is appended to the data list.

3. DataFrame and CSV:

    * The list of dictionaries (data) is converted to a pandas DataFrame.
    * The DataFrame is exported to a CSV file.

By running this script, you will generate a CSV file containing N rows of random web engagement data, which can be used for ingestion into Data Cloud.

```python
Script to Push CSV to Kinesis

import boto3
import csv
import json

# AWS credentials and Kinesis Stream name
aws_access_key_id = 'YOUR ACCESS KEY ID'
aws_secret_access_key = 'YOUR SECRET KEY'
region_name = 'us-east-1'
stream_name = 'dc-kinesis-stream'

# Initialize Kinesis client
kinesis = boto3.client('kinesis', 
                       aws_access_key_id=aws_access_key_id,
                       aws_secret_access_key=aws_secret_access_key,
                       region_name=region_name)

# Function to send records to Kinesis
def send_to_kinesis(data):
    for record in data:
        # Convert each record to JSON format
        json_data = json.dumps(record)
        # Send the record to Kinesis
        response = kinesis.put_record(StreamName=stream_name, Data=json_data, PartitionKey='1')
        print("Record sent to Kinesis: {}".format(response['SequenceNumber']))

# Read CSV file and send records to Kinesis
def send_csv_to_kinesis(file_path):
    with open(file_path, 'r') as csvfile:
        csv_reader = csv.DictReader(csvfile)
        records = []
        for row in csv_reader:
            records.append(row)
            if len(records) == 500:  # Send 500 records at a time
                send_to_kinesis(records)
                records = []
        if records:  # Send remaining records
            send_to_kinesis(records)

# Path to CSV file
csv_file_path = '/Users/jsifontes/Documents/Dev/DataSet Creation/Data Cloud/web_engagements.csv'

# Send CSV file to Kinesis
send_csv_to_kinesis(csv_file_path)

print("CSV file sent to Kinesis Data Stream.")
```

### Kinesis Push Script Explanation

This Python script reads data from a CSV file and sends it to an AWS Kinesis Data Stream.

1. Import Libraries:

    * boto3: For interacting with AWS services.
    * csv: For reading CSV files.
    * json: For converting data to JSON format.

2. AWS Credentials and Stream Configuration:

    * aws_access_key_id, aws_secret_access_key, region_name: AWS credentials and region information.
    * stream_name: The name of the Kinesis stream.

3. Initialize Kinesis Client:

    * Uses boto3.client to create a Kinesis client with the provided AWS credentials and region.

4. Function to Send Records to Kinesis:

    * send_to_kinesis(data): Takes a list of records and sends them to the Kinesis stream.
        * Converts each record to JSON format.
        * Uses kinesis.put_record to send the JSON data to Kinesis.
        * Prints the sequence number of the sent record.

5. Function to Read CSV and Send Records to Kinesis:

    * send_csv_to_kinesis(file_path): Reads data from a CSV file and sends it to Kinesis in batches.
        * Opens the CSV file using csv.DictReader.
        * Reads rows from the CSV and appends them to a list called records.
        * Sends records to Kinesis in batches of 500.
        * Sends any remaining records after the loop.

6. CSV File Path:

    * csv_file_path: The path to the CSV file that will be read and sent to Kinesis.

7. Execute the Script:

    * Calls send_csv_to_kinesis with the path to the CSV file.
    * Prints a message indicating that the CSV file has been sent to the Kinesis Data Stream.

### Explanation of Key Script Steps

1. Kinesis Client Initialization:

    * boto3.client('kinesis', ...): Creates a Kinesis client with the specified credentials and region.

2. Sending Records to Kinesis:

    * send_to_kinesis(data): Converts each record in the list to JSON and sends it to the Kinesis stream using kinesis.put_record.
    * The PartitionKey is set to '1' for all records in this example.

3. Reading and Sending CSV Data:

    * send_csv_to_kinesis(file_path): Reads the CSV file and processes it row by row.
        * Uses csv.DictReader to read the CSV file into dictionaries.
        * Appends each row to a list called records.
        * Sends the records to Kinesis in batches of 500 using send_to_kinesis.
        * Ensures any remaining records are sent after the loop completes.

#### Sample YAML Schema File for establishing Data Cloud Kinesis Ingestion Stream

You can copy this file into a text editor and save as a .yaml file then upload it into Data Cloud

```yaml
openapi: 3.0.0
info:
  title: Web Engagement Data Schema
  version: 1.0.0
paths: {}
components:
  schemas:
    WebEngagement:
      type: object
      properties:
        Account_Contact:
          type: string
          description: Randomly selected from a variable list of contacts
        Case:
          type: string
          description: Case ID populated from a list of case IDs, empty when no IDs on list
        Contact_Point:
          type: string
          description: Selected from Email Address from a variable
        Created_Date:
          type: string
          format: date-time
          description: Date Time field for creation date
        Device_Ip_Address:
          type: string
          description: Random fake IP Address
        Engagement_Channel:
          type: string
          description: Selected from a variable
        Engagement_Channel_Action:
          type: string
          description: Selected from a variable
        Engagement_Channel_Type:
          type: string
          description: Selected from a variable
        Engagement_Type:
          type: string
          description: Selected from a variable
        Engagement_Date_Time:
          type: string
          format: date-time
          description: Same as Created_Date
        Individual:
          type: string
          description: Randomly selected from a variable list of accounts
        IP_Address:
          type: string
          description: Same as Device_Ip_Address
        Name:
          type: string
          description: Selected from a variable
        Referrer:
          type: string
          description: Selected from a variable
        Session:
          type: string
          description: Randomly generated UUID
        Website_Engagement_ID:
          type: string
          description: Randomly generated UUID
        Website_Visit_Start_Time:
          type: string
          format: date-time
          description: Same as Created_Date
        Website_Visit_End_Time:
          type: string
          format: date-time
          description: Randomly selected from a range of 1 to 15 minutes from Created_Date
```
