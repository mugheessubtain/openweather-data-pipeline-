# Setup guide: Airflow on EC2 with Docker Compose

## 1. Prerequisites

- An [OpenWeather](https://openweathermap.org/) account and API key
- An AWS account and an S3 bucket for the CSV snapshots
- An SSH key pair (`.pem`) for EC2

## 2. Launch the EC2 instance

- Instance type: `t2.xlarge` (Airflow with Celery needs at least 4 GB RAM and 2 vCPUs)
- Storage: 32 GB recommended
- Security group: allow SSH (22); reach the UIs through SSH port forwarding below
- Attach an IAM role with S3 write access to the bucket (**Actions → Security → Modify IAM role**)

## 3. Copy the project and connect

```bash
scp -r -i "weatherapi.pem" docker_exp ec2-user@<EC2_PUBLIC_DNS>:/home/ec2-user/docker_exp

ssh -i "weatherapi.pem" ec2-user@<EC2_PUBLIC_DNS> \
  -L 8080:localhost:8080 -L 5050:localhost:5050 -L 5555:localhost:5555
```

WinSCP (SFTP, port 22, user `ec2-user`, private key = your `.pem`) works too if you prefer a GUI.

## 4. Install Docker and Docker Compose

```bash
sudo yum update -y
sudo yum install -y docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo gpasswd -a $USER docker
newgrp docker
sudo systemctl start docker
```

## 5. Start Airflow

```bash
cd docker_exp
cp .env.example .env        # set AIRFLOW_UID=$(id -u) and your bucket
sudo chown -R ec2-user:ec2-user dags
docker-compose up -d --build
docker ps
```

| Tool | URL (through the SSH tunnel) | Login |
|---|---|---|
| Airflow | http://localhost:8080 | `airflow` / `airflow` |
| pgAdmin | http://localhost:5050 | `admin@admin.com` / `admin` |
| Flower (optional, `--profile flower`) | http://localhost:5555 | |

These are the local-development defaults from the official Airflow compose file; change them before exposing anything.

## 6. Create the target table

In pgAdmin, register a server (host `postgres`, port `5432`, database `airflow`, user `airflow`, password `airflow`) and run [sql/create_weather_table.sql](../sql/create_weather_table.sql).

## 7. Configure Airflow

**Admin → Variables**

| Key | Value |
|---|---|
| `openweather_api_key` | your OpenWeather API key |

**Admin → Connections**

| Connection ID | Type | Settings |
|---|---|---|
| `weathermap_api` | HTTP | Host `https://api.openweathermap.org` |
| `postgres_default` | Postgres | Host `postgres`, port `5432`, database `airflow`, login `airflow`, password `airflow` |

## 8. Run the DAG

Unpause `weather_dag` in the Airflow UI and trigger it. Each run adds one row to `weather_data` and one CSV file to the S3 bucket.

## Optional: temporary AWS credentials

If you don't use an IAM role, generate session credentials and put them in `docker_exp/.env`:

```bash
aws configure
aws sts get-session-token
```
