#!/bin/bash

# One-liner fix for the missing columns issue
# Run this command to fix the admin login immediately

echo "Fixing missing columns in admin_users table..."

# Add missing columns
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS full_name VARCHAR(100) DEFAULT NULL; ALTER TABLE admin_users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;" 2>/dev/null

# Update admin user
docker exec smart_attendance-db-1 mysql -u root -proot_password -e "USE smart_attendance; UPDATE admin_users SET full_name = 'Administrator' WHERE username = 'admin';" 2>/dev/null

# Restart web container
docker compose restart web

echo "Fix completed! Try logging in now:"
echo "http://localhost/login.php?user_type=admin"
echo "Username: admin"
echo "Password: password"
