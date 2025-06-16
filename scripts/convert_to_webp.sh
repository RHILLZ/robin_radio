#!/bin/bash

# WebP Asset Conversion Script for Robin Radio
# This script converts PNG assets to WebP format with optimal quality settings

echo "🎵 Robin Radio - WebP Asset Conversion"
echo "======================================="

# Create backup directory
BACKUP_DIR="assets/original_assets"
mkdir -p "$BACKUP_DIR"

# Convert function with quality settings
convert_to_webp() {
    local input="$1"
    local output="$2"
    local quality="$3"
    local method="${4:-6}"  # Default compression method
    
    echo "Converting: $input -> $output (Q:$quality, M:$method)"
    
    # Backup original if it exists
    if [[ -f "$input" ]]; then
        cp "$input" "$BACKUP_DIR/$(basename "$input")"
        
        # Convert to WebP
        cwebp -q "$quality" -m "$method" -alpha_cleanup "$input" -o "$output"
        
        # Get file sizes
        original_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input" 2>/dev/null || echo "unknown")
        webp_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null || echo "unknown")
        
        if [[ "$original_size" != "unknown" && "$webp_size" != "unknown" ]]; then
            reduction=$(echo "scale=1; (($original_size - $webp_size) * 100.0) / $original_size" | bc -l 2>/dev/null || echo "N/A")
            echo "  Size reduction: $original_size -> $webp_size bytes ($reduction%)"
        fi
        echo ""
    else
        echo "  ⚠️  File not found: $input"
        echo ""
    fi
}

echo "Converting logo assets..."
echo "------------------------"

# High-quality settings for logos and graphics (lossless or near-lossless)
# These are brand assets that need to maintain quality

# App logo - highest quality (lossless for brand integrity)
convert_to_webp "assets/logo/rr-logo.png" "assets/logo/rr-logo.webp" 100 6

# App store icon - high quality (slight compression acceptable)
convert_to_webp "assets/logo/appstore.png" "assets/logo/appstore.webp" 95 6

# Play store icon - high quality
convert_to_webp "assets/logo/playstore.png" "assets/logo/playstore.webp" 95 6

# Earphones icon - high quality
convert_to_webp "assets/logo/rr-earphones.png" "assets/logo/rr-earphones.webp" 95 6

echo "Converting web icons..."
echo "----------------------"

# Web icons - high quality for good appearance across devices
convert_to_webp "web/icons/Icon-192.png" "web/icons/Icon-192.webp" 90 6
convert_to_webp "web/icons/Icon-512.png" "web/icons/Icon-512.webp" 90 6
convert_to_webp "web/icons/Icon-maskable-192.png" "web/icons/Icon-maskable-192.webp" 90 6
convert_to_webp "web/icons/Icon-maskable-512.png" "web/icons/Icon-maskable-512.webp" 90 6

echo "Conversion Summary"
echo "=================="

# Calculate total size savings
calculate_total_savings() {
    local total_original=0
    local total_webp=0
    
    for original in assets/logo/*.png web/icons/*.png; do
        if [[ -f "$original" ]]; then
            local webp_file="${original%.*}.webp"
            if [[ -f "$webp_file" ]]; then
                local orig_size=$(stat -f%z "$original" 2>/dev/null || stat -c%s "$original" 2>/dev/null || echo "0")
                local webp_size=$(stat -f%z "$webp_file" 2>/dev/null || stat -c%s "$webp_file" 2>/dev/null || echo "0")
                total_original=$((total_original + orig_size))
                total_webp=$((total_webp + webp_size))
            fi
        fi
    done
    
    if [[ $total_original -gt 0 ]]; then
        local savings=$((total_original - total_webp))
        local percentage=$(echo "scale=1; ($savings * 100.0) / $total_original" | bc -l 2>/dev/null || echo "N/A")
        echo "Total original size: $total_original bytes"
        echo "Total WebP size: $total_webp bytes"
        echo "Total savings: $savings bytes ($percentage%)"
    fi
}

calculate_total_savings

echo ""
echo "✅ WebP conversion complete!"
echo ""
echo "Next steps:"
echo "1. Update pubspec.yaml to include WebP assets"
echo "2. Update code references from .png to .webp"
echo "3. Test app to ensure all images load correctly"
echo "4. Remove original PNG files if WebP versions work correctly"
echo ""
echo "Backup files saved to: $BACKUP_DIR" 