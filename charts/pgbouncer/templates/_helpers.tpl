{{/*
Expand the name of the chart.
*/}}
{{- define "pgbouncer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pgbouncer.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pgbouncer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pgbouncer.labels" -}}
helm.sh/chart: {{ include "pgbouncer.chart" . }}
{{ include "pgbouncer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pgbouncer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pgbouncer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return a podAffinity/podAntiAffinity definition
*/}}
{{- define "affinities.pods" -}}
  {{- if eq .Values.podAntiAffinityPreset "soft" }}
    {{- include "affinities.pods.soft" . -}}
  {{- else if eq .Values.podAntiAffinityPreset "hard" }}
    {{- include "affinities.pods.hard" . -}}
  {{- end -}}
{{- end -}}

{{/*
Return a soft podAntiAffinity definition
*/}}
{{- define "affinities.pods.soft" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - podAffinityTerm:
        labelSelector:
          matchLabels: {{- (include "pgbouncer.selectorLabels" .) | nindent 12 }}
        namespaces:
          - {{ .Release.Namespace | quote }}
        topologyKey: kubernetes.io/hostname
      weight: 1
{{- end -}}

{{/*
Return a hard podAntiAffinity definition
*/}}
{{- define "affinities.pods.hard" -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels: {{- (include "pgbouncer.selectorLabels" .) | nindent 10 }}
      namespaces:
        - {{ .Release.Namespace | quote }}
      topologyKey: kubernetes.io/hostname
{{- end -}}

{{/*
Create the pgmetricsPassword
*/}}
{{- define "pgbouncer.pgmetricsPassword" -}}
{{- $sname := include "pgbouncer.fullname" . }}
{{- $previous := lookup "v1" "Secret" .Release.Namespace $sname }}
{{- if $previous }}
{{- default (randAlphaNum 16) ($previous.data.pgmetricsPassword | b64dec) }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Create config file userlist.txt
*/}}
{{ define "userlist.txt" }}
"pgmetrics" {{ .pgmetricsPassword | quote }}
{{- range $k, $v := .userlist }}
{{ $k | quote }} {{ $v | quote }}
{{- end }}
{{- end }}

{{/*
Create config file pgbouncer.ini
*/}}
{{ define "pgbouncer.ini" }}
;;;
;;; PgBouncer configuration file
;;;

[databases]
{{- range $k, $v := .Values.databases }}
{{- $requiredMsg := printf ".Values.databases.%v needs to include .dbname" $k }}
{{ $k }} = host={{ $v.host }} port={{ $v.port }} {{ if $v.user }}user={{ $v.user }}{{end}} {{ if $v.password }}password={{ $v.password }}{{end}} dbname={{ $v.dbname }}{{ if $v.poolmode }} pool_mode={{ $v.poolmode }} {{end}}{{ if $v.poolsize }}pool_size={{ $v.poolsize }} {{end}}
{{- end }}

[users]
{{- range $k, $v := .Values.users }}
{{ $k }} = {{ if $v.poolmode }}pool_mode={{ $v.poolmode }}{{end}}{{ if $v.connections }} max_user_connections={{ $v.connections }}{{end}}
{{- end }}

[pgbouncer]

listen_addr = *
listen_port = 5432

max_client_conn = 1024
default_pool_size = 200
min_pool_size = 0

unix_socket_dir = /var/run/postgresql

server_tls_sslmode   = {{ .Values.serverSslMode }}
server_tls_ca_file   = /etc/ssl/server/ca.crt
{{- if or .Values.serverSslSecret (and .Values.serverSsl.cert .Values.serverSsl.key) }}
server_tls_cert_file = /etc/ssl/server/tls.crt
server_tls_key_file  = /etc/ssl/server/tls.key
{{- end }}
server_tls_protocols = secure
server_tls_ciphers   = secure

client_tls_sslmode   = {{ .Values.clientSslMode }}
{{ if .Values.clientSslSecret -}}
client_tls_ca_file   = /etc/ssl/client/ca.crt
client_tls_cert_file = /etc/ssl/client/tls.crt
client_tls_key_file  = /etc/ssl/client/tls.key
{{ else -}}
client_tls_ca_file   = /etc/ssl/certs/ssl-cert-snakeoil.pem
client_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
client_tls_key_file  = /etc/ssl/private/ssl-cert-snakeoil.key
{{ end -}}
client_tls_protocols = secure
client_tls_ciphers   = fast
client_tls_ecdhcurve = auto
client_tls_dheparams = none

ignore_startup_parameters = extra_float_digits

;;;
;;; Authentication settings
;;;

;; any, trust, plain, md5, scram-sha-256, cert, hba, pam
{{ if .Values.pgHbaConfiguration -}}
auth_hba_file = /etc/pgbouncer/pg_hba.conf
auth_type = hba
{{ else -}}
auth_type = md5
{{ end -}}
auth_file = /etc/private/userlist.txt

admin_users =
stats_users = pgbouncer, pgmetrics
stats_period = 60

log_connections = 0
log_disconnections = 0
log_pooler_errors = 1

tcp_keepalive = 1
tcp_keepidle = 600

;;; Custom attributes added from .Values.customSettings
{{- range $k, $v := .Values.customSettings }}
{{ $k }} = {{ $v }}
{{- end }}

{{- end }}
