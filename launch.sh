#!/bin/sh
sudo dnf install -y nginx1.12
sudo systemctl enable --now nginx