# github.com/nexuer/errors

`errors` 用一个统一的错误结构表示状态码、错误原因和消息。状态码默认按 HTTP 状态码使用，因此同一个错误既可以作为 HTTP 响应，也可以转换为 gRPC status。

## 安装

```bash
go get github.com/nexuer/errors
```

## 基本用法

```go
import "github.com/nexuer/errors"

err := errors.New(404, "USER_NOT_FOUND", "用户不存在")
err = errors.Newf(404, "USER_NOT_FOUND", "用户 %q 不存在", "alice")

errors.Code(err)   // 404
errors.Reason(err) // USER_NOT_FOUND
```

错误支持标准的 wrapping，也可以附加 cause 和 metadata：

```go
err = err.WithCause(context.Canceled)
if errors.Is(err, context.Canceled) {
    // 处理底层原因
}
```

## JSON

`Error` 可以直接使用 `encoding/json` 序列化：

```json
{
  "code": 404,
  "reason": "USER_NOT_FOUND",
  "message": "用户不存在",
  "metadata": {
    "resource": "user"
  }
}
```

## gRPC

`Error` 实现了 gRPC-Go 识别的 `GRPCStatus()` 接口。gRPC handler 直接返回这个错误时，状态码会映射为 gRPC code，reason 和 metadata 会放入 `google.rpc.ErrorInfo`。

```go
func (s *Server) Get(ctx context.Context, req *pb.GetRequest) (*pb.GetResponse, error) {
    return nil, reasons.ErrorNotFound("用户不存在")
}
```

需要单独进行映射时，可以使用 `httpstatus` 包：

```go
grpcCode := httpstatus.ToGRPCCode(errors.Code(err))
httpCode := httpstatus.FromGRPCCode(grpcCode)
```

## reasons

`reasons` 包提供常用的错误原因，并从 [`reasons/reasons.proto`](reasons/reasons.proto) 生成构造函数和判断函数：

```go
import "github.com/nexuer/errors/reasons"

err := reasons.ErrorNotFound("用户不存在")
if reasons.IsNotFound(err) {
    // code = 404，reason = NOT_FOUND
}
```

`reasons.IsXxx` 会同时精确判断 code 和 reason。如果只关心状态码，请直接比较：

```go
if errors.Code(err) == 404 {
    // 任意 404 错误
}
```

## 自定义 reason

在 proto 中导入 `errors.proto`，为枚举设置默认状态码，或为具体值指定状态码：

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

安装生成器并执行 `protoc`：

```bash
go install github.com/nexuer/errors/cmd/protoc-gen-go-errors@latest

protoc \
  --proto_path=. \
  --go_out=paths=source_relative:. \
  --go-errors_out=paths=source_relative:. \
  my/api/errors.proto
```

生成器会为每个 reason 生成 `Error<Name>` 和 `Is<Name>`。

## 包

- `errors`：错误类型和基础操作
- `httpstatus`：HTTP 状态码与 gRPC code 的转换
- `reasons`：内置 reason 及生成的辅助函数
- `cmd/protoc-gen-go-errors`：protoc 生成器
