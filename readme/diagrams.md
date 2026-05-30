# Diagrams

The following diagrams utilize mermaid.

## Builder API Architecture

This document provides visual diagrams of the Cake query builder API architecture.

### Builder API Overview

```mermaid
graph TB
    Start([Start Building Query]):::accent0
    
    Start --> SelectQ[SELECT Query]:::accent1
    Start --> InsertQ[INSERT Query]:::accent2
    Start --> UpdateQ[UPDATE Query]:::accent3
    Start --> DeleteQ[DELETE Query]:::accent4
    
    SelectQ --> BuildSelect[Build SELECT]
    InsertQ --> BuildInsert[Build INSERT]
    UpdateQ --> BuildUpdate[Build UPDATE]
    DeleteQ --> BuildDelete[Build DELETE]
    
    BuildSelect --> ToRead[to_query]:::accent5
    BuildInsert --> ToWrite1[to_query]:::accent5
    BuildUpdate --> ToWrite2[to_query]:::accent5
    BuildDelete --> ToWrite3[to_query]:::accent5
    
    ToRead --> ReadQuery[ReadQuery]:::accent6
    ToWrite1 --> WriteQuery[WriteQuery]:::accent6
    ToWrite2 --> WriteQuery
    ToWrite3 --> WriteQuery
    
    ReadQuery --> PrepStmt[to_prepared_statement]:::accent7
    WriteQuery --> PrepStmt
    
    PrepStmt --> Exec[Execute with Adapter]:::accent0
```

### SELECT Query Builder Flow

```mermaid
graph LR
    New[select.new]:::accent0
    
    New --> Select[SELECT Clause]:::accent1
    Select --> Select1[select_col]
    Select --> Select2[selects]
    Select --> Select3[select]
    
    New --> From[FROM Clause]:::accent2
    From --> From1[from_table]
    From --> From2[from_query]
    
    New --> Join[JOIN Clause]:::accent3
    Join --> Join1[join]
    Join --> Join2[joins]
    
    New --> Where[WHERE Clause]:::accent4
    Where --> Where1[where]
    Where --> Where2[or_where]
    Where --> Where3[xor_where]
    
    New --> Group[GROUP BY]:::accent5
    Group --> Group1[group_by]
    Group --> Group2[group_bys]
    
    New --> Having[HAVING Clause]:::accent5
    Having --> Having1[having]
    
    New --> Order[ORDER BY]:::accent6
    Order --> Order1[order_by_asc]
    Order --> Order2[order_by_desc]
    
    New --> Limit[LIMIT/OFFSET]:::accent7
    Limit --> Limit1[limit]
    Limit --> Limit2[offset]
    
    New --> Meta[Metadata]:::accent0
    Meta --> Meta1[comment]
    Meta --> Meta2[epilog]
```

### INSERT Query Builder Flow

```mermaid
graph LR
    Constructor[INSERT Constructor]:::accent0
    
    Constructor --> New[insert.new]
    Constructor --> FromRec[from_records]
    Constructor --> FromVal[from_values]
    
    New --> Table[table]:::accent1
    FromRec --> Table
    FromVal --> Table
    
    Table --> Columns[Columns]:::accent2
    Columns --> Cols[columns]
    
    Table --> Source[Source Data]:::accent3
    Source --> Records[records + encoder]
    Source --> Values[values]
    
    Table --> Conflict[Conflict Strategy]:::accent4
    Conflict --> OnConflict[on_conflict_do_nothing]
    Conflict --> OnConflictUp[on_conflict_update]
    
    Table --> Return[RETURNING]:::accent5
    Return --> Returning[returning]
    
    Table --> Metadata[Metadata]:::accent6
    Metadata --> Comment[comment]
    Metadata --> Epilog[epilog]
```

### UPDATE Query Builder Flow

```mermaid
graph LR
    New[update.new]:::accent0
    
    New --> Table[table]:::accent1
    
    Table --> Set[SET Clause]:::accent2
    Set --> SetBool[set_bool]
    Set --> SetInt[set_int]
    Set --> SetStr[set_string]
    Set --> SetExpr[set_expression]
    Set --> SetSub[set_sub_query]
    
    Table --> From[FROM Clause]:::accent3
    From --> FromTable[from_table]
    From --> FromQuery[from_query]
    
    Table --> Join[JOIN Clause]:::accent4
    Join --> Joins[join/joins]
    
    Table --> Where[WHERE Clause]:::accent5
    Where --> WhereAnd[where]
    Where --> WhereOr[or_where]
    Where --> WhereXor[xor_where]
    
    Table --> Return[RETURNING]:::accent6
    Return --> Returning[returning]
    
    Table --> Meta[Metadata]:::accent7
    Meta --> Comment[comment]
    Meta --> Epilog[epilog]
```

### DELETE Query Builder Flow

