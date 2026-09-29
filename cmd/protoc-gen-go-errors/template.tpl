{{ range .Errors }}

{{ if .HasComment }}{{ .Comment }}{{ end -}}
func Is{{.CamelValue}}(err error) bool {
	if err == nil {
		return false
	}
	e := errors.FromError(err)
	return e.Reason == {{ .Name }}_{{ .Value }}.String() && e.Code == {{ .Code }}
}

{{ if .HasComment }}{{ .Comment }}{{ end -}}
func Error{{ .CamelValue }}(format string, args ...any) *errors.Error {
    if len(args) > 0 {
        return errors.Newf({{ .Code }}, {{ .Name }}_{{ .Value }}.String(), format, args...)
    }
	return errors.New({{ .Code }}, {{ .Name }}_{{ .Value }}.String(), format)
}

{{- end }}
