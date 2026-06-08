# AdventureWorksDW2022 Data Warehouse & Analytics Project

## Overview

This project demonstrates the design and implementation of a modern Data Warehouse and Analytics solution using the **AdventureWorksDW2022** dataset.

The solution follows the **Medallion Architecture** approach:

* **Bronze Layer** – Raw data ingestion
* **Silver Layer** – Data cleansing, transformation, and standardization
* **Gold Layer** – Business-ready dimensional model using a Star Schema

The objective of this project is to simulate a real-world analytics environment where raw operational data is transformed into trusted analytical datasets that support reporting, dashboarding, and business intelligence.

---

## Project Goals

* Build an end-to-end Data Warehouse solution
* Implement Medallion Architecture best practices
* Design a scalable dimensional model
* Create fact and dimension tables for analytics
* Develop business KPIs and metrics
* Enable self-service reporting and dashboard creation
* Demonstrate modern data engineering and analytics workflows

---

## Architecture

### Medallion Architecture

```text
                +--------------------+
                | Source Data        |
                | AdventureWorksDW   |
                +---------+----------+
                          |
                          v
                +--------------------+
                | Bronze Layer       |
                | Raw Ingestion      |
                +---------+----------+
                          |
                          v
                +--------------------+
                | Silver Layer       |
                | Cleansed &         |
                | Transformed Data   |
                +---------+----------+
                          |
                          v
                +--------------------+
                | Gold Layer         |
                | Star Schema        |
                | Business Models    |
                +---------+----------+
                          |
                          v
                +--------------------+
                | Analytics & BI     |
                | Dashboards         |
                +--------------------+
```

---

## Dataset

**Source:** AdventureWorksDW2022

AdventureWorksDW2022 is a Microsoft sample data warehouse that represents a fictional bicycle manufacturing company.

The dataset includes:

* Sales
* Customers
* Products
* Geography
* Resellers
* Employees
* Promotions
* Dates

These datasets provide a realistic environment for building enterprise analytics solutions.

---

## Technology Stack

| Component       | Technology                |
| --------------- | ------------------------- |
| Database        | SQL Server                |
| Data Warehouse  | SQL Server Data Warehouse |
| Data Modeling   | Star Schema               |
| ETL / ELT       | SQL                       |
| Analytics       | Tableau / Power BI        |
| Version Control | Git                       |
| Documentation   | Markdown                  |

---

## Data Layers

### Bronze Layer

Purpose:

* Store raw source data
* Preserve historical records
* Minimal transformations

Examples:

* Raw FactInternetSales
* Raw FactResellerSales
* Raw DimCustomer
* Raw DimProduct

---

### Silver Layer

Purpose:

* Data cleansing
* Data quality validation
* Standardization
* Business rule implementation

Transformations include:

* Data type standardization
* Null handling
* Duplicate removal
* Data quality checks
* Attribute enrichment

---

### Gold Layer

Purpose:

* Deliver business-ready datasets
* Support reporting and analytics
* Provide a single source of truth

The Gold layer is implemented using a dimensional model (Star Schema).

---

## Dimensional Model

### Fact Tables

#### FactSales

Business process:

* Sales transactions

Measures:

* Sales Amount
* Order Quantity
* Unit Price
* Discount Amount
* Total Cost
* Profit

---

### Dimension Tables

#### DimDate

Attributes:

* Date
* Day
* Month
* Quarter
* Year
* Fiscal Period

#### DimCustomer

Attributes:

* Customer Key
* Customer Name
* Gender
* Marital Status
* Occupation
* Education

#### DimProduct

Attributes:

* Product Name
* Product Category
* Product Subcategory
* Color
* Size
* Model

#### DimGeography

Attributes:

* City
* State
* Country
* Region

#### DimPromotion

Attributes:

* Promotion Name
* Promotion Type
* Discount Percentage

---

## Star Schema

```text
                    DimDate
                       |
                       |
DimCustomer ---- FactSales ---- DimProduct
                       |
                       |
                 DimGeography
                       |
                       |
                 DimPromotion
```

---

## Business Questions

This project aims to answer key business questions such as:

1. What are the sales trends over time?
2. Which products generate the highest revenue?
3. Which customer segments are most profitable?
4. Which geographic regions drive the most sales?
5. How effective are promotions?
6. What are the seasonal sales patterns?
7. What products contribute the highest profit margins?

---

## KPIs

The following KPIs are calculated:

* Total Sales
* Total Orders
* Total Customers
* Average Order Value
* Gross Profit
* Profit Margin %
* Sales Growth %
* Year-over-Year Growth
* Customer Retention Rate
* Top Product Revenue

---

## Data Quality Checks

Implemented validations include:

* Null value detection
* Duplicate record detection
* Referential integrity validation
* Data type validation
* Surrogate key validation
* Fact-to-dimension relationship checks

---

## Future Enhancements

* Incremental data loading
* Slowly Changing Dimensions (SCD Type 2)
* Data quality monitoring framework
* Automated ETL pipelines
* CI/CD deployment
* Data catalog and lineage tracking
* Real-time analytics architecture

---

## Repository Structure

```text
AdventureWorks-DW-Analytics/
│
├── docs/
│   └── architecture/
│
├── sql/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── validation/
│
├── data-model/
│   └── star-schema/
│
├── dashboards/
│   ├── tableau/
│   └── powerbi/
│
├── images/
│
├── README.md
│
└── LICENSE
```

---

## Project Outcomes

This project demonstrates:

* Data Warehousing
* Data Engineering
* Dimensional Modeling
* SQL Development
* Analytics Engineering
* Business Intelligence
* Dashboard Development

The final solution provides a scalable and analytics-ready Data Warehouse built using modern data architecture principles and industry best practices.