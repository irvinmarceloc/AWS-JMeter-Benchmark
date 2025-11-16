> 🇪🇸 **Spanish:** Do you prefer to read this in Spanish? [Click here for the Spanish documentation](./README_ES.md)

# AWS JMeter Benchmark: Backend Performance Comparison

This project implements an automated infrastructure on AWS to perform load testing and compare the performance of RESTful API applications developed in different frameworks. Currently, the main focus is comparing **Spring Boot (Java)** vs. **FastAPI (Python)**.

The deployment uses **Terraform** for Infrastructure as Code (IaC) and **Ansible** for configuration management and test orchestration.

## 1. Architecture and Experiment Design

The experiment deploys a distributed three-node architecture to simulate a realistic production environment:

1.  **Test Client (JMeter Node):** An EC2 instance (`t3.large`) dedicated exclusively to generating traffic.
2.  **Application Server (App Server):** An EC2 instance (`t3.large`) hosting the API (Spring Boot or FastAPI).
3.  **Database:** An RDS instance (`db.t3.micro`) running **PostgreSQL**.

### Data Model

To meet realistic complexity requirements, a three-table relational schema is used:
* `students`: Student information.
* `courses`: Course information.
* `student_courses`: Join table for many-to-many relationships.

The database is automatically initialized and populated via a SQL script executed by Ansible (`ansible/roles/db_setup/files/init.sql`) at deployment time.

## 2. Prerequisites and AWS Configuration

To replicate this experiment, proper AWS security and access configuration is critical. Two types of credentials are required:

### A. EC2 Key Pair (.pem)

**Purpose:** Allows Ansible (from your local control machine) to SSH into the created EC2 instances to install software and run tests.
* **How to get it:** AWS Console > EC2 > Key Pairs > "Create key pair".
* **Configuration:** Download the `.pem` file. You must set restrictive permissions (`chmod 400 your-key.pem`) and configure its path in the `terraform/inventory.tpl` file.

### B. IAM Access Keys

**Purpose:** Allows Terraform to communicate with the AWS API to create and destroy resources (VPC, EC2, RDS).
* **How to get it:** AWS IAM > Users > Security credentials > Create access key.
* **Configuration:** Typically configured via `aws configure` in your terminal or by exporting `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` variables.

### C. Sensitive Variables (Secrets)

Before starting, ensure you have defined the following critical variables. These should not be hardcoded in the repository:
* **`ssh_key_name`**: The exact name of the Key Pair created in the AWS Console.
* **`db_password`**: The master password for the RDS database.

## 3. Backend Projects (Test Subjects)

The backend projects located in the `projects/` folder have been AI-assisted for the purposes of this benchmark.

* **Spring Boot CRUD:** Standard implementation with Spring Data JPA and embedded Tomcat.
* **FastAPI CRUD:** Asynchronous implementation with Uvicorn and SQLAlchemy (async).

> **Note:** Since the code was AI-generated, it may not strictly follow all production design patterns, but they are functionally suitable for transactional load testing.

## 4. Test Configuration (JMeter)

The test plan is located at: `ansible/roles/deploy_jmeter_test/templates/test_plan.jmx.j2`.

It is a dynamic Ansible template that automatically injects the server IP and application port. The experiment conditions are:

* **Concurrent Users (Threads):** 100 users.
* **Ramp-up Period:** 30 seconds (users enter gradually).
* **Duration:** 300 seconds (5 minutes of sustained load).
* **Transaction Mix:**
    * 80% Read (GET `/api/students`)
    * 15% Write (POST `/api/students`)
    * 5% Single Read (GET `/api/students/{id}`)

## 5. Deployment and Execution

The recommended workflow to run a full test is sequential:

1.  **Infrastructure:** Run `terraform apply` to provision servers.
2.  **App Deployment:** Use `ansible-playbook` to install the specific framework (Spring or FastAPI).
3.  **Test Execution:** Use `ansible-playbook` to trigger the JMeter load test.

### Execution Example Commands

To run a **Spring Boot** test, the exact commands would be:

```bash
# 1. Create infrastructure
cd terraform
terraform apply -auto-approve

# 2. Deploy Spring Boot
cd ../ansible
ansible-playbook -i inventory.ini playbook-deploy-spring.yml -e "db_password=YOUR_SECRET_PASSWORD"

# 3. Run JMeter Test
ansible-playbook -i inventory.ini playbook-run-test.yml -e "app_name=spring-boot"
```

**Expected Output:**
* **Step 1:** Terraform creating resources. Displays public IPs at the end.
* **Step 2:** Ansible connecting to instances, installing Java, configuring DB, and starting the service. Expect `changed=...` and zero `failed`.
* **Step 3:** Ansible running JMeter on the remote client. Finally, it downloads the report to your local `results/spring-boot-dashboard/` folder.

### Result Visualization (Nginx)

An automated script (`serve_reports.sh`) is provided to expose the JMeter HTML results via web.

* **Requirement:** `nginx` installed on the control machine.
* **Usage:** `./serve_reports.sh`
* **Result:** Nginx serves reports on port 80:
    * `http://<YOUR_IP>/spring/`
    * `http://<YOUR_IP>/fastapi/`

## 6. Results Obtained

Below is a summary of results from tests performed on `t3.large` instances in the `us-east-1` region.

| **Metric** | **Spring Boot (Java)** | **FastAPI (Python)** |
| :--- | :--- | :--- |
| **Throughput (Tx/sec)** | **~125.78** | ~63.08 |
| **Error Rate** | **0.00%** | 2.90% |
| **Avg Response Time** | **754 ms** | 1502 ms |
| **APDEX** | **0.618 (Tolerable)** | 0.435 (Poor) |

**Experiment Observations:**
Under these test conditions, the **Spring Boot** application demonstrated significantly superior performance and stability. It handled double the transactions per second compared to FastAPI and operated with zero errors. **FastAPI** showed difficulties under write load (POST), generating `SocketTimeoutException` errors and partially collapsing under concurrent load.

## 7. Project Extensibility

This project is designed to be modular and easily extensible. We encourage other students and researchers to use this base to:

* **Add New Frameworks:** Simply create a new folder in `projects/` (e.g., `projects/go-gin-crud/`) and a new Ansible role (`ansible/roles/deploy_go_app`).
* **Change Infrastructure:** Modify `terraform/variables.tf` to test with larger instances (`c5.xlarge`) or different databases.
* **Scale the Test:** Adjust `test_plan.jmx.j2` to simulate 500 or 1000 users.

## Cleanup

To avoid AWS costs, always destroy the infrastructure after testing:

```bash
cd terraform
terraform destroy
```
