[Unit]
Description=DevOps Practice Application
After=network.target

[Service]
Type=simple
ExecStart=/home/rishi/DevOps-Winter-Arc/Week1-Linux/Task3-Processes_Services_Logs/app/devops-app.sh
Restart=on-failure
User=rishi

[Install]
WantedBy=multi-user.target
