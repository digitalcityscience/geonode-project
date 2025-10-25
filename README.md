# DCS GeoNode Project

DCS GeoNode is a customized, containerized version of the official GeoNode Project Template.
It introduces better port management, platform compatibility, and Docker modularity while keeping full upstream compatibility.

🚀 Highlights
• 🧱 Based on GeoNode 4.4.x and compatible with GeoServer 2.27.x
• ⚙️ Dynamic Nginx configuration – supports custom HTTP_PORT (not limited to 80/443)
• 🍎 Apple Silicon ready – runs seamlessly on arm64 and amd64 architectures
• 🌐 Configurable external access – GEOSERVER_MACHINE_PORT and POSTGRES_MACHINE_PORT are defined in .env
• 🧩 Modular Docker structure – each component (nginx, geoserver, postgis, letsencrypt) lives in its own build folder

## Quick Start

1️⃣ Clone and setup environment

git clone https://github.com/digitalcityscience/geonode-project.git
cd geonode-project
cp env_sample_dev.md .env

Edit .env and adjust the key parameters:

HTTP_PORT=8085
GEOSERVER_MACHINE_PORT=8080
POSTGRES_MACHINE_PORT=55432

2️⃣ Build and run the stack

docker compose build --no-cache
docker compose up -d

Access your instance at:
👉 http://localhost:8085/

⸻

🍎 Apple Silicon Support

On Apple M chip, use the linux/amd64 platform flag to ensure compatibility with memcached, rabbitmq, and postgis:

docker compose build --platform linux/amd64

⸻

## Creating a New GeoNode Project

⚠️ Important First Step — Project Naming

When creating your own GeoNode project, always define a unique and valid project name:

COMPOSE_PROJECT_NAME=my_geonode

⚠️ The name cannot contain dashes (-) or spaces.
All Docker container names, network aliases, and image tags depend on this variable — changing it later can break references in Docker and Django paths.

⸻

🧩 Creating a New Project

You can generate a new GeoNode-based project using the included script:

python create_dcs_geonode_project.py

Please go and check the detail of the file for customization.

This script:
• Downloads the latest GeoNode template (e.g., branch 4.4.x)
• Creates your custom project structure under a folder you choose
• Prepares all base files (Dockerfile, docker-compose.yml, .env)

💡 Use it whenever you want to start fresh with a new project name or branch.

⸻

⚙️ Required .env Adjustments

After creating the project, open your .env file and make sure these parameters exist:

GEOSERVER_MACHINE_PORT=8080
POSTGRES_MACHINE_PORT=55432

These define how GeoServer and PostGIS are exposed on your local machine.
If these ports are already in use, the containers will fail to start.
➡️ Change them to unused ports if needed (e.g., 8081, 55433).

Also verify your base URLs (trailing / is critical):

NGINX_BASE_URL=http://localhost:8085
SITEURL=${NGINX_BASE_URL}/

Even a missing / at the end of SITEURL can break URL routing.

You can use the examples under env_sample_dev.md and env_sample_prod.md for reference.

⸻

🐳 Docker Compose Notes

In your docker-compose.yml, make sure to reference those ports properly:

ports:

- "${GEOSERVER_MACHINE_PORT}:8080"
- "${POSTGRES_MACHINE_PORT}:5432"

If you skip this step, Docker will use default values (8080 / 5432),
which might cause conflicts on systems running other databases or services.

⸻

💻 Running the Project

docker compose build --no-cache
docker compose up -d

Access your GeoNode instance at:
👉 http://localhost:8085/

## 📄 License

This project follows the GPLv3 License, identical to the official GeoNode Project Template.
All Docker and Django components remain open-source and freely reusable for research, development, and customization.
