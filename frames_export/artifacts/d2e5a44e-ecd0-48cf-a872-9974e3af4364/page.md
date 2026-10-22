# Shared Semantic Models vs SSAS Tabular: Digital Banking Examples

<!-- tab: Shared Semantic Models vs SSAS Tabular: Digital Banking Examples -->

# Self-Service BI with Power BI: Options, Licensing and Digital Banking Examples

A governed self-service layer is possible in Power BI Desktop, but sharing it needs paid licensing or SSAS Tabular. This covers how to build it, what free Power BI allows, and two approaches illustrated with digital banking scenarios.

## 1. Building a self-service layer in Power BI Desktop

Yes. The self-service layer is a **shared semantic model** that report authors connect to instead of building their own.

### Ways to build it

1. **Published semantic model in the Power BI Service.** Build the model in Desktop (tables, relationships, DAX measures, RLS), publish it, then certify or promote it. Authors use *Get Data → Power BI semantic models* and build thin reports on top with a live connection.
2. **Live connection to SSAS Tabular.** If the model sits in SSAS, Desktop connects to it directly. This is the stronger option for governance and large models.

### Limitations

- Desktop is the authoring tool; sharing and governance (endorsement, workspaces, RLS assignment, access control) happen in the Service.
- On-premises, that means Power BI Report Server, which supports fewer features and has no shared-dataset discovery like the Service.
- Report Server needs the matching "optimized for Report Server" Desktop build, and live connection to SSAS Tabular is the main route there.

## 2. Does it work on free Power BI?

Partly. You can build everything in Desktop for free, but you can't share a model through the Service without a paid license.

| Capability | Free | Pro / PPU / Fabric |
| --- | --- | --- |
| Build the full model in Desktop | Yes | Yes |
| Live connection to SSAS Tabular | Yes | Yes |
| Publish a shared semantic model for others | No (My workspace only) | Yes |
| Endorsement, workspaces, RLS assignment | No | Yes |
| Build permission on a shared model | No | Yes |
| Analyze in Excel against Service models | No | Yes |

### Workarounds

- **SSAS Tabular with Desktop or Excel as the front end.** A real governed self-service layer, with the semantic layer in SSAS rather than Power BI. Excel PivotTables connect to the same model.
- **Distributing a .pbix as a template.** Each user gets their own copy of the model. It is not governed, duplicates data, and nothing updates centrally.
- **Power BI Report Server.** The on-prem route, but it requires Power BI Premium or SQL Server Enterprise with Software Assurance, so it isn't free either.

## 3. Publishing a shared semantic model

**Idea:** One team builds and owns the model once. Everyone else builds reports on top of it without touching the raw data or redefining metrics.

### Digital banking example

A "Digital Channels" model holds Customers, Accounts, Transactions and Channel tables, with measures defined once (Active Digital Users, Transaction Value, Failed Transaction Rate) and RLS so branch managers see only their region. Retail, Risk and Marketing each build their own reports on it, all sharing one definition of "Active Digital User"; change it once and every report updates. Requires Pro, PPU, or Fabric.

## 4. SSAS Tabular

**Idea:** The same semantic model, but hosted on a SQL Server Analysis Services instance instead of inside the Power BI Service. It is an in-memory, columnar engine that sits between your data source and your front-end tools.

### Digital banking example

The same Digital Channels model sits on a server you manage: built in Visual Studio or Tabular Editor, processed nightly after transactions land, with roles mapped to Active Directory groups (for example, a Karachi-region group sees only Karachi branches). Analysts connect from Power BI Desktop (Live Connection) and finance from Excel PivotTables, and both get identical numbers. It handles very large transaction volumes and needs no per-user Power BI license, but you run the server, processing, and deployments, and live connections limit how much users can extend the model.

