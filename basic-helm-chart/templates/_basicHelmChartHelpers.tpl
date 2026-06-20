###
# It's good practice to prefix function names so you don't have collisions, I've prefixed these with "bhch" for "basic helm chart helpers"
###


{{/*
  Adds labels for "telling" Checkov to ignore certain issues, defined under `checkovSkipChecks` node at the root of the values file (map of `check_id: reason`)
*/}}
{{- define "bhch.checkovSkipChecks" -}}
{{- if .Values.checkovSkipChecks -}}
{{- $index := 1 -}}
{{- range $key, $value := .Values.checkovSkipChecks }}
checkov.io/skip{{ $index }}: "{{ $key }}={{ $value }}"
{{- $index = add $index 1 -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
  Example of validation logic for scenarios where using `required` in templates doesn't suffice or adding logic to `values.schema.json` is overly complex. Just add an `{{- include "bhch.exampleValidationLogic" . -}}` in any template (only needed once) for it to run against the entire values file
*/}}
{{- define "bhch.exampleValidationLogic" -}}
  {{- if and (not .Values.appSettings.someMap.someNestedValue) (empty .Values.appSettings.someMap.listInMap) }}
    {{- fail "appSettings.someMap.listInMap must be provided if appSettings.someMap.someNestedValue is not provided" -}}
  {{- end -}}
{{- end -}}