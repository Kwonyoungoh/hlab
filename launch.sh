#!/bin/sh
sudo dnf install -y nginx
sudo systemctl enable --now nginx