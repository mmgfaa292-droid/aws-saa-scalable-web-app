#!/bin/bash
set -euxo pipefail
dnf install -y nginx

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
IID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

mkdir -p /usr/share/nginx/html/static
cat > /usr/share/nginx/html/index.html <<HTMLEOF
<!doctype html>
<html><head><meta charset="utf-8"><title>${project_name}</title>
<link rel="stylesheet" href="/static/style.css"></head>
<body><main>
<h1>${project_name}</h1>
<p>Served by instance <b>$IID</b> in <b>$AZ</b></p>
<p>Static assets under <code>/static/*</code> are cached by CloudFront.</p>
</main></body></html>
HTMLEOF

cat > /usr/share/nginx/html/static/style.css <<'CSSEOF'
body{font-family:system-ui,sans-serif;background:#0f172a;color:#e2e8f0;display:grid;place-items:center;min-height:100vh;margin:0}
main{max-width:640px;padding:2rem;border:1px solid #334155;border-radius:12px}
code{background:#1e293b;padding:2px 6px;border-radius:4px}
CSSEOF

echo "ok" > /usr/share/nginx/html/health

cat > /etc/nginx/default.d/static.conf <<'NGEOF'
location /static/ {
    expires 7d;
    add_header Cache-Control "public, max-age=604800";
}
location = /health {
    default_type text/plain;
    add_header Cache-Control "no-store";
}
NGEOF

systemctl enable --now nginx
