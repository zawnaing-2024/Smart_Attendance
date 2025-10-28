#!/bin/bash

# Smart Attendance System - Update Script
# This script handles updates and deployment for the Smart Attendance System

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to backup database
backup_database() {
    print_status "Creating database backup..."
    if docker-compose exec -T db mysqldump -u attendance_user -pattendance_pass smart_attendance > backup_$(date +%Y%m%d_%H%M%S).sql 2>/dev/null; then
        print_success "Database backup created successfully"
    else
        print_warning "Could not create database backup (database might not be running)"
    fi
}

# Function to update from Git
update_from_git() {
    print_status "Updating from Git repository..."
    if git pull origin main; then
        print_success "Code updated from Git"
    else
        print_warning "Could not update from Git (not a Git repository or no internet connection)"
    fi
}

# Function to rebuild containers
rebuild_containers() {
    print_status "Stopping existing containers..."
    docker-compose down
    
    print_status "Rebuilding containers..."
    docker-compose up --build -d
    
    print_status "Waiting for services to start..."
    sleep 10
    
    # Check if all services are running
    if docker-compose ps | grep -q "Up"; then
        print_success "All services are running"
    else
        print_error "Some services failed to start. Check logs with: docker-compose logs"
        exit 1
    fi
}

# Function to check service health
check_services() {
    print_status "Checking service health..."
    
    # Check web service
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|403"; then
        print_success "Web service is responding"
    else
        print_warning "Web service is not responding"
    fi
    
    # Check face detection service
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5001 | grep -q "200"; then
        print_success "Face detection service is responding"
    else
        print_warning "Face detection service is not responding"
    fi
    
    # Check database
    if docker-compose exec db mysqladmin ping -h localhost -u attendance_user -pattendance_pass > /dev/null 2>&1; then
        print_success "Database is responding"
    else
        print_warning "Database is not responding"
    fi
}

# Function to show system status
show_status() {
    print_status "System Status:"
    echo "=================="
    docker-compose ps
    echo ""
    
    print_status "Resource Usage:"
    echo "================"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    echo ""
    
    print_status "Service URLs:"
    echo "=============="
    echo "Main Portal: http://localhost:8080"
    echo "Live View: http://localhost:5001"
    echo "Database: localhost:3306"
    echo "Redis: localhost:6379"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up unused Docker resources..."
    docker system prune -f
    print_success "Cleanup completed"
}

# Function to show logs
show_logs() {
    print_status "Showing recent logs..."
    docker-compose logs --tail=50
}

# Function to restart services
restart_services() {
    print_status "Restarting all services..."
    docker-compose restart
    print_success "Services restarted"
}

# Function to show help
show_help() {
    echo "Smart Attendance System - Update Script"
    echo "========================================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  update     - Update system from Git and rebuild containers"
    echo "  rebuild    - Rebuild containers without Git update"
    echo "  restart    - Restart all services"
    echo "  status     - Show system status and health"
    echo "  logs       - Show recent logs"
    echo "  backup     - Create database backup"
    echo "  cleanup    - Clean up unused Docker resources"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 update    # Full update from Git and rebuild"
    echo "  $0 status    # Check system status"
    echo "  $0 logs      # View recent logs"
}

# Main script logic
main() {
    case "${1:-update}" in
        "update")
            print_status "Starting full system update..."
            check_docker
            backup_database
            update_from_git
            rebuild_containers
            check_services
            print_success "Update completed successfully!"
            ;;
        "rebuild")
            print_status "Rebuilding containers..."
            check_docker
            rebuild_containers
            check_services
            print_success "Rebuild completed successfully!"
            ;;
        "restart")
            check_docker
            restart_services
            check_services
            print_success "Restart completed successfully!"
            ;;
        "status")
            check_docker
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "backup")
            check_docker
            backup_database
            ;;
        "cleanup")
            check_docker
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
