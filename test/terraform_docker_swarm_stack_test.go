package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/terraform-config-inspect/tfconfig"
	"testing"
)

const StackServiceReplicasEnvConfig = "stack_service_replicas_env_config"

func TestTerraformDockerSwarmStack(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
	})

	// Prevent destruction of infrastructure used for local purposes.
	// defer terraform.Destroy(t, terraformOptions)

	variable, err := LoadTerraformReplicasVariable("../")
	if err != nil {
		t.Fatalf("Error loading variable: %v", err)
	}

	for key, val := range variable {
		t.Logf("%s = %d", key, val)
	}

	terraform.InitAndApply(t, terraformOptions)
}

// Load Terraform variable by name and returns its default value.
func LoadTerraformReplicasVariable(terraformDir string) (map[string]int, error) {
	module, diagnostics := tfconfig.LoadModule(terraformDir)

	if module == nil {
		return nil, fmt.Errorf("failed to load module: module is nil")
	}

	if diagnostics.HasErrors() {
		return nil, diagnostics.Err()
	}

	variable, exists := module.Variables[StackServiceReplicasEnvConfig]
	if !exists {
		return nil, fmt.Errorf("variable %q not found", StackServiceReplicasEnvConfig)
	}

	if variable.Default == nil {
		return nil, fmt.Errorf("variable %q has no default value", StackServiceReplicasEnvConfig)
	}

	// Convert default value
	m, ok := variable.Default.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("default value is not a map[string]interface{}")
	}

	result := make(map[string]int, len(m))
	for k, v := range m {
		switch val := v.(type) {
		case int:
			result[k] = val
		case float64:
			result[k] = int(val)
		default:
			return nil, fmt.Errorf("unexpected value type %T for key %q", v, k)
		}
	}

	return result, nil
}
