{{/*
Expand the name of the chart.
*/}}
{{- define "backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "backend.fullname" -}}
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
{{- define "backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "backend.labels" -}}
helm.sh/chart: {{ include "backend.chart" . }}
{{ include "backend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "backend.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
secrets
{{- end }}
{{- end }}

{{- define "backend.envVars" -}}
{{- $secretName := include "backend.secretName" . }}
{{- $envs := dict }}

{{- /* Collect plain env vars */}}
{{- range $key, $value := .Values.env }}
  {{- $_ := set $envs $key (dict "name" $key "value" $value "secret" false) }}
{{- end }}

{{- /* Collect secret env vars */}}
{{- range $key, $_ := .Values.secretEnv }}
  {{- $_ := set $envs $key (dict "name" $key "secret" true "secretName" $secretName "key" $key) }}
{{- end }}

{{- range $key, $item := $envs }}
- name: {{ $item.name }}
  {{- if $item.secret }}
  valueFrom:
    secretKeyRef:
      name: {{ $item.secretName }}
      key: {{ $item.key }}
  {{- else }}
  value: {{ $item.value | quote }}
  {{- end }}
{{- end }}
{{- end }}