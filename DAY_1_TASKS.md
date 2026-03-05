# Day 1 Tasks - Let's Build!

**Date:** Today
**Goal:** Set up Project 1 foundation - AWS + Snowflake infrastructure
**Time:** 9 AM - 10 PM (with breaks)

---

## ✅ Already Complete
- [x] Development environment setup
- [x] AWS CLI configured
- [x] Snowflake account created and tested
- [x] All tools installed and verified

---

## Morning Session (9 AM - 1 PM) - 4 hours

### Task 1: Create GitHub Repository (30 min)

**Steps:**
1. Go to https://github.com/new
2. Repository name: `data-engineering-portfolio`
3. Description: `Production-grade data engineering projects: AWS, Snowflake, Dagster, dbt`
4. ✓ Public
5. ✗ Don't initialize with README
6. Create repository

7. Connect local to GitHub:
```bash
cd ~/data-engineering-portfolio
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/data-engineering-portfolio.git

# Create initial .gitignore
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
*.egg-info/

# Secrets
*.pem
*.key
.env
credentials.json
**/secrets/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl

# dbt
dbt_packages/
target/
logs/

# Dagster
dagster_home/
EOF

# First commit
git add .gitignore
git commit -m "Initial commit: Add .gitignore"
git branch -M main
git push -u origin main
```

**Success criteria:** Repository visible on GitHub

---

### Task 2: Project 1 - AWS Infrastructure with Terraform (2 hours)

**What we're building:**
- S3 buckets for data landing
- IAM roles and policies
- VPC and security groups (basic)

**Steps:**

1. **Create infrastructure directory:**
```bash
cd ~/data-engineering-portfolio/project-1-retail-analytics
mkdir -p infrastructure
cd infrastructure
```

2. **I'll provide the Terraform code** - You'll apply it

3. **Initialize Terraform:**
```bash
terraform init
```

4. **Review the plan:**
```bash
terraform plan
```

5. **Apply infrastructure:**
```bash
terraform apply
```

Type `yes` when prompted.

**Files I'll create for you:**
- `main.tf` - Main infrastructure
- `variables.tf` - Configuration variables
- `outputs.tf` - Output values
- `provider.tf` - AWS provider config

**Success criteria:**
- S3 buckets created
- IAM roles configured
- `terraform apply` succeeds

---

### Task 3: Test S3 Upload (1 hour)

**What we're doing:**
- Create sample CSV file
- Upload to S3
- Verify via AWS CLI and Console

**Steps:**

1. **Create test data:**
```bash
cd ~/data-engineering-portfolio/project-1-retail-analytics

cat > sample_customers.csv << 'EOF'
customer_id,name,email,signup_date
1,John Doe,john@example.com,2024-01-15
2,Jane Smith,jane@example.com,2024-01-16
3,Bob Johnson,bob@example.com,2024-01-17
EOF
```

2. **Upload to S3:**
```bash
# Get bucket name from Terraform output
cd infrastructure
terraform output

# Upload file
aws s3 cp ../sample_customers.csv s3://YOUR-BUCKET-NAME/raw/customers/2024/02/18/
```

3. **Verify:**
```bash
aws s3 ls s3://YOUR-BUCKET-NAME/raw/customers/2024/02/18/
```

**Success criteria:**
- File visible in S3
- Can download it back

---

### Task 4: Documentation - Initial README (30 min)

**Create project README:**

```bash
cd ~/data-engineering-portfolio/project-1-retail-analytics
```

I'll provide a README template for you to customize.

**Success criteria:**
- README.md exists
- Describes project goals
- Shows architecture (basic)

---

## Afternoon Session (2 PM - 6 PM) - 4 hours

### Task 5: Snowflake Schema Design (2 hours)

**What we're building:**
- Medallion architecture (Bronze, Silver, Gold)
- Database, schemas, tables

**Steps:**

1. **Create SQL file:**
```bash
cd ~/data-engineering-portfolio/project-1-retail-analytics
mkdir -p snowflake
cd snowflake
```

2. **I'll provide DDL scripts**

3. **Execute in Snowflake:**
- Log into Snowflake web UI
- Open a worksheet
- Run the scripts I provide

**Schemas to create:**
- `BRONZE` - Raw data landing
- `SILVER` - Cleaned, validated data
- `GOLD` - Business-ready analytics

**Tables to create:**
- Bronze: Raw tables matching S3 structure
- Silver: Cleaned versions
- Gold: Star schema (fact_sales, dim_customer, dim_product, dim_date)

**Success criteria:**
- All schemas exist
- All tables created
- Can query empty tables

---

### Task 6: Snowflake External Tables (1.5 hours)

**What we're doing:**
- Create Snowflake external tables pointing to S3
- Test querying S3 data directly

**Steps:**

1. **Create external stage:**
```sql
-- I'll provide the exact SQL
```

2. **Create external table:**
```sql
-- I'll provide the exact SQL
```

