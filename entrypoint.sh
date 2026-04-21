#!/bin/bash
set -e

# Default to non-root user for security on new installations.
DEFAULT_PUID=1000
DEFAULT_PGID=1000
DEFAULT_RUNTIME=true

if [ -n "${PUID+x}" ] || [ -n "${PGID+x}" ]; then
    DEFAULT_RUNTIME=false
fi

PUID=${PUID:-$DEFAULT_PUID}
PGID=${PGID:-$DEFAULT_PGID}

print_data_dir_state() {
    stat -c 'UID=%u GID=%g MODE=%A PATH=%n' /vintagestory/data 2>/dev/null || echo "unknown"
}

run_server_as_requested_user() {
    export HOME=/vintagestory
    exec gosu "$PUID:$PGID" ./VintagestoryServer --dataPath ./data
}

mkdir -p /vintagestory/data

# Check if data directory exists and has files (existing installation).
if [ "$(ls -A /vintagestory/data 2>/dev/null)" ]; then
    DATA_OWNER=$(stat -c '%u' /vintagestory/data 2>/dev/null || echo "$DEFAULT_PUID")
    DATA_GROUP=$(stat -c '%g' /vintagestory/data 2>/dev/null || echo "$DEFAULT_PGID")

    if [ "$DATA_OWNER" = "0" ] && [ "$DATA_GROUP" = "0" ]; then
        echo "⚠️  Detected legacy root-owned data."
        echo "   Data directory: $(print_data_dir_state)"
        echo "   Starting as root for backward compatibility."
        echo "   To migrate later: chown -R $PUID:$PGID /path/to/data on your host"
        exec ./VintagestoryServer --dataPath ./data
    fi

    if [ "$DEFAULT_RUNTIME" = "true" ] && [ "$DATA_OWNER" = "$DEFAULT_PUID" ] && [ "$DATA_GROUP" = "$DEFAULT_PGID" ]; then
        echo "Detected existing data owned by the default runtime user (UID=$DEFAULT_PUID GID=$DEFAULT_PGID)."
        echo "Using the default non-root runtime user."
    elif [ "$DEFAULT_RUNTIME" = "true" ]; then
        echo "⚠️  WARNING: Detected existing data owned by non-default UID:GID $DATA_OWNER:$DATA_GROUP."
        echo "    This image defaults to UID:GID $DEFAULT_PUID:$DEFAULT_PGID for non-root operation."
        echo "    No explicit PUID/PGID override was provided, so the container will try to start as $DEFAULT_PUID:$DEFAULT_PGID."
        echo ""
        echo "    If this is an existing non-root installation, keep using the same UID/GID explicitly:"
        echo "    docker run ... -e PUID=$DATA_OWNER -e PGID=$DATA_GROUP ..."
        echo ""
    fi

    if [ "$DATA_OWNER" != "$PUID" ] || [ "$DATA_GROUP" != "$PGID" ]; then
        echo "⚠️  WARNING: Data directory ownership does not match the requested runtime user."
        echo "    Data directory: $(print_data_dir_state)"
        echo "    Requested runtime UID:GID: $PUID:$PGID"
        echo ""
        echo "    This usually means one of the following:"
        echo "    - PUID/PGID were set explicitly and do not match the existing data"
        echo "    - the mounted data directory is owned by a different UID/GID"
        echo "    - the host mount does not allow write access for this runtime user"
        echo ""
        echo "    How to fix it:"
        echo "    - set PUID=$DATA_OWNER and PGID=$DATA_GROUP to match existing data"
        echo "    - or change ownership on the host: chown -R $PUID:$PGID /path/to/data"
        echo "    - for legacy root-owned data, run once with PUID=0 PGID=0 or migrate ownership first"
        echo ""
        echo "    Startup will continue, but write access may still fail."
        echo "    Attempting to start anyway in 5 seconds..."
        sleep 5
    fi
fi

echo "Running with PUID=$PUID and PGID=$PGID"

# Handle existing installations.
if [ "$(ls -A /vintagestory/data 2>/dev/null)" ]; then
    # Only fix root-owned files if we're not running as root.
    if [ "$PUID" != "0" ] || [ "$PGID" != "0" ]; then
        MARKER_FILE="/vintagestory/data/.permissions_fixed"

        if [ ! -f "$MARKER_FILE" ]; then
            ROOT_FILES=$(find /vintagestory/data -user 0 -print -quit 2>/dev/null)

            if [ -n "$ROOT_FILES" ]; then
                echo "🔧 Detected root-owned files inside the data directory."
                echo "   Data directory itself is non-root, so attempting a one-time ownership fix."
                echo "   Target ownership: $PUID:$PGID"
                echo "   This may take a moment..."
                chown -R "$PUID:$PGID" /vintagestory/data 2>/dev/null || {
                    echo "   ⚠️  Could not change ownership of some files."
                    echo "   If startup fails, fix ownership manually on the host."
                }
                echo "   ✅ Done!"
            fi

            touch "$MARKER_FILE" 2>/dev/null || true
        fi
    fi
else
    # Empty directory - new installation.
    echo "Detected empty data directory."
    echo "Initializing ownership to UID=$PUID GID=$PGID."
    chown "$PUID:$PGID" /vintagestory/data
fi

if [ "$PUID" = "0" ] && [ "$PGID" = "0" ]; then
    echo "Starting server as root..."
    exec ./VintagestoryServer --dataPath ./data
fi

echo "Starting server as UID=$PUID and GID=$PGID..."

# Test write access with an actual file operation instead of mode bits only.
WRITE_TEST_FILE="/vintagestory/data/.write-test.$$"
if ! gosu "$PUID:$PGID" /bin/sh -c "touch '$WRITE_TEST_FILE' && rm -f '$WRITE_TEST_FILE'" 2>/dev/null; then
    echo ""
    echo "❌ ERROR: Cannot write to /vintagestory/data as UID=$PUID GID=$PGID"
    echo "   Data directory: $(print_data_dir_state)"
    echo ""
    echo "   This usually means one of the following:"
    echo "   - the mounted data directory is owned by a different UID/GID"
    echo "   - PUID/PGID were set explicitly and do not match the existing data"
    echo "   - the host mount does not allow write access for this runtime user"
    echo ""
    echo "   How to fix it:"
    echo "   - set PUID/PGID to match the existing ownership shown above"
    echo "   - or change ownership on the host: chown -R $PUID:$PGID /path/to/data"
    echo "   - if this is legacy root-owned data, migrate ownership or run with PUID=0 PGID=0"
    if [ "$DEFAULT_RUNTIME" = "true" ]; then
        echo "   - if this is an existing non-root installation, restart with explicit PUID/PGID matching the data directory owner"
    fi
    echo ""
    exit 1
fi

run_server_as_requested_user
