import os
import subprocess
from pathlib import Path

# === 🧭 SETTINGS ===
PROJECT_NAME = "dcs_geonode"
GN_VERSION = "4.4.x"
DJANGO_VERSION = "4.2.9"

# === 📍 Ask user for install path ===
default_dir = Path(__file__).resolve().parent
user_input = input(f"\n📁 Enter project install path "
                   f"(press Enter for default: {default_dir}): ").strip()

BASE_PATH = Path(user_input) if user_input else default_dir / PROJECT_NAME
BASE_PATH.mkdir(parents=True, exist_ok=True)

print(f"\n📂 Target installation directory: {BASE_PATH}")

# === 🧩 Ensure Django is installed ===
try:
    subprocess.run(["django-admin", "--version"], check=True, stdout=subprocess.DEVNULL)
except subprocess.CalledProcessError:
    print("📦 Installing Django ...")
    subprocess.run(["pip", "install", f"Django=={DJANGO_VERSION}"], check=True)

# === 🧱 Run django-admin ===
template_url = f"https://github.com/GeoNode/geonode-project/archive/refs/heads/{GN_VERSION}.zip"
print(f"🧩 Using GeoNode template: {template_url}")

subprocess.run([
    "django-admin", "startproject",
    f"--template={template_url}",
    "-e", "py,sh,md,rst,json,yml,ini,env,sample,properties",
    "-n", "monitoring-cron", "-n", "Dockerfile",
    PROJECT_NAME, str(BASE_PATH)
], check=True)

# === 🧾 Auto-generate .env ===
os.chdir(BASE_PATH)
print("\n🧰 Generating default .env file ...")
subprocess.run([
    "python", "create-envfile.py",
    "--env_type", "dev",
    "--hostname", "localhost"
], check=True)

# === ✅ DONE ===
print(f"""
✅ DCS-GeoNode project created at:
   {BASE_PATH}

Next steps:
------------------------------------------
cd {BASE_PATH}
docker compose build
docker compose up -d
------------------------------------------
""")