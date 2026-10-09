package reasons

import (
	"testing"

	"github.com/nexuer/errors"
	"google.golang.org/protobuf/proto"
)

func TestReasonCodeOptions(t *testing.T) {
	enum := Reason_INTERNAL_SERVER_ERROR.Descriptor()
	if got := proto.GetExtension(enum.Options(), errors.E_DefaultCode); got != int32(500) {
		t.Fatalf("default_code = %v, want 500", got)
	}

	for _, tc := range []struct {
		reason Reason
		code   int32
	}{
		{Reason_NOT_FOUND, 404},
		{Reason_NOT_ACCEPTABLE, 406},
		{Reason_UNSUPPORTED_MEDIA_TYPE, 415},
		{Reason_BAD_GATEWAY, 502},
	} {
		t.Run(tc.reason.String(), func(t *testing.T) {
			options := enum.Values().ByNumber(tc.reason.Number()).Options()
			if got := proto.GetExtension(options, errors.E_Code); got != tc.code {
				t.Fatalf("code = %v, want %d", got, tc.code)
			}
		})
	}
}
