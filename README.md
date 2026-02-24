ഇന്ന് നമ്മൾ ചെയ്ത കാര്യങ്ങൾ എല്ലാം ഉൾപ്പെടുത്തി നിങ്ങളുടെ GitHub റെപ്പോസിറ്ററിക്കായി ഒരു മനോഹരമായ **README.md** ഫയൽ താഴെ നൽകുന്നു. ഇത് കോപ്പി ചെയ്ത് നിങ്ങളുടെ പ്രോജക്റ്റിൽ ചേർക്കാവുന്നതാണ്.

---

# 🚀 AWS-VPC-EC2 CI/CD പ്രോജക്റ്റ്

ഈ പ്രോജക്റ്റിലൂടെ ടെറാഫോം ഉപയോഗിച്ച് ഒരു AWS ഇൻഫ്രാസ്ട്രക്ചർ നിർമ്മിക്കുകയും, GitHub Actions വഴി ഒരു വെബ്‌സൈറ്റ് ഓട്ടോമാറ്റിക്കായി ഡിപ്ലോയ് ചെയ്യുകയും ചെയ്തു.

## 📋 ഇന്ന് നമ്മൾ പൂർത്തിയാക്കിയ ടാസ്ക്കുകൾ

1. **Terraform Provisioning:** AWS-ൽ VPC, Subnet, EC2 ഇൻസ്റ്റൻസ് എന്നിവ നിർമ്മിച്ചു.
2. **Nginx Setup:** EC2 സെർവറിൽ വെബ് സെർവർ ഇൻസ്റ്റാൾ ചെയ്തു.
3. **Git/GitHub Optimization:** വലിയ ഫയലുകളെ ഒഴിവാക്കി കോഡ് GitHub-ലേക്ക് പുഷ് ചെയ്തു.
4. **GitHub Actions (CI/CD):** ഓരോ പുഷ് ചെയ്യുമ്പോഴും വെബ്സൈറ്റ് തനിയെ അപ്ഡേറ്റ് ആകുന്ന പൈപ്പ്‌ലൈൻ സെറ്റ് ചെയ്തു.
5. **Portfolio UI:** മനോഹരമായ ഒരു CSS തീം വെബ്സൈറ്റിൽ നടപ്പിലാക്കി.

---

## 🛠️ പ്രധാന ഘട്ടങ്ങളും കമാൻഡുകളും

### 1. ഗിറ്റ് ഹിസ്റ്ററി ക്ലീൻ ചെയ്യൽ (Git Cleaning)

ഭീമൻ ഫയലുകൾ ഒഴിവാക്കി ഗിറ്റ് ഫ്രഷ് ആയി തുടങ്ങാൻ നമ്മൾ ചെയ്തത്:

```bash
rm -rf .git
git init
git branch -M main

```

### 2. `.gitignore` നിർമ്മാണം

അനാവശ്യമായ വലിയ ഫയലുകൾ ഗിറ്റിലേക്ക് വരാതിരിക്കാൻ:

```bash
# താഴെ പറയുന്നവ .gitignore ഫയലിൽ ചേർത്തു
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl

```

### 3. GitHub Secrets ക്രമീകരണം

GitHub-ന് സെർവറുമായി കണക്ട് ചെയ്യാൻ നമ്മൾ റെപ്പോസിറ്ററി സെറ്റിംഗ്സിൽ ഈ സീക്രട്ടുകൾ ചേർത്തു:

* `EC2_PUBLIC_IP`: നിങ്ങളുടെ AWS സെർവർ ഐപി.
* `EC2_SSH_KEY`: സെർവറിലെ പ്രൈവറ്റ് കീ (`cat ~/.ssh/id_rsa`).

### 4. CI/CD പൈപ്പ്‌ലൈൻ (deploy.yml)

