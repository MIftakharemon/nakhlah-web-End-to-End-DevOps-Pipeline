# Nakhlah - End-to-End DevOps Pipeline

> Production-ready Next.js application with automated CI/CD, infrastructure provisioning, and deployment pipeline.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                             │
│  ┌─────────────┐  ┌─────────────────┐  ┌──────────────────────┐    │
│  │  Source Code │  │ GitHub Actions  │  │  Docker Registry     │    │
│  │  (Next.js)   │  │  (CI/CD)        │  │  (GHCR)             │    │
│  └──────┬──────┘  └────────┬────────┘  └──────────┬───────────┘    │
│         │                  │                       │                 │
│         ▼                  ▼                       ▼                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Pipeline Stages                          │    │
│  │  ┌───────┐  ┌───────┐  ┌──────┐  ┌──────┐  ┌──────────┐  │    │
│  │  │ Lint  │→ │ Test  │→ │Build │→ │ Push │→ │  Deploy  │  │    │
│  │  └───────┘  └───────┘  └──────┘  └──────┘  └──────────┘  │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                                   │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                        VPC (10.0.0.0/16)                     │   │
│  │  ┌──────────────────┐          ┌──────────────────────────┐  │   │
│  │  │  Public Subnet    │          │  Private Subnet           │  │   │
│  │  │  ┌──────────────┐│          │  ┌────────────────────┐  │  │   │
│  │  │  │   EC2 Instance││          │  │  (Future RDS/ECS)  │  │  │   │
│  │  │  │  + Docker     ││          │  │                    │  │  │   │
│  │  │  │  + Next.js    ││          │  └────────────────────┘  │  │   │
│  │  │  └──────────────┘│          └──────────────────────────┘  │   │
│  │  └──────────────────┘          └──────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│  ┌──────────────────┐  ┌───────────────────────────────────────┐   │
│  │  Security Group   │  │  S3 Backend (Terraform State)        │   │
│  │  - HTTP/HTTPS     │  │                                       │   │
│  │  - SSH            │  └───────────────────────────────────────┘   │
│  └──────────────────┘                                              │
└──────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | >= 20.9.0 | Runtime |
| pnpm | >= 10.0 | Package manager |
| Docker | >= 24.0 | Containerization |
| Docker Compose | >= 2.20 | Multi-container orchestration |
| Terraform | >= 1.0 | Infrastructure as Code |
| Ansible | >= 2.15 | Configuration Management |
| AWS CLI | >= 2.0 | AWS operations |
| Git | >= 2.0 | Version control |

## Local Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_ORG/nakhlah-pipeline.git
cd nakhlah-pipeline
```

### 2. Run with Docker Compose (Recommended)

```bash
# Copy environment variables
cp .env.example .env

# Edit .env with your values
# NEXTAUTH_SECRET=your-secret-key
# API_BASE_URL=https://api.nakhlah.net

# Start the application
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f app

# Stop
docker-compose down
```

### 3. Run Locally (Development)

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start
```

## CI/CD Pipeline Workflow

The GitHub Actions pipeline at `.github/workflows/devops-pipeline.yml` automates the entire lifecycle:

### Pipeline Stages

| Stage | Trigger | Description |
|-------|---------|-------------|
| **Lint** | push/PR | ESLint static analysis |
| **Test** | push/PR | Unit testing execution |
| **Build Docker** | After lint+test | Multi-stage Docker build & push to GHCR |
| **Deploy** | Main branch only | SSH to EC2 & run updated container |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `EC2_HOST` | EC2 instance public IP |
| `EC2_USER` | EC2 SSH username (e.g., `ec2-user`) |
| `EC2_SSH_KEY` | Private SSH key content |
| `NEXTAUTH_SECRET` | NextAuth.js secret key |
| `GHCR_USERNAME` | GitHub Container Registry username |
| `GHCR_TOKEN` | GitHub token with `packages:write` scope |

### Running the Pipeline

1. Push to `main` or `develop` branch triggers lint + test
2. Successful lint + test triggers Docker build & push
3. Merge to `main` triggers deployment to production EC2

## Infrastructure (Terraform)

### Provision AWS Resources

```bash
cd terraform

# Initialize
terraform init

# Plan changes
terraform plan -var="key_name=your-key-pair"

# Apply
terraform apply -var="key_name=your-key-pair"

# Get outputs
terraform output
```

### Provisioned Resources

- VPC with public/private subnets across 2 AZs
- EC2 instance (t3.medium) with Docker pre-installed
- Security group (HTTP, HTTPS, SSH)
- Encrypted root volume (30GB gp3)
- S3 backend for state management

## Configuration Management (Ansible)

### Run Playbook on Provisioned Server

```bash
cd ansible

# Update inventory with EC2 IP from terraform output
echo "[app_servers]" > inventory.ini
echo "YOUR_EC2_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-key.pem" >> inventory.ini

# Run playbook
ansible-playbook -i inventory.ini playbook.yml
```

### What the Playbook Does

- Installs Docker and Docker Compose
- Configures user permissions
- Pulls latest image from GHCR
- Deploys and runs the container

## Project Structure

```
nakhlah-pipeline/
├── .github/workflows/
│   └── devops-pipeline.yml    # CI/CD pipeline
├── terraform/
│   ├── main.tf                # VPC, EC2, Security Group
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Resource outputs
│   └── userdata.sh            # EC2 bootstrap script
├── ansible/
│   └── playbook.yml           # Server configuration
├── app/                       # Next.js pages
├── components/                # React components
├── lib/                       # Utility functions
├── stores/                    # Zustand state stores
├── services/                  # API services
├── hooks/                     # React hooks
├── public/                    # Static assets
├── Dockerfile                 # Multi-stage build
├── docker-compose.yml         # Container orchestration
├── .dockerignore              # Docker ignore rules
├── .gitignore                 # Git ignore rules
└── package.json               # Dependencies
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODE_ENV` | Yes | `production` | Environment mode |
| `NEXTAUTH_SECRET` | Yes | - | Auth secret key |
| `NEXTAUTH_URL` | No | `http://localhost:3000` | Auth callback URL |
| `API_BASE_URL` | No | `https://api.nakhlah.net` | Backend API URL |

## License

Private - All rights reserved.
