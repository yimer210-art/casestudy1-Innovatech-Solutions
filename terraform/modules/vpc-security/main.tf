resource "aws_vpc" "security" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-security"
  }
}

resource "aws_internet_gateway" "security" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "igw-security"
  }
}

resource "aws_subnet" "security" {
  vpc_id                  = aws_vpc.security.id
  cidr_block              = "10.3.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-sec-monitoring"
  }
}

resource "aws_route_table" "security" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security.id
  }

  tags = {
    Name = "rt-sec-monitoring"
  }
}

resource "aws_route_table_association" "security" {
  subnet_id      = aws_subnet.security.id
  route_table_id = aws_route_table.security.id
}

# --- Security Group voor SOAR (Shuffle) en Observability (Loki/Prometheus/Grafana) ---

resource "aws_security_group" "security_stack" {
  name        = "sec-stack-sg"
  description = "Toegang tot Shuffle SOAR, Loki, Prometheus en Grafana"
  vpc_id      = aws_vpc.security.id

  # SSH beheer vanaf Admin en Hub Bastion (Ansible)
  ingress {
    description = "SSH Beheer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr, var.hub_cidr]
  }

  # Grafana Web Dashboard (Poort 3000)
  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr, var.hub_cidr]
  }

  # Loki Log Ingestie (Poort 3100) vanaf alle spokes en filialen
  ingress {
    description = "Loki Ingestion"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", var.branch_cidr]
  }

  # Prometheus Metrics (Poort 9090)
  ingress {
    description = "Prometheus Metrics"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", var.branch_cidr, var.admin_cidr]
  }

  # Shuffle SOAR UI & Webhook (Poort 3443 / 5001)
  ingress {
    description = "Shuffle SOAR Frontend"
    from_port   = 3443
    to_port     = 3443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr, var.hub_cidr]
  }

  ingress {
    description = "Shuffle SOAR Webhook"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", var.branch_cidr, var.admin_cidr]
  }

  ingress {
    description = "SOAR Active Responder Webhook"
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", var.branch_cidr, var.admin_cidr]
  }

  # ICMP (Ping) voor diagnostiek
  ingress {
    description = "ICMP Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8", var.branch_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec-stack-sg"
  }
}

