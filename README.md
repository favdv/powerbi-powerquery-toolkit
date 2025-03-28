# The repository
This repository is used to store snippets of Power Query that other Power BI developers might also find of interest.

Note that some snippets can be copied and used immediately, while others need some minor tweaking for your specific environment. For example: API calls using the Web.Contents function must have the domain hard coded, otherwise auto-refresh will not work.  

# Repo structure
The repository is set up in a way to easily target specific functions or patterns by seprating them into categories, like apis, data management (expanding/removing columns), etc.  

## Functions
 Functions can be used without any user amendments and they should work immediately if used properly. To make them recognisable, their extension is *.pq* (Power Queries)

_**Note:** While it might not be obvious that this is needed in PowerBI desktop, the functions are written in a way so it will also ensure auto-refresh works once published._

## Templates
Patterns typically might require some user updating before they can be used. To make them recognisable, their extension is *.pt* (PQ Templates)

Typical example is functions calling APIs since the Web.Contents function in PowerBi requires the domain to be hardcoded. So the user needs to hardcode their own domain in. 

Since patterns require some modification, these should not be linked directly from github

## Sample Data
Sample data is added to the *samples* folder. Most of this is based on well known sample databases, like *Northwind*. The data is either directly retrieved from the sourse repositories or from another repo who has done some conversion (e.g. from a SQL Server database to CSV or Excel). No responsibility of the quality or accuracy of the data data will be assumed as the data is converted as-is and no values or table columns are modified or added. In some cases, data is removed that were ot essential (like blob representation or links), and entries were fixes where the CSV or imports would not be properly structured (e.g. interpretation of addresses with commas that would be split on import wr fixed by wrapping them in quotes in the csv).

Samples are not intended to be interpreted as live data, but can be used to test certain scenarios in PowerBI. 


