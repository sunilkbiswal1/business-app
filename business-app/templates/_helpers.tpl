{{/*
Chart name
*/}}
{{- define "business-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Full resource name
*/}}
{{- define "business-app.fullname" -}}
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
Chart label
*/}}
{{- define "business-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "business-app.commonLabels" -}}
helm.sh/chart: {{ include "business-app.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Application selector labels
*/}}
{{- define "business-app.appSelectorLabels" -}}
app.kubernetes.io/name: {{ include "business-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: app
{{- end }}


{{/*
Application labels
*/}}
{{- define "business-app.appLabels" -}}
{{ include "business-app.commonLabels" . }}
{{ include "business-app.appSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}


{{/*
Database selector labels
*/}}
{{- define "business-app.dbSelectorLabels" -}}
app.kubernetes.io/name: {{ include "business-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}


{{/*
Database labels
*/}}
{{- define "business-app.dbLabels" -}}
{{ include "business-app.commonLabels" . }}
{{ include "business-app.dbSelectorLabels" . }}
{{- end }}


{{/*
Database service/statefulset name
*/}}
{{- define "business-app.dbFullname" -}}
{{- printf "%s-db" (include "business-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Database headless service name
*/}}
{{- define "business-app.dbHeadlessFullname" -}}
{{- printf "%s-db-headless" (include "business-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
ConfigMap name
*/}}
{{- define "business-app.configName" -}}
{{- printf "%s-config" (include "business-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Secret name
*/}}
{{- define "business-app.secretName" -}}
{{- printf "%s-db-secret" (include "business-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
ServiceAccount name
*/}}
{{- define "business-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "business-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}