```mermaid
graph LR
    New[delete.new]:::accent0
    
    New --> Mod[modifier]:::accent1
    
    New --> Table[table]:::accent2
    
    Table --> Using[USING Clause]:::accent3
    Using --> UsingTable[using_table]
    Using --> UsingQuery[using_query]
    
    Table --> Join[JOIN Clause]:::accent4
    Join --> Joins[join/joins]
    
    Table --> Where[WHERE Clause]:::accent5
    Where --> WhereAnd[where]
    Where --> WhereOr[or_where]
    Where --> WhereXor[xor_where]
    
    Table --> Return[RETURNING]:::accent6
    Return --> Returning[returning]
    
    Table --> Meta[Metadata]:::accent7
    Meta --> Comment[comment]
    Meta --> Epilog[epilog]
```

### Query to Prepared Statement Flow

```mermaid
graph TB
    Query[Query Builder]:::accent0
    
    Query --> ToQuery[to_query]:::accent1
    
    ToQuery --> CakeRead[CakeReadQuery]:::accent2
    ToQuery --> CakeWrite[CakeWriteQuery]:::accent3
    
    CakeRead --> Prep[to_prepared_statement]:::accent4
    CakeWrite --> Prep
    
    Prep --> Dialect{Select Dialect}:::accent5
    
    Dialect --> Postgres[PostgreSQL]:::accent6
    Dialect --> SQLite[SQLite]:::accent6
    Dialect --> MariaDB[MariaDB]:::accent6
    Dialect --> MySQL[MySQL]:::accent6
    
    Postgres --> PrepStmt[PreparedStatement]:::accent7
    SQLite --> PrepStmt
    MariaDB --> PrepStmt
    MySQL --> PrepStmt
    
    PrepStmt --> SQL[get_sql]:::accent0
    PrepStmt --> Params[get_params]:::accent0
    
    SQL --> Execute[Execute Query]:::accent1
    Params --> Execute
```

### Value Types and Parameters

```mermaid
graph TB
    Values[Value Types]:::accent0
    
    Values --> Select[SELECT Values]:::accent1
    Select --> Col[col - Column Reference]
    Select --> Alias[alias - Column Alias]
    Select --> Param1[Params: bool, int, float, string, date, null]
    Select --> Frag1[fragment - Raw SQL]
    
    Values --> Insert[INSERT Values]:::accent2
    Insert --> Row[row - InsertRow]
    Insert --> Param2[Params: bool, int, float, string, date, null]
    Insert --> Frag2[fragment - Raw SQL]
    
    Values --> Update[UPDATE Values]:::accent3
    Update --> SetParam[set_* - Param Sets]
    Update --> SetExpr[set_expression - SQL Expression]
    Update --> SetSub[set_sub_query - SubQuery]
    Update --> SetFrag[set_fragment - Raw SQL]
    
    Values --> Where[WHERE Conditions]:::accent4
    Where --> Comparison[eq, ne, gt, lt, gte, lte]
    Where --> Pattern[like, ilike]
    Where --> Membership[in, not_in]
    Where --> Nullness[is_null, is_not_null]
    Where --> Logic[and, or, xor]
```

### JOIN Types and Structure

```mermaid
graph TB
    JoinRoot[JOIN Operations]:::accent0
    
    JoinRoot --> Types[Join Types]:::accent1
    Types --> Inner[inner - INNER JOIN]
    Types --> Left[left - LEFT JOIN]
    Types --> Right[right - RIGHT JOIN]
    Types --> Full[full - FULL JOIN]
    Types --> Cross[cross - CROSS JOIN]
    
    JoinRoot --> Target[Join Target]:::accent2
    Target --> JTable[table - Table Name]
    Target --> JQuery[query - SubQuery]
    
    JoinRoot --> On[Join Condition]:::accent3
    On --> OnWhere[on - WHERE condition]
    On --> Using[using - Column List]
    
    JoinRoot --> Alias[Join Alias]:::accent4
    Alias --> AliasName[alias - Table Alias]
    
    JoinRoot --> Lateral[LATERAL Support]:::accent5
    Lateral --> LatFlag[lateral - Boolean Flag]
```

### Complete Query Building Example

```mermaid
sequenceDiagram
    participant User
    participant Builder
    participant Query
    participant PrepStmt
    participant Adapter
    
    User->>Builder: select.new()
    Builder->>Query: Create empty Select
    
    User->>Builder: select_cols(["name", "age"])
    Builder->>Query: Add SELECT columns
    
    User->>Builder: from_table("users")
    Builder->>Query: Add FROM clause
    
    User->>Builder: join(inner join owners)
    Builder->>Query: Add JOIN clause
    
    User->>Builder: where(name eq "John")
    Builder->>Query: Add WHERE clause
    
    User->>Builder: order_by_asc("name")
    Builder->>Query: Add ORDER BY clause
    
    User->>Builder: limit(10)
    Builder->>Query: Add LIMIT clause
    
    User->>Builder: to_query()
    Builder->>Query: Convert to ReadQuery
    
    User->>PrepStmt: to_prepared_statement(dialect)
    Query->>PrepStmt: Generate SQL + params
    
    User->>Adapter: run_read_query(query, conn)
    Adapter->>PrepStmt: get_sql() & get_params()
    Adapter->>Adapter: Execute with database
    Adapter-->>User: Return results
```

