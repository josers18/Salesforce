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