# LWC Data Table Screen Flow for Data Cloud

## Step-by-Step Guide to Installing Data table Lightning Web Component for Flow Screens in Salesforce

**Video Walkthrough** [Click Here](https://drive.google.com/file/d/1bpwktVm8bVJREvfaGfWl7nPf_HJrSpd9/view?usp=drive_link)

**Main Link**: [UnofficialSF](https://unofficialsf.com/datatable-lightning-web-component-for-flow-screens-2/)

### Step 1: Install or Upgrade Flow Base Packs

1. FlowActionsBasePack: Version 3.0.0 or later.
2. FlowScreenComponentsBasePack: Version 3.0.7 or later.

### Step 2: Install the Datatable Package

* Install the package in Production or Developer Org or Sandbox.

### Step 3: Activate Datatable Configuration Wizard

* Activate the latest version of the “Datatable Configuration Wizard” Flow.

### Step 4: Manage Assignments for Permission Set

1. Go to Setup > Users > Permission Sets > USF Flow Screen Component – Datatable.
2. Click Manage Assignments > Add Assignments.
3. Select users to assign.

### Step 5: Configure Columns and Attributes

* Use the Datatable Configuration Wizard to configure columns and set various attributes such as column widths, alignment, and filtering options.

### Step 6: Use in Flow Builder

* Drag the Datatable component onto the flow screen in Flow Builder.
* Provide it with a collection of records and a list of field names.

For detailed instructions and troubleshooting, refer to the full UnofficialSF Datatable Guide.

### Apex Class for Data Table LWC

```Apex
public class DC_WebEngagements {
    
    public class Request {
        @InvocableVariable(label='Input ID')
        public String id;
    }

    public class Result {
        @InvocableVariable
        public String queryResultJSON;
    }
    
    @InvocableMethod
    public static List<Result> returnRelatedRecords(List<Request> requests) {
        List<Result> response = new List<Result>();
        Result result = new Result();
        
        try {
            if (requests != null && !requests.isEmpty()) {
                Request request = requests[0]; // Assuming only one request is expected
                String id = request.id;
                String escapedId = id.replaceAll('\'', '\'\'');
                String sqlQuery = 'select ssot__EngagementDateTm__c as "EngagementDate", ssot__DataSourceId__c as "DataSource", ssot__Name__c as "Description", ssot__EngagementChannelActionId__c as "Action", ssot__EngagementChannelId__c as "Channel", ssot__EngagementChannelTypeId__c as "ChannelType", ssot__EngagementTypeId__c as "EngagementType", ssot__Referrer__c as "Referrer", ssot__IndividualId__c as "AccountID", ssot__AccountContactId__c as "ContactID" from ssot__WebsiteEngagement__dlm WHERE ssot__AccountContactId__c =\'' + escapedId + '\' order by ContactID, EngagementDate desc' ;
                
                ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
                input.sql = sqlQuery;
                ConnectApi.CdpQueryOutputV2 output = queryAnsiSqlV2(input);

                List<Map<String, Object>> resultsList = new List<Map<String, Object>>();
                for (ConnectApi.CdpQueryV2Row resultRow : output.data) {
                    Map<String, Object> rowDataMap = new Map<String, Object>();
                    rowDataMap.put('EngagementDate', resultRow.rowData[0]);
                    rowDataMap.put('DataSource', resultRow.rowData[1]);
                    rowDataMap.put('Description', resultRow.rowData[2]);
                    rowDataMap.put('Action', resultRow.rowData[3]);
                    rowDataMap.put('Channel', resultRow.rowData[4]);
                    rowDataMap.put('ChannelType', resultRow.rowData[5]);
                    rowDataMap.put('EngagementType', resultRow.rowData[6]);
                    rowDataMap.put('Referrer', resultRow.rowData[7]);
                    rowDataMap.put('AccountID', resultRow.rowData[8]);
                    rowDataMap.put('ContactID', resultRow.rowData[9]);
                    resultsList.add(rowDataMap);
                }

                if (!resultsList.isEmpty()) {
                    result.queryResultJSON = JSON.serialize(resultsList);
                } else {
                    result.queryResultJSON = 'No records found.';
                }
            } else {
                result.queryResultJSON = 'Invalid input.';
            }
        } catch (Exception e) {
            result.queryResultJSON = 'Error: ' + e.getMessage();
        }
        
        response.add(result);
        return response;
    }
    
    public static ConnectApi.CdpQueryOutputV2 queryAnsiSqlV2(ConnectApi.CdpQueryInput input) {
        return ConnectApi.CdpQuery.queryAnsiSqlV2(input);
    }
}
```

### Apex Class Explanation

#### Class and Inner Classes

* QueryAccountCases: The main class that handles querying related records.
* Request: An inner class that represents the input with a single field id.
* Result: An inner class that represents the output with a field queryResultJSON.

#### Invocable Method

* returnRelatedRecords: This is an @InvocableMethod which means it can be called from processes like Flow.
* Input: A list of Request objects.
* Output: A list of Result objects.

#### Process Flow

1. Initialization: Create a response list and a Result object.
2. Validation: Check if the input list requests is not null and not empty.
3. Retrieve Request: Take the first request object.
4. Escape ID: Sanitize the id to prevent SQL injection.
5. SQL Query: Construct a SQL query string to fetch related records based on the sanitized id.
6. Query Execution: Use ConnectApi.CdpQuery.queryAnsiSqlV2 to execute the query.
7. Process Results:
   * Iterate over the returned data.
   * Map the fields from the result rows to a list of maps.

8. Serialize Results: Convert the list of maps to JSON and assign it to queryResultJSON.
9. Error Handling: Catch any exceptions and set queryResultJSON to an error message if needed.
10. Return Response: Add the result to the response list and return it.

#### Helper Method

* queryAnsiSqlV2: Executes the SQL query using the ConnectApi and returns the results.

#### Example Breakdown of the SQL Query

* Fetch specific fields from the ssot__WebsiteEngagement__dlm object.
* Filter the records where ssot__AccountContactId__c matches the given id.
* Order the results by ssot__AccountContactId__c and ssot__EngagementDateTm__c.

This class is designed to be invoked from Salesforce Flow, taking an id, querying related records, and returning the results as JSON
