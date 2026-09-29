package main

import (
	"flag"
	"fmt"

	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/types/pluginpb"
)

// release is the current protoc-gen-go-errors version.
const release = "v0.0.1"

var showVersion = flag.Bool("version", false, "print the version and exit")

func main() {
	flag.Parse()
	if *showVersion {
		fmt.Printf("protoc-gen-go-errors %v\n", release)
		return
	}
	var flags flag.FlagSet
	(protogen.Options{
		ParamFunc: flags.Set,
	}).Run(func(plugin *protogen.Plugin) error {
		plugin.SupportedFeatures = uint64(pluginpb.CodeGeneratorResponse_FEATURE_PROTO3_OPTIONAL)
		for _, f := range plugin.Files {
			if !f.Generate {
				continue
			}
			generateFile(plugin, f)
		}
		return nil
	})
}
