# github.com/nexuer/errors

[中文文档](README.zh-CN.md)

`errors` provides one error type for a status code, reason, and message. The
code normally represents an HTTP status code, so the same error can be used in
an HTTP response or converted to a gRPC status.

## Install

```bash
go get github.com/nexuer/errors
```

## Usage

```go
import "github.com/nexuer/errors"

err := errors.New(404, "USER_NOT_FOUND", "user does not exist")
err = errors.Newf(404, "USER_NOT_FOUND", "user %q does not exist", "alice")

errors.Code(err)   // 404
errors.Reason(err) // USER_NOT_FOUND
```

Errors support standard Go wrapping:

```go
err = err.WithCause(context.Canceled)
if errors.Is(err, context.Canceled) {
    // handle the cause
}
```

You can also attach metadata or use `Clone` to make a copy.

## JSON

`Error` can be encoded directly with `encoding/json`:

```json
{
  "code": 404,
  "reason": "USER_NOT_FOUND",
  "message": "user does not exist",
  "metadata": {
    "resource": "user"
  }
}
```

## gRPC

`Error` implements the `GRPCStatus()` interface recognized by gRPC-Go. When a
handler returns it, the code is mapped to a gRPC code and the reason and
metadata are carried in `google.rpc.ErrorInfo`.

```go
func (s *Server) Get(ctx context.Context, req *pb.GetRequest) (*pb.GetResponse, error) {
    return nil, reasons.ErrorNotFound("user does not exist")
}
```

For explicit conversion, use `httpstatus`:

```go
grpcCode := httpstatus.ToGRPCCode(errors.Code(err))
httpCode := httpstatus.FromGRPCCode(grpcCode)
```

## reasons

The `reasons` package contains common reasons generated from
[`reasons/reasons.proto`](reasons/reasons.proto):

```go
import "github.com/nexuer/errors/reasons"

err := reasons.ErrorNotFound("user does not exist")
if reasons.IsNotFound(err) {
    // code = 404 and reason = NOT_FOUND
}
```

`reasons.IsXxx` checks both the code and the reason. If only the code matters,
compare it directly:

```go
if errors.Code(err) == 404 {
    // any 404 error
}
```

## Custom reasons

Import `errors.proto` and set a default code for the enum or a code for an
individual value:

```proto
syntax = "proto3";

package my.api;

import "errors.proto";

enum Reason {
  option (nexuer.errors.default_code) = 400;

  INVALID_INPUT = 0;
  USER_NOT_FOUND = 1 [(nexuer.errors.code) = 404];
}
```

Install the generator and run `protoc`:

```bash
go install github.com/nexuer/errors/cmd/protoc-gen-go-errors@latest

protoc \
  --proto_path=. \
  --go_out=paths=source_relative:. \
  --go-errors_out=paths=source_relative:. \
  my/api/errors.proto
```

The generator creates `Error<Name>` constructors and `Is<Name>` predicates.

## Packages

- `errors`: core error type and helpers
- `httpstatus`: HTTP status and gRPC code conversion
- `reasons`: built-in reasons and generated helpers
- `cmd/protoc-gen-go-errors`: protoc plugin
