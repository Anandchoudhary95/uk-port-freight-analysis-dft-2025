# Department for Transport (DfT), UK Port Freight Statistics – Business Case Study 2025

## Overview
This project analyses the **UK Port Freight Statistics** dataset from the Department for Transport (DfT).  
The goal is to identify performance trends, cargo specializations, and regional freight patterns across UK ports using **T-SQL**.

## Objectives
- Determine top-performing ports by total tonnage and container traffic (TEUs).
- Compare domestic vs international cargo volumes.
- Identify ports specializing in specific cargo types.
- Analyse trade direction (imports vs exports).
- Examine regional freight distribution and growth trends.
- Assess port capacity and identify underperforming or congested ports.

## Data Source
Dataset used: `Port0302` (a SQL table created from the DfT Port Freight Statistics).  
**Main columns:**
- `Port`
- `Year`
- `Region_1`
- `Cargo_Group_Name`
- `Tonnage_thousands`
- `TEU_thousands`
- `Units_thousands`
- `Direction`
- `Port_UK_Country`

The dataset used in this analysis comes from the **Department for Transport (DfT), UK** — 
specifically the **UK Port Freight Statistics** for 2025.  


Data Source: Department for Transport (DfT), UK Port Freight Statistics, 2025.


- **Source:** [Department for Transport – Port Freight Statistics](https://www.gov.uk/government/collections/maritime-and-shipping-statistics)
- **Publisher:** Department for Transport (DfT), UK Government
- **Copyright:** © Crown Copyright. Contains public sector information licensed under the Open Government Licence v3.0.

## SQL Structure
The analysis is organised into sections:
1. **Overall Port Performance** – ranking ports by tonnage and container throughput.  
2. **Domestic vs International Traffic** – comparing regions and ports by trade type.  
3. **Cargo Type Analysis** – identifying dominant cargo categories and growth trends.  
4. **Trade Direction and Flow** – examining imports vs exports and port dominance.  
5. **Regional and Country-Level Analysis** – showing freight distribution and imbalances.  
6. **Infrastructure and Capacity Assessment** – evaluating port utilisation and growth potential.

Each section uses SQL features such as:
- Common Table Expressions (CTEs)
- Aggregate functions (SUM, MAX, AVG)
- Conditional logic with `CASE`
- Joins and subqueries

