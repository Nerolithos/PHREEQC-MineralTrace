#!/bin/sh
# Local launch; engine paths come only from the trusted user's environment.
cd "$(dirname "$0")/.." || exit 1
if [ ! -f workbench/dist/index.html ]; then
  printf '%s\n' 'Build the interface once: npm ci --prefix workbench && npm run build --prefix workbench'
  exit 1
fi
exec python3 scripts/workbench_server.py --julia "${MINERALTRACE_JULIA:-julia}"
