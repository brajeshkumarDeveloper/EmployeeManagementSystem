#!/bin/bash
set -e
cd ~

if [ -d "EmployeeManagementSystem" ]; then
  echo "Repo exists. Pulling latest changes..."
  cd EmployeeManagementSystem
  git pull origin main
  source venv/bin/activate
  pip install -r requirements.txt
else
  echo "First time setup..."

  git clone https://github.com/brajeshkumarDeveloper/EmployeeManagementSystem.git
  cd EmployeeManagementSystem

  sudo apt update
  sudo apt install -y python3-pip python3-venv nginx

  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt

  sudo tee /etc/systemd/system/fastapi.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=FastAPI App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/EmployeeManagementSystem
ExecStart=/home/ubuntu/EmployeeManagementSystem/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
SERVICEEOF

  sudo systemctl daemon-reload
  sudo systemctl enable fastapi
  sudo systemctl start fastapi

  sudo tee /etc/nginx/sites-available/fastapi > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXEOF

  sudo ln -sf /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/fastapi
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo nginx -t
  sudo systemctl restart nginx
fi

sudo systemctl restart fastapi
