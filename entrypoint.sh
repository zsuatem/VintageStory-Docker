#!/bin/bash
set -e

# Default to non-root user for security (new installations)
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Check if data directory exists and has files (existing installation)
if [ -d "/vintagestory/data" ] && [ "$(ls -A /vintagestory/data 2>/dev/null)" ]; then
    DATA_OWNER=$(stat -c '%u' /vintagestory/data 2>/dev/null || echo "1000")
    
    if [ "$DATA_OWNER" = "0" ]; then
        echo "⚠️  Detected existing data owned by root (old installation)"
        echo "⚠️  Running in backward compatibility mode as root..."
        echo "⚠️  Consider migrating to non-root user for better security."
        echo "⚠️  To migrate: chown -R $PUID:$PGID /path/to/data on your host"
        exec ./VintagestoryServer --dataPath ./data
    fi
    
    # Check if data ownership doesn't match expected PUID/PGID
    DATA_GROUP=$(stat -c '%g' /vintagestory/data 2>/dev/null || echo "1000")
    if [ "$DATA_OWNER" != "$PUID" ] || [ "$DATA_GROUP" != "$PGID" ]; then
        echo "⚠️  WARNING: Data directory ownership mismatch!"
        echo "    Current: UID:GID $DATA_OWNER:$DATA_GROUP"
        echo "    Expected: UID:GID $PUID:$PGID"
        echo ""
        echo "    If you see permission errors, fix ownership on your host:"
        echo "    sudo chown -R $PUID:$PGID /path/to/data"
        echo ""
        echo "    Or set PUID=$DATA_OWNER and PGID=$DATA_GROUP to match existing data."
        echo ""
        echo "    Attempting to start anyway in 5 seconds..."
        sleep 5
    fi
fi

# Run as non-root user (new installations or when PUID/PGID specified)
echo "Running with PUID=$PUID and PGID=$PGID"

# Create group if it doesn't exist
if ! getent group vsuser > /dev/null 2>&1; then
    groupadd -g "$PGID" vsuser 2>/dev/null || true
fi

# Create user if it doesn't exist
if ! id vsuser > /dev/null 2>&1; then
    useradd -u "$PUID" -g "$PGID" -d /vintagestory vsuser 2>/dev/null || true
fi

# Ensure data directory exists
mkdir -p /vintagestory/data

# Handle existing installations
if [ -n "$(ls -A /vintagestory/data 2>/dev/null)" ]; then
    # Only fix root-owned files if we're NOT running as root
    # If user wants to run as root (PUID=0), leave files as-is
    if [ "$PUID" != "0" ]; then
        # Check if we've already fixed permissions (marker file exists)
        MARKER_FILE="/vintagestory/data/.permissions_fixed"
        
        if [ ! -f "$MARKER_FILE" ]; then
            # Check for files owned by root (created by old image version that ran as root)
            ROOT_FILES=$(find /vintagestory/data -user 0 -print -quit 2>/dev/null)
            
            if [ -n "$ROOT_FILES" ]; then
                echo "🔧 Detected files owned by root (created by previous image version)"
                echo "   Fixing ownership to $PUID:$PGID..."
                echo "   This may take a moment..."
                chown -R "$PUID:$PGID" /vintagestory/data 2>/dev/null || {
                    echo "   ⚠️  Could not change ownership of some files"
                    echo "   This should not affect operation if data directory itself is writable"
                }
                echo "   ✅ Done!"
            fi
            
            # Create marker file to skip this check on future starts
            touch "$MARKER_FILE" 2>/dev/null || true
        fi
    fi
else
    # Empty directory - new installation
    chown "$PUID:$PGID" /vintagestory/data
fi

# Run as vsuser
echo "Starting server as vsuser (UID=$PUID, GID=$PGID)..."

# Test if vsuser can write to data directory
if ! gosu vsuser:vsuser test -w /vintagestory/data 2>/dev/null; then
    echo ""
    echo "❌ ERROR: User $PUID:$PGID cannot write to /vintagestory/data!"
    echo "   Current ownership: $(stat -c 'UID=%u GID=%g' /vintagestory/data 2>/dev/null || echo 'unknown')"
    echo ""
    echo "   Fix permissions on your host:"
    echo "   sudo chown -R $PUID:$PGID /path/to/data"
    echo ""
    echo "   Or set PUID/PGID to match existing data ownership."
    echo ""
    exit 1
fi

exec gosu vsuser:vsuser ./VintagestoryServer --dataPath ./data