# Implementation of functions
There are different ways to use the functions available in the repo. This provides some guidance on options with an example (based on a simple function). In this section, function [DeleteEmptyColumnsViaLooping](https://github.com/favdv/powerbi-powerquery-toolkit/blob/main/generic/DeleteEmptyColumnsViaLooping.pq) is being used as it is small, but the process is the same for all functions.

## Linking to the function in the Github repo

In PowerBI: 
- Open a new blank query
- Copy the following code in the query:

```
let
  Source = Expression.Evaluate(
    Text.FromBinary(
      Web.Contents(
        "<github url of the raw version of the function>"
      )
    ), 
    <array of functions>
  )
in Source
```
_**Note:** The URL can be found by browsing the the function in the repo and select the Raw button._

- Rename the function/query to whatever you want in PowerBI (unless explicitly stated otherwise in the comments of the function itself)

To call the function/query, simply add a new step to call the function. For example, If you have a previous step containing your table, named **"Table1"** and the function was renamed **DeleteCols** the new step can be called via 

```
let
  Table1 = ...,
  #"Delete my columns" = DeleteCols(Table1)
in #"Delete my columns"
```
Pros
- The function is always up to date, so any amendments made to the code are automatically reflected.
- The function can be updated without interaction with the report itself. (if preferred, this repo can be forked and maintained independently.
- No need for the powerBI user or developer to maintain the function.
- The function can be called in any position in any table within the PowerBi report.
- If used across powerBi reports, the functionality will be consistent.  

Cons
- If the function is moved, the report will break. To fix a moved function, the link will need to be updated.
- If the function is deleted, the report will break. To fix this, remove the references to the function and/or rewrite the function.
- This option is not suitable for patterns.
- Any bugs or changes introduced in the function within Github will be reflected in the report and could impact performance, functionality in PowerBi, etc.
- Authentication might be required depending on the type of repo. _**Note:** Depending if the repository is public or private, you might need to authenticate. If it is a public repository, you can select the repo from the dropdown and perform authenticate anonymously._
- Using this method stops auto-refresh as it assumes retrieving the code via a link to github is a dynamic data source when using #shared as the environment. To mitigate this, replace #shared with an array of specific functions. For instance, if the function only uses Table.AddColumn and Text.Replace functions, the function would look something like this:
```
let
  Source = Expression.Evaluate(
    Text.FromBinary(
      Web.Contents(
        "<github url of the raw version of the function>"
      )
    ), 
    	[
		Table.AddColumn = Table.AddColumn,
		Text.Replace = Text.Replace
	]
  )
in Source
```
A full list of functions available can be found as follows:
- Open a blank query
- Copy the following function into the blank query:
```
let Source = Record.FieldNames(#shared) in Source
```
- A list with all functions available in your powerbi report. Since you can't use a fullstop for a custom function name, you could filter the list on items with a fullstop only to get the default functions.

_**Note that some functions, like Web.Contents are not available in #shared, meaning that those will likely be treated as dynamic data sources. This currently mainly relates to API functions. To mitigate this, those would need to be copied into the powerBI report instead of referencing from the github repo.**_
|
## Copy the code as a new function in PowerBI

In PowerBI: 
- Open a new blank query
- Copy the content of the function in the querye.g. :
```
(selectedTable as table) =>
  Table.RemoveColumns(
    selectedTable, List.RemoveNulls( 
      List.Generate(
      ()=>[i=0],
      each [i]<Table.ColumnCount(selectedTable),
      each [i=[i]+1],
      each let i = [i] in 
        if Table.RowCount(Table.SelectRows(
          selectedTable,
          each Record.Field(_,Table.ColumnNames(selectedTable){i})<>null)) = 0 
        then Table.ColumnNames(selectedTable){i} 
        else null
      ) 
    )
  )
```
 
- Rename the function/query to whatever you want in PowerBI (unless explicitly stated otherwise in the comments of the function itself)

To call the function/query, simply add a new step to call the function. For example, If you have a previous step containing your table, named **"Table1"** and the function was renamed **DeleteCols** the new step can be called via 

```
let
  Table1 = ...,
  #"Delete my columns" = DeleteCols(Table1)
in #"Delete my columns"
```

Pros:
- Any detrimental changes (deletion, moving a function, introduction of bugs) to the function in Github will not be reflected in the report.
- No authentication is required (unless the function calls an API or uses a connector requiring authentication).
- The function can be called in any position in any table within the PowerBi report.  

Cons:
- If the intent is to keep the function up to date, the developer needs to replace the content of the function when an update is made.
- Since only one person can work on a report in PoweBI Desktop, it needs to be updated by someone with PowerBi desktop and republish.

## Embed the code as a new function in a PowerBI table

In PowerBI: 
- Open the table where you want to embed the table
- Anywhere above the area where you want to call the function, add a new step and after the equal sign paste the content of the function in the query, e.g.:

```
let
  Table1 = ...,
  DeleteCols = (selectedTable as table) =>
               Table.RemoveColumns(
                 selectedTable, List.RemoveNulls( 
                 List.Generate(
                ()=>[i=0],
                each [i]<Table.ColumnCount(selectedTable),
                each [i=[i]+1],
                each let i = [i] in 
                   if Table.RowCount(Table.SelectRows(
                     selectedTable,
                     each Record.Field(_,Table.ColumnNames(selectedTable){i})<>null)) = 0 
                   then Table.ColumnNames(selectedTable){i} 
                 else null
               ) 
             )
           ),
  Delete = DeleteCols(Table1)
in Delete
```

To call the function/query, simply add a new step to call the function. For example, If you have a previous step containing your table, named **"Table1"** and the function was renamed **DeleteCols** the new step can be called as shown above.

Pros:
- Any detrimental changes (deletion, moving a function, introduction of bugs) to the function in Github will not be reflected in the report.
- No authentication is required (unless the function calls an API or uses a connector requiring authentication).
- The function can be called in any position in the table containing within the PowerBi report as long as the function is above a step where the function is called.
- It is easier to work out what is happening in the function than having the function external to the table.
- The function is customisable on a table by table basis  

Cons:
- If the intent is to keep the function up to date, the developer needs to replace the content of the function when an update is made.
- Since only one person can work on a report in PoweBI Desktop, it needs to be updated by someone with PowerBi desktop and republish.
- The function can only be called within the table the function resides, so if it is needed for a second table, the same process needs to be followed.

## Turn the function to a step in a PowerBI table

In PowerBI: 
- Open the table where you want to embed the table
- Ads a new step  with the code as needed and rename the references to the parameters to the values needed (e.g. in the below, the parameter was **selectedTable**, and these would need to be changed to **Table1** in this case:

```
let
  Table1 = ...,
  DeleteCols = Table.RemoveColumns(
                 Table1, List.RemoveNulls( 
                 List.Generate(()=>[i=0],each [i]<Table.ColumnCount(Table1), each [i=[i]+1], each let i = [i] in 
                   if Table.RowCount(Table.SelectRows(
                     Table1,
                     each Record.Field(_,Table.ColumnNames(Table1){i})<>null)) = 0 
                   then Table.ColumnNames(Table1){i} 
                 else null
               ) 
             )
           )
in DeleteCols
```

Pros:
- Any detrimental changes (deletion, moving a function, introduction of bugs) to the function in Github will not be reflected in the report.
- No authentication is required (unless the function calls an API or uses a connector requiring authentication).
- No need to call the function as it is just a step.
- It is easier to work out what is happening in the step than having the function external to the table.
- The function is customisable on a table by table basis  

Cons:
- If the intent is to keep the function up to date, the developer needs to replace the content of the function when an update is made.
- Since only one person can work on a report in PoweBI Desktop, it needs to be updated by someone with PowerBi desktop and republish.
- If the intent is to call the functionality more than once, you have copy and update the step multiple times, making it more difficult to maintain if somehting is incorrect.
- For more complex functions, you might end up creating a [partitioned step](https://learn.microsoft.com/en-us/analysis-services/tom/table-partitions?view=asallproducts-allversions), which could cause refresh issues, especially when you're working with multiple external sources (an error stating that a source cannot be accessed directly or similar will be shown).

## Retrieve repo directly into PowerBI  
You can retrieve information directly from Github using the Github.RetrieveFiles.pt function un the Utils folder. Simply copy the fnction in a blank query.

To run the query, create a second blank query and copy the following code in:
```
let
    Source = Query1()
in
    Source
```

_**Note:** In this case the query that the function was copied into was called Query1 - rename as appropriate._

Now it is called, you can continue building your table and call the functions in the table as follows with the relevant function name in the square brackets:

```
let
    Source = Query( ),

    Data = <your data>,

     ExpandAll = Source[Table.ExpandAllColumns](Data)

in
    ExpandAll
```    

_**Note:** For more information, see also [https://www.linkedin.com/pulse/using-power-queries-directly-from-github-repository-van-der-vorst-wm6pe/?trackingId=yM4vQH%2FTTwmy%2BR4AayQCig%3D%3D](https://www.linkedin.com/pulse/using-power-queries-directly-from-github-repository-van-der-vorst-wm6pe/?trackingId=yM4vQH%2FTTwmy%2BR4AayQCig%3D%3D)._

Pros:
- The function is always up to date, so any amendments made to the code are automatically reflected.
- The function can be updated without interaction with the report itself. (if preferred, this repo can be forked and maintained independently.
- No need for the powerBI user or developer to maintain the function.
- The function can be called in any position in any table within the PowerBi report.
- If used across powerBi reports, the functionality will be consistent.  
- As the repo with functions grows, so will the list of available functions.
- Rereshing the report once published will work  

Cons:
- Authentication might be requireddepending on the repo.
- Any detrimental changes (deletion, moving a function, introduction of bugs) to the function in Github will be reflected in the report.
- Depending on the filters set, functions created might not work appropriately. In this repo, oly items with extension .pq are considered out of the box functions
- The function might occasionally need updated when new #shared functions are used.

# Using Templates
As mentioned, a pattern is defined as a function where some modification is needed. A typical example is a web service call, e.g. 

```
(SourceTable as table, Domains as text, Projects as text)=> 
let
  #"Get Keys" = Table.ExpandRecordColumn(
		  Table.ExpandListColumn(
		    Table.ExpandRecordColumn(
		      Table.AddColumn(SourceTable, "keys", each 
            if Record.Field(_,Domains) = "<your domain>" 
            then Json.Document(
              Web.Contents(
                "<your domain>",
                  [
                    RelativePath = "rest/api/3/search/",
                    Query = [
                      jql="project="&Record.Field(_,Projects),
                      maxResults = "10000" 
                    ]
                  ]
              )
            )
            else null
          ), 
		      "keys", {"issues"}
		    ), "issues"
		  ), 
		  "issues", {"key"}
	  )
in #"Get Keys"
```

In this case, **"&lt;your domain&gt;"** needs to be replaced with the string (e.g. with **"https://xyz.atlassian.net"**) of your JIRA domain omit the forward slash at the end of your domain, otherwise the function will return nothing). While a reasonable question would be to ask why **Record.Field(_,Domains)** is not added to the Web.Contents area as this works in PowerBI desktop, there is a reason for it being implemented as it is. 

In the function above, if the domain does not match the string, the field will be populated with null. This can be changed to suit of course.

Essentially, a published PowerBi report cannot easily verify a dynamic domain, meaning you end up with an "dynamic datasource" error. To mitigate this, you can use a workaround via an if statement to check if **Record.Field(_,Domains)** matches a certain string and if it does, use the string as the domain. 

_**Note:** All other parts of the Web.Contents function (RelativePath and Query's) do allow parameters and dynamic content to be used, only the main domain does not._

To add more domains (in this case), extend the if statement as follows:

```
(SourceTable as table, Domains as text, Projects as text)=> 
let
  #"Get Keys" = Table.ExpandRecordColumn(
		  Table.ExpandListColumn(
		    Table.ExpandRecordColumn(
		      Table.AddColumn(SourceTable, "keys", each 
            if Record.Field(_,Domains) = "<your domain>" 
            then Json.Document(
              Web.Contents(
                "<your domain>",
                  [
                    RelativePath = "rest/api/3/search/",
                    Query = [
                      jql="project="&Record.Field(_,Projects),
                      maxResults = "10000" 
                    ]
                  ]
              )
            ) else


            if Record.Field(_,Domains) = "<your second domain>" 
            then Json.Document(
              Web.Contents(
                "<your second domain>",
                  [
                    RelativePath = "rest/api/3/search/",
                    Query = [
                      jql="project="&Record.Field(_,Projects),
                      maxResults = "10000" 
                    ]
                  ]
              )
            )

            ...

            else null
          ), 
		      "keys", {"issues"}
		    ), "issues"
		  ), 
		  "issues", {"key"}
	  )
in #"Get Keys"
```