# --- Ubuntu 22.04 LTS AMI Data Source ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- IAM Role & Instance Profile voor Observability (CloudWatch Flow Logs toegang) ---
resource "aws_iam_role" "sec_stack_role" {
  name = "sec-stack-observability-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sec_stack_cw" {
  name = "sec-stack-cloudwatch-read-policy"
  role = aws_iam_role.sec_stack_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "sec_stack_profile" {
  name = "sec-stack-observability-profile"
  role = aws_iam_role.sec_stack_role.name
}

# --- EC2 Instance voor de gecombineerde Security & Observability Stack ---
resource "aws_instance" "sec_stack" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.security.id
  private_ip                  = "10.3.1.50"
  vpc_security_group_ids      = [aws_security_group.security_stack.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.sec_stack_profile.name
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data_base64 = base64gzip(<<-EOF
              #!/bin/bash
              set -euo pipefail
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release jq python3-boto3
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              # Sysctl tuning voor OpenSearch / Shuffle
              sysctl -w vm.max_map_count=262144
              echo "vm.max_map_count=262144" >> /etc/sysctl.conf

              # IaC Deploy Shuffle SOAR & Observability Stack (Flavor B)
              SOAR_DIR="/opt/security-stack/shuffle"
              mkdir -p "$${SOAR_DIR}/shuffle-apps" "$${SOAR_DIR}/shuffle-files" "$${SOAR_DIR}/shuffle-database" \
                "$${SOAR_DIR}/grafana-provisioning/datasources" "$${SOAR_DIR}/grafana-provisioning/dashboards" \
                "$${SOAR_DIR}/grafana-dashboards"
              chmod -R 777 "$${SOAR_DIR}"

              cat << 'PROM_EOF' > "$${SOAR_DIR}/prometheus.yml"
              global:
                scrape_interval: 15s
                evaluation_interval: 15s

              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']

                - job_name: 'shuffle_soar'
                  static_configs:
                    - targets: ['shuffle-exporter:9108']

                - job_name: 'cadvisor'
                  static_configs:
                    - targets: ['cadvisor:8080']

                - job_name: 'node_exporter'
                  static_configs:
                    - targets:
                        - 'node-exporter:9100'
                        - 'workstation-01.innovatech.internal:9100'
                        - 'branch-server-01.innovatech.internal:9100'
              PROM_EOF

              cat << 'EXP_EOF' > "$${SOAR_DIR}/shuffle_exporter.py"
              import http.server, json, socket, struct, time, urllib.request

              def probe(url):
                  t0 = time.monotonic()
                  try:
                      with urllib.request.urlopen(url, timeout=2) as r:
                          return (1 if r.status < 500 else 0), time.monotonic() - t0, r.read().decode("utf-8", "ignore")
                  except urllib.error.HTTPError as e:
                      return (1 if e.code < 500 else 0), time.monotonic() - t0, ""
                  except Exception:
                      return 0, time.monotonic() - t0, ""

              def os_count(idx):
                  up, _, body = probe(f"http://shuffle-opensearch:9200/{idx}/_count")
                  if up and body:
                      try:
                          return int(json.loads(body).get("count", 0))
                      except Exception:
                          pass
                  return 0

              def os_org_executions():
                  up, _, body = probe("http://shuffle-opensearch:9200/org_statistics/_search?size=20")
                  if up and body:
                      try:
                          hits = json.loads(body).get("hits", {}).get("hits", [])
                          return sum(int(h.get("_source", {}).get("total_workflow_executions", 0)) for h in hits)
                      except Exception:
                          pass
                  return 0

              def responder_mitigations():
                  candidates = ["10.3.1.50"]
                  try:
                      with open("/proc/net/route") as f:
                          for line in f.readlines()[1:]:
                              parts = line.split()
                              if len(parts) >= 3 and parts[1] == "00000000":
                                  candidates.insert(0, socket.inet_ntoa(struct.pack("<L", int(parts[2], 16))))
                                  break
                  except Exception:
                      pass
                  for host in candidates:
                      up, _, body = probe(f"http://{host}:5002/health")
                      if up and body:
                          try:
                              return int(json.loads(body).get("mitigations_total", 0))
                          except Exception:
                              pass
                  return 0

              class Handler(http.server.BaseHTTPRequestHandler):
                  def do_GET(self):
                      if self.path != "/metrics":
                          self.send_response(404); self.end_headers(); return
                      b_up, b_lat, _ = probe("http://shuffle-backend:5001/api/v1/_ah/health")
                      f_up, _, _ = probe("http://shuffle-frontend:80")
                      o_up, _, _ = probe("http://shuffle-opensearch:9200")
                      l_up, _, _ = probe("http://loki:3100/ready")
                      wf = os_count("workflow")
                      ex = max(os_count("workflowexecution"), os_org_executions()) + responder_mitigations()
                      lines = [
                          "# HELP shuffle_backend_up Shuffle backend HTTP availability",
                          "# TYPE shuffle_backend_up gauge",
                          f"shuffle_backend_up {b_up}",
                          "# HELP shuffle_backend_response_seconds Shuffle backend health latency",
                          "# TYPE shuffle_backend_response_seconds gauge",
                          f"shuffle_backend_response_seconds {b_lat:.6f}",
                          "# HELP shuffle_frontend_up Shuffle frontend availability",
                          "# TYPE shuffle_frontend_up gauge",
                          f"shuffle_frontend_up {f_up}",
                          "# HELP shuffle_opensearch_up Shuffle OpenSearch availability",
                          "# TYPE shuffle_opensearch_up gauge",
                          f"shuffle_opensearch_up {o_up}",
                          "# HELP shuffle_loki_up Loki ready status",
                          "# TYPE shuffle_loki_up gauge",
                          f"shuffle_loki_up {l_up}",
                          "# HELP shuffle_workflows_total Registered Shuffle workflows",
                          "# TYPE shuffle_workflows_total gauge",
                          f"shuffle_workflows_total {wf}",
                          "# HELP shuffle_executions_total Recorded Shuffle executions",
                          "# TYPE shuffle_executions_total gauge",
                          f"shuffle_executions_total {ex}",
                      ]
                      payload = ("\n".join(lines) + "\n").encode()
                      self.send_response(200)
                      self.send_header("Content-Type", "text/plain; version=0.0.4")
                      self.end_headers()
                      self.wfile.write(payload)
                  def log_message(self, *args):
                      pass

              http.server.ThreadingHTTPServer(("0.0.0.0", 9108), Handler).serve_forever()
              EXP_EOF

              cat << 'FLOW_EOF' > "$${SOAR_DIR}/flowlogs_to_loki.py"
              import boto3, json, os, time, urllib.request

              LOG_GROUP = "/aws/vpc/innovatech-flow-logs"
              LOKI_URL = "http://127.0.0.1:3100/loki/api/v1/push"
              STATE_FILE = "/opt/security-stack/flowlogs_state.json"

              def load_last_ts():
                  if os.path.exists(STATE_FILE):
                      try:
                          return int(json.load(open(STATE_FILE)).get("last_ts", 0))
                      except Exception:
                          pass
                  return int((time.time() - 600) * 1000)

              def save_last_ts(ts):
                  with open(STATE_FILE, "w") as f:
                      json.dump({"last_ts": ts}, f)

              client = boto3.client("logs", region_name="eu-central-1")
              last_ts = load_last_ts()

              while True:
                  try:
                      streams = {}
                      max_ts = last_ts
                      kwargs = {"logGroupName": LOG_GROUP, "startTime": last_ts + 1, "limit": 200}
                      while True:
                          resp = client.filter_log_events(**kwargs)
                          for ev in resp.get("events", []):
                              ts = int(ev["timestamp"])
                              if ts > max_ts:
                                  max_ts = ts
                              msg = ev.get("message", "").strip()
                              parts = msg.split()
                              action = parts[12] if len(parts) >= 13 else "UNKNOWN"
                              streams.setdefault(action, []).append([str(ts * 1000000), msg])
                          tok = resp.get("nextToken")
                          if not tok:
                              break
                          kwargs["nextToken"] = tok

                      if streams:
                          payload = {
                              "streams": [
                                  {"stream": {"job": "vpc_flow_logs", "action": act, "log_group": LOG_GROUP}, "values": vals}
                                  for act, vals in streams.items()
                              ]
                          }
                          req = urllib.request.Request(LOKI_URL, data=json.dumps(payload).encode(), headers={"Content-Type": "application/json"})
                          with urllib.request.urlopen(req, timeout=5) as r:
                              if r.status in (200, 204):
                                  last_ts = max_ts
                                  save_last_ts(last_ts)
                  except Exception as e:
                      print("flowlogs-loki error:", e, flush=True)
                  time.sleep(15)
              FLOW_EOF

              cat << 'SVC_EOF' > /etc/systemd/system/flowlogs-loki.service
              [Unit]
              Description=AWS VPC Flow Logs to Grafana Loki Bridge
              After=docker.service network-online.target
              Wants=network-online.target

              [Service]
              Type=simple
              ExecStart=/usr/bin/python3 /opt/security-stack/shuffle/flowlogs_to_loki.py
              Restart=always
              RestartSec=10

              [Install]
              WantedBy=multi-user.target
              SVC_EOF

              cat << 'DS_EOF' > "$${SOAR_DIR}/grafana-provisioning/datasources/datasources.yml"
              apiVersion: 1
              datasources:
                - name: Prometheus
                  uid: prometheus
                  type: prometheus
                  access: proxy
                  url: http://prometheus:9090
                  isDefault: true
                  editable: true
                - name: Loki
                  uid: loki
                  type: loki
                  access: proxy
                  url: http://loki:3100
                  editable: true
                - name: CloudWatch
                  uid: cloudwatch
                  type: cloudwatch
                  access: proxy
                  jsonData:
                    authType: default
                    defaultRegion: eu-central-1
                  editable: true
              DS_EOF

              cat << 'DBPROV_EOF' > "$${SOAR_DIR}/grafana-provisioning/dashboards/dashboards.yml"
              apiVersion: 1
              providers:
                - name: 'Innovatech CS2'
                  orgId: 1
                  folder: 'Innovatech'
                  type: file
                  disableDeletion: false
                  updateIntervalSeconds: 30
                  options:
                    path: /var/lib/grafana/dashboards
              DBPROV_EOF

              cat << 'DASH_EOF' > "$${SOAR_DIR}/grafana-dashboards/innovatech-observability.json"
              {
                "title": "Innovatech Security & Observability (CS2)",
                "uid": "innovatech-cs2",
                "timezone": "browser",
                "refresh": "10s",
                "schemaVersion": 39,
                "panels": [
                  {"id":1,"type":"stat","title":"Shuffle SOAR Backend Up","gridPos":{"h":4,"w":6,"x":0,"y":0},"datasource":{"type":"prometheus","uid":"prometheus"},"targets":[{"expr":"shuffle_backend_up","refId":"A"}]},
                  {"id":2,"type":"stat","title":"SOAR Health Latency (s)","gridPos":{"h":4,"w":6,"x":6,"y":0},"datasource":{"type":"prometheus","uid":"prometheus"},"targets":[{"expr":"shuffle_backend_response_seconds","refId":"A"}]},
                  {"id":3,"type":"stat","title":"SOAR Playbook Executions","gridPos":{"h":4,"w":6,"x":12,"y":0},"datasource":{"type":"prometheus","uid":"prometheus"},"targets":[{"expr":"shuffle_executions_total","refId":"A"}]},
                  {"id":4,"type":"stat","title":"Prometheus Targets Up","gridPos":{"h":4,"w":6,"x":18,"y":0},"datasource":{"type":"prometheus","uid":"prometheus"},"targets":[{"expr":"sum(up)","refId":"A"}]},
                  {"id":5,"type":"timeseries","title":"Node CPU % (Branch & Security)","gridPos":{"h":7,"w":12,"x":0,"y":4},"datasource":{"type":"prometheus","uid":"prometheus"},"targets":[{"expr":"100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) * 100)","legendFormat":"{{instance}}","refId":"A"}]},
                  {"id":6,"type":"timeseries","title":"Docker Container Memory (MB)","gridPos":{"h":7,"w":12,"x":12,"y":4},"datasource":{"type":"prometheus","uid":"prometheus"},"targets":[{"expr":"container_memory_usage_bytes{name!=\"\"} / 1048576","legendFormat":"{{image}}","refId":"A"}]},
                  {"id":7,"type":"logs","title":"Logbron 1: Branch Office Auth & Syslog (Promtail)","gridPos":{"h":8,"w":12,"x":0,"y":11},"datasource":{"type":"loki","uid":"loki"},"targets":[{"expr":"{job=\"varlog\"}","refId":"A"}]},
                  {"id":8,"type":"logs","title":"Logbron 2: AWS VPC Flow Logs (ACCEPT & REJECT)","gridPos":{"h":8,"w":12,"x":12,"y":11},"datasource":{"type":"loki","uid":"loki"},"targets":[{"expr":"{job=\"vpc_flow_logs\"}","refId":"A"}]}
                ]
              }
              DASH_EOF

              chmod -R a+rX "$${SOAR_DIR}/grafana-provisioning" "$${SOAR_DIR}/grafana-dashboards"

              cat << 'DOCKER_EOF' > "$${SOAR_DIR}/docker-compose.yml"
              name: innovatech-sec
              services:
                frontend:
                  image: ghcr.io/shuffle/shuffle-frontend:latest
                  container_name: shuffle-frontend
                  restart: unless-stopped
                  ports:
                    - "3443:80"
                  environment:
                    - BACKEND_HOSTNAME=shuffle-backend
                  networks:
                    - shuffle-net
                  depends_on:
                    - backend

                backend:
                  image: ghcr.io/shuffle/shuffle-backend:latest
                  container_name: shuffle-backend
                  restart: unless-stopped
                  ports:
                    - "5001:5001"
                  environment:
                    - SHUFFLE_APP_HOTLOAD_FOLDER=/shuffle-apps
                    - SHUFFLE_FILE_LOCATION=/shuffle-files
                    - SHUFFLE_OPENSEARCH_URL=http://opensearch:9200
                    - SHUFFLE_SWARM_CONFIG=run
                    - ORG_ID=innovatech
                  volumes:
                    - /var/run/docker.sock:/var/run/docker.sock
                    - /opt/security-stack/shuffle/shuffle-apps:/shuffle-apps
                    - /opt/security-stack/shuffle/shuffle-files:/shuffle-files
                  networks:
                    - shuffle-net
                  depends_on:
                    - opensearch

                orborus:
                  image: ghcr.io/shuffle/shuffle-orborus:latest
                  container_name: shuffle-orborus
                  restart: unless-stopped
                  environment:
                    - SHUFFLE_APP_SDK_TIMEOUT=300
                    - SHUFFLE_BASE_IMAGE_NAME=shuffle
                    - BASE_URL=http://shuffle-backend:5001
                    - DOCKER_API_VERSION=1.40
                    - CLEANUP=false
                    - SHUFFLE_CONTAINER_AUTO_CLEANUP=false
                    - SHUFFLE_PROTECTED_CLEANUP_DISABLED=false
                  volumes:
                    - /var/run/docker.sock:/var/run/docker.sock
                  networks:
                    - shuffle-net
                  depends_on:
                    - backend

                opensearch:
                  image: opensearchproject/opensearch:2.12.0
                  container_name: shuffle-opensearch
                  restart: unless-stopped
                  environment:
                    - discovery.type=single-node
                    - "DISABLE_INSTALL_DEMO_CONFIG=true"
                    - "DISABLE_SECURITY_PLUGIN=true"
                    - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m"
                  volumes:
                    - /opt/security-stack/shuffle/shuffle-database:/usr/share/opensearch/data
                  networks:
                    - shuffle-net

                # Observability Stack: Grafana Dashboard
                grafana:
                  image: grafana/grafana:latest
                  container_name: grafana
                  restart: unless-stopped
                  ports:
                    - "3000:3000"
                  environment:
                    - GF_SECURITY_ADMIN_USER=admin
                    - GF_SECURITY_ADMIN_PASSWORD=admin
                    - GF_USERS_ALLOW_SIGN_UP=false
                  volumes:
                    - /opt/security-stack/shuffle/grafana-provisioning:/etc/grafana/provisioning:ro
                    - /opt/security-stack/shuffle/grafana-dashboards:/var/lib/grafana/dashboards:ro
                  networks:
                    - shuffle-net

                # Observability Stack: Prometheus Metrics Server
                prometheus:
                  image: prom/prometheus:latest
                  container_name: prometheus
                  restart: unless-stopped
                  ports:
                    - "9090:9090"
                  dns:
                    - 10.3.0.2
                  volumes:
                    - /opt/security-stack/shuffle/prometheus.yml:/etc/prometheus/prometheus.yml:ro
                  networks:
                    - shuffle-net

                # Observability Stack: Grafana Loki Log Ingestion
                loki:
                  image: grafana/loki:2.9.4
                  container_name: loki
                  restart: unless-stopped
                  ports:
                    - "3100:3100"
                  networks:
                    - shuffle-net

                # Observability Exporters (Host, Containers & Shuffle SOAR)
                node-exporter:
                  image: prom/node-exporter:latest
                  container_name: node-exporter
                  restart: unless-stopped
                  pid: host
                  networks:
                    - shuffle-net

                cadvisor:
                  image: gcr.io/cadvisor/cadvisor:v0.55.1
                  container_name: cadvisor
                  restart: unless-stopped
                  command:
                    - "--containerd=/run/containerd/containerd.sock"
                    - "--containerd-namespace=moby"
                  volumes:
                    - /:/rootfs:ro
                    - /var/run:/var/run:ro
                    - /run/containerd/containerd.sock:/run/containerd/containerd.sock:ro
                    - /sys:/sys:ro
                    - /sys/fs/cgroup:/sys/fs/cgroup:ro
                    - /var/lib/docker/:/var/lib/docker:ro
                  networks:
                    - shuffle-net

                shuffle-exporter:
                  image: python:3.10-alpine
                  container_name: shuffle-exporter
                  restart: unless-stopped
                  ports:
                    - "9108:9108"
                  command: ["python3", "/app/shuffle_exporter.py"]
                  volumes:
                    - /opt/security-stack/shuffle/shuffle_exporter.py:/app/shuffle_exporter.py:ro
                  networks:
                    - shuffle-net

              networks:
                shuffle-net:
                  driver: bridge
              DOCKER_EOF

              # Start stack geautomatiseerd
              cd "$${SOAR_DIR}"
              docker compose up -d
              systemctl daemon-reload
              systemctl enable flowlogs-loki
              systemctl start flowlogs-loki

              # Pre-pull and tag Shuffle app images under SHUFFLE_BASE_IMAGE_NAME (shuffle:<app>)
              docker pull frikky/shuffle:shuffle-tools_1.2.0 || true
              docker pull frikky/shuffle:testing_1.0.0 || true
              for img in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^frikky/shuffle:"); do
                docker tag "$img" "shuffle:$${img#frikky/shuffle:}" || true
              done
              EOF
  )

  tags = {
    Name = "sec-monitoring-soar"
    Role = "Security-and-Observability"
  }
}