3. **Query external table:**
```sql
SELECT * FROM bronze.ext_customers LIMIT 10;
```

**Success criteria:**
- Can query S3 data from Snowflake
- External tables work

---

### Task 7: Test Python → Snowflake (30 min)

**What we're doing:**
- Write Python script to load data into Snowflake
- Test COPY command

**Steps:**

1. **Create script directory:**
```bash
cd ~/data-engineering-portfolio/project-1-retail-analytics
mkdir -p scripts
```

2. **I'll provide Python script**

3. **Run script:**
```bash
python3 scripts/test_load.py
```

**Success criteria:**
- Data loaded into Snowflake table
- Can query the data

---

## Evening Session (7 PM - 10 PM) - 3 hours

### Task 8: Quick Win - Simple dbt Project (2 hours)

**What we're building:**
- Basic dbt project structure
- One simple model
- One test

**Steps:**

1. **Initialize dbt project:**
```bash
cd ~/data-engineering-portfolio/project-3-quick-wins
mkdir -p dbt-project
cd dbt-project

dbt init retail_dbt
cd retail_dbt
```

2. **Configure profiles.yml** (already done in setup)

3. **Create first model:**
```bash
mkdir -p models/staging
```

I'll provide the model SQL.

4. **Run dbt:**
```bash
dbt run
dbt test
```

**Success criteria:**
- dbt project runs successfully
- Model created in Snowflake
- Tests pass

---

### Task 9: Git - First Real Commit (30 min)

**What we're committing:**
- All Terraform code
- Snowflake DDL scripts
- Python scripts
- dbt project
- Documentation

**Steps:**

```bash
cd ~/data-engineering-portfolio

# Check status
git status

# Add all files
git add .

# Commit with meaningful message
git commit -m "Add Project 1 foundation: AWS infrastructure, Snowflake schemas, initial dbt project"

# Push to GitHub
git push origin main
```

**Success criteria:**
- All code on GitHub
- Clean commit history
- README visible on GitHub

---

### Task 10: Plan Tomorrow (30 min)

**Review Day 1:**
- What worked well?
- What took longer than expected?
- Any blockers for tomorrow?

**Plan Day 2:**
- Review Day 2 tasks in roadmap
- Prepare any questions
- Set morning start time

**Document learnings:**
```bash
cd ~/data-engineering-portfolio/docs
mkdir -p daily-logs

cat > daily-logs/day-01.md << 'EOF'
# Day 1 - [Date]

## Completed
- [ ] GitHub repository created
- [ ] AWS infrastructure deployed
- [ ] Snowflake schemas created
- [ ] First dbt project
- [ ] Code pushed to GitHub

## Learnings
- [What you learned today]

## Challenges
- [Any difficulties you faced]

## Tomorrow
- Data generators
- Dagster setup
- More complex dbt models
EOF
```

---

## Day 1 Success Criteria

By end of day, you should have:
- ✅ GitHub repository live
- ✅ AWS S3 buckets created via Terraform
- ✅ Snowflake database with Bronze/Silver/Gold schemas
- ✅ External tables querying S3
- ✅ Basic dbt project running
- ✅ All code committed to GitHub
- ✅ Understanding of the overall architecture

---

## If You Get Stuck

**For each task:**
1. Read the error message carefully
2. Check AWS/Snowflake documentation
3. Ask me for help - provide:
   - Exact error message
   - What you were trying to do
   - What you've tried already

**Common Issues:**
- **Terraform errors:** Usually permissions or typos
- **S3 access denied:** Check IAM roles
- **Snowflake connection:** Verify credentials
- **dbt errors:** Check profiles.yml configuration

---

## Time Management Tips

**If running ahead:**
- Add more test data
- Experiment with Snowflake features
- Start Day 2 tasks early

**If running behind:**
- Focus on core tasks (1-7)
- Quick win can wait until tomorrow
- Don't stress - learning takes time

**Take breaks:**
- Every 90 minutes, take 10-15 min break
- Stretch, walk, hydrate
- Don't code tired

---

## What I'll Provide You

As you work through tasks, I'll create:
1. **Terraform files** - Complete AWS infrastructure
2. **Snowflake DDL** - All schema and table definitions
3. **Python scripts** - Data loading utilities
4. **dbt project** - Initial model structure
5. **README templates** - Documentation frameworks

**You:**
- Execute the code
- Understand what it does
- Customize as needed
- Test and verify
- Commit to Git

---

## End of Day 1 Checklist

Before you finish today:
- [ ] All tasks attempted
- [ ] Code pushed to GitHub
- [ ] Tomorrow's tasks reviewed
- [ ] Questions noted for tomorrow
- [ ] Feeling confident about progress

---

**Ready to start?** Tell me which task you want to begin with, and I'll provide the complete code/configuration for that task! 🚀

**Recommended order:**
1. GitHub repository (quick win)
2. Terraform infrastructure (most important)
3. Snowflake schemas
4. Rest in order

Let's build something amazing! 💪
