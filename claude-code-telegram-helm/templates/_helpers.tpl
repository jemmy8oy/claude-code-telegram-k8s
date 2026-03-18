{{/* Common labels */}}
{{- define "claude-code-telegram.labels" -}}
app: claude-bot
release: {{ .Release.Name }}
{{- end }}
