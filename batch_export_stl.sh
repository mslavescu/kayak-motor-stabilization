#!/bin/bash

# =============================================================================
# KAYAK STABILIZER 3D MODEL BATCH EXPORT SCRIPT
# =============================================================================
#
# This script automatically exports all 3D printable components from the
# OpenSCAD script as individual STL files for 3D printing.
#
# Usage:
#   chmod +x batch_export_stl.sh
#   ./batch_export_stl.sh
#
# Requirements:
#   - OpenSCAD installed and in PATH
#   - kayak_stabilizer_3d_models.scad in same directory
#
# Output:
#   - Individual STL files for each component
#   - Export log with timestamps and file sizes
#
# =============================================================================

# Configuration
SCRIPT_NAME="kayak_stabilizer_3d_models.scad"
OUTPUT_DIR="stl_exports"
LOG_FILE="export_log.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Components to export
COMPONENTS=(
    "motor_mount_bracket"
    "enclosure_housing"
    "enclosure_lid"
    "cable_gland_assembly"
    "advanced_vibration_dampener"
)

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize log file
echo "=========================================" > "$LOG_FILE"
echo "KAYAK STABILIZER STL EXPORT LOG" >> "$LOG_FILE"
echo "Generated on: $(date)" >> "$LOG_FILE"
echo "=========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to log messages
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$LOG_FILE"
    echo "$(date '+%H:%M:%S'): $message"
}

# Check if OpenSCAD is installed
check_openscad() {
    if ! command -v openscad &> /dev/null; then
        print_status $RED "Error: OpenSCAD is not installed or not in PATH"
        print_status $YELLOW "Please install OpenSCAD from https://openscad.org/"
        exit 1
    fi
}

# Check if source file exists
check_source_file() {
    if [ ! -f "$SCRIPT_NAME" ]; then
        print_status $RED "Error: Source file '$SCRIPT_NAME' not found"
        print_status $YELLOW "Please ensure the OpenSCAD script is in the current directory"
        exit 1
    fi
}

# Export individual component
export_component() {
    local component=$1
    local output_file="$OUTPUT_DIR/${component}.stl"

    log_message "Starting export of $component..."

    # Run OpenSCAD export
    if openscad -o "$output_file" -D "${component}();" "$SCRIPT_NAME" 2>/dev/null; then
        # Check if file was created and get size
        if [ -f "$output_file" ]; then
            local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "unknown")
            print_status $GREEN "✓ Successfully exported $component.stl (${file_size} bytes)"
            log_message "SUCCESS: Exported $component.stl (${file_size} bytes)"
        else
            print_status $RED "✗ Failed to create $output_file"
            log_message "ERROR: Failed to create $output_file"
            return 1
        fi
    else
        print_status $RED "✗ OpenSCAD export failed for $component"
        log_message "ERROR: OpenSCAD export failed for $component"
        return 1
    fi

    return 0
}

# Export complete assembly for visualization
export_assembly() {
    local output_file="$OUTPUT_DIR/complete_assembly.stl"

    log_message "Starting export of complete assembly..."

    if openscad -o "$output_file" -D "complete_assembly();" "$SCRIPT_NAME" 2>/dev/null; then
        if [ -f "$output_file" ]; then
            local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null || echo "unknown")
            print_status $GREEN "✓ Successfully exported complete_assembly.stl (${file_size} bytes)"
            log_message "SUCCESS: Exported complete_assembly.stl (${file_size} bytes)"
        else
            print_status $YELLOW "! Assembly export completed but file not found"
            log_message "WARNING: Assembly export completed but file not found"
        fi
    else
        print_status $YELLOW "! Assembly export failed (this is normal for complex assemblies)"
        log_message "INFO: Assembly export failed (expected for visualization)"
    fi
}

# Generate summary report
generate_summary() {
    local total_components=${#COMPONENTS[@]}
    local successful_exports=0
    local total_size=0

    echo "" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
    echo "EXPORT SUMMARY" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"

    for component in "${COMPONENTS[@]}"; do
        local file="$OUTPUT_DIR/${component}.stl"
        if [ -f "$file" ]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
            echo "$component.stl: ${size} bytes" >> "$LOG_FILE"
            ((successful_exports++))
            ((total_size += size))
        else
            echo "$component.stl: FAILED" >> "$LOG_FILE"
        fi
    done

    echo "" >> "$LOG_FILE"
    echo "Total Components: $total_components" >> "$LOG_FILE"
    echo "Successful Exports: $successful_exports" >> "$LOG_FILE"
    echo "Total File Size: ${total_size} bytes" >> "$LOG_FILE"
    echo "Output Directory: $OUTPUT_DIR/" >> "$LOG_FILE"

    print_status $BLUE "========================================="
    print_status $BLUE "EXPORT SUMMARY"
    print_status $BLUE "========================================="
    print_status $GREEN "Total Components: $total_components"
    print_status $GREEN "Successful Exports: $successful_exports"
    print_status $GREEN "Total File Size: ${total_size} bytes"
    print_status $BLUE "Output Directory: $OUTPUT_DIR/"
    print_status $BLUE "Log File: $LOG_FILE"
}

# Main execution
main() {
    print_status $BLUE "========================================="
    print_status $BLUE "KAYAK STABILIZER STL BATCH EXPORT"
    print_status $BLUE "========================================="

    log_message "Starting batch export process"

    # Pre-flight checks
    check_openscad
    check_source_file

    print_status $YELLOW "Source file: $SCRIPT_NAME"
    print_status $YELLOW "Output directory: $OUTPUT_DIR/"
    print_status $YELLOW "Components to export: ${#COMPONENTS[@]}"
    echo ""

    # Export individual components
    local success_count=0
    for component in "${COMPONENTS[@]}"; do
        if export_component "$component"; then
            ((success_count++))
        fi
        echo ""
    done

    # Export assembly (optional)
    echo "Exporting complete assembly for visualization..."
    export_assembly
    echo ""

    # Generate summary
    generate_summary

    # Final status
    if [ $success_count -eq ${#COMPONENTS[@]} ]; then
        print_status $GREEN "🎉 All components exported successfully!"
        log_message "Batch export completed successfully"
    else
        print_status $YELLOW "⚠️  Export completed with $success_count/${#COMPONENTS[@]} successful"
        log_message "Batch export completed with warnings"
    fi

    print_status $BLUE "========================================="
    print_status $YELLOW "Next Steps:"
    print_status $YELLOW "1. Review STL files in $OUTPUT_DIR/"
    print_status $YELLOW "2. Load into your slicer (Cura, PrusaSlicer, etc.)"
    print_status $YELLOW "3. Use provided printing settings for best results"
    print_status $YELLOW "4. Check export_log.txt for detailed information"
    print_status $BLUE "========================================="
}

# Run main function
main "$@"