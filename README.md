# AdventureWorksDW2022 Data Warehouse and Analytics Project

Welcome to the **AdventureWorksDW2022 Data Warehouse and Analytics** repository 🚀
This project demonstrates a comprehensive data warehousing and analytics solution, from building an enterprise data warehouse to generating actionable executive insights. Designed as a portfolio project, it highlights industry best practices in data engineering and analytics.

### Data Architecture
The data architecture for this project follows the Medallion Architecture __Bronze__, __Silver__, __Gold__ layers, bridging back-end database engineering directly to front-end business intelligence dashboards.
<img width="641" height="529" alt="Data_Archicture" src="https://github.com/user-attachments/assets/606d7b70-0017-45ed-aafd-99b5db9aec17" />


---

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective
Develop a modern, high-performance data warehouse using SQL Server based on the enterprise **AdventureWorksDW2022** schema to consolidate corporate data, enabling high-concurrency analytical reporting and informed decision-making.

#### Specifications
- **Data Source**: Import and model transaction data across relational Fact and Dimension schemas (e.g., *FactInternetSales*, *DimCustomer*, *DimProduct*).
- **Data Quality**: Build an isolated landing staging framework for all tables in the Bronze layer to buffer and trace raw transactional payloads prior to database committing.
- **Data Tracing**: Implement SHA-256 cryptographic hashing techniques on dateless Dimension columns to programmatically track downstream schema changes without relying on datetime flags.
- **Delta Processing**: Utilize dynamic watermark checkpoint columns across all transactional Fact tables to isolate incremental delta rows, bypassing computationally heavy full table scans.
- **Integration & Design**: Cleanse, standardize, and combine both relational and operational sources into an optimized, business-ready **Star Schema** in the Gold layer to eliminate redundancy and maximize analytical query efficiency.

---

### BI: Analytics & Reporting (Data Analytics)

#### Objectives:
Develop a production-ready, executive-level interactive Tableau Dashboard ("Global Sales & Performance Executive Hub") to deliver granular details into:
- **Global Financial Health**: High-level corporate KPI tiles tracking **$16.3M in Sales**, **$6.8M in Net Profits**, Average Order Value (AOV), and an active **17.4K Customer Baseline** alongside color-coded Year-over-Year (% vs PY) alerts.
- **Product Portfolio Performance**: An 80/20 Pareto Sales Analysis curve for inventory optimization, mapping out the critical product lines (Mountain, Road, Touring) driving the top revenue.
- **Sales Trends & Regional Distribution**: Deep geographical visualizations tracking sales by country (US, AU, UK, DE, FR, CA) combined with dynamic horizontal bullet graphs to measure actual revenue against historical prior-year targets.

These insights empower stakeholders with key business metrics, enabling strategic decision-making at a single glance.
<img width="1440" height="900" alt="executive_sales_hub_dashboard" src="https://github.com/user-attachments/assets/fcf906b0-cb9b-472d-9ac5-a03a4b6583e8" />

---
### Customer Lifetime Value & RFM Analysis

Implemented a custom RFM (Recency, Frequency, Monetary) segmentation model in Pandas. As shown in the charts, while 'High Value Champions' represent a specific subset of the customer base, they contribute a massive, disproportionate share of total internet sales revenue—providing clear actionable targeting data for marketing teams.

<img width="1567" height="584" alt="adventureworks_charts" src="https://github.com/user-attachments/assets/e84f354c-c951-4fc7-8aac-16dc4b67f332" />

Aggregated multi-channel sales performance across distinct transactional engines. This visualization contrasts top revenue-generating assets with actual bottom-line net profitability, allowing product management teams to accurately evaluate product health beyond surface-level volume indicators.

<img width="1584" height="684" alt="top_product_by_sale_profit" src="https://github.com/user-attachments/assets/b5842fdc-3164-4ad7-b39f-f0d2e956b5cf" />


---

## 🛡️ License

This project is licensed under [MIT License](LICENSE). You are free to use, modify and share this project with proper attribution.

## 👨‍💻 About Me

Hello! I'm **Roel Somido**, an Information Technology graduate transitioning into **Data Analytics & Data Engineering**. With a strong foundational background in IT infrastructure combined with years of professional experience handling high-volume operational systems, transactions, and data integrity in the technical support and services sector, I excel at bridging the gap between back-end data architecture and front-end business intelligence[cite: 1].

Driven by a passion for uncovering "the story behind the numbers," I specialize in building robust, end-to-end data pipelines, modern data warehouse architectures, and interactive visualizations that empower data-driven decisions[cite: 1]. 

### 🛠️ My Analytics Toolkit
* **Languages & Database Engineering:** Advanced SQL (CTEs, Window Functions, Joins), Medallion Architecture (Bronze/Silver/Gold data streams), ETL Pipelines, Star Schema Data Modeling[cite: 1].
* **Business Intelligence & Visualization:** Tableau (Desktop & Public Cloud), Dynamic Dashboard Design, Data Storytelling[cite: 1].
* **Core Systems & Tools:** Microsoft SQL Server, PostgreSQL, Excel (Power Query, Pivot Tables), Git/GitHub[cite: 1].

### 📈 Featured Portfolio Projects
* **[SQL Data Warehouse & Analytics Platform](https://github.com/Datanerdbytes/sql-data-warehouse-project-v3.git):** A modern warehouse framework using a multi-tiered Medallion pipeline to clean, model, and aggregate raw business data[cite: 1].
* **Enterprise Data Warehouse & BI Hub (AdventureWorksDW2022)** (This Repo!): A full-stack solution featuring advanced hashing, watermarked delta pipelines, and a live executive performance command hub.
* **[Sales & Customer Performance Dashboard](https://public.tableau.com/views/SuperstoreSalesCustomerDashboard_17704475544910/CustomerDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link):** An interactive Tableau layout mapping regional performance, revenue growth trends, and deep customer segmentation[cite: 1].
* **[HR Analytics Dashboard](https://public.tableau.com/views/HRDashboard_17646633980990/HRSummary_1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link):** An executive workforce intelligence view tracking employee headcount distributions and attrition risk factors[cite: 1].

---
📫 **Let's Connect!**
* **Email:** [roel.somido@icloud.com](mailto:roel.somido@icloud.com)[cite: 1]
* **LinkedIn:** [www.linkedin.com/in/roel-somido-06853331b]
* **Tableau Public:** [https://public.tableau.com/app/profile/roel.somido/vizzes]