`.github/workflows/deploy.yml` എന്ന ഫയലിൽ ഓട്ടോമേഷൻ കോഡ് ചേർത്തു. ഇതിലൂടെ `index.html`, `styles.css` എന്നിവ തനിയെ സെർവറിലെ `/var/www/html/` എന്ന ഫോൾഡറിലേക്ക് മാറും.

### 5. കോഡ് പുഷ് ചെയ്യൽ (Pushing Changes)

മാറ്റങ്ങൾ വരുത്തിയ ശേഷം ഗിറ്റിലേക്ക് അയക്കാൻ ഉപയോഗിച്ച കമാൻഡുകൾ:

```bash
git add .
git commit -m "Final Success: Added UI and CI/CD"
git remote add origin [YOUR_REPO_URL]
git push -u origin main --force

```

---

## 🏗️ പ്രോജക്റ്റ് സ്ട്രക്ചർ

```text
.
├── .github/workflows/
│   └── deploy.yml      # CI/CD ഓട്ടോമേഷൻ ഫയൽ
├── .gitignore          # ഒഴിവാക്കേണ്ട ഫയലുകൾ
├── index.html          # വെബ്സൈറ്റ് കോഡ്
├── styles.css          # വെബ്സൈറ്റ് ഡിസൈൻ
├── main.tf             # ടെറാഫോം കോഡ്
└── variables.tf        # ടെറാഫോം വേരിയബിൾസ്

```

നമ്മുടെ പ്രോജക്റ്റിന് അനുയോജ്യമായ രീതിയിൽ അപ്‌ഡേറ്റ് ചെയ്ത **README.md** താഴെ നൽകുന്നു. ഇത് നിങ്ങളുടെ GitHub റിപ്പോസിറ്ററിയിൽ കോപ്പി-പേസ്റ്റ് ചെയ്യാവുന്നതാണ്. ആർക്കിടെക്ചർ ഡയഗ്രം ഇതിൽ ഉൾപ്പെടുത്തിയിട്ടുണ്ട്.

---

# AWS Infrastructure Automation with Terraform & GitHub Actions

This project demonstrates a fully automated CI/CD pipeline for deploying a high-availability web application on AWS using Terraform.

## 🚀 Features

* **VPC & Networking:** Custom VPC with public subnets across 2 Availability Zones (us-east-2a & us-east-2b).
* **High Availability:** Application Load Balancer (ALB) to distribute traffic and Auto Scaling Group (ASG) to manage EC2 instances automatically.
* **Automation:** Full CI/CD via GitHub Actions for automated infrastructure deployment on every code push.
* **State Management:** Secure remote backend using AWS S3 and DynamoDB for state locking to prevent concurrent execution.
* **Monitoring & Alerts:** Integrated CloudWatch Alarms and SNS (Simple Notification Service) for real-time email notifications on infrastructure changes or health issues.

## 📸 Architecture Diagram

![AWS Architecture Diagram](architecture-diagram.png)

This diagram illustrates the high-availability setup including the VPC, Public Subnets across two Availability Zones, the Application Load Balancer, and the Auto Scaling Group.

---

## 🛠️ Tech Stack

* **Cloud:** AWS (EC2, VPC, ALB, ASG, S3, DynamoDB, CloudWatch, SNS)
* **IaC:** Terraform
* **CI/CD:** GitHub Actions
* **Web Server:** Nginx

## 🏗️ Project Structure

* `main.tf`: Core infrastructure components (VPC, Subnets, ALB, ASG).
* `providers.tf`: AWS and Terraform backend configuration.
* `variables.tf`: Reusable variables for the project.
* `.github/workflows/deploy.yml`: GitHub Actions pipeline configuration.

## 🏁 How it Works

1. **Push Code:** Developer pushes Terraform code to the `main` branch.
2. **GitHub Actions:** The workflow triggers, running `terraform init`, `plan`, and `apply`.
3. **Infrastructure Creation:** AWS resources are provisioned/updated automatically.
4. **Health Monitoring:** CloudWatch monitors the ASG; if an instance fails, it triggers an SNS notification to your email.

---

