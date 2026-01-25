# DevSphere - MoMo SMS Data Processing System

## Team Information
**Team Name:** DevSphere

**Team Members:**
- [Member 1 Name] - [mugishamoses] - Mugisha Moses
- [Member 2 Name] - [lisaineza] - Lisa Ineza
- [Member 3 Name] - [Gakindi1] - Nkingi Chris

## GitHub Project
**Project Repository:** (https://github.com/users/mugishamoses/projects/3)

## Project Description
DevSphere is an enterprise-level fullstack application designed to process, analyze, and visualize MoMo (Mobile Money) SMS transaction data. The system implements a robust ETL (Extract, Transform, Load) pipeline that:

- **Parses** XML-formatted MoMo SMS data
- **Cleans & Normalizes** transaction amounts, dates, and phone numbers
- **Categorizes** transactions by type (deposits, withdrawals, transfers, etc.)
- **Stores** processed data in a SQLite relational database
- **Visualizes** analytics through an interactive web dashboard
- **Provides** RESTful API endpoints for data access (bonus feature)

## System Architecture
**High-Level Architecture Diagram:** [View Diagram](https://app.diagrams.net/#G1DGuZax9Q7vG3ZBcaDFQD7OxBJoXdOU2L#%7B%22pageId%22%3A%220FZFO2k6RsIXJbJPgprR%22%7D)
This ERD for the Momo data processing system uses a simple database structure to make sure that the data integrity, eliminate redundancy, and make sure the efficiency for mobile money transaction analytics. There is a users table which shows both senders and receivers of mobile money transfers. This avoids duplication and allows a single user profile to be connected to multiple transactions. Key attributes such as phone_number(unique identifier), account_balance(for tracking wallet state), and status(for account management) support user-level control and operational control. 

The transactions table serves as the central entity.  It contains two keys(sender_id and receiver_id)referencing the Users table, forming a self-referential 1:M relationship that accurately shows real-world financial flows. 
