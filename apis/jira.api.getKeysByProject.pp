let 
functionName = "Jira.GetKeysByProject",
doc = 
  [
    DOcumentation.Api = "https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/#api-rest-api-3-search-get",
    Documentation.Name =  "Get JIRA Keys by Project", 
    Documentation.Description = "This function is a jira specific pattern, which retrieves the JIRA keys for specific project IDs. Ensure you modify your domain(s) to suit your specific requirements. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace "&functionName&" with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Retrieve Filter Ids with specified column name",
            Code = functionName&"(Source, ""DomainColumn"",""ProjectColumn"",""Key"")",
            Result = "A new column 'Key' is added with the keys for value combination the specified columns"
          ],
          [
            Description = "Retrieve Filter Ids with default column name",
            Code = functionName&"(Source, ""DomainColumn"",""ProjectColumn"")",
            Result = "A new column 'keys' (default column name) is added with the keys for value combination the specified columns"
          ]
	}
  ],
fn = (SourceTable as table, Domains as text, Projects as text, optional NewKeyColumnName as nullable text)=> 
  Table.ExpandRecordColumn(
    Table.ExpandListColumn(
      Table.ExpandRecordColumn(
	      Table.AddColumn(SourceTable, if NewKeyColumnName = null then "keys" else NewKeyColumnName, each 
          if Record.Field(_,Domains) = "<domain>" 
          then Json.Document(Web.Contents(
            "<domain>",
            [RelativePath = "rest/api/3/search/",
             Query = [
               jql="project="&Record.Field(_,Projects),
               fields="key",
               maxResults = "10000" 
             ]
            ]))
          else null
        ), 
	      NewKeyColumnName, {"issues"}
	    ), "issues"
	  ), 
    "issues",{"key"}, {NewKeyColumnName}
	)
 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
