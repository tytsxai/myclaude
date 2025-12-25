package main

import (
	"os/exec"
	"regexp"
	"sort"
	"strings"
	"testing"
)

func TestRealCmdSetEnv_MergesOverridesAndSorts(t *testing.T) {
	cmd := exec.Command("env")
	cmd.Env = []string{
		"CODEAGENT_WRAPPER_TEST_ALPHA=old",
		"CODEAGENT_WRAPPER_TEST_BETA=keep",
	}

	runner := &realCmd{cmd: cmd}
	runner.SetEnv(map[string]string{
		"CODEAGENT_WRAPPER_TEST_ALPHA": "new",
		"CODEAGENT_WRAPPER_TEST_GAMMA": "added",
		"   ":                          "ignored",
	})

	seen := make(map[string]string, len(cmd.Env))
	var keys []string
	for _, kv := range cmd.Env {
		parts := strings.SplitN(kv, "=", 2)
		if len(parts) != 2 {
			t.Fatalf("unexpected env entry: %q", kv)
		}
		keys = append(keys, parts[0])
		seen[parts[0]] = parts[1]
	}

	if got := seen["CODEAGENT_WRAPPER_TEST_ALPHA"]; got != "new" {
		t.Fatalf("expected override, got CODEAGENT_WRAPPER_TEST_ALPHA=%q", got)
	}
	if got := seen["CODEAGENT_WRAPPER_TEST_BETA"]; got != "keep" {
		t.Fatalf("expected preserved, got CODEAGENT_WRAPPER_TEST_BETA=%q", got)
	}
	if got := seen["CODEAGENT_WRAPPER_TEST_GAMMA"]; got != "added" {
		t.Fatalf("expected added, got CODEAGENT_WRAPPER_TEST_GAMMA=%q", got)
	}
	if _, ok := seen[""]; ok {
		t.Fatalf("did not expect empty env var key")
	}

	sorted := append([]string(nil), keys...)
	sort.Strings(sorted)
	if strings.Join(keys, "\n") != strings.Join(sorted, "\n") {
		t.Fatalf("expected env keys sorted")
	}
}

func TestRealCmdSetEnv_NilReceiverDoesNotPanic(t *testing.T) {
	var runner *realCmd
	runner.SetEnv(map[string]string{"CODEAGENT_WRAPPER_TEST_X": "1"})
}

func TestFallbackLogSuffix_ProducesStableFormat(t *testing.T) {
	a := fallbackLogSuffix()
	b := fallbackLogSuffix()

	if a == "" || b == "" {
		t.Fatalf("expected non-empty suffixes")
	}
	if a == b {
		t.Fatalf("expected different suffixes, got %q", a)
	}
	if !regexp.MustCompile(`^task-\d+$`).MatchString(a) {
		t.Fatalf("unexpected suffix format: %q", a)
	}
}

func TestExtractMessageSummary_SkipsNoiseAndFallsBack(t *testing.T) {
	msg := "\n```\n---\n   \nFirst meaningful line\nSecond line\n"
	if got := extractMessageSummary(msg, 200); got != "First meaningful line" {
		t.Fatalf("unexpected summary: %q", got)
	}

	noiseOnly := "\n```\n---\n"
	if got := extractMessageSummary(noiseOnly, 200); got != "```\n---" {
		t.Fatalf("unexpected fallback summary: %q", got)
	}
}

func TestExtractKeyOutput_PrefersSummaryAndMeaningfulLines(t *testing.T) {
	withSummary := "Summary: Added JWT middleware and tests\nother line"
	if got := extractKeyOutput(withSummary, 200); got != "Added JWT middleware and tests" {
		t.Fatalf("unexpected key output: %q", got)
	}

	withMeaningful := "# Header\nshort\nThis is a meaningful line with more than twenty characters.\n"
	if got := extractKeyOutput(withMeaningful, 200); got != "This is a meaningful line with more than twenty characters." {
		t.Fatalf("unexpected key output: %q", got)
	}
}
