{{- define "demo-app.name" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "demo-app.apiName" -}}
{{- printf "%s-api" .Release.Name -}}
{{- end -}}

{{- define "demo-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "demo-app.apiName" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "demo-app.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- end -}}
{{- end -}}
