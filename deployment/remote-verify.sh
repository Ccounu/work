#!/bin/bash
set -e
source /opt/railway/secrets/railway.env
mysql -urailway -p"$SPRING_DATASOURCE_PASSWORD" railway_ticket_risk -e "SELECT COUNT(*) AS orders FROM ticket_orders; SELECT COUNT(*) AS stations FROM stations;"
curl -s http://127.0.0.1/api/health
echo
curl -s -o /dev/null -w "frontend=%{http_code}\n" http://127.0.0.1/
