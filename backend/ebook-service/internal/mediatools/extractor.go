package mediatools

import (
	"encoding/json"
	"strings"
)

// ExtractMediaKeys walks a TipTap-like JSON document and returns S3 object keys
// by normalizing CDN URLs to keys. Only keys under the allowedPrefix are returned.
// Example: cdnBase="https://assets.expotoworld.com", allowedPrefix="ebooks/huashangdao/"
func ExtractMediaKeys(content any, cdnBase, allowedPrefix string) []string {
	set := map[string]struct{}{}
	walk(content, func(val any) {
		if s, ok := val.(string); ok {
			if cdnBase != "" && strings.HasPrefix(s, strings.TrimRight(cdnBase, "/")+"/") {
				key := strings.TrimPrefix(s, strings.TrimRight(cdnBase, "/")+"/")
				if allowedPrefix == "" || strings.HasPrefix(key, allowedPrefix) {
					set[key] = struct{}{}
				}
			}
		}
	})
	out := make([]string, 0, len(set))
	for k := range set {
		out = append(out, k)
	}
	return out
}

// walk traverses maps, slices, and looks into common fields like attrs.src.
func walk(v any, visit func(any)) {
	visit(v)
	switch val := v.(type) {
	case map[string]any:
		for k, child := range val {
			// prioritize common media fields but still traverse everything
			if k == "src" || k == "href" {
				visit(child)
			}
			walk(child, visit)
		}
	case []any:
		for _, child := range val {
			walk(child, visit)
		}
	case json.RawMessage:
		var x any
		_ = json.Unmarshal(val, &x)
		walk(x, visit)
	}
}

