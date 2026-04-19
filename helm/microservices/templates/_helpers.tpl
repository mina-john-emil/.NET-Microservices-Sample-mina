{{/*
Common labels — added to every resource
Usage: {{- include "ms.labels" . | nindent 4 }}
*/}}
{{- define "ms.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
MongoDB connection string
- Gets username and password from values.yaml
- Replaces @ with %40 (URL encoding) to avoid double-@ bug
Usage: {{ include "ms.mongoconn" . | quote }}
*/}}
{{- define "ms.mongoconn" -}}
{{- $user := .Values.secrets.mongo.username -}}
{{- $pass := .Values.secrets.mongo.password | replace "@" "%40" -}}
mongodb://{{ $user }}:{{ $pass }}@mongo-clusterip-srv:27017/?authSource=admin
{{- end }}

{{/*
TCP readiness probe for .NET services (port 8080)
tcpSocket just checks if port is open — no /health endpoint needed
Usage: {{- include "ms.readinessProbe" . | nindent 10 }}
*/}}
{{- define "ms.readinessProbe" -}}
readinessProbe:
  tcpSocket:
    port: {{ .Values.global.appPort }}
  initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
  failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
{{- end }}

{{/*
TCP liveness probe for .NET services (port 8080)
*/}}
{{- define "ms.livenessProbe" -}}
livenessProbe:
  tcpSocket:
    port: {{ .Values.global.appPort }}
  initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
  failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
{{- end }}

{{/*
TCP probe for frontend services (port 80)
webfrontend and adminfrontend listen on 80, not 8080
*/}}
{{- define "ms.frontendReadinessProbe" -}}
readinessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
  failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
{{- end }}

{{- define "ms.frontendLivenessProbe" -}}
livenessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
  failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
{{- end }}