### Builder Pattern Characteristics

```mermaid
graph TB
    Characteristics[Builder Pattern Features]:::accent0
    
    Characteristics --> Immutable[Immutable Updates]:::accent1
    Immutable --> Pipe[Pipeable with |> operator]
    Immutable --> Copy[Each function returns new query]
    
    Characteristics --> TypeSafe[Type Safety]:::accent2
    TypeSafe --> Compile[Compile-time checking]
    TypeSafe --> NoString[No raw SQL strings required]
    
    Characteristics --> Composable[Composable]:::accent3
    Composable --> Conditional[Conditional building]
    Composable --> Reusable[Reusable query fragments]
    
    Characteristics --> Flexible[Flexible Order]:::accent4
    Flexible --> AnyOrder[Call builders in any order]
    Flexible --> Replace[Replace clauses with replace_*]
    
    Characteristics --> Safe[Safe Defaults]:::accent5
    Safe --> NoDefaults[No* variants for empty clauses]
    Safe --> Validation[Runtime validation]
```

### Adapter Integration

```mermaid
graph TB
    Query[PreparedStatement]:::accent0
    
    Query --> Adapters[Database Adapters]:::accent1
    
    Adapters --> PG[PostgreSQL Adapter]:::accent2
    PG --> PGConn[with_connection]
    PG --> PGRead[run_read_query]
    PG --> PGWrite[run_write_query]
    
    Adapters --> SQLite[SQLite Adapter]:::accent3
    SQLite --> SQLConn[with_connection]
    SQLite --> SQLRead[run_read_query]
    SQLite --> SQLWrite[run_write_query]
    
    Adapters --> Maria[MariaDB Adapter]:::accent4
    Maria --> MariaConn[with_connection]
    Maria --> MariaRead[run_read_query]
    Maria --> MariaWrite[run_write_query]
    
    Adapters --> MyS[MySQL Adapter]:::accent5
    MyS --> MySConn[with_connection]
    MyS --> MySRead[run_read_query]
    MyS --> MySWrite[run_write_query]
    
    PGRead --> Decode[Decoder]:::accent6
    SQLRead --> Decode
    MariaRead --> Decode
    MySRead --> Decode
    
    Decode --> Results[Query Results]:::accent7
```

## Type Hierarchy

Type hierarchy of `CakeQuery` and its constructors:

```mermaid
graph TD
    CakeQuery["CakeQuery(a)"]:::accent0

    CakeQuery --> CakeReadQuery["CakeReadQuery(ReadQuery)"]:::accent1
    CakeQuery --> CakeWriteQuery["CakeWriteQuery(WriteQuery(a))"]:::accent2

    CakeReadQuery --> SelectQuery["SelectQuery(Select)"]:::accent3
    CakeReadQuery --> CombinedQuery["CombinedQuery(Combined)"]:::accent3

    CakeWriteQuery --> InsertQuery["InsertQuery(Insert(a))"]:::accent4
    CakeWriteQuery --> UpdateQuery["UpdateQuery(Update(a))"]:::accent4
    CakeWriteQuery --> DeleteQuery["DeleteQuery(Delete(a))"]:::accent4

    SelectQuery --> Select["Select<br/>• SelectKind<br/>• Selects<br/>• From<br/>• Joins<br/>• Where<br/>• GroupBy<br/>• Having<br/>• OrderBy<br/>• Limit<br/>• Offset<br/>• Epilog<br/>• Comment"]:::accent5

    CombinedQuery --> Combined["Combined<br/>• CombinedQueryKind<br/>• queries: List(Select)<br/>• OrderBy<br/>• Limit<br/>• Offset<br/>• Epilog<br/>• Comment"]:::accent5

    InsertQuery --> Insert["Insert(a)<br/>• InsertIntoTable<br/>• InsertColumns<br/>• InsertModifier<br/>• InsertSource(a)<br/>• InsertConflictStrategy(a)<br/>• Returning<br/>• Epilog<br/>• Comment"]:::accent6

    UpdateQuery --> Update["Update(a)<br/>• UpdateTable<br/>• UpdateModifier<br/>• UpdateSets<br/>• From<br/>• Joins<br/>• Where<br/>• Returning<br/>• Epilog<br/>• Comment"]:::accent6

    DeleteQuery --> Delete["Delete(a)<br/>• DeleteModifier<br/>• DeleteTable<br/>• DeleteUsing<br/>• Joins<br/>• Where<br/>• Returning<br/>• Epilog<br/>• Comment"]:::accent6
```

**Legend:**

- `CakeQuery(a)` is the top-level type with type parameter `a`
- **Read Queries** (`CakeReadQuery`) are for SELECT and combined
  operations (UNION, INTERSECT, EXCEPT)
- **Write Queries** (`CakeWriteQuery`) are for INSERT, UPDATE, and DELETE
  operations
- Each query type contains structured fields for building SQL statements
