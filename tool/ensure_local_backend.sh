#!/bin/sh

set -eu

project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
project_parent=$(dirname "$project_dir")

if [ -f "$project_parent/taxsista/server.php" ]; then
  backend_dir="$project_parent/taxsista"
elif [ -f "$project_parent/TaxistaPro/server.php" ]; then
  backend_dir="$project_parent/TaxistaPro"
elif [ -f "$project_parent/server.php" ]; then
  backend_dir="$project_parent"
else
  echo "Taxista backend was not found next to or above $project_dir" >&2
  exit 1
fi

if /usr/bin/nc -z 127.0.0.1 8002 >/dev/null 2>&1; then
  echo "Taxista REST server is already running on http://127.0.0.1:8002"
  exit 0
fi

log_file="/tmp/taxista-local-backend.log"
pid_file="/tmp/taxista-local-backend.pid"

cd "$backend_dir"
nohup php -d display_errors=0 -d log_errors=1 -d error_reporting=8191 \
  -S 127.0.0.1:8002 server.php >"$log_file" 2>&1 &
echo $! >"$pid_file"

attempt=0
while [ "$attempt" -lt 30 ]; do
  if /usr/bin/nc -z 127.0.0.1 8002 >/dev/null 2>&1; then
    echo "Taxista REST server started on http://127.0.0.1:8002"
    exit 0
  fi
  attempt=$((attempt + 1))
  sleep 0.2
done

echo "Taxista REST server did not start. See $log_file" >&2
exit 1
